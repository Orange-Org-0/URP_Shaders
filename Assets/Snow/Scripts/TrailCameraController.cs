using UnityEngine;
using UnityEngine.SceneManagement;

[ExecuteAlways]
[DisallowMultipleComponent]
[RequireComponent(typeof(Camera))]
public sealed class TrailCameraController : MonoBehaviour
{
    private const string TrailCameraName = "TrailCam";

    private static readonly int OrthCamPosID =
        Shader.PropertyToID("_OrthCamPos");

    private static readonly int OrthCamSizeID =
        Shader.PropertyToID("_OrthCamSize");

    private Camera trailCamera;



    private void FaceWorldDown()
    {
        if (Quaternion.Angle(transform.rotation, WorldDownRotation) > 0.001f)
        {
            transform.rotation = WorldDownRotation;
        }
    }
   
    private void SnapToTexelGrid()
    {
        if (trailCamera == null)
        {
            trailCamera = GetComponent<Camera>();
        }

        if (trailCamera == null ||
            trailCamera.targetTexture == null ||
            !trailCamera.orthographic)
        {
            return;
        }

        RenderTexture rt = trailCamera.targetTexture;

        float texelSizeX =
            trailCamera.orthographicSize * 2f *
            trailCamera.aspect / rt.width;

        float texelSizeZ =
            trailCamera.orthographicSize * 2f /
            rt.height;

        Vector3 position = transform.position;

        position.x =
            Mathf.Round(position.x / texelSizeX) * texelSizeX;

        position.z =
            Mathf.Round(position.z / texelSizeZ) * texelSizeZ;

        transform.position = position;
    }

    private void PublishShaderGlobals()
    {
        if (trailCamera == null)
        {
            trailCamera = GetComponent<Camera>();
        }

        if (trailCamera == null)
        {
            return;
        }

        Vector3 position = transform.position;
        Shader.SetGlobalVector(
            OrthCamPosID,
            new Vector4(position.x, position.y, position.z, 0f));
        Shader.SetGlobalFloat(
            OrthCamSizeID,
            Mathf.Max(trailCamera.orthographicSize, 0.0001f));
    }

    private static readonly Quaternion WorldDownRotation =
        Quaternion.LookRotation(Vector3.down, Vector3.forward);

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void RegisterSceneLoadedHandler()
    {
        SceneManager.sceneLoaded -= OnSceneLoaded;
        SceneManager.sceneLoaded += OnSceneLoaded;
    }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    private static void InstallInLoadedScenes()
    {
        InstallOnSnowTrailCameras();
    }

    private static void OnSceneLoaded(Scene scene, LoadSceneMode mode)
    {
        InstallOnSnowTrailCameras();
    }

    private static void InstallOnSnowTrailCameras()
    {
        Camera[] cameras = FindObjectsByType<Camera>(
            FindObjectsInactive.Include,
            FindObjectsSortMode.None);

        foreach (Camera cameraComponent in cameras)
        {
            if (cameraComponent.name != TrailCameraName ||
                cameraComponent.TryGetComponent(out TrailCameraController _))
            {
                continue;
            }

            cameraComponent.gameObject.AddComponent<TrailCameraController>();
        }
    }

    private void OnEnable()
    {
        trailCamera = GetComponent<Camera>();
        FaceWorldDown();
        SnapToTexelGrid();
        PublishShaderGlobals();
        FaceWorldDown();
    }

    private void LateUpdate()
    {
        FaceWorldDown();
        SnapToTexelGrid();
        PublishShaderGlobals();
    }

    private void OnValidate()
    {
        FaceWorldDown();
        SnapToTexelGrid();  // ������Һ������� RT ��������
        PublishShaderGlobals();
    }
}
