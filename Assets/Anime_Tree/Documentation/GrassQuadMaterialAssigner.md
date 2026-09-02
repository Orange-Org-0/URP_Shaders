# Grass Quad 材质分配工具

## 用法

1. 将 `GrassQuadMaterialAssigner` 添加到包含全部草地分组的根物体。
2. 在“目标材质”槽中指定草地材质。
3. 点击“查找并添加材质”。

工具会递归处理名称同时包含 `grass` 和 `quad` 的 `MeshRenderer`，包括子级、孙子级、更深层级及未激活物体。例如 `grass001_quad001` 会被匹配，而中间分组 `grass001` 不会被匹配。匹配节点原有的材质列表会被完全覆盖，只保留目标材质。

## 防重复与撤销

- 已经只使用目标材质的节点会被跳过，重复点击不会重复添加材质槽。
- 整次批处理支持 Unity Undo。
- 支持同时选择多个挂有该组件的根物体。
- Console 会报告找到、修改和跳过的节点数量。

## 已知限制

- 节点名称必须同时包含 `grass` 和 `quad`，不区分大小写。
- 目标节点必须具有 `MeshRenderer`。
- 工具修改场景或 Prefab 模式中的模型实例，不直接修改 FBX 源文件。

## 相关文件

- `Scripts/Runtime/GrassQuadMaterialAssigner.cs`
- `Scripts/Editor/GrassQuadMaterialAssignerEditor.cs`
