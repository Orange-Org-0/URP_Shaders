using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.VFX;

[ExecuteAlways]
public class InteractiveControl_Snow : MonoBehaviour
{
    private const string PlayerLayerName = "Player";

    [Header("Movement")]
    [SerializeField, Min(0f)]
    [Tooltip("Player movement speed in world units per second.")]
    private float moveSpeed = 5f;

    [Header("TrailCam")]
    [SerializeField]
    public Camera trailCam; 

    [Header("SnowTrail")]
    [FormerlySerializedAs("SnowTrail")]
    [SerializeField]
    private VisualEffect SnowTrail;

    [FormerlySerializedAs("speed")]
    [SerializeField]
    private float currentSpeed;

    private Vector3 lastFramePos;
    private int playerLayer;
    private SnowController snowController;

    public float CurrentSpeed => currentSpeed;
    private bool IsPlayerLayer => playerLayer >= 0 && gameObject.layer == playerLayer;

    private void OnEnable()
    {
        playerLayer = LayerMask.NameToLayer(PlayerLayerName);
        snowController = FindFirstObjectByType<SnowController>();
        lastFramePos = transform.position;
        ApplyPlayerCollisionConstraints();
        RegisterSnowController();
    }

    private void Update()
    {
        if (Application.isPlaying && IsPlayerLayer)
        {
            UpdateMovement();
        }

        UpdateSpeed();
        if (snowController != null)
        {
            snowController.SetPlayerSpeed(currentSpeed);
        }
    }

    private void OnValidate()
    {
        playerLayer = LayerMask.NameToLayer(PlayerLayerName);
        moveSpeed = Mathf.Max(0f, moveSpeed);
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

    private void UpdateMovement()
    {
        Vector3 direction = Vector3.zero;

        if (Input.GetKey(KeyCode.W))
        {
            direction += Vector3.forward;
        }

        if (Input.GetKey(KeyCode.S))
        {
            direction += Vector3.back;
        }

        if (Input.GetKey(KeyCode.D))
        {
            direction += Vector3.right;
        }

        if (Input.GetKey(KeyCode.A))
        {
            direction += Vector3.left;
        }

        if (Input.GetKey(KeyCode.E))
        {
            direction += Vector3.up;
        }

        if (Input.GetKey(KeyCode.Q))
        {
            direction += Vector3.down;
        }

        if (direction.sqrMagnitude > 0f)
        {
            transform.position += direction.normalized * (moveSpeed * Time.deltaTime);
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



    private void RegisterSnowController()
    {
        if (snowController == null)
        {
            return;
        }

        snowController.SetReferences(trailCam, SnowTrail);
    }
}
