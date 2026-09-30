using UnityEngine;
using UnityEngine.VFX;

[DisallowMultipleComponent]
public sealed class InteractiveControl_Leaves : MonoBehaviour
{
    private const string PlayerSpeedProperty = "PlayerSpeed";
    private const string OrthCamPosProperty = "OrthCamPos";
    private const string OrthCamSizeProperty = "OrthCamSize";

    [SerializeField]
    private VisualEffect leavesEffect;

    [SerializeField]
    private VisualEffect groundLeavesEffect;

    [SerializeField]
    private float currentSpeed;

    private Vector3 lastFramePosition;
    private Camera trailCamera;

    public float CurrentSpeed => currentSpeed;

    private void OnEnable()
    {
        trailCamera = GetComponentInChildren<Camera>(true);
        lastFramePosition = transform.position;
        currentSpeed = 0f;
        SendParametersToEffects();
    }

    private void Update()
    {
        float deltaTime = Time.deltaTime;
        currentSpeed = deltaTime > Mathf.Epsilon
            ? Vector3.Distance(transform.position, lastFramePosition) / deltaTime
            : 0f;

        lastFramePosition = transform.position;
        SendParametersToEffects();
    }

    private void SendParametersToEffects()
    {
        if (leavesEffect != null && leavesEffect.HasFloat(PlayerSpeedProperty))
        {
            leavesEffect.SetFloat(PlayerSpeedProperty, currentSpeed);
        }

        if (groundLeavesEffect == null)
        {
            return;
        }

        if (groundLeavesEffect.HasFloat(PlayerSpeedProperty))
        {
            groundLeavesEffect.SetFloat(PlayerSpeedProperty, currentSpeed);
        }

        if (trailCamera == null)
        {
            return;
        }

        if (groundLeavesEffect.HasVector3(OrthCamPosProperty))
        {
            groundLeavesEffect.SetVector3(
                OrthCamPosProperty,
                trailCamera.transform.position);
        }

        if (groundLeavesEffect.HasFloat(OrthCamSizeProperty))
        {
            groundLeavesEffect.SetFloat(
                OrthCamSizeProperty,
                trailCamera.orthographicSize);
        }
    }
}
