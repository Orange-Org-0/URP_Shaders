using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.VFX;

[ExecuteAlways]
public class InteractiveControl : MonoBehaviour
{
    private const string PlayerLayerName = "Player";

    [Header("Movement")]
    [SerializeField, Min(0f)]
    [Tooltip("Player movement speed in world units per second.")]
    private float moveSpeed = 5f;

    [Header("Ripple")]
    [FormerlySerializedAs("Ripple")]
    [SerializeField]
    private VisualEffect ripple;

    public float rippleSize;

    [FormerlySerializedAs("speed")]
    [SerializeField]
    private float currentSpeed;

    public Rigidbody rigidbody_Player;

    private Vector3 lastFramePos;
    private int playerLayer;

    public float CurrentSpeed => currentSpeed;
    private bool IsPlayerLayer => playerLayer >= 0 && gameObject.layer == playerLayer;

    private void OnEnable()
    {
        playerLayer = LayerMask.NameToLayer(PlayerLayerName);
        lastFramePos = transform.position;
        ApplyPlayerCollisionConstraints();
        if (rigidbody_Player == null)
        {
            rigidbody_Player = GetComponentInChildren<Rigidbody>(true);
        }

        ripple.SetFloat("Size", rippleSize);
    }

    private void Update()
    {
        if (Application.isPlaying && IsPlayerLayer)
        {
            UpdateMovement();
        }
        if(rigidbody_Player == null)
        {
            rigidbody_Player = GetComponentInChildren<Rigidbody>(true);
        }

        UpdateSpeed();
        UpdateRippleParams();
    }

    private void OnValidate()
    {
        playerLayer = LayerMask.NameToLayer(PlayerLayerName);
        moveSpeed = Mathf.Max(0f, moveSpeed);
    }

    private void OnTransformChildrenChanged()
    {
        //ApplyPlayerCollisionConstraints();
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

        //if (Input.GetKey(KeyCode.E))
        //{
        //    direction += Vector3.up;
        //}

        //if (Input.GetKey(KeyCode.Q))
        //{
        //    direction += Vector3.down;
        //}

        
        rigidbody_Player.velocity = direction.normalized * (moveSpeed);
        
    }

    private void UpdateSpeed()
    {
        float deltaTime = Time.deltaTime;
        currentSpeed = deltaTime > Mathf.Epsilon
            ? Vector3.Distance(transform.position, lastFramePos) / deltaTime
            : 0f;
        lastFramePos = transform.position;
    }

    private void UpdateRippleParams()
    {
        if (ripple != null)
        {
            ripple.SetInt("SpawnRate", Mathf.FloorToInt(currentSpeed * 1.8f));
        }
    }
}
