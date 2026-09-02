# Foliage Quad 材质分配工具

## 用法

1. 将 `FoliageQuadMaterialAssigner` 添加到包含 foliage quad 的根物体。
2. 在“目标材质”栏中指定叶片材质。
3. 点击“查找并添加材质”。

工具会递归查找名称同时包含 `foliage` 和 `quad` 的 `MeshRenderer`，
包括未激活的后代物体。匹配不区分大小写，例如 `foliage001_quad002`
会被处理。匹配对象原有的共享材质列表会被目标材质完全覆盖。

## 行为

- 已经只使用目标材质的 Renderer 会被跳过。
- 支持同时选择多个挂有该组件的根物体。
- 整次操作支持 Unity Undo。
- 场景实例和 Prefab 实例的修改会被正确记录。
- Console 会报告找到、修改和跳过的数量。

## 相关文件

- `Scripts/Runtime/FoliageQuadMaterialAssigner.cs`
- `Scripts/Editor/FoliageQuadMaterialAssignerEditor.cs`
