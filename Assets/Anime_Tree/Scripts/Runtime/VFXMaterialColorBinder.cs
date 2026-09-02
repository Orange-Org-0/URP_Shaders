using UnityEngine;
using UnityEngine.VFX;

[ExecuteAlways]
[DisallowMultipleComponent]
public sealed class VFXMaterialColorBinder : MonoBehaviour
{
    private const string MaterialColorProperty = "_MainColor";
    private const string VfxColorProperty = "SourceColor";

    [SerializeField]
    public Material sourceMaterial;

    private VisualEffect targetVfx;
    private Color lastColor;
    private bool hasLastColor;
    private bool warnedMissingMaterial;
    private bool warnedMissingVfx;
    private bool warnedMissingMaterialProperty;
    private bool warnedMissingVfxProperty;

    private void OnEnable()
    {
        FindTargetVfx();
        SynchronizeColor();
    }

    private void Update()
    {
        if (targetVfx == null)
        {
            FindTargetVfx();
        }

        SynchronizeColor();
    }

    private void OnValidate()
    {
        FindTargetVfx();
        hasLastColor = false;
        SynchronizeColor();
    }

    private void OnTransformChildrenChanged()
    {
        FindTargetVfx();
        hasLastColor = false;
        SynchronizeColor();
    }

    private void FindTargetVfx()
    {
        targetVfx = GetComponentInChildren<VisualEffect>(true);

        if (targetVfx != null)
        {
            warnedMissingVfx = false;
            warnedMissingVfxProperty = false;
        }
    }

    private void SynchronizeColor()
    {
        if (sourceMaterial == null)
        {
            WarnOnce(
                ref warnedMissingMaterial,
                "A source Material must be assigned before its color can be synchronized.");
            return;
        }

        warnedMissingMaterial = false;

        if (targetVfx == null)
        {
            WarnOnce(
                ref warnedMissingVfx,
                "No VisualEffect component was found on this GameObject or any of its descendants.");
            return;
        }

        warnedMissingVfx = false;

        if (!sourceMaterial.HasColor(MaterialColorProperty))
        {
            WarnOnce(
                ref warnedMissingMaterialProperty,
                $"Material '{sourceMaterial.name}' does not contain the color property '{MaterialColorProperty}'.");
            return;
        }

        warnedMissingMaterialProperty = false;

        if (!targetVfx.HasVector4(VfxColorProperty))
        {
            WarnOnce(
                ref warnedMissingVfxProperty,
                $"VisualEffect '{targetVfx.name}' does not expose a Vector4/Color property named '{VfxColorProperty}'.");
            return;
        }

        warnedMissingVfxProperty = false;

        Color color = sourceMaterial.GetColor(MaterialColorProperty);
   
        if (hasLastColor && color == lastColor)
        {
            return;
        }

        targetVfx.SetVector4(VfxColorProperty, color);
        lastColor = color;
        hasLastColor = true;
    }

    private void WarnOnce(ref bool warningIssued, string message)
    {
        if (warningIssued)
        {
            return;
        }

        Debug.LogWarning($"{nameof(VFXMaterialColorBinder)}: {message}", this);
        warningIssued = true;
    }
}
