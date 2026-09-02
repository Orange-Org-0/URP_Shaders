using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteAlways]
[DisallowMultipleComponent]
[RequireComponent(typeof(Renderer))]
public sealed class PlanarReflection : MonoBehaviour
{
    private const string ReflectionTextureName = "_ReflectionTex";
    private const string MainCameraTag = "MainCamera";
    private const string SnowTrailLayerName = "SnowTrail";

    private static readonly int ReflectionTextureId = Shader.PropertyToID(ReflectionTextureName);
    [Header("Reflection")]
    [SerializeField] private LayerMask reflectionMask = 265;
    [SerializeField] private bool reflectSkybox;
    [SerializeField, Min(0.0f)] private float clipPlaneOffset = 0.07f;
    [SerializeField, Range(1.0f, 4.0f)] private float downsample = 3.0f;
    [SerializeField, Min(0)] private int reflectionRendererIndex = 1;

    private Renderer targetRenderer;
    private MaterialPropertyBlock propertyBlock;

    private Camera reflectionCamera;
    private RenderTexture reflectionTexture;

    private int textureWidth;
    private int textureHeight;
    private int SnowTrailLayerMask;

    private bool warnedMissingReflectionProperty;

    // RenderSingleCamera 不会触发 beginCameraRendering，但仍保留保护，避免意外递归。
    private static bool isRenderingReflection;

    private void OnEnable()
    {
        targetRenderer = GetComponent<Renderer>();
        propertyBlock ??= new MaterialPropertyBlock();
        SnowTrailLayerMask = LayerMask.GetMask(SnowTrailLayerName);

        warnedMissingReflectionProperty = false;

        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
        RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
        ReleaseResources();
    }

    private void OnDestroy()
    {
        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
        ReleaseResources();
    }

    private void OnValidate()
    {
        clipPlaneOffset = Mathf.Max(0.0f, clipPlaneOffset);
        downsample = Mathf.Clamp(downsample, 1.0f, 4.0f);
        reflectionRendererIndex = Mathf.Max(0, reflectionRendererIndex);

        warnedMissingReflectionProperty = false;
    }

    // 算法入口：为当前 Game/Scene 相机生成一次平面反射。
    private void OnBeginCameraRendering(ScriptableRenderContext context, Camera sourceCamera)
    {
        if (!ShouldRender(sourceCamera) || !ValidateReflectionProperty())
        {
            return;
        }

        EnsureReflectionCamera();
        EnsureRenderTextures(sourceCamera);
        ConfigureReflectionCamera(sourceCamera);

        bool previousInvertCulling = GL.invertCulling;
        isRenderingReflection = true;

        try
        {
            GL.invertCulling = !previousInvertCulling;

#pragma warning disable 0618 // Unity 2022.3 / URP 14 的上下文内独立相机渲染入口。
            UniversalRenderPipeline.RenderSingleCamera(context, reflectionCamera);
#pragma warning restore 0618

            SendTextureToRenderer(reflectionTexture);
        }
        finally
        {
            GL.invertCulling = previousInvertCulling;
            isRenderingReflection = false;
        }
    }

    private bool ShouldRender(Camera sourceCamera)
    {
        if (isRenderingReflection || sourceCamera == null || targetRenderer == null || !targetRenderer.enabled)
        {
            return false;
        }

        if (sourceCamera == reflectionCamera)
        {
            return false;
        }

        if (sourceCamera.cameraType != CameraType.Game || !sourceCamera.CompareTag(MainCameraTag))
        {
            return false;
        }

        if (sourceCamera.TryGetComponent(out UniversalAdditionalCameraData cameraData) &&
            cameraData.renderType == CameraRenderType.Overlay)
        {
            return false;
        }

        return true;
    }

    private bool ValidateReflectionProperty()
    {
        Material material = targetRenderer.sharedMaterial;
        bool hasProperty = material != null && material.HasProperty(ReflectionTextureId);

        if (!hasProperty && !warnedMissingReflectionProperty)
        {
            Debug.LogWarning(
                $"{nameof(PlanarReflection)}: 当前材质的 Shader 没有 {ReflectionTextureName} 属性。",
                this);
            warnedMissingReflectionProperty = true;
        }

        return hasProperty;
    }

    // 第 1 步：创建隐藏反射相机。
    private void EnsureReflectionCamera()
    {
        if (reflectionCamera != null)
        {
            return;
        }

        GameObject cameraObject = new GameObject($"{name} Planar Reflection Camera")
        {
            hideFlags = HideFlags.HideAndDontSave
        };

        reflectionCamera = cameraObject.AddComponent<Camera>();
        reflectionCamera.enabled = false;

        UniversalAdditionalCameraData cameraData = reflectionCamera.GetUniversalAdditionalCameraData();
        cameraData.renderType = CameraRenderType.Base;
        cameraData.renderPostProcessing = false;
        cameraData.requiresColorOption = CameraOverrideOption.Off;
        cameraData.requiresDepthOption = CameraOverrideOption.Off;
        cameraData.allowXRRendering = false;
    }

    // 第 4 步：创建接收反射画面的 RenderTexture。
    private void EnsureRenderTextures(Camera sourceCamera)
    {
        int width = Mathf.Max(1, Mathf.RoundToInt(sourceCamera.pixelWidth / downsample));
        int height = Mathf.Max(1, Mathf.RoundToInt(sourceCamera.pixelHeight / downsample));
        bool needsRebuild = reflectionTexture == null ||
                            width != textureWidth ||
                            height != textureHeight;

        if (!needsRebuild)
        {
            return;
        }

        ReleaseRenderTexture(ref reflectionTexture);

        textureWidth = width;
        textureHeight = height;

        reflectionTexture = CreateRenderTexture("Planar Reflection", 24);
    }

    private RenderTexture CreateRenderTexture(string textureName, int depthBits)
    {
        RenderTexture texture = new RenderTexture(
            textureWidth,
            textureHeight,
            depthBits,
            RenderTextureFormat.Default)
        {
            name = $"{name} {textureName}",
            hideFlags = HideFlags.HideAndDontSave,
            filterMode = FilterMode.Bilinear,
            wrapMode = TextureWrapMode.Clamp,
            antiAliasing = 1,
            useMipMap = false,
            autoGenerateMips = false
        };

        texture.Create();
        return texture;
    }

    // 第 2、3 步：镜像主相机，并将水面变成斜裁剪平面。
    private void ConfigureReflectionCamera(Camera sourceCamera)
    {
        reflectionCamera.CopyFrom(sourceCamera);
        reflectionCamera.enabled = false;
        reflectionCamera.targetTexture = reflectionTexture;
        reflectionCamera.cullingMask = reflectionMask.value & ~SnowTrailLayerMask;
        reflectionCamera.allowHDR = false;
        reflectionCamera.allowMSAA = false;
        reflectionCamera.useOcclusionCulling = false;
        reflectionCamera.clearFlags = reflectSkybox
            ? CameraClearFlags.Skybox
            : CameraClearFlags.SolidColor;
        reflectionCamera.backgroundColor = Color.black;

        UniversalAdditionalCameraData cameraData = reflectionCamera.GetUniversalAdditionalCameraData();
        cameraData.renderType = CameraRenderType.Base;
        cameraData.renderPostProcessing = false;
        cameraData.requiresColorOption = CameraOverrideOption.Off;
        cameraData.requiresDepthOption = CameraOverrideOption.Off;
        cameraData.renderShadows = false;
        cameraData.allowXRRendering = false;
        cameraData.SetRenderer(reflectionRendererIndex);

        CopySkybox(sourceCamera);

        Vector3 planePosition = transform.position;
        Vector3 planeNormal = transform.up.normalized;

        // Mirror around the actual water surface. The offset belongs only to the
        // oblique clipping plane; applying it here shifts reflections by 2 * offset.
        float planeDistance = -Vector3.Dot(planeNormal, planePosition);
        Vector4 reflectionPlane = new Vector4(
            planeNormal.x,
            planeNormal.y,
            planeNormal.z,
            planeDistance);

        Matrix4x4 reflectionMatrix = BuildReflectionMatrix(reflectionPlane);
        reflectionCamera.worldToCameraMatrix = sourceCamera.worldToCameraMatrix * reflectionMatrix;

        Vector4 cameraSpacePlane = BuildCameraSpacePlane(
            reflectionCamera,
            planePosition,
            planeNormal);
        reflectionCamera.projectionMatrix = BuildObliqueProjection(
            sourceCamera.projectionMatrix,
            cameraSpacePlane);

        Vector3 reflectedPosition = reflectionMatrix.MultiplyPoint(sourceCamera.transform.position);
        Vector3 sourceEuler = sourceCamera.transform.eulerAngles;
        reflectionCamera.transform.SetPositionAndRotation(
            reflectedPosition,
            Quaternion.Euler(-sourceEuler.x, sourceEuler.y, sourceEuler.z));
    }

    private void CopySkybox(Camera sourceCamera)
    {
        Skybox sourceSkybox = sourceCamera.GetComponent<Skybox>();
        Skybox reflectionSkybox = reflectionCamera.GetComponent<Skybox>();

        if (!reflectSkybox || sourceSkybox == null || sourceSkybox.material == null)
        {
            if (reflectionSkybox != null)
            {
                reflectionSkybox.material = null;
            }

            return;
        }

        if (reflectionSkybox == null)
        {
            reflectionSkybox = reflectionCamera.gameObject.AddComponent<Skybox>();
        }

        reflectionSkybox.material = sourceSkybox.material;
    }

    private static Matrix4x4 BuildReflectionMatrix(Vector4 plane)
    {
        Matrix4x4 matrix = Matrix4x4.identity;

        matrix.m00 = 1.0f - 2.0f * plane.x * plane.x;
        matrix.m01 = -2.0f * plane.x * plane.y;
        matrix.m02 = -2.0f * plane.x * plane.z;
        matrix.m03 = -2.0f * plane.w * plane.x;

        matrix.m10 = -2.0f * plane.y * plane.x;
        matrix.m11 = 1.0f - 2.0f * plane.y * plane.y;
        matrix.m12 = -2.0f * plane.y * plane.z;
        matrix.m13 = -2.0f * plane.w * plane.y;

        matrix.m20 = -2.0f * plane.z * plane.x;
        matrix.m21 = -2.0f * plane.z * plane.y;
        matrix.m22 = 1.0f - 2.0f * plane.z * plane.z;
        matrix.m23 = -2.0f * plane.w * plane.z;

        return matrix;
    }

    private Vector4 BuildCameraSpacePlane(Camera camera, Vector3 position, Vector3 normal)
    {
        // Move the clipping plane slightly below the surface so it does not cut
        // a visible slice out of reflected geometry touching the waterline.
        Vector3 offsetPosition = position - normal * clipPlaneOffset;
        Matrix4x4 worldToCamera = camera.worldToCameraMatrix;
        Vector3 cameraPosition = worldToCamera.MultiplyPoint(offsetPosition);
        Vector3 cameraNormal = worldToCamera.MultiplyVector(normal).normalized;

        return new Vector4(
            cameraNormal.x,
            cameraNormal.y,
            cameraNormal.z,
            -Vector3.Dot(cameraPosition, cameraNormal));
    }

    private static Matrix4x4 BuildObliqueProjection(Matrix4x4 projection, Vector4 clipPlane)
    {
        Vector4 q = projection.inverse * new Vector4(
            Mathf.Sign(clipPlane.x),
            Mathf.Sign(clipPlane.y),
            1.0f,
            1.0f);
        Vector4 c = clipPlane * (2.0f / Vector4.Dot(clipPlane, q));

        projection[2] = c.x - projection[3];
        projection[6] = c.y - projection[7];
        projection[10] = c.z - projection[11];
        projection[14] = c.w - projection[15];
        return projection;
    }

    // 将结果写入 Renderer 的 _ReflectionTex。
    private void SendTextureToRenderer(RenderTexture texture)
    {
        targetRenderer.GetPropertyBlock(propertyBlock);
        propertyBlock.SetTexture(ReflectionTextureId, texture);
        targetRenderer.SetPropertyBlock(propertyBlock);
    }

    private void ReleaseResources()
    {
        ReleaseRenderTexture(ref reflectionTexture);

        if (reflectionCamera != null)
        {
            DestroyUnityObject(reflectionCamera.gameObject);
            reflectionCamera = null;
        }

    }

    private static void ReleaseRenderTexture(ref RenderTexture texture)
    {
        if (texture == null)
        {
            return;
        }

        texture.Release();
        DestroyUnityObject(texture);
        texture = null;
    }

    private static void DestroyUnityObject(Object target)
    {
        if (target == null)
        {
            return;
        }

        if (Application.isPlaying)
        {
            Destroy(target);
        }
        else
        {
            DestroyImmediate(target);
        }
    }
}
