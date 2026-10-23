# Architecture lab iteration 5 — cutaway, doorway previews and exterior grid

23 October 2026, based on `c70caaa`, on `experiment/architecture-lab`.
Active scene: `scenes/grid_geometry_audit_25d.tscn`. Godot compatibility: **4.5.2**.

## Changes

### Connected-panel cutaways

Camera-to-player obstruction still selects individual wall segments. A static
visual topology now connects segments whose mesh bounds physically meet (1mm
comparison tolerance). A directly obstructing panel requests its immediate panel
neighbours too. Small join boxes connect panels without consuming a panel of
width; the joins at the window's edges fade with the panels. This gives a
three-panel window on a straight wall, wraps connected corners, and never jumps
an opening. Multiple direct hits can produce overlapping, wider windows.

Expansion is one hop from the original hits, not a flood through the wall graph.
Hidden meshes cannot be revealed by expansion. The existing 20% wall target and
0.22-second smooth transitions remain; closed door leaves retain their independent
28% obstruction target. The player/camera movement and physical wall dimensions
are unchanged. The topology is visual metadata, not a navigation or physics graph.

### Open-door previews without discovery

Discovery still changes only when the player enters a logical floor region.
Rendering now also accepts a temporary, doorway-visible preview. Opening or
closing a nearby door refreshes visibility immediately, before another movement
frame. Movement refreshes the preview without modifying discovery.

For each undiscovered floor tile, wall segment or closed door, the render policy:

1. Considers open doors directly incident to the player's current room.
2. Requires the target's owner to be that door's adjoining room.
3. Tests a ray from player eye height through the actual door opening plane and
   its width/height bounds, rather than using room distance or wall transparency.
4. Rejects rays blocked by any solid wall or closed door, including hidden or
   visually faded ones. A target wall may exclude itself from the blocking test.

The policy samples each visual's horizontal centre at player eye height. This is
player sight, not camera sight: camera rotation can change cutaways, but never
creates discoveries or changes which portals the player can see through.
`visible_rooms` records rooms with currently rendered floors separately from
`discovered_rooms`. Previously discovered rooms retain their existing persistent
rendering behavior; closing a door only removes previews that are not discovered.

Preview does **not** recurse through a chain of open doors. Opening a second door
elsewhere cannot expose a second-hop room. From inside the corridor, either of
its directly adjoining rooms can be previewed through its own open door.

### Exterior ground grid

`exterior_grid_25d.gd` creates a static, visual-only ground mesh outside occupied
floor cells, with a muted world-space shader grid at the dungeon's 2m spacing.
Grid lines use derivative antialiasing and stay anchored through movement/rotation.
The plane is at `floor_origin.y - 0.2`, below the floor top at `+0.09`, with no
collision nodes or shadows.

The first browser check caught hidden-room silhouettes where excluded cells left
holes in the ground. Matching background grid patches now cover concealed cells
at the same lower height; a patch is disabled whenever its actual floor is rendered,
including portal previews. Thus the grid never overlays a rendered dungeon floor,
and the missing grid pattern cannot advertise an undiscovered room's footprint.

## Validation

| Check | Result |
| --- | --- |
| New cutaway/portal/grid suite, 4.5.2 and 4.6.3 | 38,067 checks, 0 failures each |
| Camera/occlusion sweep, 4.5.2 and 4.6.3 | 238,884 checks, 0 failures each |
| Production architecture movement/geometry, 4.5.2 and 4.6.3 | 3,598 checks, 0 failures each |
| Discovery regression, 4.5.2 | 293 checks, 0 failures |
| GridMap floor collision, 4.5.2 | 17 checks, 0 failures |
| Original 2D targeting / dual weapon, 4.5.2 | 35 checks / 0 failures; both pass |
| Exporter success/failure/interruption tests | 3 tests passed |
| Script validation, both versions | All 31 GDScript files passed |
| Real dedicated release Web export, 4.5.2 | Passed import, artifact checks and default pack startup |
| Chromium via plain HTTP port 8000 | Grid, widening, opening/closing preview, 360° rotation and overhead smoke checks passed; no console errors/warnings |

The new fixtures require exactly three panels for one straight-wall obstruction,
correct join inclusion, corner wrapping, no jump across a door gap, target-following
windows, hidden-neighbour exclusion and smooth opacity through the existing suite.
Portal tests cover opening before entry, closing, both doorways, a concealed
around-jamb target, an additional hidden blocker beyond the aperture, faded closed
doors, non-recursive visibility, camera rotation and permanent discovery after entry.
Grid tests check all exterior cells and vertex heights, background concealment,
no collision nodes, tile spacing and stable world transform.

The large assertion totals include repeated per-wall, per-angle and per-vertex
checks; they are not counts of independent scenarios. The movement suite retains
all 16 rotating edge/diagonal doorway routes, closed-door and faded-wall blocking,
and support checks. No version-specific behavior was observed in the new tests.
The existing 2D suites still emit their previously documented ObjectDB shutdown
leak warnings. No 2D production code changed.

The exporter and source `project.godot` / `export_presets.cfg` remain unchanged.
The Web build still starts the lab from an isolated project copy, leaving the
original main scene and ordinary 2D Web output alone. Browser smoke validation
used software WebGL 2, not a hardware-GPU performance benchmark.

## Repeatable checks

```sh
godot --headless --path . --script res://tests/cutaway_portal_grid_test.gd
godot --headless --path . --script res://tests/wall_occlusion_test.gd
godot --headless --path . --script res://tests/room_visibility_test.gd
godot --headless --path . --script res://tests/architecture_lab_test.gd
godot --headless --path . --script res://tests/grid_floor_collision_test.gd
python3 -m unittest discover -s tests -p test_lab_export.py -v
python3 tools/export_architecture_lab.py --godot /path/to/godot-4.5.2
```

## Remaining limits

- Doorway preview is whole-tile/whole-segment visibility based on centre sight
  samples, not per-pixel portal clipping. Reveal edges can advance by a tile or
  panel as the player moves; arbitrary concave geometry needs richer sampling or
  clipping. Only directly adjoining rooms are previewed intentionally.
- Window topology is built once from this static box layout. Moving walls or
  procedurally rebuilding geometry must rebuild it. A hit on a junction or several
  panels can give more than three faded panels; door gaps can give fewer.
- Grid coverage is finite (32 tiles beyond the layout bounds), sufficient for
  the lab's existing camera. Larger/free cameras need a different coverage policy.
- Automated angle sweeps and browser smoke tests do not exhaust all continuous
  trajectories, alpha sorting cases or GPU/browser combinations. Combat and enemy
  line-of-sight/navigation code remain untouched; this lab has no enemies.
