using System;
using System.Collections.Generic;
using UnityEngine;

[DisallowMultipleComponent]
public sealed class GrassQuadMaterialAssigner : MonoBehaviour
{
    [SerializeField]
    [Tooltip("要分配给所有 Grass Quad 的共享材质。")]
    private Material targetMaterial = null;

    public Material TargetMaterial => targetMaterial;

    /// <summary>
    /// 查找当前物体及其所有后代中名称同时包含 grass 和 quad 的 MeshRenderer。
    /// 未激活的物体也会被查找。
    /// </summary>
    public List<MeshRenderer> FindMatchingRenderers()
    {
        MeshRenderer[] renderers = GetComponentsInChildren<MeshRenderer>(true);
        var matches = new List<MeshRenderer>(renderers.Length);

        foreach (MeshRenderer renderer in renderers)
        {
            string objectName = renderer.gameObject.name;
            if (objectName.IndexOf("grass", StringComparison.OrdinalIgnoreCase) >= 0 &&
                objectName.IndexOf("quad", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                matches.Add(renderer);
            }
        }

        return matches;
    }

    /// <summary>
    /// 判断 Renderer 是否已经只使用目标材质。
    /// </summary>
    public bool HasTargetMaterialOnly(MeshRenderer renderer)
    {
        if (renderer == null || targetMaterial == null)
        {
            return false;
        }

        Material[] materials = renderer.sharedMaterials;
        return materials.Length == 1 && materials[0] == targetMaterial;
    }

    /// <summary>
    /// 用目标材质完全覆盖 Renderer 的共享材质列表。
    /// </summary>
    public void AssignTargetMaterial(MeshRenderer renderer)
    {
        if (renderer == null)
        {
            throw new ArgumentNullException(nameof(renderer));
        }

        if (targetMaterial == null)
        {
            throw new InvalidOperationException("必须先指定目标材质。");
        }

        renderer.sharedMaterials = new[] { targetMaterial };
    }
}
