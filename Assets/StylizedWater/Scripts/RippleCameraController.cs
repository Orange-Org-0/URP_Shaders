using UnityEngine;
using UnityEngine.SceneManagement;

[ExecuteAlways]
[DisallowMultipleComponent]
[RequireComponent(typeof(Camera))]
public sealed class RippleCameraController : MonoBehaviour
{
    private const string RippleCameraName = "RippleCam";

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
        InstallOnRippleCameras();
    }

    private static void OnSceneLoaded(Scene scene, LoadSceneMode mode)
    {
        InstallOnRippleCameras();
    }

    private static void InstallOnRippleCameras()
    {
        Camera[] cameras = FindObjectsByType<Camera>(
            FindObjectsInactive.Include,
            FindObjectsSortMode.None);

        foreach (Camera cameraComponent in cameras)
        {
            if (cameraComponent.name != RippleCameraName ||
                cameraComponent.TryGetComponent(out RippleCameraController _))
            {
                continue;
            }

            cameraComponent.gameObject.AddComponent<RippleCameraController>();
        }
    }

    private void OnEnable()
    {
        FaceWorldDown();
    }

    private void LateUpdate()
    {
        FaceWorldDown();
    }

    private void OnValidate()
    {
        FaceWorldDown();
    }

    private void FaceWorldDown()
    {
        if (Quaternion.Angle(transform.rotation, WorldDownRotation) > 0.001f)
        {
            transform.rotation = WorldDownRotation;
        }
    }
}
