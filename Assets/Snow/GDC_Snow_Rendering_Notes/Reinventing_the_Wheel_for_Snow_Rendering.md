# GDC 2023：Re-inventing the Wheel for Snow Rendering

> Santa Monica Studio 在《God of War Ragnarök》中重写实时可变形雪地／高度场系统的设计复盘

## 目录

- [1. 演讲信息与阅读约定](#1-演讲信息与阅读约定)
- [2. Big Picture：这次重写真正解决了什么](#2-big-picture这次重写真正解决了什么)
- [3. 旧系统：Screen-Space Parallax Snow](#3-旧系统screen-space-parallax-snow)
- [4. 从最终产品倒推技术方案](#4-从最终产品倒推技术方案)
- [5. 新系统：从交互到最终画面的完整数据流](#5-新系统从交互到最终画面的完整数据流)
- [6. 新系统组件级拆解](#6-新系统组件级拆解)
- [7. Tessellation 的代价与 PS4 关键优化](#7-tessellation-的代价与-ps4-关键优化)
- [8. 从“雪地渲染”扩展为通用高度场工具](#8-从雪地渲染扩展为通用高度场工具)
- [9. 美术工作流与调试思路](#9-美术工作流与调试思路)
- [10. 演讲中的重要 Tips](#10-演讲中的重要-tips)
- [11. 一页式心智模型](#11-一页式心智模型)
- [12. 核心术语表](#12-核心术语表)
- [13. 主题索引与官方资料](#13-主题索引与官方资料)

---

## 1. 演讲信息与阅读约定

### 1.1 基本信息

- 演讲：**Advanced Graphics Summit: Re-inventing the Wheel for Snow Rendering**
- 演讲者：**Paolo Surricchio**，Santa Monica Studio Senior Staff Rendering Programmer
- 场合：GDC 2023 Advanced Graphics Summit
- 对象：《God of War Ragnarök》的实时雪地，更准确地说，是一个可复用的 **Height Field System（高度场系统）**
- 官方视频页面：[GDC Vault](https://gdcvault.com/play/1028917/Advanced-Graphics-Summit-Reinventing-the)
- 官方讲义：[Santa Monica Studio PDF](https://sms.playstation.com/media/documents/GOWR_Paolo_Surricchio_ReinventingTheWheel_GDC23.pdf)
- GDC 讲义镜像：[GDC Vault Slides PDF](https://media.gdcvault.com/gdc2023/Slides/Re-inventing%2Bthe%2Bwheel%2Bfor%2Bsnow%2Brendering_Surricchio_Paolo.pdf)

官方讲义共 91 页，并包含大量演讲者注释。本文依据视频页面的演讲说明、讲义正文和演讲者注释进行结构化转述，不是逐字字幕。

### 1.2 证据标记

为了避免把讲解时的类比误当成 Santa Monica Studio 的公开实现，本文采用以下标记：

- **[演讲明确]**：演讲者直接说明的事实、目标、流程或数据。
- **[图示推导]**：可由演讲流程图或多个明确描述组合得到，但不是逐字陈述。
- **[辅助类比]**：为了帮助建立心智模型而添加的解释。
- **[未公开]**：演讲没有披露足够细节，不应自行补全。

> [!IMPORTANT]
> 本文只解释演讲中的 Santa Monica Studio 方案，不把它改写成某个引擎的教程，也不讨论当前工程应当如何实现。

### 1.3 演讲真正想传达的主题

表面上，这是一场雪地渲染演讲；实际上，它更像一次渲染系统架构复盘。

Paolo 在开场便说明：重点不是某个精巧算法的全部细节，而是团队为什么放弃已经出货的方案、怎样从产品目标反推技术、怎样把系统拆成可替换的模块，以及怎样让一次针对雪地的投入继续服务于粒子、程序化模型、沙地和未来项目。

因此，理解这场演讲需要同时看两条线：

1. **画面线**：脚印怎样记录、表面怎样变形、材质与细节怎样补足。
2. **工程线**：为什么旧系统无法扩展，新系统如何控制性能风险并保留未来扩展空间。

---

## 2. Big Picture：这次重写真正解决了什么

### 2.1 背景不是“做出脚印”，而是“让整个项目都能用”

《God of War (2018)》已经有看起来很好的动态雪地。如果只看单个展示场景，很容易认为续作只需重新启用该功能。

但《Ragnarök》的生产条件完全不同：

- 游戏从一开始就确定同时登陆 PS4 与 PS5。
- Midgard 因 Fimbulwinter 被大面积积雪覆盖。
- 世界规模超过前作两倍，团队、合作方和外包规模也更大。
- 最终使用雪地位移的关卡数量比前作高出约一个数量级。
- 同一套技术还会被用在雪以外的材质上。

旧方案的问题不是“不能运行”，而是每次使用都需要太多人工照料、跨部门约束和特殊资产。它能做出少量精品场景，却无法成为整个大型项目的默认能力。

### 2.2 新系统的硬性目标

**[演讲明确]** 团队给新系统列出的要求可以归纳为：

1. **任意网格**：引擎没有统一地形系统，地形是美术手工雕刻的 bespoke meshes，因此功能不能只支持规则高度场地形。
2. **材质系统原生集成**：应自动获得材质编辑器已有的图层、混合和渲染能力。
3. **最小设置成本**：理想情况是材质上勾选一个选项，其余由构建流程完成。
4. **较稳定的性能**：缩小最好与最坏场景之间的波动。
5. **按需付费**：未使用该功能的区域不承担固定内存成本。
6. **跨代扩展**：PS4 上运行良好且画面合格，PS5 上无需重新制作美术内容即可提升质量。

团队接受的主要妥协，是几何方案在 PS4 上很难达到旧 Parallax 方案的逐像素位移精度。美术团队认为这是值得的：可用性、稳定性和规模化生产更重要。

### 2.3 一句话架构

> 在相机周围维护一个持续滚动的顶视高度场，把交互形状合成为位移及辅助纹理；渲染时只在高度发生变化的网格区域启用硬件细分并执行真实几何位移，再把高度信息转换为材质混合、法线细节、粒子碰撞和程序化模型生成的共同语言。

### 2.4 完整大图

```text
角色 / 物体 / VFX 的交互形状
        │
        │ capsules、spheres、meshes、effects
        ▼
相机周围的 Top-down 数据采集
        ├── 未位移表面的深度（每帧重绘）
        └── Carving Map（持久保存并随相机滚动）
        │
        ▼
Compute Composite
        ├── 合成最终高度 / 位移数据
        ├── 平滑高度，避免尖锐断层
        ├── 计算邻域高度变化
        ├── 输出 Tessellation Factor Texture
        └── 输出可被其他系统复用的 masks / heights
        │
        ├─────────────────────────────────────────────┐
        ▼                                             ▼
网格渲染                                      共享高度场信息
        ├── GPU meshlet culling                       ├── 材质图层混合
        ├── 只给必要 patch 开 Tessellation            ├── Detail Normal
        ├── Vertex displacement                       ├── Dynamic Normal
        └── Screen-space shadow                       ├── GPU 粒子碰撞
                                                      └── 程序化小模型生成
        │                                             │
        └──────────────────┬──────────────────────────┘
                           ▼
                 最终可交互雪地 / 沙地画面
```

Big Picture 中最重要的一点是：**位移纹理不是系统的最终目的，而是多个渲染与 VFX 组件共同消费的数据接口。**

---

## 3. 旧系统：Screen-Space Parallax Snow

### 3.1 旧方案如何工作

《God of War (2018)》使用的是 **Screen-Space Parallax Mapping（屏幕空间视差映射）**。它与常规 Parallax Mapping 的核心思想相同，但不是在切线／纹理空间做 ray marching，而是在屏幕空间进行。

旧系统大致包含以下数据流：

```text
交互 meshes / VFX
        │ 写入“挖多深”
        ▼
持久 Top-down Render Target
        │ 随相机滚动
        ▼
Projection Mesh 把顶视信息投到屏幕
        │
        ├── 从相机视角加入额外 meshes / particles 细节
        ▼
Screen-space Height Representation
        │
        ▼
屏幕空间 Parallax Ray March
        │
        ▼
看起来发生凹陷的表面
```

交互形状通常是角色对应的 capsule、sphere 或其他任意网格。它们使用专用 Shader，把适合 Parallax 算法的数据写入持久 Render Target。

### 3.2 资产为什么复杂

一个雪地区域不只是“一张雪地网格”。演讲展示的 Maya 横截面至少涉及：

- **Rendering Surface**：真正使用雪材质绘制的表面。为了让 Parallax 工作良好，它需要尽量平坦。
- **Projection Surface**：位置匹配的另一张网格，用于把顶视数据投影到屏幕空间。
- **Maximum / Minimum Meshes**：位于下方、描述未受扰动雪面上下界的网格。
- **Height Textures 与材质设置**：部分形状以高度纹理表达，所以 Maya 中甚至看不到最终起伏地形。

演讲者强调，幻灯片展示的仍是简化版本；实际还有更多材质和纹理设置。很多部件必须彼此吻合，导致设置容易出错。

### 3.3 它为什么曾经是好方案

旧系统并不是失败的技术。

- 能获得接近逐像素精度的位移外观。
- 成本与表面状态有关：当表面大部分处于未挖掘状态时，可以较早退出 ray march。
- 对天然就是平面的特殊表面非常合适。

Santa Monica Studio 在两代游戏的水体位移中仍继续使用这一类屏幕空间 Parallax，因为水本来就是受特殊规则约束的平面，玩法和美术也已经会围绕水面处理。

> [!TIP]
> 判断技术好坏不能脱离使用域。同一技术用于平坦水面可能非常合适，用于大面积、弯曲且与大量物体自然相交的地形却可能不合适。

### 3.4 无法规模化的原因

#### 性能波动与最坏时机重合

位移越深、覆盖越广，ray march 穿过的像素越多，Shader 越贵。最坏情况常发生在战斗中：玩家和敌人频繁破坏雪面，而战斗本身已经在消耗最多的性能预算。

#### 视角伪影

当视线方向逐渐平行于 Parallax 平面时，普通 Parallax 已容易出现伪影；屏幕空间版本还会把大量高度信息压入少量像素，使问题更明显。

#### 细节与位移表面不一致

细节最初绘制在顶部表面，而最终看到的是“虚拟位移”后的表面，所以细节会相对最终形状发生闪烁或漂移。Projected Decal 可以缓解，但系统可能产生数百甚至数千个粒子，无法为每个细节都支付 Decal 成本。

#### 生产约束扩散到整个团队

为了规避伪影，环境美术、设计、Camera Collision、Gameplay Programming、Cinematic Animation 等部门都必须知道雪地的特殊限制。技术的内部约束变成了跨部门依赖。

#### 只能用于少量特制区域

前作最终只有少数区域使用该技术，并且每一区域都需要特别照料。续作需要在多得多的关卡中使用它，这种生产模式无法扩展。

> [!WARNING]
> 旧方案最严重的问题不是单个 Shader 很复杂，而是算法的特殊数据要求支配了资产、关卡、镜头和跨部门流程。局部的技术选择变成了整个生产管线的核心支柱。

---

## 4. 从最终产品倒推技术方案

### 4.1 先让美术定义视觉目标

团队没有从“Tessellation 能做什么”开始，而是先请 Senior Environment Artist Kyle Bromley 给出目标画面和功能需求。

从美术规格中自然出现了三个相对独立的子系统：

1. 玩家走过的位置产生真实形状变化。
2. 凹陷内部的材质外观发生改变。
3. 凹陷周围出现更细的雪粒、法线和堆积细节。

工程团队再用硬件实验确认几何方案是否在可行范围内：在 Maya 中不断细分测试网格，观察三角形数量和 tiny-triangle overdraw，确认几何位移足以达到产品需要。

> [!IMPORTANT]
> 演讲的第一条 Takeaway：**Always start from the product and work backwards.** 先确定最终产品，再向后推导方案；同时尽早估算成本，确认方向至少处于“可能做成”的范围。

### 4.2 研究已有方案，但不为“业界常用”牺牲硬需求

团队调研了其他游戏与研究方案。部分方案会留下 T-junction，部分依赖预处理网格或受限的特性集合，无法同时满足任意网格、内存、跨代和工作流要求。

这并不代表这些研究不好。演讲者明确建议继续阅读，因为某些限制对别的游戏或引擎可能完全可以接受。

由于人员和生产日程有限，团队严格 timebox 自己的 R&D，目标集中在：

- 只在需要时细分。
- 能降低细分因子时尽量降低。
- 不让系统其余部分绑定到某一种具体细分实现。

### 4.3 选择硬件 Tessellation 的理由

另一位 Rendering Programmer Valerio Guagliumi 当时正在把 Hardware Tessellation 加入通用 Shader Pipeline，原本用于 PS5 的更高网格细节。这个能力也符合雪地系统的约束：

- 不需要为预细分网格支付额外常驻内存。
- 可动态调整细分程度。
- 可随平台和场景缩放。
- 可以只对需要的区域增加几何密度。

团队知道硬件 Tessellation 有性能风险，但已经把风险纳入设计，并且没有让系统其他模块依赖“细分必须由硬件 Tessellator 完成”。

> [!IMPORTANT]
> 演讲的第二条 Takeaway：把技术做成积木。任何一块都不应成为“一旦替换，整个系统就倒塌”的唯一核心支柱。

---

## 5. 新系统：从交互到最终画面的完整数据流

### 5.1 美术侧入口

与旧系统相比，美术不再搭建 Projection Surface、上下界网格等专用组合。他们像平常一样雕刻地形网格。

早期版本对网格密度有一定规则，后来也被解决。最终对合理的任意网格都能工作。

启用方式被压缩为材质中的一个 checkbox，其余数据由 build pipeline 自动生成。

### 5.2 顶视数据采集

运行时仍保留旧系统中已经证明有用的“相机周围顶视窗口”概念，但移除了 Parallax 专用的数据包装。

每帧执行：

1. 从上向下绘制相机周围固定区域内的**原始、未位移网格深度**。
2. 把角色、物体和 VFX 的 carving shapes 绘入 Render Target。
3. 用未位移深度测试交互形状；没有真正与雪面相交的形状不能挖雪。
4. 深度纹理每帧重绘，Carving Map 则持久保存。
5. 相机移动时，Carving Map 随相机反向滚动，让投影中心保持在相机附近。

官方 bonus notes 进一步说明：相机移动会锁定到纹素级移动，纹理向相反方向滚动，新暴露的区域清回适合该技术的默认值。这样可以避免连续亚纹素滚动造成不稳定采样。

```text
Camera moves +Δx,+Δz
        │
        ├── Top-down window stays centered near camera
        └── Persistent textures scroll -Δx,-Δz
                         │
                         └── newly exposed texels = default state
```

### 5.3 Compute 合成

Compute Shader 把深度、持久 carving 数据和其他交互信息合成为几张供后续消费的纹理。

其中包括：

- 最终位移高度。
- 平滑后的高度，避免尖锐、突然的几何断层。
- 每个像素邻域的高度／细节变化。
- 由邻域变化推导出的 Tessellation Factor Texture。
- 可转换为材质 alpha、法线、粒子碰撞和程序化生成 mask 的信息。

**[辅助类比]** 可以把 Composite Pass 理解为系统的“数据编译器”：上游输入是各种交互描述，下游不直接关心角色或粒子是什么，只读取标准化后的高度、变化率与 mask。

### 5.4 从高度变化推导细分需求

演讲没有公开精确 kernel、采样半径或完整公式，但明确说明：系统会分析每个像素周围的 detail variance，并把它转换为 Tessellation Factor。

下面仅是忠于该描述的简化伪代码，不代表原始实现：

```text
for each heightFieldPixel p:
    localHeights = sampleNeighborhood(heightTexture, p)
    smoothedHeight[p] = smooth(localHeights)
    localVariation = measureVariation(localHeights)
    tessFactorTexture[p] = mapVariationToTessFactor(localVariation)
```

其意义不是“脚印区域全部使用最大细分”，而是：

- 平坦且没有位移变化的区域不需要增加几何。
- 高度变化缓慢的区域只需少量细分。
- 脚印边缘、沟槽和细节变化大的区域获得更高细分。

### 5.5 网格细分与真实位移

渲染网格时，Hardware Tessellation 根据 Tessellation Factor Texture 对三角形进行细分，然后顶点阶段使用高度场进行真实几何位移。

与旧方案的根本区别是：

- 旧方案的几何表面仍大体平坦，凹陷主要是屏幕空间 ray march 产生的视觉结果。
- 新方案产生真实的细分顶点，并把这些顶点移到新的空间位置。

这使弯曲地形、与其他网格自然相交的大型地表更容易处理，也移除了旧 Parallax 投影结构对资产的支配。

### 5.6 高度转换为材质语言

只有几何变形还不像雪。团队构建了一组工具，把系统内部高度转换为材质编辑器熟悉的 alpha。

```text
Displacement Height
        │ remap / mask
        ▼
Material Alpha
        │
        ├── 未压雪层
        ├── 压实雪层
        ├── 泥土层
        ├── 沙地层
        └── 任意已有材质层与混合功能
```

这样，材质系统已有的图层混合能力立即全部可用。演讲中的示例是在雪被压下后露出泥层，但它可以是任何层，也可以是多层。

美术后来要求 Vertex Color Mask 等额外控制。Paolo 特别区分了两种工具：

- 如果额外控制只是增加新的“动词”，不用它也能正常出货，它是**加法工具**。
- 如果工具是让功能勉强工作的唯一方式，它会把限制转嫁给用户，是**减法工具**。

### 5.7 恢复高频细节

从逐像素 Parallax 改为几何位移后，高分辨率细节会减少。团队用两个补充层恢复感知质量：

1. 在脚步附近维护另一张低分辨率、持久滚动的顶视 mask，用来混合 Detail Normal Map。
2. 从顶视 Height Mask 每帧推导 Dynamic Normal Map，模拟雪面更细小的变化。

第二项最终出货并默认用于材质，但由于 VFX 团队排期有限，没有被推到可能达到的最完整程度。因为它不是出货硬需求，团队接受了当前完成度。

### 5.8 阴影与裂缝限制

**[演讲明确]** 系统只使用 Screen-Space Shadow；在 Shadow Map 中再次用 Tessellation 重绘网格代价过高。

此外，系统不是渐进式地让所有相邻 patch 缓慢靠近同一细分等级，而是只在需要处开启细分。因此同一条边两侧可能有很大的 subdivision difference，若形成 T-junction，可能出现缝隙。其他方案会用更渐进的细分减小缝隙，但这套系统选择了符合自身目标的权衡。

> [!WARNING]
> “真实几何位移”不等于没有伪影或没有代价。阴影路径、patch 边界连续性和 Tessellator 固定开销仍是必须明确接受的约束。

---

## 6. 新系统组件级拆解

| 组件 | 主要输入 | 主要输出 | 解决的问题 |
|---|---|---|---|
| 原始表面深度 Pass | 未位移网格、顶视相机 | 每帧深度纹理 | 判断交互形状是否真的与表面相交 |
| Persistent Carving Map | Capsules、spheres、meshes、VFX | 持久交互痕迹 | 保存脚印和拖痕，并让数据跟随相机窗口 |
| Composite Compute Pass | 深度、carving、其他 masks | 位移、平滑高度、细分因子及辅助纹理 | 把多种交互编译为标准高度场数据 |
| Tessellation Factor Generation | 高度邻域变化 | Tessellation Factor Texture | 只在几何细节有必要时增加顶点 |
| Mesh Rendering | 原网格、位移纹理、细分因子 | 真实位移表面 | 产生可参与后续渲染的几何形状 |
| Material Translation | 高度与 masks | 材质 alpha／图层参数 | 复用现有材质编辑器和美术工作流 |
| Detail Normal Mask | 脚步附近的持久 mask | Detail Normal 混合权重 | 补偿几何位移缺少的高频表面细节 |
| Dynamic Normal | 顶视 Height Mask | 每帧法线纹理 | 为所有材质提供动态微细节 |
| GPU Meshlet Classification | 网格 meshlets、视锥、位移区域 | 细分／普通两个 index queues | 避免整张大型地形进入 Tessellator |
| Height-field Particle Collision | 顶视高度场、GPU 粒子 | 粒子碰撞结果 | 让 opaque particles 和 mini-models 正确撞击动态表面 |
| Procedural Model Placement | 位移 mask、区域参数 | 持久小模型实例 | 在动态变化区域自动生成雪块等几何细节 |

### 6.1 依赖方向为何重要

```text
Interaction Recording
        ▼
Height-field Composite  ───────► Shared Data Products
        ▼                              │
Geometry Displacement                 ├── Material
                                       ├── Normals
                                       ├── Particles
                                       └── Procedural Models
```

系统的核心契约是“生产和消费高度场数据”，而不是“所有功能都必须知道硬件 Tessellation”。因此：

- 粒子碰撞不需要知道网格如何细分。
- 材质混合不需要知道 carving shape 是角色还是特效。
- 程序化模型只需要读取位移信息。
- 未来若替换细分实现，上游交互和许多下游效果仍可保留。

这正是演讲所说的 block-based architecture。

---

## 7. Tessellation 的代价与 PS4 关键优化

### 7.1 固定入口成本

团队本来知道 Tessellation 较慢，但某些 PS4 场景仍比预想更差。GPU capture 中 Hull／Domain Shader 调用形成明显波峰，Occupancy 接近零：执行单元在等待 Tessellator 返回。

演讲给出的粗略经验值是：在所讨论的 AMD 硬件上，即使 Hull Shader 只是 passthrough、完全不增加 subdivision，开启 Tessellation 的 draw 也可能比普通 draw 慢约 **30%～40%**。这是用于建立量级感的估算，不是跨平台常数；旧硬件的固定代价更高。

因此规则不是“细分因子永远越小越快”，而是：

> 一旦支付 Tessellator 的固定入口成本，就应该让它真正细分。少量较大的输入三角形并进行较多细分，通常好过大量小三角形只做很少细分。

### 7.2 为什么地形是最坏情况

大地形通常：

- 网格面积大、形状不规则。
- 难以作为整体进行有效剔除。
- 同时处于活动状态的三角形很多。
- 但真正靠近脚印、需要细分的区域很小。

如果整张地形只因为局部脚印就进入 Tessellation Pipeline，固定成本会浪费在绝大多数平坦区域。

美术曾提出在 LOD 阶段手工切分网格，但工程团队选择自动化，避免把优化负担转给资产作者。

### 7.3 Meshlet 化

构建阶段把 Index Buffer 分成多个**几何上连续的三角形片段**。演讲称它们为 meshlets。

每个 meshlet 保存：

- Index Offset。
- Index Count。
- 用于剔除的数据；该场景中 Bounding Sphere 已足够。

同一网格的 meshlets 尽量拥有相同或接近的三角形／索引数量，并记录其中最大的 Index Count。

### 7.4 GPU 分类

每张网格执行一次 Compute Dispatch，逐 meshlet 判断：

1. 是否在视锥外；若是，直接剔除。
2. 若可见，是否离位移区域足够远；若是，进入普通渲染队列。
3. 若可见且靠近位移，进入 Tessellated 队列。

```text
for each meshlet:
    if outsideFrustum(meshlet.bounds):
        discard
    else if farFromDisplacement(meshlet.bounds, displacementRegion):
        regularQueue.append(meshlet.indices)
    else:
        tessellatedQueue.append(meshlet.indices)
```

最终不是把整张网格一次绘制，而是进行两次 Indirect Draw：

- 一次使用 Hardware Tessellation。
- 一次使用普通 Vertex Pipeline。

### 7.5 不同 Index Count 的处理

Indirect Arguments 按“所有 meshlets 的最坏 Index Count × 通过测试的 meshlet 数量”填写。较短 meshlet 会产生额外顶点槽位。

在 Vertex Shader 中，系统根据硬件提供的索引找到当前 meshlet 信息，读出它的真实 Index Count，再把超出该数量的额外顶点折叠到 0。

这也是为什么 meshlet 尺寸应尽量一致：差距越小，需要折叠的无效工作越少。

演讲还指出该技巧依赖不使用 Automatic Vertex Fetching；在目标主机的 GCN 硬件上，团队本来就采用相应路径。

> [!IMPORTANT]
> 这里的目标不是让 Tessellation 本身“免费”，而是让尽可能少的输入三角形支付它的固定成本。

### 7.6 优化结果

调试视图中，红色 patch 表示 Tessellated，绿色表示普通渲染。锁定 Frustum 后回看，可以清楚看到大量 meshlets 被剔除。

**[演讲明确]** 这项优化在部分场景节省约 **0.5 ms 到 2 ms**，是让整个系统能在基础 PS4 上出货的主要因素之一。

> [!TIP]
> 演讲的第三条 Takeaway 可以概括为：提前识别将要遇到的风险，并准备不止一条解决路线。已知的性能问题是可规划的工程任务，突然出现的性能问题才会破坏生产。

---

## 8. 从“雪地渲染”扩展为通用高度场工具

### 8.1 为什么后期仍能增加功能

团队本来可以在完成几何位移、材质混合和 PS4 优化后停止。项目后期 Rendering Team 扩大，获得额外时间时，他们已经拥有一个可扩展的 Composite Pass 和廉价可访问的高度场数据，所以可以把时间直接用于增加效果，而不是先拆掉旧架构。

### 8.2 Height-field Particle Collision

Santa Monica Studio 的粒子模拟完全运行在 GPU 上，并支持 Depth Collision。但 Opaque Particles 和以真实小模型代替 sprite 的 mini-models 会写入深度；若使用普通 Depth Collision，它们会与自己和彼此发生错误碰撞。

现在系统拥有从上向下的表面表示，可以直接进行 Height-field Collision：

- 雪块在角色行走时被抛起。
- 颗粒与动态地形正确碰撞。
- 数百个小模型可以参与碰撞。
- 不受当前屏幕可见范围限制，只要处于相机周围约 **25 米半径**的雪地区域即可查询。

### 8.3 程序化持久模型

系统还会在位移周围实时生成持久小模型。其概念类似 Vegetation System：

- 植被系统从手绘 mask 读取适合生成植物的位置。
- 这里从 Height-field Composite 产生的动态 displacement 信息读取适合生成雪块的位置。

参数可以按区域调整，并实时看到结果。演讲者强调，这让美术直观看到程序化模型放置在动态网格上、接近零手工制作成本且运行成本很低时的潜力。

### 8.4 不只用于雪

同一技术被用于 Alfheim 的沙地。值得注意的是，这套沙地效果由合作方 Bluepoint Games 的美术人员完成；他们只需很少的工程输入，就能使用同一系统获得完全不同的外观。

这说明可复用性不是“参数换成黄色就叫沙”，而是：高度场记录、材质翻译和附加细节足够解耦，另一支团队可以用熟悉的美术语言重新组合它们。

### 8.5 最终画面分层

演讲最后用 Kratos 房屋后方场景逐层展示：

```text
Base Mesh
   + Kratos 行走产生的 Geometry Displacement
   + 根据高度位移混合的 Material Layers
   + 玩家行走区域的 Detail Normal
   + Opaque / Transparent Particles
   + Procedurally Placed Models
   = Final Interactive Surface
```

左侧参考是美术手工雕刻的形状，右侧则主要由玩家跑动动态生成。最终效果不仅接近最初美术目标，在部分方面还超出了原始设想。

---

## 9. 美术工作流与调试思路

### 9.1 Santa Monica Studio 的生产背景

团队使用 Maya 作为关卡编辑器，关卡由设计与美术手工雕刻；游戏渲染只能在 Development Kit 上查看。Houdini 等工具会自动化流程，但管线末端仍保留手工微调能力。

这使工程方案必须在两个极端之间取得平衡：

- 太专用：单一效果很强，但每次使用都需要工程和多个部门配合。
- 太通用：抽象宏大，却不能高质量地满足当前游戏的具体目标。

新系统的策略是先满足明确产品目标，同时让产出的中间数据和组件可被复用。

### 9.2 艺术家看到的入口

- 正常雕刻合理网格。
- 在材质中启用位移 checkbox。
- 使用熟悉的材质图层与 alpha 混合。
- 可选地使用 Vertex Color 等增加控制，而不是修复系统才能工作。
- 按区域调整程序化细节参数并实时预览。

### 9.3 建议观察的调试层

演讲通过关闭其他功能来隔离问题。可以把展示方式归纳成以下调试视图：

1. **Base Mesh Only**：确认原始资产形状。
2. **Displacement Only**：观察高度场到几何位移的结果。
3. **Wireframe / Tessellation**：确认只有变化区域被细分。
4. **Red / Green Meshlet Classification**：红色细分、绿色普通，验证 GPU 分类。
5. **Frustum Lock**：固定视锥后查看身后区域，直观看剔除效率。
6. **Material Layers**：逐层检查高度到 alpha 的映射。
7. **Detail Normal Only**：检查高频细节是否稳定贴合凹陷。
8. **Particles / Models Separately**：验证附加系统使用相同高度数据时的贡献。

> [!TIP]
> 一个适合美术使用的复杂效果，必须能被拆层观察。最终画面很漂亮并不能证明系统正确；关闭各层后仍能解释每一层的输入和贡献，才有利于生产与优化。

### 9.4 PS4 与 PS5 的缩放

演讲中此前展示的资产均来自 PS4。团队在两台主机上达成性能目标，并且平台间质量变化不需要美术修改内容。

PS5 展示关闭了动态模型和附加细节，刻意只保留高质量纹理、Tessellation 与位移，以说明基础网格路径本身可以随更强硬件提升质量。

跨代设计的关键不是维护两套资产，而是让同一内容通过细分和纹理质量等系统参数扩展。

---

## 10. 演讲中的重要 Tips

### 10.1 产品与决策

> [!IMPORTANT]
> **从最终产品倒推。** 先由美术目标定义“必须看到什么”，再选择算法；不要先决定使用 Tessellation，再寻找适合它的问题。

> [!TIP]
> 在正式投入前做量级测试。即使知识不完整，也应通过原型、硬件 Capture 和压力场景提高估算质量，确认方案在可行区间。

> [!TIP]
> 调研其他方案时，比较的是“它的限制是否适合我的产品”，而不是它是否先进或是否被 AAA 游戏使用。

### 10.2 架构

> [!IMPORTANT]
> **强迫系统模块化。** 上游生产标准数据，下游消费标准数据；不要让某个算法的特殊输入格式支配整个资产和渲染管线。

> [!TIP]
> 优先设计稳定的组件契约，而不是把当前算法写成不可替换的核心。新系统依赖“网格最终会获得足够顶点”，并不要求所有模块理解硬件 Tessellation。

> [!TIP]
> Composite Pass 不应只输出“当前最终画面需要的唯一纹理”。廉价、通用的中间信息可能在后期成为粒子碰撞、程序化模型或新材质的输入。

### 10.3 工具与美术体验

> [!IMPORTANT]
> 区分“加法控制”和“减法控制”。可选的 Vertex Color Mask 为美术增加表达能力；必须手工搭 Projection Mesh 才能避免错误，则是在把技术债交给用户。

> [!TIP]
> 自动化重复且可判断的工作。大型网格切分和细分区域分类可以由构建流程与 GPU 完成，不应要求每个资产作者手工优化。

> [!TIP]
> 让新技术说材质系统已有的语言。把高度转换为 alpha 后，美术立即获得现有图层混合能力，也更容易创造雪之外的外观。

### 10.4 性能

> [!WARNING]
> Tessellation 有显著固定入口成本。只开启却几乎不细分，可能比真正使用它更浪费；演讲中的 30%～40% 是特定 AMD／目标硬件上的粗略量级，不能直接当作其他平台预算。

> [!TIP]
> 对 Tessellation 的优化重点之一，是减少进入 Tessellator 的输入 patch 数量，而不仅是降低每个 patch 的 factor。

> [!TIP]
> 测试最坏的玩法时刻。雪地 ray march 的最坏情况恰好发生在战斗中，若只测安静场景，会错判系统可用性。

> [!TIP]
> 预先知道风险会改变问题性质。团队从选择 Tessellation 的第一天就准备减少参与细分的三角形，因此实际成本超预期时仍有可执行的备选路线。

### 10.5 生产与长期价值

> [!IMPORTANT]
> R&D 原型与真正出货之间有巨大差距。只有把系统带过资产生产、跨平台性能、工具和最终产品，获得的知识才完整。

> [!TIP]
> 先交付必需模块，再在有时间时扩展。新系统在没有粒子碰撞和程序化模型时已经能出货，因此后期功能是增益，不是阻塞风险。

> [!TIP]
> 可复用技术不一定来自“先做一个万能框架”。先解决真实且严格的问题，同时保持组件边界，往往能得到更可信的通用工具。

---

## 11. 一页式心智模型

### 11.1 为什么重写

```text
旧技术画面好
    但
需要平坦表面 + 专用投影资产 + 大量手工规避 + 性能随破坏程度波动
    所以
无法覆盖更大的世界、更多关卡、更多团队和更多平台
```

### 11.2 新系统怎样工作

```text
交互形状
  → 顶视深度测试
  → 持久滚动 Carving Map
  → Compute 合成 / 平滑 / 邻域变化
  → Tessellation Factor Texture
  → 必要 meshlets 进入 Tessellator
  → 真实几何位移
  → 高度驱动材质、法线、粒子与模型
```

### 11.3 最关键的三个工程决策

1. 用产品目标和硬约束选择几何方案，而不是追随单一算法。
2. 让高度场成为共享数据接口，不让 Tessellation 成为全系统依赖。
3. 用 GPU meshlet 分类减少进入 Tessellator 的三角形，使方案在 PS4 上可出货。

### 11.4 最关键的三个视觉层

1. **低频形状**：真实几何位移。
2. **中频外观**：高度驱动的材质层混合。
3. **高频反馈**：Detail Normal、Dynamic Normal、粒子和程序化模型。

### 11.5 最终成果

- 任意合理网格。
- 材质 checkbox 级别的设置入口。
- 同一内容跨 PS4／PS5 缩放。
- 以很少额外支持复用于沙地和合作团队。
- 在完成出货目标后，继续扩展到粒子碰撞与程序化模型。

---

## 12. 核心术语表

| 术语 | 本演讲中的含义 |
|---|---|
| Height Field System | 在相机周围记录、合成并消费动态表面高度的整套系统，不只等于一张高度图 |
| Screen-Space Parallax Mapping | 旧系统在屏幕空间 ray march 高度信息、制造表面凹陷外观的技术 |
| Carving Shape | 描述角色、物体或 VFX 如何挖入表面的 capsule、sphere 或其他网格 |
| Persistent Carving Map | 保存历史脚印并随相机滚动的顶视交互纹理 |
| Un-displaced Depth | 原始表面的顶视深度，用于阻止未相交形状错误挖雪 |
| Composite Pass | 把交互数据合成高度、mask、细分因子等标准数据的 Compute 阶段 |
| Tessellation Factor Texture | 表示各区域需要多少细分的纹理，由高度邻域变化推导 |
| Hardware Tessellation | 通过 Hull、固定功能 Tessellator 与 Domain 阶段动态增加几何的管线 |
| Meshlet | 从 Index Buffer 切出的几何连续小片段，用于更细粒度剔除和路径分类 |
| Indirect Draw | 绘制参数由 GPU 生成／填写的 draw；这里分别绘制细分与普通 meshlets |
| Detail Normal | 在脚步附近混入的预制高频法线细节 |
| Dynamic Normal | 从动态顶视高度 mask 每帧推导出的法线 |
| Mini-model | 粒子系统中以小型不透明模型而非 sprite 表示的粒子 |
| Additive Verb | 不使用也能完成目标、使用后增加美术表达能力的可选控制 |
| T-junction | 相邻 patch 细分不一致时可能形成的拓扑连接问题，可导致位移后裂缝 |

---

## 13. 主题索引与官方资料

### 13.1 按讲义内容顺序定位

官方讲义文本没有提供稳定的段落锚点，GDC 播放器时间轴也可能随播放器版本变化，因此本文不填写未经核实的精确时间戳或页码。以下索引按 91 页讲义的叙事顺序列出，可用标题或关键词在 PDF 中查找：

| 顺序 | 主题 | PDF 搜索关键词 |
|---:|---|---|
| 1 | SMS 工作方式与本演讲目标 | `reusable toolset`、`height field system` |
| 2 | 《Ragnarök》的跨代与积雪背景 | `PS4 and PS5`、`Fimbulwinter` |
| 3 | 旧 Screen-Space Parallax 流程 | `screen-space parallax mapping`、`persistent top-down render target` |
| 4 | 旧资产设置与缺点 | `projection surface`、`maximum and minimum meshes` |
| 5 | 新系统需求 | `arbitrary meshes`、`material editor`、`memory` |
| 6 | 美术目标与几何可行性测试 | `Kyle Bromley`、`work your way backwards` |
| 7 | 模块化开发哲学 | `build things in blocks` |
| 8 | 新高度场与 Composite 流程 | `carving map`、`detail variance`、`tessellation factor` |
| 9 | 材质层与法线细节 | `Heights are transformed into alpha`、`detail normal map` |
| 10 | PS4 Tessellation 性能问题 | `occupancy`、`30% to 40% slower` |
| 11 | Meshlet GPU 分类与 Indirect Draw | `meshlets`、`2 indirect draws` |
| 12 | 粒子碰撞与程序化模型 | `height field collision`、`permanent models` |
| 13 | 沙地复用与最终画面拆层 | `sands of Alfheim`、`breakdown` |
| 14 | 总结与三个 Takeaways | `Always start from the end goal` |
| 15 | Bonus Notes | `screen space shadows`、`t-junction` |

> [!IMPORTANT]
> 精确数字需要保留上下文：30%～40% 是特定 AMD 旧硬件上的粗略固定开销量级；0.5～2 ms 是部分场景的 meshlet 优化收益；25 米是演讲中粒子高度场碰撞可覆盖的相机周围半径。它们不是通用引擎常数。

### 13.2 官方资料

1. [GDC Vault - Advanced Graphics Summit: Re-inventing the Wheel for Snow Rendering](https://gdcvault.com/play/1028917/Advanced-Graphics-Summit-Reinventing-the)
2. [Santa Monica Studio - Official Presentation PDF](https://sms.playstation.com/media/documents/GOWR_Paolo_Surricchio_ReinventingTheWheel_GDC23.pdf)
3. [GDC Vault - Official Slides PDF](https://media.gdcvault.com/gdc2023/Slides/Re-inventing%2Bthe%2Bwheel%2Bfor%2Bsnow%2Brendering_Surricchio_Paolo.pdf)

### 13.3 最终总结

Santa Monica Studio 并不是因为旧雪地“看起来不好”才重写，而是因为旧方案无法承担续作的生产规模。新系统通过真实几何位移解决大型弯曲表面问题，通过高度到材质 alpha 的转换接入既有美术语言，通过持久顶视高度场向法线、粒子和程序化模型提供共享数据，再通过 GPU meshlet 分类控制硬件 Tessellation 在 PS4 上的固定成本。

这场演讲最值得记住的并非某个 Shader 技巧，而是选择技术的顺序：

```text
最终产品 → 硬约束 → 成本验证 → 模块契约 → 最小可出货系统
                                      │
                                      └── 有余力时继续扩展
```

技术价值最终体现在两件事上：它既解决了《Ragnarök》眼前的大面积动态雪地问题，也为团队留下了可继续复用的数据、工具和经验。
