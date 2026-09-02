# Interactive Snow Tessellation 学习笔记

## 目标

只关注 Tessellation Pipeline，暂时忽略：

-   Snow Height
-   RenderTexture 交互
-   Noise
-   Lighting
-   Fragment Shader

目标：理解这两份代码中 Tessellation 的完整数据流。

涉及：

-   InteractiveSnowURP.shader
-   SnowTessellation.hlsl

------------------------------------------------------------------------

# 总体数据流

    Mesh Attributes
          ↓
    TessellationVertexProgram
          ↓
    ControlPoint
          ↓
    Hull Shader
          ├── hull()：传递控制点
          └── patchConstantFunction()：计算细分系数
                        ↓
                 Hardware Tessellator
                        ↓
           barycentricCoordinates
                        ↓
                   Domain Shader
                        ↓
                    Attributes
                        ↓
              后续 Vertex Processing

------------------------------------------------------------------------

# ① Tessellation Pipeline 接入

主 Shader 中：

``` hlsl
#pragma vertex TessellationVertexProgram
#pragma hull hull
#pragma domain domain
```

说明：

-   Vertex 阶段入口：TessellationVertexProgram
-   Hull Shader：hull
-   Domain Shader：domain

这里真正进入 Tessellation 的 Vertex 函数不是普通的 vert()。

------------------------------------------------------------------------

## TessellationVertexProgram

输入：

    Attributes

输出：

    ControlPoint

作用：

把普通 Mesh 顶点数据转换成 Tessellation 使用的数据格式。

数据变化：

    Attributes
        ↓
    TessellationVertexProgram
        ↓
    ControlPoint

它主要复制：

-   vertex
-   normal
-   uv

没有复杂计算。

------------------------------------------------------------------------

# ② 核心数据结构

## Attributes

表示：

> Unity Mesh 输入的普通顶点数据

例如：

    vertex
    normal
    uv

流程：

    Mesh
     ↓
    Attributes

------------------------------------------------------------------------

## ControlPoint

表示：

> Tessellation Patch 中的控制点

一个三角形 Patch：

            A

           / \

          /   \

         B-----C

对应：

    ControlPoint A
    ControlPoint B
    ControlPoint C

Hull Shader 接收：

``` hlsl
InputPatch<ControlPoint,3>
```

表示：

一个三角形由三个 ControlPoint 组成。

------------------------------------------------------------------------

## TessellationFactors

表示：

> 这个 Patch 应该细分多少

包含：

    edge[3]
    inside

不保存：

-   position
-   normal
-   uv

它只控制 Tessellation 强度。

------------------------------------------------------------------------

# ③ Hull Shader

Hull 阶段有两条输出路线。

------------------------------------------------------------------------

## 路线 1：hull()

输入：

    InputPatch<ControlPoint,3>

输出：

    ControlPoint

作用：

传递控制点。

本代码中：

``` hlsl
return patch[id];
```

基本没有修改。

------------------------------------------------------------------------

## 路线 2：patchConstantFunction()

输入：

    ControlPoint × 3

输出：

    TessellationFactors

作用：

计算：

-   三条边细分程度
-   内部细分程度

整体：

    ControlPoint × 3

            ↓

    hull()
            ↓
    ControlPoint × 3


    patchConstantFunction()

            ↓

    TessellationFactors

------------------------------------------------------------------------

# ④ Tessellation Factor 计算

函数链：

    patchConstantFunction
            ↓
    DistanceBasedTess
            ↓
    CalcDistanceTessFactor
            ↓
    UnityCalcTriEdgeTessFactors
            ↓
    TessellationFactors

------------------------------------------------------------------------

## CalcDistanceTessFactor

处理一个顶点。

输入：

    vertex
    Camera
    _Tess
    _MaxTessDistance

计算：

    顶点距离 Camera
            ↓
    距离权重
            ↓
    乘最大 Tess 强度
            ↓
    顶点 Tess Factor

规律：

    靠近 Camera
        ↓
    Tess Factor 大

    远离 Camera
        ↓
    Tess Factor 小

------------------------------------------------------------------------

## DistanceBasedTess

三个顶点分别计算：

    A → factorA

    B → factorB

    C → factorC

得到：

    float3 vertexFactors

------------------------------------------------------------------------

## UnityCalcTriEdgeTessFactors

把：

    顶点 Tess Factor

转换成：

    边 Tess Factor

例如：

    AB 边

    =
    (A factor + B factor) / 2

最终得到：

    edge[0]
    edge[1]
    edge[2]
    inside

------------------------------------------------------------------------

# ⑤ Tessellator + Domain Shader

## Hardware Tessellator

输入：

    ControlPoint × 3

    +

    TessellationFactors

作用：

根据 Factor 切分三角形。

输出：

    barycentricCoordinates

它不直接生成完整顶点。

------------------------------------------------------------------------

# barycentricCoordinates

表示：

> 新顶点在原三角形中的位置

例如：

    (1,0,0) → A

    (0,1,0) → B

    (0,0,1) → C

------------------------------------------------------------------------

# Domain Shader

输入：

    ControlPoint × 3

    +

    barycentricCoordinates

作用：

插值生成新的顶点数据。

例如：

    newPosition

    =
    A.position*x
    +
    B.position*y
    +
    C.position*z

同理：

    normal
    uv

也进行插值。

------------------------------------------------------------------------

输出：

    Attributes

即：

新的细分顶点。

------------------------------------------------------------------------

# 完整闭环

    Mesh

    ↓

    Attributes

    ↓

    TessellationVertexProgram

    ↓

    ControlPoint

    ↓

    Hull Shader

        ├── hull()
        │
        └── patchConstantFunction()

    ↓

    TessellationFactors

    ↓

    Hardware Tessellator

    ↓

    barycentricCoordinates

    ↓

    Domain Shader

    ↓

    Attributes

    ↓

    后续 Vertex Processing

------------------------------------------------------------------------

# 最终记忆

一句话：

> Vertex Program 把 Mesh 顶点转换成 ControlPoint；Hull
> 决定怎么切；Tessellator 负责生成新点；Domain
> 根据新点位置插值出真正的新顶点。
