using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

// 让脚本在没有进入 Play Mode 时也能运行。
[ExecuteAlways]
[DisallowMultipleComponent]
public class GrassControl : MonoBehaviour
{
    // 保存父物体下面所有需要朝向摄像机的草模型。
    private readonly List<Transform> targets = new List<Transform>();

    // 保存渲染前每个模型的世界旋转，渲染结束后用于恢复。
    private Quaternion[] originalRotations = System.Array.Empty<Quaternion>();
    private Camera activeCamera;
    private bool rotationsApplied;

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
    }

    private void OnDestroy()
    {
        RestoreRotations();
    }

    // 子物体发生变化时，重新获取模型。
    private void OnTransformChildrenChanged()
    {
        RefreshTargets();
    }

    // 递归获取所有名称同时包含 grass 和 quad，且拥有 MeshFilter 和 MeshRenderer 的后代物体。
    private void RefreshTargets()
    {
        RestoreRotations();
        targets.Clear();

        MeshFilter[] meshFilters = GetComponentsInChildren<MeshFilter>(true);
        foreach (MeshFilter meshFilter in meshFilters)
        {
            if (meshFilter.transform == transform || meshFilter.sharedMesh == null)
            {
                continue;
            }

            string objectName = meshFilter.gameObject.name;
            if (objectName.IndexOf("grass", System.StringComparison.OrdinalIgnoreCase) < 0 ||
                objectName.IndexOf("quad", System.StringComparison.OrdinalIgnoreCase) < 0)
            {
                continue;
            }

            if (meshFilter.TryGetComponent(out MeshRenderer _))
            {
                targets.Add(meshFilter.transform);
            }
        }

        originalRotations = new Quaternion[targets.Count];
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
        Vector3 directionToCamera = cameraTransform.position - target.position;
        if (directionToCamera.sqrMagnitude <= 0.000001f)
        {
            directionToCamera = -cameraTransform.forward;
        }

        directionToCamera.Normalize();

        // 使用摄像机 Up 稳定 Quad 的滚转，同时保证 Quad 的局部 -X 轴指向摄像机。
        Vector3 quadUp = Vector3.ProjectOnPlane(cameraTransform.up, directionToCamera);
        if (quadUp.sqrMagnitude <= 0.000001f)
        {
            quadUp = Vector3.ProjectOnPlane(cameraTransform.forward, directionToCamera);
        }

        quadUp.Normalize();
        Vector3 quadRight = -directionToCamera;
        Vector3 quadForward = Vector3.Cross(quadRight, quadUp).normalized;
        target.rotation = Quaternion.LookRotation(quadForward, quadUp);
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
