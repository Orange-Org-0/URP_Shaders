using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// 让脚本在没有进入 Play Mode 时也能运行。
[ExecuteAlways]
[DisallowMultipleComponent]
[DefaultExecutionOrder(100)]
public class LeavesControl : MonoBehaviour
{
    private static readonly int WorldPosId = Shader.PropertyToID("_WorldPos");

    [Header("Foliage Movement")]
    [SerializeField, Min(0f)]
    [Tooltip("foliage 父级在世界空间中的最大位移。")]
    [Range(0f, 5f)]private float movementIntensity = 3f;

    [SerializeField, Min(0f)]
    [Tooltip("每秒完成的离开原点并返回原点的运动周期数。")]
    private float movementSpeed = 1f;

    // 保存父物体下面所有需要朝向摄像机的模型。
    private readonly List<Transform> targets = new List<Transform>();
    private readonly List<MeshRenderer> targetRenderers = new List<MeshRenderer>();
    private MaterialPropertyBlock propertyBlock;

    // 每个 foliage 父级拥有独立的方向、周期进度和随机数序列。
    private readonly List<FoliageMotionState> foliageMotionStates = new List<FoliageMotionState>();

    // 保存渲染前每个模型的世界旋转，渲染结束后用于恢复。
    private Quaternion[] originalRotations = System.Array.Empty<Quaternion>();
    private Camera activeCamera;
    private bool rotationsApplied;
    private double lastMovementTime;
    private bool hasMovementTime;

    private sealed class FoliageMotionState
    {
        public readonly Transform Target;
        public readonly Vector3 OriginalLocalPosition;
        public readonly System.Random Random;
        public Vector3 WorldDirection;
        public float CycleProgress;

        public FoliageMotionState(Transform target, int randomSeed)
        {
            Target = target;
            OriginalLocalPosition = target.localPosition;
            Random = new System.Random(randomSeed);
            WorldDirection = NextDirection(Random);
            CycleProgress = (float)Random.NextDouble();
        }
    }

    private void OnEnable()
    {
        RefreshTargets();
        RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;
        RenderPipelineManager.endCameraRendering += OnEndCameraRendering;
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
        RenderPipelineManager.endCameraRendering -= OnEndCameraRendering;
        RestoreRotations();
        RestoreFoliagePositions();
    }

    private void OnDestroy()
    {
        RestoreRotations();
        RestoreFoliagePositions();
    }

    private void Update()
    {
        ApplyWorldPosition();
        //UpdateFoliageMovement();
    }

    private void OnValidate()
    {
        movementIntensity = Mathf.Max(0f, movementIntensity);
        movementSpeed = Mathf.Max(0f, movementSpeed);

        if (movementIntensity <= 0f || movementSpeed <= 0f)
        {
            RestoreFoliagePositions();
        }
    }

    // 直接子物体发生变化时，重新获取模型。
    private void OnTransformChildrenChanged()
    {
        RefreshTargets();
    }

    // 获取所有名称同时包含 foliage 和 quad，且拥有 MeshFilter 和 MeshRenderer 的后代物体。
    private void RefreshTargets()
    {
        RestoreRotations();
        RestoreFoliagePositions();
        targets.Clear();
        targetRenderers.Clear();
        foliageMotionStates.Clear();

        HashSet<Transform> foliageParents = new HashSet<Transform>();

        MeshFilter[] meshFilters = GetComponentsInChildren<MeshFilter>(true);
        foreach (MeshFilter meshFilter in meshFilters)
        {
            if (meshFilter.transform == transform || meshFilter.sharedMesh == null)
            {
                continue;
            }

            string objectName = meshFilter.gameObject.name;
            if (objectName.IndexOf("foliage", System.StringComparison.OrdinalIgnoreCase) < 0 ||
                objectName.IndexOf("quad", System.StringComparison.OrdinalIgnoreCase) < 0)
            {
                continue;
            }

            if (meshFilter.TryGetComponent(out MeshRenderer meshRenderer))
            {
                targets.Add(meshFilter.transform);
                targetRenderers.Add(meshRenderer);

                Transform foliageParent = meshFilter.transform.parent;
                if (foliageParent != null && foliageParents.Add(foliageParent))
                {
                    int randomSeed = unchecked((foliageParent.GetInstanceID() * 397) ^ GetInstanceID());
                    foliageMotionStates.Add(new FoliageMotionState(foliageParent, randomSeed));
                }
            }
        }

        originalRotations = new Quaternion[targets.Count];
        hasMovementTime = false;
    }

    private void ApplyWorldPosition()
    {
        if (propertyBlock == null)
        {
            propertyBlock = new MaterialPropertyBlock();
        }

        for (int i = 0; i < targetRenderers.Count; i++)
        {
            MeshRenderer targetRenderer = targetRenderers[i];
            if (targetRenderer == null)
            {
                continue;
            }

            Transform foliageParent = targetRenderer.transform.parent;
            if (foliageParent == null)
            {
                continue;
            }

            targetRenderer.GetPropertyBlock(propertyBlock);
            propertyBlock.SetVector(WorldPosId, foliageParent.position);
            targetRenderer.SetPropertyBlock(propertyBlock);
        }
    }

    private void UpdateFoliageMovement()
    {
        double currentTime = Time.realtimeSinceStartupAsDouble;
        float deltaTime = hasMovementTime
            ? Mathf.Max(0f, (float)(currentTime - lastMovementTime))
            : 0f;

        lastMovementTime = currentTime;
        hasMovementTime = true;

        if (movementIntensity <= 0f || movementSpeed <= 0f)
        {
            RestoreFoliagePositions();
            return;
        }

        for (int i = 0; i < foliageMotionStates.Count; i++)
        {
            FoliageMotionState state = foliageMotionStates[i];
            Transform foliage = state.Target;
            if (foliage == null)
            {
                continue;
            }

            float nextProgress = state.CycleProgress + deltaTime * movementSpeed;
            if (nextProgress >= 1f)
            {
                nextProgress %= 1f;
                state.WorldDirection = NextDirection(state.Random);
            }

            state.CycleProgress = nextProgress;

            Transform parent = foliage.parent;
            Vector3 originalWorldPosition = parent != null
                ? parent.TransformPoint(state.OriginalLocalPosition)
                : state.OriginalLocalPosition;
            float displacement = Mathf.Sin(nextProgress * Mathf.PI) * movementIntensity * 0.01f;
            foliage.position = originalWorldPosition + state.WorldDirection * displacement;
        }
    }

    private static Vector3 NextDirection(System.Random random)
    {
        // 在单位球内拒绝采样，归一化后可得到覆盖任意世界方向的独立向量。
        for (int attempt = 0; attempt < 16; attempt++)
        {
            Vector3 candidate = new Vector3(
                (float)(random.NextDouble() * 2.0 - 1.0),
                (float)(random.NextDouble() * 2.0 - 1.0),
                (float)(random.NextDouble() * 2.0 - 1.0));

            float squaredMagnitude = candidate.sqrMagnitude;
            if (squaredMagnitude > 0.000001f && squaredMagnitude <= 1f)
            {
                return candidate / Mathf.Sqrt(squaredMagnitude);
            }
        }

        return Vector3.up;
    }

    private void RestoreFoliagePositions()
    {
        for (int i = 0; i < foliageMotionStates.Count; i++)
        {
            FoliageMotionState state = foliageMotionStates[i];
            if (state.Target != null)
            {
                state.Target.localPosition = state.OriginalLocalPosition;
            }
        }

        hasMovementTime = false;
    }

    // 每当 URP 准备渲染一台相机时，Unity 会调用这个方法。
    private void OnBeginCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        // 如果上一次渲染意外中断，先恢复可能残留的临时旋转。
        RestoreRotations();

        if (!ShouldFaceCamera(camera))
        {
            return;
        }

        for (int i = 0; i < targets.Count; i++)
        {
            Transform target = targets[i];
            if (target == null)
            {
                continue;
            }

            // 先保存世界旋转，再临时对齐目标摄像机的观察平面。
            originalRotations[i] = target.rotation;
            FaceCameraPlane(target, camera.transform);
        }

        activeCamera = camera;
        rotationsApplied = true;
    }

    // 当前目标相机完成渲染后，恢复所有模型原来的旋转。
    private void OnEndCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        if (camera == activeCamera)
        {
            RestoreRotations();
        }
    }

    private static bool ShouldFaceCamera(Camera camera)
    {
        if (camera == null)
        {
            return false;
        }

        if (!Application.isPlaying)
        {
            return camera.cameraType == CameraType.SceneView;
        }

        Camera mainCamera = Camera.main;
        return mainCamera != null && camera == mainCamera;
    }

    private static void FaceCameraPlane(Transform target, Transform cameraTransform)
    {
        // LookRotation 将局部 Z 轴对齐第一个参数，并将局部 Y 轴对齐第二个参数。
        // 因此 Quad 的局部 Z 轴与摄像机 Up 平行，局部 Y 轴朝向摄像机观察平面。
        target.rotation = Quaternion.LookRotation(
            cameraTransform.up,
            -cameraTransform.forward);
    }

    private void RestoreRotations()
    {
        if (!rotationsApplied)
        {
            return;
        }

        for (int i = 0; i < targets.Count; i++)
        {
            if (targets[i] != null)
            {
                targets[i].rotation = originalRotations[i];
            }
        }

        activeCamera = null;
        rotationsApplied = false;
    }
}
