using StarterAssets;
using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.VFX;

[ExecuteAlways]
public class InteractiveControl_Snow : MonoBehaviour
{
    private const string PlayerLayerName = "Player";
    private const string LandingEventName = "OnLanding";
    private const float SnowMinY = -0.5f;
    private const float SnowMaxY = 0.55f;

    [Header("TrailCam")]
    [SerializeField]
    public Camera trailCam;

    [Header("Snow Effects")]
    [SerializeField]
    private VisualEffect[] snowEffects = System.Array.Empty<VisualEffect>();

    [Header("Landing Splash")]
    [SerializeField]
    private VisualEffect snowSplashEffect;

    [SerializeField, Min(0f)]
    [Tooltip("Minimum downward speed required to trigger the landing splash.")]
    private float minimumLandingSpeed = 0.5f;

    [FormerlySerializedAs("speed")]
    [SerializeField]
    private float currentSpeed;

    private Vector3 lastFramePos;
    private int playerLayer;
    private SnowController snowController;
    private ThirdPersonController playerController;
    private float lastLandingSampleY;
    private float peakDownwardSpeed;
    private bool wasGrounded;

    public float CurrentSpeed => currentSpeed;
    private bool IsPlayerLayer => playerLayer >= 0 && gameObject.layer == playerLayer;

    private void OnEnable()
    {
        playerLayer = LayerMask.NameToLayer(PlayerLayerName);
        snowController = FindFirstObjectByType<SnowController>();
        playerController = GetComponentInParent<ThirdPersonController>();
        lastFramePos = transform.position;

        if (playerController != null)
        {
            wasGrounded = playerController.Grounded;
            lastLandingSampleY = playerController.transform.position.y;
        }

        ApplyPlayerCollisionConstraints();
        RegisterSnowController();
    }

    private void Update()
    {
        UpdateSpeed();
        if (snowController != null)
        {
            snowController.SetPlayerSpeed(currentSpeed);
            snowController.SetIsOnSnow(IsOnSnow());
        }
    }

    private void OnValidate()
    {
        playerLayer = LayerMask.NameToLayer(PlayerLayerName);
        minimumLandingSpeed = Mathf.Max(0f, minimumLandingSpeed);
    }

    private void LateUpdate()
    {
        if (!Application.isPlaying || playerController == null)
        {
            return;
        }

        float currentY = playerController.transform.position.y;
        float verticalSpeed = Time.deltaTime > Mathf.Epsilon
            ? (currentY - lastLandingSampleY) / Time.deltaTime
            : 0f;

        if (!playerController.Grounded && verticalSpeed < 0f)
        {
            peakDownwardSpeed = Mathf.Max(peakDownwardSpeed, -verticalSpeed);
        }

        if (!wasGrounded && playerController.Grounded)
        {
            if (peakDownwardSpeed >= minimumLandingSpeed && IsOnSnow())
            {
                snowSplashEffect?.SendEvent(LandingEventName);
            }

            peakDownwardSpeed = 0f;
        }
        else if (wasGrounded && !playerController.Grounded)
        {
            peakDownwardSpeed = 0f;
        }

        wasGrounded = playerController.Grounded;
        lastLandingSampleY = currentY;
    }

    private void OnTransformChildrenChanged()
    {
        ApplyPlayerCollisionConstraints();
    }

    private void ApplyPlayerCollisionConstraints()
    {
        if (!Application.isPlaying || !IsPlayerLayer)
        {
            return;
        }

        Rigidbody[] rigidbodies = GetComponentsInChildren<Rigidbody>(true);
        foreach (Rigidbody body in rigidbodies)
        {
            body.constraints |= RigidbodyConstraints.FreezePositionY;

            Vector3 velocity = body.velocity;
            velocity.y = 0f;
            body.velocity = velocity;
        }
    }

    private void UpdateSpeed()
    {
        float deltaTime = Time.deltaTime;
        currentSpeed = deltaTime > Mathf.Epsilon
            ? Vector3.Distance(transform.position, lastFramePos) / deltaTime
            : 0f;
        lastFramePos = transform.position;
    }

    private bool IsOnSnow()
        => transform.position.y >= SnowMinY && transform.position.y <= SnowMaxY;

    private void RegisterSnowController()
    {
        if (snowController == null)
        {
            return;
        }

        snowController.SetReferences(trailCam, snowEffects);
    }
}
