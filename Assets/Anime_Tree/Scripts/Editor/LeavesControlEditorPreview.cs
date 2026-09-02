using System;
using UnityEditor;
using UnityEngine;

/// <summary>
/// 在非 Play 模式持续驱动 ExecuteAlways 的 LeavesControl 和 GrassControl，并刷新 Scene 视图。
/// </summary>
[InitializeOnLoad]
internal static class LeavesControlEditorPreview
{
    private const double RefreshInterval = 1.0;

    private static LeavesControl[] leavesControls = Array.Empty<LeavesControl>();
    private static GrassControl[] grassControls = Array.Empty<GrassControl>();
    private static double nextRefreshTime;

    static LeavesControlEditorPreview()
    {
        RefreshControls();
        EditorApplication.hierarchyChanged += RefreshControls;
        EditorApplication.update += OnEditorUpdate;
    }

    private static void OnEditorUpdate()
    {
        if (EditorApplication.isPlayingOrWillChangePlaymode)
        {
            return;
        }

        if (EditorApplication.timeSinceStartup >= nextRefreshTime)
        {
            RefreshControls();
        }

        if (HasActiveControl(leavesControls) || HasActiveControl(grassControls))
        {
            EditorApplication.QueuePlayerLoopUpdate();
            SceneView.RepaintAll();
        }
    }

    private static bool HasActiveControl<T>(T[] controls) where T : Behaviour
    {
        for (int i = 0; i < controls.Length; i++)
        {
            T control = controls[i];
            if (control != null && control.isActiveAndEnabled)
            {
                return true;
            }
        }

        return false;
    }

    private static void RefreshControls()
    {
        leavesControls = UnityEngine.Object.FindObjectsOfType<LeavesControl>(true);
        grassControls = UnityEngine.Object.FindObjectsOfType<GrassControl>(true);
        nextRefreshTime = EditorApplication.timeSinceStartup + RefreshInterval;
    }
}
