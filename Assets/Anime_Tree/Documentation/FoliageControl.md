# FoliageControl

`FoliageControl` uses a `MaterialPropertyBlock` to send the world position of one
foliage object to its `MeshRenderer` without creating a material instance.

## Setup

1. Add `FoliageControl` to every merged foliage mesh object.
2. Keep using the shared foliage material. Do not duplicate the material for each
   foliage object.
3. Make sure the foliage mesh uses its local -Z axis as the plane normal that
   should face the camera, with local +Y as its vertical axis.
4. Leave **Face Camera** enabled to use camera-facing foliage, or disable it for
   objects that must keep their authored rotation.
5. In Amplify Shader Editor, create a `Vector3` property with:
   - Display Name: `WorldPos`
   - Reference: `_WorldPos`
6. Connect `_WorldPos` to the `PositionWS` input of the foliage movement Custom
   Expression.

Use `_WorldPos` instead of ASE's regular `World Position` node for the object seed.
The regular node changes for every vertex, while `_WorldPos` is one position shared
by all vertices rendered by that `MeshRenderer`.

## Runtime behaviour

- `OnEnable` writes the initial world position immediately.
- `Update` writes the current `transform.position` every frame.
- Existing values in the renderer's property block are preserved.
- The shared material is not modified and `renderer.material` is never accessed.
- During Play Mode, before each URP camera renders, the component temporarily
  aligns the foliage's local -Z axis with the negative camera forward direction and
  aligns its local +Y axis with the camera up direction.
- After that camera finishes rendering, the original world rotation is restored.
  This allows multiple cameras to render the same foliage from different views
  without permanently changing the Transform.

## Limitations

- The component controls only the `MeshRenderer` on the same GameObject.
- It runs only during Play Mode; edit-time preview is not enabled.
- Camera-facing rotation assumes the mesh plane normal is its local -Z axis.
- The shader property reference must remain `_WorldPos`.
