using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(FoliageMaterialAssigner))]
[CanEditMultipleObjects]
public sealed class FoliageMaterialAssignerEditor : Editor
{
    private SerializedProperty targetMaterialProperty;

    private void OnEnable()
    {
        targetMaterialProperty = serializedObject.FindProperty("targetMaterial");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        EditorGUILayout.PropertyField(targetMaterialProperty, new GUIContent("目标材质"));
        serializedObject.ApplyModifiedProperties();

        if (!targetMaterialProperty.hasMultipleDifferentValues &&
            targetMaterialProperty.objectReferenceValue == null)
        {
            EditorGUILayout.HelpBox("请先指定要分配给合并后 Foliage Mesh 的材质。", MessageType.Warning);
        }

        EditorGUILayout.Space();

        if (GUILayout.Button("查找并添加材质", GUILayout.Height(28f)))
        {
            AssignMaterials();
        }
    }

    private void AssignMaterials()
    {
        Undo.IncrementCurrentGroup();
        int undoGroup = Undo.GetCurrentGroup();
        Undo.SetCurrentGroupName("分配 Foliage Mesh 材质");

        int totalFound = 0;
        int totalChanged = 0;
        int totalSkipped = 0;
        int missingMaterialCount = 0;

        foreach (Object selectedTarget in targets)
        {
            var assigner = (FoliageMaterialAssigner)selectedTarget;
            Material material = assigner.TargetMaterial;

            if (material == null)
            {
                missingMaterialCount++;
                Debug.LogWarning($"[{assigner.name}] 未指定目标材质，未执行批量分配。", assigner);
                continue;
            }

            List<MeshRenderer> matches = assigner.FindMatchingRenderers();
            int changed = 0;
            int skipped = 0;

            foreach (MeshRenderer renderer in matches)
            {
                if (assigner.HasTargetMaterialOnly(renderer))
                {
                    skipped++;
                    continue;
                }

                Undo.RecordObject(renderer, "分配 Foliage Mesh 材质");
                assigner.AssignTargetMaterial(renderer);
                PrefabUtility.RecordPrefabInstancePropertyModifications(renderer);
                EditorUtility.SetDirty(renderer);
                changed++;
            }

            totalFound += matches.Count;
            totalChanged += changed;
            totalSkipped += skipped;

            Debug.Log(
                $"[{assigner.name}] Foliage Mesh 材质处理完成：找到 {matches.Count} 个，修改 {changed} 个，跳过 {skipped} 个。",
                assigner);
        }

        Undo.CollapseUndoOperations(undoGroup);

        if (targets.Length > 1)
        {
            Debug.Log(
                $"Foliage Mesh 批量处理汇总：找到 {totalFound} 个，修改 {totalChanged} 个，" +
                $"跳过 {totalSkipped} 个，缺少材质的组件 {missingMaterialCount} 个。");
        }
    }
}
