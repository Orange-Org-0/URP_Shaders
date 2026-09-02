# Camera Controller

## 设置

1. 将 `CameraController` 添加到场景中的 Game Camera。
2. 将该相机的 Tag 设为 `MainCamera`，使 Play 模式下的 Quad 能够找到它。
3. 通过 `Move Speed` 调整移动速度，通过 `Look Sensitivity` 调整鼠标视角灵敏度。

## Edit 模式

Game Camera 会跟随最近活动的 Scene Camera，但只同步位置和旋转。投影模式、FOV、Orthographic Size、近远裁剪面、Aspect、Culling Mask、Clear Flags 和 Target Texture 等镜头与渲染配置均由 Game Camera 自身控制，不会被 Scene Camera 覆盖。

## Play 模式

- `W` / `S`：沿相机前后移动。
- `A` / `D`：沿相机左右移动。
- `E` / `Q`：沿世界 Y 轴上下移动。
- 鼠标移动：始终控制偏航和俯仰，不锁定或隐藏光标。俯仰限制为 -89° 至 89°。

## Quad 朝向

`LeavesControl` 只处理名称同时包含 `foliage` 和 `quad`（不区分大小写），并且具有有效 `MeshFilter` 和 `MeshRenderer` 的后代物体。渲染时，Quad 的局部 Y 轴与摄像机的反向 Forward 平行，使 Quad 朝向摄像机观察平面；Quad 的局部 Z 轴与摄像机 Up 平行，使所有叶片保持与画面一致的上方向。

- Edit 模式使用 Scene Camera。
- Play 模式只使用带 `MainCamera` Tag 的 Camera。
- 朝向只在相机渲染期间临时生效，渲染结束后恢复原始旋转。

## Foliage 随机移动

`LeavesControl` 会取得每个匹配 Quad 的直接父级并去重，使 `foliage001`、`foliage020` 等组在原始位置附近独立移动。组内所有 Quad 会一起移动，但不同 foliage 使用各自的随机世界空间方向和周期进度。

- `Movement Intensity`：最大世界空间位移，单位为 Unity 世界单位。
- `Movement Speed`：每秒完成的“离开原点并返回原点”周期数。
- 每个周期使用半个正弦波，foliage 平滑离开原点并返回；只有回到原点后才会选择下一条随机方向。
- 编辑模式和 Play 模式都会持续预览。强度或速度设为 `0`、禁用组件时，所有 foliage 恢复原始位置。

## 已知限制

- 使用旧版 Input Manager 的 `Mouse X` 和 `Mouse Y` 输入轴。
- Game 窗口必须正在接收输入，按键和鼠标控制才会生效。
- Play 模式下若没有带 `MainCamera` Tag 的有效相机，`LeavesControl` 不会改变 Quad 朝向。
- Quad 使用屏幕对齐方式，不根据 Quad 与摄像机之间的位置差产生透视朝向变化。
- `LeavesControl` 启用期间会控制 foliage 父级的位置，不应再由其他动画或脚本同时写入这些位置。
