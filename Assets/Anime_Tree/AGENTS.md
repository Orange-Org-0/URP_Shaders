# AGENTS.md

## Project Overview

This Unity project aims to recreate a stylized anime/cartoon tree effect based on the following reference video:

https://www.youtube.com/watch?v=52sTppv7Y-E&t=308s

The final tree effect should be reusable in future Unity game projects rather than being limited to a single demonstration scene.

---

## Project Environment

* Unity version: `2022.3.62f2`
* Render pipeline: Universal Render Pipeline (URP)
* Primary programming language: C#
* Shader environment: Use Unity URP shaders, ASE, or custom HLSL as appropriate

Do not change the Unity version or replace the current render pipeline unless explicitly requested by the user.

---

## Current Goal

Study the reference materials provided by the user and reproduce the important visual characteristics of the cartoon tree effect in Unity.

Important characteristics may include:

* Stylized tree canopies and foliage
* Cartoon lighting and separated color bands
* Foliage color variation
* Wind animation for the tree and foliage
* Appropriate lighting and shadow behaviour
* Reusable materials and components

The exact implementation may be refined as the user provides additional reference materials and more specific requirements.

---

## Reference Materials

Use the YouTube video and any other materials provided by the user as visual references.

Additional reference materials provided by the user may be placed in the following folder:

```text
E:\UnityHub\URP_Shader\Assets\Anime_Tree\References
```

Reference materials may include:

* Screenshots
* Notes
* Textures
* Models
* Blender files
* Example projects
* Shader references
* Video subtitles or transcripts

Do not invent details that cannot be confirmed from the available reference materials.

When a conclusion is based on inference, clearly identify it as an inference rather than a confirmed fact.

---

## Repository Inspection

Before modifying the project, inspect the existing project structure and relevant configuration files.

Check the following files:

```text
ProjectSettings/ProjectVersion.txt
Packages/manifest.json
Packages/packages-lock.json
```

Also inspect:

* Existing shaders
* Existing materials
* Existing scripts
* Existing namespaces
* Existing folder conventions
* Existing assembly definition files
* Existing scenes and prefabs

If the project already has clear and reasonable conventions, follow those conventions.

---

## Unity Project Rules

* Keep runtime code and editor code separate.
* Place editor-only scripts inside an `Editor` folder or an editor-only assembly.
* Do not modify generated folders such as `Library`, `Temp`, `Logs`, or `obj`.
* Do not add third-party Unity packages without explicit permission.
* Do not modify files unrelated to the current task.
* Avoid introducing unnecessary dependencies.
* Avoid unnecessary per-frame CPU operations.
* Do not create a separate GameObject or MonoBehaviour for every individual leaf.
* Prefer reusable components, shared materials, and configurable assets.
* Do not duplicate a material for every tree instance without a clear reason.
* Artist-facing Inspector parameters should be clearly named and logically organised.
* Preserve `.meta` files and references between Unity assets.
* Ensure that scripts compile without warnings or errors.

---

## File Organisation

If the existing project does not already have an established folder convention, files related to this effect may be organised as follows:

```text
Assets/AnimeTree/
├── Art/
├── Materials/
├── Prefabs/
├── Scenes/
├── Scripts/
│   ├── Runtime/
│   └── Editor/
├── Shaders/
├── Textures/
└── Documentation/
```

Experimental files should be kept separate from production-ready files:

```text
E:\UnityHub\URP_Shader\Assets\Anime_Tree\Experiments\
```

Do not treat experimental code or assets as production-ready content without clearly stating their experimental status.

---

## Implementation Guidelines

Implement the effect incrementally.

Prefer small, testable implementations instead of creating a large system framework at the beginning.

When implementing a feature, follow this process:

1. Inspect the existing project.
2. Identify the files that need to be modified.
3. Make the smallest reasonable changes required to satisfy the task.
4. Confirm that the project still compiles.
5. Test the feature in an appropriate scene.
6. Document important setup steps and known limitations.

Do not over-engineer the first implementation.

Where reasonable, leave room for future expansion, but do not create abstraction layers without a demonstrated requirement.

---

## Shader Guidelines

Shaders must be compatible with the URP version used by the Unity `2022.3.62f2` project.

When editing or creating shaders:

* Maintain compatibility with URP lighting and shadow systems where required.
* Clearly explain the behaviour of transparent, Alpha Clip, and opaque rendering modes.
* Avoid unnecessary texture samples and Shader Variants.
* Expose only useful artist-facing controls.
* Use consistent property naming conventions.
* Consider GPU Instancing compatibility where appropriate.
* Check the shader in both the Scene view and Game view.
* Test the shader under different lighting conditions.
* Do not rely on features that are only supported by other render pipelines.

When using custom HLSL, organise shared functions appropriately and give them clear names.

---

## Reusability Requirements

The final result should not unnecessarily depend on one specific scene.

Reusable elements should be stored separately where appropriate, including:

* Shaders
* Materials
* Textures
* Runtime scripts
* Editor tools
* Prefabs
* Configuration assets

Unless absolutely necessary, avoid hard-coding:

* Scene references
* GameObject names
* Camera names
* Asset paths

Important visual parameters should be exposed through materials, components, or configuration assets rather than being hard-coded in scripts.

---

## Documentation

Important development records should be stored in:

```text
Assets/AnimeTree/Documentation/
```

The documentation should explain:

* What has been implemented
* Required project setup
* How to use the effect
* Important material parameters
* Required components
* Known limitations
* Files that were created or modified

Keep the documentation concise and update it whenever the implementation changes.

---

## Communication Requirements

When reporting work:

* Clearly state which files were inspected.
* Clearly state which files were created or modified.
* Explain important technical decisions.
* Distinguish confirmed information from temporary assumptions.
* State the currently known limitations.
* Do not exaggerate the quality or completeness of the implementation.
* Do not describe experimental features as production-ready.
* Honestly report compilation errors or missing dependencies.
* Request user review or approval before making large-scale architectural changes unrelated to the current task.

---

## Current Known Information

* Engine: Unity

* Unity version: `2022.3.62f2`

* Render pipeline: URP

* Visual reference:

  https://www.youtube.com/watch?v=52sTppv7Y-E&t=308s

* The goal is to create a reusable stylized cartoon tree effect.

* More detailed requirements may be added later.
