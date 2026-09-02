using System;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class SnowController : MonoBehaviour
{
    private const string GroundLayerName = "Ground";
    private static readonly int SnowHeightId = Shader.PropertyToID("_SnowHeight");

    //[Header("Ground Scan")]
    //[SerializeField]
    //[Tooltip("All objects on the Ground layer in the currently loaded scenes, including inactive objects.")]
    //private GameObject[] groundObjects = Array.Empty<GameObject>();
    public Material SnowMaterial;

    [Header("Snow Material")]
    [SerializeField, Range(0f, 3f)]
    [Tooltip("Overrides the _SnowHeight shader property on every Ground renderer.")]
    private float snowHeight = 1.68f;

    //private MaterialPropertyBlock materialPropertyBlock;

    //public IReadOnlyList<GameObject> GroundObjects => groundObjects;
    public float SnowHeight
    {
        get => snowHeight;
        set
        {
            snowHeight = Mathf.Clamp(value, 0f, 3f);
            ApplySnowHeight();
        }
    }

    private void OnEnable()
    {
        //RefreshGroundObjects();
    }

    private void OnValidate()
    {
        snowHeight = Mathf.Clamp(snowHeight, 0f, 3f);
        ApplySnowHeight();
        
    }

    private void Update()
    {
        ApplySnowHeight();
    }

    [ContextMenu("Refresh Ground Objects")]
    //public void RefreshGroundObjects()
    //{
    //    int groundLayer = LayerMask.NameToLayer(GroundLayerName);
    //    if (groundLayer < 0)
    //    {
    //        groundObjects = Array.Empty<GameObject>();
    //        Debug.LogWarning($"Layer '{GroundLayerName}' does not exist.", this);
    //        return;
    //    }

    //    Transform[] sceneTransforms = FindObjectsByType<Transform>(
    //        FindObjectsInactive.Include,
    //        FindObjectsSortMode.None);
    //    List<GameObject> foundGroundObjects = new List<GameObject>();

    //    foreach (Transform sceneTransform in sceneTransforms)
    //    {
    //        GameObject sceneObject = sceneTransform.gameObject;
    //        if (sceneObject.layer == groundLayer &&
    //            sceneObject.scene.IsValid() &&
    //            sceneObject.scene.isLoaded)
    //        {
    //            foundGroundObjects.Add(sceneObject);
    //        }
    //    }

    //    groundObjects = foundGroundObjects.ToArray();
    //    ApplySnowHeight();
    //}

    [ContextMenu("Apply Snow Height")]
    public void ApplySnowHeight()
    {
        SnowMaterial.SetFloat(SnowHeightId, snowHeight);
        //if (groundObjects == null || groundObjects.Length == 0)
        //{
        //    return;
        //}

        //materialPropertyBlock ??= new MaterialPropertyBlock();

        //foreach (GameObject groundObject in groundObjects)
        //{
        //    if (groundObject == null)
        //    {
        //        continue;
        //    }

        //    Renderer[] renderers = groundObject.GetComponentsInChildren<Renderer>(true);
        //    foreach (Renderer groundRenderer in renderers)
        //    {
        //        if (!RendererSupportsSnowHeight(groundRenderer))
        //        {
        //            continue;
        //        }

        //        materialPropertyBlock.Clear();
        //        groundRenderer.GetPropertyBlock(materialPropertyBlock);
        //materialPropertyBlock.SetFloat(SnowHeightId, snowHeight);
        //        groundRenderer.SetPropertyBlock(materialPropertyBlock);
        //    }
        //}
    }

    private static bool RendererSupportsSnowHeight(Renderer targetRenderer)
    {
        foreach (Material material in targetRenderer.sharedMaterials)
        {
            if (material != null && material.HasProperty(SnowHeightId))
            {
                return true;
            }
        }

        return false;
    }
}
