using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.VFX;

[ExecuteAlways]
public class SnowController : MonoBehaviour
{
    private static readonly int SnowHeightId = Shader.PropertyToID("_SnowHeight");
    private static readonly int SnowColorId = Shader.PropertyToID("_SnowColor");
    private static readonly int MudColorId = Shader.PropertyToID("_MudColor");
    private static readonly int NormalStrengthId = Shader.PropertyToID("_NormalStrength");
    private static readonly int MudHeightId = Shader.PropertyToID("_MudHeight");
    private static readonly int NoiseScaleId = Shader.PropertyToID("_NoiseScale");
    private static readonly int NoiseStrengthId = Shader.PropertyToID("_NoiseStrength");
    private static readonly int GroundHeightTexId = Shader.PropertyToID("_GroundHeightTex");
    private static readonly int GroundStrengthId = Shader.PropertyToID("_GroundStrength");
    private static readonly int TessValueId = Shader.PropertyToID("_TessValue");
    private static readonly int TessMinId = Shader.PropertyToID("_TessMin");
    private static readonly int TessMaxId = Shader.PropertyToID("_TessMax");
    private static readonly int SpecularHighlightsId = Shader.PropertyToID("_SpecularHighlights");
    private static readonly int EnvironmentReflectionsId = Shader.PropertyToID("_EnvironmentReflections");
    private static readonly int ReceiveShadowsId = Shader.PropertyToID("_ReceiveShadows");
    private static readonly int SnowTrailTexId = Shader.PropertyToID("_SnowTrailTex");
    private static readonly int OrthCamPosId = Shader.PropertyToID("_OrthCamPos");
    private static readonly int OrthCamSizeId = Shader.PropertyToID("_OrthCamSize");

    private const string PlayerSpeedName = "PlayerSpeed";
    private const string OrthCamPosName = "OrthCamPos";
    private const string OrthCamSizeName = "OrthCamSize";
    private const string SnowHeightName = "SnowHeight";
    private const string SnowTrailTexName = "SnowtrailTex";
    private const string GroundHeightTexName = "GroundHeightTex";
    private const string GroundHeightStrengthName = "GroundHeightStrength";

    [Header("Snow Material")]
    [FormerlySerializedAs("SnowMaterial")]
    [SerializeField] private Material snowMaterial;
    [SerializeField, Range(0f, 3f)] private float snowHeight = 1.69f;
    [SerializeField] private Color snowColor = Color.white;
    [SerializeField] private Color mudColor = new Color(0.47843137f, 0.31764707f, 0.078431375f, 0f);
    [SerializeField, Range(1f, 1.5f)] private float normalStrength = 1f;
    [SerializeField, Range(0f, 3f)] private float mudHeight = 1.17f;
    [SerializeField, Range(0f, 20f)] private float noiseScale = 2.4f;
    [SerializeField, Range(0f, 1.2f)] private float noiseStrength = 0.92f;
    [SerializeField] private Texture2D groundHeightTex;
    [SerializeField, Range(0f, 1f)] private float groundStrength;

    [Header("Tessellation")]
    [SerializeField, Range(1f, 32f)] private float tessValue = 19.5f;
    [SerializeField] private float tessMin = 0.1f;
    [SerializeField] private float tessMax = 60f;

    [Header("Lighting")]
    [SerializeField] private bool specularHighlights;
    [SerializeField] private bool environmentReflections;
    [SerializeField] private bool receiveShadows;

    private Camera trailCamera;
    private VisualEffect snowTrail;
    private float playerSpeed;

    public float SnowHeight
    {
        get => snowHeight;
        set
        {
            snowHeight = Mathf.Clamp(value, 0f, 3f);
            ApplyParameters();
        }
    }

    public void SetReferences(Camera camera, VisualEffect effect)
    {
        trailCamera = camera;
        snowTrail = effect;
        ApplyParameters();
    }

    public void SetPlayerSpeed(float speed) => playerSpeed = Mathf.Max(0f, speed);

    private void OnEnable() => ApplyParameters();

    private void OnValidate()
    {
        snowHeight = Mathf.Clamp(snowHeight, 0f, 3f);
        normalStrength = Mathf.Clamp(normalStrength, 1f, 1.5f);
        mudHeight = Mathf.Clamp(mudHeight, 0f, 3f);
        noiseScale = Mathf.Clamp(noiseScale, 0f, 20f);
        noiseStrength = Mathf.Clamp(noiseStrength, 0f, 1.2f);
        groundStrength = Mathf.Clamp01(groundStrength);
        tessValue = Mathf.Clamp(tessValue, 1f, 32f);
        ApplyParameters();
    }

    private void LateUpdate() => ApplyParameters();

    [ContextMenu("Apply Snow Parameters")]
    public void ApplyParameters()
    {
        if (snowMaterial == null)
        {
            return;
        }

        groundHeightTex ??= snowMaterial.GetTexture(GroundHeightTexId) as Texture2D;
        Texture snowTrailTex = Shader.GetGlobalTexture(SnowTrailTexId);

        snowMaterial.SetFloat(SnowHeightId, snowHeight);
        snowMaterial.SetColor(SnowColorId, snowColor);
        snowMaterial.SetColor(MudColorId, mudColor);
        snowMaterial.SetFloat(NormalStrengthId, normalStrength);
        snowMaterial.SetFloat(MudHeightId, mudHeight);
        snowMaterial.SetFloat(NoiseScaleId, noiseScale);
        snowMaterial.SetFloat(NoiseStrengthId, noiseStrength);
        snowMaterial.SetTexture(GroundHeightTexId, groundHeightTex);
        snowMaterial.SetFloat(GroundStrengthId, groundStrength);
        snowMaterial.SetFloat(TessValueId, tessValue);
        snowMaterial.SetFloat(TessMinId, tessMin);
        snowMaterial.SetFloat(TessMaxId, tessMax);
        snowMaterial.SetFloat(SpecularHighlightsId, specularHighlights ? 1f : 0f);
        snowMaterial.SetFloat(EnvironmentReflectionsId, environmentReflections ? 1f : 0f);
        snowMaterial.SetFloat(ReceiveShadowsId, receiveShadows ? 1f : 0f);
        SetKeyword("_SPECULARHIGHLIGHTS_OFF", !specularHighlights);
        SetKeyword("_ENVIRONMENTREFLECTIONS_OFF", !environmentReflections);
        SetKeyword("_RECEIVE_SHADOWS_OFF", !receiveShadows);
        snowMaterial.SetTexture(SnowTrailTexId, snowTrailTex);

        if (trailCamera != null)
        {
            Vector3 cameraPosition = trailCamera.transform.position;
            float cameraSize = trailCamera.orthographicSize;
            Shader.SetGlobalVector(OrthCamPosId, cameraPosition);
            Shader.SetGlobalFloat(OrthCamSizeId, cameraSize);
            SetVFXVector3(OrthCamPosName, cameraPosition);
            SetVFXFloat(OrthCamSizeName, cameraSize);
        }

        SetVFXFloat(PlayerSpeedName, playerSpeed);
        SetVFXFloat(SnowHeightName, snowHeight);
        if (snowTrailTex != null)
        {
            SetVFXTexture(SnowTrailTexName, snowTrailTex);
        }
        SetVFXTexture(GroundHeightTexName, groundHeightTex);
        SetVFXFloat(GroundHeightStrengthName, groundStrength);
    }

    private void SetVFXFloat(string name, float value)
    {
        if (snowTrail != null && snowTrail.HasFloat(name))
        {
            snowTrail.SetFloat(name, value);
        }
    }

    private void SetVFXVector3(string name, Vector3 value)
    {
        if (snowTrail != null && snowTrail.HasVector3(name))
        {
            snowTrail.SetVector3(name, value);
        }
    }

    private void SetVFXTexture(string name, Texture value)
    {
        if (snowTrail != null && snowTrail.HasTexture(name))
        {
            snowTrail.SetTexture(name, value);
        }
    }

    private void SetKeyword(string keyword, bool enabled)
    {
        if (enabled)
        {
            snowMaterial.EnableKeyword(keyword);
        }
        else
        {
            snowMaterial.DisableKeyword(keyword);
        }
    }
}
