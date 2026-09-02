using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
[DisallowMultipleComponent]
public sealed class CameraController : MonoBehaviour
{
    private const float MinimumPitch = -89f;
    private const float MaximumPitch = 89f;

    [SerializeField]
    [Min(0f)]
    [Tooltip("Play 模式下摄像机每秒移动的世界单位数。")]
    private float moveSpeed = 5f;

    [SerializeField]
    [Min(0f)]
    [Tooltip("Play 模式下鼠标控制视角的灵敏度。")]
    private float lookSensitivity = 2f;

    private float yaw;
    private float pitch;
    private bool playRotationInitialized;

    private void OnEnable()
    {
        playRotationInitialized = false;

#if UNITY_EDITOR
        EditorApplication.update += OnEditorUpdate;
#endif
    }

    private void OnDisable()
    {
#if UNITY_EDITOR
        EditorApplication.update -= OnEditorUpdate;
#endif
    }

    private void Update()
    {
        if (!Application.isPlaying)
        {
            return;
        }

        if (!playRotationInitialized)
        {
            InitializePlayRotation();
        }

        UpdateRotation();
        UpdatePosition();
    }

    private void OnValidate()
    {
        moveSpeed = Mathf.Max(0f, moveSpeed);
        lookSensitivity = Mathf.Max(0f, lookSensitivity);
    }

    private void InitializePlayRotation()
    {
        Vector3 eulerAngles = transform.eulerAngles;
        yaw = eulerAngles.y;
        pitch = NormalizeAngle(eulerAngles.x);
        pitch = Mathf.Clamp(pitch, MinimumPitch, MaximumPitch);
        transform.rotation = Quaternion.Euler(pitch, yaw, 0f);
        playRotationInitialized = true;
    }

    private void UpdateRotation()
    {
        yaw += Input.GetAxis("Mouse X") * lookSensitivity;
        pitch -= Input.GetAxis("Mouse Y") * lookSensitivity;
        pitch = Mathf.Clamp(pitch, MinimumPitch, MaximumPitch);

        transform.rotation = Quaternion.Euler(pitch, yaw, 0f);
    }

    private void UpdatePosition()
    {
        Vector3 direction = Vector3.zero;

        if (Input.GetKey(KeyCode.W))
        {
            direction += transform.forward;
        }

        if (Input.GetKey(KeyCode.S))
        {
            direction -= transform.forward;
        }

        if (Input.GetKey(KeyCode.D))
        {
            direction += transform.right;
        }

        if (Input.GetKey(KeyCode.A))
        {
            direction -= transform.right;
        }

        if (Input.GetKey(KeyCode.E))
        {
            direction += Vector3.up;
        }

        if (Input.GetKey(KeyCode.Q))
        {
            direction -= Vector3.up;
        }

        if (direction.sqrMagnitude > 0f)
        {
            transform.position += direction.normalized * (moveSpeed * Time.deltaTime);
        }
    }

    private static float NormalizeAngle(float angle)
    {
        return angle > 180f ? angle - 360f : angle;
    }

#if UNITY_EDITOR
    private void OnEditorUpdate()
    {
        if (Application.isPlaying || this == null || !isActiveAndEnabled)
        {
            return;
        }

        SceneView sceneView = SceneView.lastActiveSceneView;
        Camera sceneCamera = sceneView != null ? sceneView.camera : null;
        if (sceneCamera == null)
        {
            return;
        }

        SyncTransform(sceneCamera.transform);
    }

    private void SyncTransform(Transform sceneCameraTransform)
    {
        if (transform.position != sceneCameraTransform.position ||
            transform.rotation != sceneCameraTransform.rotation)
        {
            transform.SetPositionAndRotation(
                sceneCameraTransform.position,
                sceneCameraTransform.rotation);
        }
    }

#endif
}
