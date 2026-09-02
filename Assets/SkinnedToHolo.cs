using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SkinnedToHolo : MonoBehaviour
{
    public SkinnedMeshRenderer skinned;
    public MeshFilter targetFilter;
    Mesh baked;
    void Awake() { baked = new Mesh(); baked.MarkDynamic(); }
    void LateUpdate()
    {
        if (skinned == null || targetFilter == null) return;
        skinned.BakeMesh(baked);         // 后蒙皮形状
        targetFilter.sharedMesh = baked; // 普通网格
    }
}
