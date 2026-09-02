using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;
using UnityEngine.Experimental.Rendering;

public sealed class SnowTrailRendererFeature : ScriptableRendererFeature
{
    [Header("Render Timing")]
    public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRendering;

    [Tooltip("�� RenderPassEvent ����������ƫ�ơ����� AfterRendering + 1��")]
    [Range(-10, 10)]
    public int renderPassEventOffset = 0;

    [Header("Persistent RenderTextures")]
    public RenderTexture currentTexture;
    public RenderTexture historyA;
    public RenderTexture historyB;
    public RenderTexture finalTrail;

    [Header("Shaders")]
    public Shader accumulationShader;
    public Shader blurShader;

    [Header("Blur")]
    [Min(0)]
    public int blurIterations = 1;

    [Min(0f)]
    public float blurRadius = 1.0f;

    private SnowTrailPass _pass;

    public override void Create()
    {
        _pass?.Dispose();
        _pass = null;

        if (!ValidateSettings())
            return;

        _pass = new SnowTrailPass(
            historyA,
            historyB,
            finalTrail,
            accumulationShader,
            blurShader
        );

        // ���� URP����� Pass ��Ҫ��ȡ Camera Color��
        _pass.ConfigureInput(ScriptableRenderPassInput.Color);

        _pass.renderPassEvent =
            (RenderPassEvent)((int)renderPassEvent + renderPassEventOffset);
    }

    public override void AddRenderPasses(
        ScriptableRenderer renderer,
        ref RenderingData renderingData)
    {
        if (_pass == null)
            return;

        Camera camera = renderingData.cameraData.camera;

        if (camera == null)
            return;

        // ֻ�ù켣���ִ�С�
        if (camera.targetTexture != currentTexture)
            return;

        _pass.renderPassEvent =
            (RenderPassEvent)((int)renderPassEvent + renderPassEventOffset);

        _pass.Setup(
            camera,
            Mathf.Max(0, blurIterations),
            Mathf.Max(0f, blurRadius)
        );

        renderer.EnqueuePass(_pass);
    }

    protected override void Dispose(bool disposing)
    {
        _pass?.Dispose();
        _pass = null;
    }

    private bool ValidateSettings()
    {
        if (currentTexture == null ||
            historyA == null ||
            historyB == null ||
            finalTrail == null)
        {
            Debug.LogError(
                "[SnowTrail] Current / HistoryA / HistoryB / FinalTrail ����Ϊ��.",
                this);

            return false;
        }

        if (accumulationShader == null || blurShader == null)
        {
            Debug.LogError(
                "[SnowTrail] accumulationShader / blurShader ����Ϊ��.",
                this);

            return false;
        }

        if (historyA == historyB ||
            historyA == finalTrail ||
            historyB == finalTrail)
        {
            Debug.LogError(
                "[SnowTrail] HistoryA / HistoryB / FinalTrail �����ǲ�ͬ�� RenderTexture.",
                this);

            return false;
        }

        if (historyA.width != historyB.width ||
            historyA.height != historyB.height ||
            historyA.width != finalTrail.width ||
            historyA.height != finalTrail.height)
        {
            Debug.LogError(
                "[SnowTrail] HistoryA / HistoryB / FinalTrail �ֱ��ʱ���һ��.",
                this);

            return false;
        }

        return true;
    }

    private sealed class SnowTrailPass : ScriptableRenderPass
    {
        // ================================================================
        // Shader IDs
        // ================================================================

        private static readonly int CurrentTexID =
            Shader.PropertyToID("_CurrentTex");

        private static readonly int OrthCamPosID =
            Shader.PropertyToID("_OrthCamPos");

        private static readonly int LastFrameCamPosID =
            Shader.PropertyToID("_LastFrameCamPos");

        private static readonly int OrthCamSizeID =
            Shader.PropertyToID("_OrthCamSize");

        private static readonly int BlurRadiusID =
            Shader.PropertyToID("_BlurRadius");

        private static readonly int BlitTextureTexelSizeID =
            Shader.PropertyToID("_BlitTexture_TexelSize");

        private static readonly int BlitTextureID =
            Shader.PropertyToID("_BlitTexture");

        private static readonly int BlitScaleBiasID =
            Shader.PropertyToID("_BlitScaleBias");

        private static readonly int BlurTempID =
            Shader.PropertyToID("_SnowTrailBlurTemp");

        private static readonly int SnowTrailTexID =
            Shader.PropertyToID("_SnowTrailTex");

        private static readonly Vector4 FullscreenScaleBias =
            new Vector4(1f, 1f, 0f, 0f);

        // ================================================================
        // Persistent RT
        // ================================================================

        private readonly RenderTexture _historyA;
        private readonly RenderTexture _historyB;
        private readonly RenderTexture _finalTrail;

        private RTHandle _historyART;
        private RTHandle _historyBRT;
        private RTHandle _finalTrailRT;

        // ================================================================
        // Material
        // ================================================================

        private Material _accumulationMaterial;
        private Material _blurMaterial;

        // ================================================================
        // Runtime
        // ================================================================

        private Camera _camera;

        private int _blurIterations;
        private float _blurRadius;

        /*
         * true:
         * Read  A
         * Write B
         *
         * false:
         * Read  B
         * Write A
         */
        private bool _readFromA = true;

        private bool _historyInitialized = false;

        private Vector3 _lastFrameCamPos;

        // ================================================================
        // Pass Data
        // ================================================================

        private sealed class CopyPassData
        {
            public TextureHandle source;
            public TextureHandle destination;
            public bool publishGlobal;
        }

        private sealed class AccumulationPassData
        {
            public TextureHandle current;
            public TextureHandle history;

            public Material material;

            public Vector4 currentCamPos;
            public Vector4 lastCamPos;

            public float orthCamSize;
        }

        private sealed class BlurPassData
        {
            public TextureHandle source;
            public TextureHandle destination;

            public Material material;

            public float radius;
            public Vector4 texelSize;

            public int shaderPass;
            public bool publishGlobal;
        }

        // ================================================================
        // Constructor
        // ================================================================

        public SnowTrailPass(
            RenderTexture historyA,
            RenderTexture historyB,
            RenderTexture finalTrail,
            Shader accumulationShader,
            Shader blurShader)
        {
            _historyA = historyA;
            _historyB = historyB;
            _finalTrail = finalTrail;

            EnsureCreated(_historyA);
            EnsureCreated(_historyB);
            EnsureCreated(_finalTrail);

            /*
             * �ⲿ�־� RenderTexture ��װ�� RTHandle��
             * transferOwnership=false��
             * Release RTHandle ʱ�������� Inspector �е� RT��
             */
            _historyART = RTHandles.Alloc(
                _historyA);

            _historyBRT = RTHandles.Alloc(
                _historyB);

            _finalTrailRT = RTHandles.Alloc(
                _finalTrail);

            _accumulationMaterial =
                CoreUtils.CreateEngineMaterial(accumulationShader);

            _blurMaterial =
                CoreUtils.CreateEngineMaterial(blurShader);
        }

        public void Setup(
            Camera camera,
            int blurIterations,
            float blurRadius)
        {
            _camera = camera;
            _blurIterations = blurIterations;
            _blurRadius = blurRadius;
        }

        // ================================================================
        // Render Graph
        // ================================================================

        public override void RecordRenderGraph(
            RenderGraph renderGraph,
            FrameResources frameResources,
            ref RenderingData renderingData)
        {
            if (_camera == null)
                return;

            /*
             * ֱ�Ӷ�ȡ��ǰ�켣����� Camera Color��
             * ���� Import camera.targetTexture��
             */
            TextureHandle current =
                frameResources.GetTexture(UniversalResource.CameraColor);

            if (!current.IsValid())
                return;

            // �ⲿ�־� RT ���� RenderGraph��
            TextureHandle historyA =
                renderGraph.ImportTexture(_historyART);

            TextureHandle historyB =
                renderGraph.ImportTexture(_historyBRT);

            TextureHandle final =
                renderGraph.ImportTexture(_finalTrailRT);

            TextureHandle historyRead =
                _readFromA ? historyA : historyB;

            TextureHandle historyWrite =
                _readFromA ? historyB : historyA;

            Vector3 currentPos3 =
                _camera.transform.position;

            Vector3 lastPos3 =
                _historyInitialized
                    ? _lastFrameCamPos
                    : currentPos3;

            Vector4 currentPos = new Vector4(
                currentPos3.x,
                currentPos3.y,
                currentPos3.z,
                0f);

            Vector4 lastPos = new Vector4(
                lastPos3.x,
                lastPos3.y,
                lastPos3.z,
                0f);

            // ============================================================
            // 1. History
            // ============================================================

            if (!_historyInitialized)
            {
                /*
                 * ��һ֡��
                 *
                 * Current -> HistoryWrite
                 *
                 * ��ȫ����ȡ HistoryRead��
                 */
                AddCopyPass(
                    renderGraph,
                    "SnowTrail First Frame Copy",
                    current,
                    historyWrite,
                    false);
            }
            else
            {
                /*
                 * Current + HistoryRead -> HistoryWrite
                 */
                AddAccumulationPass(
                    renderGraph,
                    current,
                    historyRead,
                    historyWrite,
                    currentPos,
                    lastPos,
                    _camera.orthographicSize);
            }

            // ============================================================
            // 2. Blur
            // ============================================================

            if (_blurIterations > 0)
            {
                RenderTextureDescriptor blurDesc =
                    _finalTrail.descriptor;

                // BlurTemp �Ǵ���ɫ RenderGraph ��ʱ������
                blurDesc.depthBufferBits = 0;
                blurDesc.depthStencilFormat = GraphicsFormat.None;
                blurDesc.msaaSamples = 1;
                blurDesc.bindMS = false;
                blurDesc.useMipMap = false;
                blurDesc.autoGenerateMips = false;
                blurDesc.enableRandomWrite = false;

                TextureHandle blurTemp =
                    UniversalRenderer.CreateRenderGraphTexture(
                        renderGraph,
                        blurDesc,
                        "_SnowTrailBlurTemp",
                        false);

                float width = _finalTrail.width;
                float height = _finalTrail.height;

                Vector4 texelSize = new Vector4(
                    1f / width,
                    1f / height,
                    width,
                    height);

                for (int i = 0; i < _blurIterations; i++)
                {
                    TextureHandle horizontalSource =
                        i == 0
                            ? historyWrite
                            : final;

                    // Horizontal
                    AddBlurPass(
                        renderGraph,
                        $"SnowTrail Blur H {i}",
                        horizontalSource,
                        blurTemp,
                        0,
                        texelSize,
                        false);

                    bool lastIteration =
                        i == _blurIterations - 1;

                    // Vertical
                    AddBlurPass(
                        renderGraph,
                        $"SnowTrail Blur V {i}",
                        blurTemp,
                        final,
                        1,
                        texelSize,
                        lastIteration);
                }
            }
            else
            {
                // ��ģ��ʱֱ������� Final��
                AddCopyPass(
                    renderGraph,
                    "SnowTrail History To Final",
                    historyWrite,
                    final,
                    true);
            }

            // ============================================================
            // CPU history state
            // ============================================================

            _lastFrameCamPos = currentPos3;

            _historyInitialized = true;

            _readFromA = !_readFromA;
        }

        public override void Execute(
            ScriptableRenderContext context,
            ref RenderingData renderingData)
        {
            if (_camera == null || _camera.targetTexture == null)
                return;

            RenderTexture current = _camera.targetTexture;
            RenderTexture historyRead = _readFromA ? _historyA : _historyB;
            RenderTexture historyWrite = _readFromA ? _historyB : _historyA;

            Vector3 currentPos = _camera.transform.position;
            Vector3 lastPos = _historyInitialized ? _lastFrameCamPos : currentPos;

            CommandBuffer cmd = CommandBufferPool.Get("SnowTrail");

            // Blit.hlsl's Vert uses _BlitScaleBias to build input.texcoord.
            // CommandBuffer.Blit does not populate this URP-specific value.
            cmd.SetGlobalVector(BlitScaleBiasID, FullscreenScaleBias);

            if (!_historyInitialized)
            {
                cmd.Blit(current, historyWrite);
            }
            else
            {
                cmd.SetGlobalTexture(CurrentTexID, current);
                _accumulationMaterial.SetVector(
                    OrthCamPosID,
                    new Vector4(currentPos.x, currentPos.y, currentPos.z, 0f));
                _accumulationMaterial.SetVector(
                    LastFrameCamPosID,
                    new Vector4(lastPos.x, lastPos.y, lastPos.z, 0f));
                _accumulationMaterial.SetFloat(
                    OrthCamSizeID,
                    _camera.orthographicSize);
                cmd.SetGlobalTexture(BlitTextureID, historyRead);
                cmd.Blit(historyRead, historyWrite, _accumulationMaterial, 0);
            }

            if (_blurIterations > 0)
            {
                RenderTextureDescriptor blurDescriptor = _finalTrail.descriptor;
                blurDescriptor.depthBufferBits = 0;
                blurDescriptor.msaaSamples = 1;
                blurDescriptor.useMipMap = false;
                blurDescriptor.autoGenerateMips = false;

                cmd.GetTemporaryRT(BlurTempID, blurDescriptor, FilterMode.Bilinear);
                Vector4 texelSize = new Vector4(
                    1f / _finalTrail.width,
                    1f / _finalTrail.height,
                    _finalTrail.width,
                    _finalTrail.height);

                RenderTargetIdentifier blurTemp =
                    new RenderTargetIdentifier(BlurTempID);
                RenderTargetIdentifier source =
                    new RenderTargetIdentifier(historyWrite);

                for (int i = 0; i < _blurIterations; i++)
                {
                    _blurMaterial.SetFloat(BlurRadiusID, _blurRadius);
                    _blurMaterial.SetVector(BlitTextureTexelSizeID, texelSize);

                    cmd.SetGlobalTexture(BlitTextureID, source);
                    cmd.Blit(source, blurTemp, _blurMaterial, 0);

                    cmd.SetGlobalTexture(BlitTextureID, blurTemp);
                    cmd.Blit(blurTemp, _finalTrail, _blurMaterial, 1);
                    source = new RenderTargetIdentifier(_finalTrail);
                }

                cmd.ReleaseTemporaryRT(BlurTempID);
            }
            else
            {
                cmd.Blit(historyWrite, _finalTrail);
            }

            cmd.SetGlobalTexture(SnowTrailTexID, _finalTrail);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);

            _lastFrameCamPos = currentPos;
            _historyInitialized = true;
            _readFromA = !_readFromA;
        }

        // ================================================================
        // Copy
        // ================================================================

        private static void AddCopyPass(
            RenderGraph renderGraph,
            string passName,
            TextureHandle source,
            TextureHandle destination,
            bool publishGlobal)
        {
            using (
                var builder =
                    renderGraph.AddRasterRenderPass<CopyPassData>(
                        passName,
                        out var passData))
            {
                passData.source = source;
                passData.destination = destination;
                passData.publishGlobal = publishGlobal;

                // ������ȡ��
                builder.UseTexture(
                    source,
                    IBaseRenderGraphBuilder.AccessFlags.Read);

                // ����д�롣
                builder.UseTextureFragment(
                    destination,
                    0,
                    IBaseRenderGraphBuilder.AccessFlags.Write);

                builder.AllowGlobalStateModification(true);

                builder.SetRenderFunc(
                    static (
                        CopyPassData data,
                        RasterGraphContext context) =>
                    {
                        Blitter.BlitTexture(
                            context.cmd,
                            data.source,
                            FullscreenScaleBias,
                            0,
                            false);

                        if (data.publishGlobal)
                        {
                            context.cmd.SetGlobalTexture(
                                SnowTrailTexID,
                                data.destination);
                        }
                    });
            }
        }

        // ================================================================
        // Accumulation
        // ================================================================

        private void AddAccumulationPass(
            RenderGraph renderGraph,
            TextureHandle current,
            TextureHandle historyRead,
            TextureHandle historyWrite,
            Vector4 currentCamPos,
            Vector4 lastCamPos,
            float orthCamSize)
        {
            using (
                var builder =
                    renderGraph.AddRasterRenderPass<AccumulationPassData>(
                        "SnowTrail Accumulation",
                        out var passData))
            {
                passData.current = current;
                passData.history = historyRead;

                passData.material = _accumulationMaterial;

                passData.currentCamPos = currentCamPos;
                passData.lastCamPos = lastCamPos;

                passData.orthCamSize = orthCamSize;

                // Current������
                builder.UseTexture(
                    current,
                    IBaseRenderGraphBuilder.AccessFlags.Read);

                // HistoryRead������
                builder.UseTexture(
                    historyRead,
                    IBaseRenderGraphBuilder.AccessFlags.Read);

                // HistoryWrite��д��
                builder.UseTextureFragment(
                    historyWrite,
                    0,
                    IBaseRenderGraphBuilder.AccessFlags.Write);

                /*
                 * ������Ҫͨ�� RasterCommandBuffer
                 * ��ʱ�� _CurrentTex��
                 *
                 * RenderGraph ��ͨ�� UseTexture ֪�� Current ��������ϵ��
                 */
                builder.AllowGlobalStateModification(true);

                builder.SetRenderFunc(
                    static (
                        AccumulationPassData data,
                        RasterGraphContext context) =>
                    {
                        Material mat = data.material;

                        /*
                         * TextureHandle ����ֱ�Ӵ���
                         * RasterCommandBuffer.SetGlobalTexture��
                         */
                        context.cmd.SetGlobalTexture(
                            CurrentTexID,
                            data.current);

                        mat.SetVector(
                            OrthCamPosID,
                            data.currentCamPos);

                        mat.SetVector(
                            LastFrameCamPosID,
                            data.lastCamPos);

                        mat.SetFloat(
                            OrthCamSizeID,
                            data.orthCamSize);

                        /*
                         * Blitter source = HistoryRead
                         *
                         * ��� accumulation shader��
                         *
                         * _BlitTexture = HistoryRead
                         * _CurrentTex  = Current
                         */
                        Blitter.BlitTexture(
                            context.cmd,
                            data.history,
                            FullscreenScaleBias,
                            mat,
                            0);
                    });
            }
        }

        // ================================================================
        // Blur
        // ================================================================

        private void AddBlurPass(
            RenderGraph renderGraph,
            string passName,
            TextureHandle source,
            TextureHandle destination,
            int shaderPass,
            Vector4 texelSize,
            bool publishGlobal)
        {
            using (
                var builder =
                    renderGraph.AddRasterRenderPass<BlurPassData>(
                        passName,
                        out var passData))
            {
                passData.source = source;
                passData.destination = destination;

                passData.material = _blurMaterial;

                passData.radius = _blurRadius;
                passData.texelSize = texelSize;

                passData.shaderPass = shaderPass;
                passData.publishGlobal = publishGlobal;

                // �������
                builder.UseTexture(
                    source,
                    IBaseRenderGraphBuilder.AccessFlags.Read);

                // ���д��
                builder.UseTextureFragment(
                    destination,
                    0,
                    IBaseRenderGraphBuilder.AccessFlags.Write);

                builder.AllowGlobalStateModification(true);

                builder.SetRenderFunc(
                    static (
                        BlurPassData data,
                        RasterGraphContext context) =>
                    {
                        Material mat = data.material;

                        mat.SetFloat(
                            BlurRadiusID,
                            data.radius);

                        mat.SetVector(
                            BlitTextureTexelSizeID,
                            data.texelSize);

                        Blitter.BlitTexture(
                            context.cmd,
                            data.source,
                            FullscreenScaleBias,
                            mat,
                            data.shaderPass);

                        if (data.publishGlobal)
                        {
                            context.cmd.SetGlobalTexture(
                                SnowTrailTexID,
                                data.destination);
                        }
                    });
            }
        }

        // ================================================================
        // Dispose
        // ================================================================

        public void Dispose()
        {
            // These RTHandles wrap serialized RenderTexture assets. In URP 16,
            // RTHandle.Release() calls CoreUtils.Destroy on the wrapped asset.
            // Do not release the wrappers here, otherwise Unity logs an asset
            // destruction error during renderer recreation in the compatibility loop.
            _historyART = null;
            _historyBRT = null;
            _finalTrailRT = null;

            CoreUtils.Destroy(_accumulationMaterial);
            CoreUtils.Destroy(_blurMaterial);

            _accumulationMaterial = null;
            _blurMaterial = null;

            _camera = null;
        }

        private static void EnsureCreated(RenderTexture texture)
        {
            if (texture != null && !texture.IsCreated())
                texture.Create();
        }
    }
}
