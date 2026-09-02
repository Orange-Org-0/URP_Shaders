# GrassControl

`GrassControl` 让草模型中的 Quad 在 URP 渲染时朝向目标摄像机。它不会移动草模型，也不包含随机移动参数。

## 使用方法

1. 将 `GrassControl` 挂载到包含全部草分组的最上层父物体。
2. Quad 可以位于任意深度；组件会递归搜索所有后代，包括未激活物体。
3. 可控制的物体名称必须同时包含 `grass` 和 `quad`，并具有有效的 `MeshFilter`、Mesh 和 `MeshRenderer`。

例如：

```text
GrassRoot（挂载 GrassControl）
└── grass001
    └── grass001_quad001_mesh
```

编辑模式下，匹配 Quad 的局部 `-X` 轴指向 Scene View 摄像机；Play 模式下，局部 `-X` 轴仅指向带 `MainCamera` 标签的主摄像机。组件使用摄像机的 Up 方向稳定 Quad 的滚转，并且只在渲染期间临时修改世界旋转；渲染结束、组件禁用或组件销毁时会恢复原始旋转。

## 已知限制

- Play 模式必须存在可由 `Camera.main` 找到的摄像机。
- 运行时改变嵌套层级后，只有在组件收到子物体变化通知并刷新目标列表后，新 Quad 才会被控制。
