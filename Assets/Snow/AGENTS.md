# AGENTS.md

# Project: Interactive Snow Deformation System

## Project Overview

This project aims to implement a real-time interactive snow system in Unity.

The goal is not only visual snow rendering, but building a Technical Artist oriented interaction system that demonstrates:

- Shader programming
- Render Texture workflow
- GPU based deformation
- Runtime texture painting
- Performance optimization
- VFX integration

The final result should be suitable for a Technical Art portfolio.

---

# Environment

## Engine

Unity Version:
- Unity 2022.3.62f1

Render Pipeline:
- Universal Render Pipeline (URP)

Main Development Tools:

- Shader Graph
- Amplify Shader Editor (ASE)
- HLSL
- C#
- Render Texture
- Custom Renderer Feature if necessary

---

# Core Goal

Create a snow surface that reacts to player interaction.

Examples:

- Player footsteps
- Object dragging
- Object falling
- Snow impact
- Snow trails

The system should support:

1. Real-time deformation
2. Persistent footprints
3. Adjustable deformation strength
4. Multiple interaction sources
5. Reasonable GPU performance

---

# Technical Direction

The preferred architecture is:

## Interaction Recording

Do NOT create thousands of permanent particles to represent footprints.

Avoid storing every footprint as an individual GameObject.

Preferred approach:

Use a texture based interaction buffer.

Pipeline:

Player/Object position
        |
        v
Interaction Brush
        |
        v
Render Texture
        |
        v
Snow Shader Sampling
        |
        v
Vertex displacement + shading


The Render Texture works as a dynamic snow mask / height map.

---

# Snow Data Representation

The snow surface should use texture based data.

Possible channels:

R channel:
- deformation height

G channel:
- footprint mask

B channel:
- wet snow / melting information

A channel:
- additional interaction data


The system should avoid unnecessary texture storage.

---

# Shader Requirements

The snow shader should support:

## Base Snow Rendering

Features:

- Snow color
- Normal detail
- Roughness variation
- Stylized or realistic snow appearance


## Deformation

Use the interaction texture to modify:

Vertex position:

Y displacement based on height map.

Example:

higher value:
snow pushed down

lower value:
normal snow


## Edge Detail

Add:

- footprint edge shadow
- snow compression area
- soft transition

Avoid hard binary masks.

---

# Interaction System

The interaction system should use a brush concept.

Each interaction event provides:

Position:
- world position

Radius:
- deformation size

Strength:
- deformation amount

Type:

Examples:

Footstep:
small radius
high compression

Vehicle:
large radius
continuous trail

Explosion:
large radius
temporary deformation


---

# Performance Requirements

Important:

Do not create one object per footprint.

Do not update mesh vertices on CPU every frame.

Prefer GPU operations.

Avoid:

- Instantiate many particles
- Create many RenderTextures
- Frequent memory allocation


Prefer:

- Single or limited RenderTexture buffers
- GPU drawing
- MaterialPropertyBlock
- CommandBuffer when necessary


---

# Possible System Architecture

Recommended modules:


## SnowInteractionManager.cs

Responsibilities:

- Receive interaction positions
- Send brush information
- Manage RenderTexture update


## SnowBrush.shader

Responsibilities:

- Draw interaction marks into RenderTexture


## SnowSurface.shader

Responsibilities:

- Sample deformation texture
- Modify vertex position
- Render snow material


---

# Development Order

## Phase 1

Basic snow material:

- Snow color
- Normal
- Lighting


## Phase 2

RenderTexture interaction:

- Orthographic camera
- Draw player position into texture


## Phase 3

Vertex deformation:

- Sample RenderTexture
- Offset snow vertices


## Phase 4

Improve realism:

Add:

- footprint edge
- snow compression
- smooth fading
- multiple interaction types


## Phase 5

Optimization:

Analyze:

- GPU cost
- Texture resolution
- Update frequency
- Number of interaction sources


---

# Portfolio Requirements

The final project should demonstrate:

## Technical Explanation

Document:

- Why RenderTexture is used
- Why not particles
- GPU vs CPU comparison
- Performance analysis


## Showcase

Provide:

- Before/after comparison
- Wireframe view
- Shader breakdown
- Debug visualization

---

# Coding Style

C#:

- Clear class responsibility
- Avoid unnecessary Update loops
- Use meaningful names


Shader:

- Keep calculations readable
- Separate deformation and shading logic


Do not sacrifice clarity for premature optimization.

---

# Decision Principle

When choosing an implementation:

Priority:

1. Portfolio technical value
2. GPU performance
3. Scalability
4. Visual quality


The project should demonstrate Technical Artist skills rather than only achieving a visual effect.