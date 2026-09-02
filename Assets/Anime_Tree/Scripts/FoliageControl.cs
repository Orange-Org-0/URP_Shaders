using UnityEngine;
using UnityEngine.Rendering;

[DisallowMultipleComponent]
[RequireComponent(typeof(MeshRenderer))]
public sealed class FoliageControl : MonoBehaviour
{
    private static readonly int WorldPosId = Shader.PropertyToID("_WorldPos");

    [Header("Camera Facing")]
    [SerializeField]
    [Tooltip("During Play Mode, aligns the foliage's local -Z axis with -camera.forward and local +Y with camera.up.")]
    private bool faceCamera = true;

    private MeshRenderer cachedRenderer;
    private MaterialPropertyBlock propertyBlock;
    private Quaternion rotationBeforeRendering;
    private Camera activeCamera;
    private bool cameraRotationApplied;

    private void OnEnable()
    {
        EnsureInitialized();
        ApplyWorldPosition();

        if (Application.isPlaying)
        {
            RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;
            RenderPipelineManager.endCameraRendering += OnEndCameraRendering;
        }
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
        RenderPipelineManager.endCameraRendering -= OnEndCameraRendering;
        RestoreRotation();
    }

    private void OnDestroy()
    {
        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
        RenderPipelineManager.endCameraRendering -= OnEndCameraRendering;
        RestoreRotation();
    }

    private void Update()
    {
        ApplyWorldPosition();
    }

    private void EnsureInitialized()
    {
        if (cachedRenderer == null)
        {
            cachedRenderer = GetComponent<MeshRenderer>();
        }

        if (propertyBlock == null)
        {
            propertyBlock = new MaterialPropertyBlock();
        }
    }

    private void ApplyWorldPosition()
    {
        EnsureInitialized();

        Vector3 worldPosition = transform.position;

        cachedRenderer.GetPropertyBlock(propertyBlock);
        propertyBlock.SetVector(WorldPosId, worldPosition);
        cachedRenderer.SetPropertyBlock(propertyBlock);
    }

    private void OnBeginCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        RestoreRotation();

        if (!Application.isPlaying || !faceCamera || camera == null)
        {
            return;
        }

        rotationBeforeRendering = transform.rotation;
        transform.rotation = Quaternion.LookRotation(
            camera.transform.forward,
            camera.transform.up);
        activeCamera = camera;
        cameraRotationApplied = true;
    }

    private void OnEndCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        if (camera == activeCamera)
        {
            RestoreRotation();
        }
    }

    private void RestoreRotation()
    {
        if (!cameraRotationApplied)
        {
            return;
        }

        transform.rotation = rotationBeforeRendering;
        activeCamera = null;
        cameraRotationApplied = false;
    }
}
