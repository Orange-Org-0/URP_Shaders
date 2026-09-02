# Foliage Mesh 材质分配工具

## 用法

1. 将 `FoliageMaterialAssigner` 添加到树模型的根物体。
2. 在“目标材质”槽中指定叶片材质。
3. 点击“查找并添加材质”。

工具会递归处理名称包含 `foliage` 的合并后 `MeshRenderer`，包括未激活物体。每个匹配对象可以包含由多个 Quad 合并成的单个 Mesh，不再要求存在独立的 Quad GameObject。匹配节点原有的材质列表会被完全覆盖，只保留目标材质。

## 防重复与撤销

- 已经只使用目标材质的节点会被跳过，重复点击不会重复添加材质槽。
- 整次批处理支持 Unity Undo。
- Console 会报告找到、修改和跳过的节点数量。

## 已知限制

- 合并后的 Mesh 对象名称必须包含 `foliage`，不区分大小写。
- 工具只处理 `MeshRenderer`，没有 Renderer 的 Foliage 容器不会被修改。
- 工具修改场景或 Prefab 模式中的模型实例，不直接修改 FBX 源文件。

## 相关文件

- `Scripts/Runtime/FoliageMaterialAssigner.cs`
- `Scripts/Editor/FoliageMaterialAssignerEditor.cs`
