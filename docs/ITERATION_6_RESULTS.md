# Architecture lab iteration 6 — doorway and geometry regression

23 October 2026, on `experiment/architecture-lab`. The compatibility target
remains Godot **4.5.2**. The active scene remains
`scenes/grid_geometry_audit_25d.tscn`.

## Root causes reproduced before editing

- Opening a door did not delete or regenerate the floor. Both closed and open
  states retained the same 69 GridMap collision cells and 69 floor mesh nodes.
  The apparent missing tiles were a rendering decision: preview rays to each
  floor tile centre exposed only 5 of 9 corridor tiles from one position and 1
  of 9 from an offset position. The exterior grid showed through the other
  hidden floor meshes.
- The same per-centre visibility test independently gated wall spans and corner
  joins. It could reveal a return while hiding the adjacent span, leaving
  fragments, even though the physical wall was continuous.
- Door openings had a 2.36 m leaf in a 2.8 m wall and 1.75 m between returns,
  but no jamb or lintel surfaces. The opening therefore lacked a visible frame.
  Opaque wall records also used alpha-blend rendering at 100% opacity, allowing
  transparent-surface ordering to accentuate seams.

## Changes

An open door now qualifies **one directly adjoining region** for temporary
rendering when the player's eye has a clear sightline through its actual
aperture. All tiles and wall pieces owned by that region render together, so
the floor and wall structure cannot develop per-tile or per-piece holes.
Closed doors and solid walls still block the qualifying ray, and an open door
cannot reveal a second-hop region. Discovery remains a separate, permanent
logical-floor state; room rendering never mutates it. Camera cutaway remains a
separate three-panel obstruction calculation with its existing 20% target and
0.22 s transition.

Each doorway now has two 0.30 m visual jambs and a lintel extending from the
top of the leaf to the top of the wall. They join the visual wall topology for
cutaways, but have no collision shapes. The leaf, partition returns, 1.75 m
physical opening, all floor meshes, and GridMap cells are unchanged. Wall
materials switch to the opaque depth pass at full opacity and to alpha blending
only while fading.

The exterior grid, original 2D game and dedicated Web export configuration are
unchanged.

## Validation

| Check | Result |
| --- | --- |
| Doorway geometry regression, Godot 4.5.2 and 4.6.3 | 315 checks, 0 failures each |
| Godot 4.5.2 editor import and GDScript validation | Passed |
| Production architecture movement/geometry | 3,598 checks, 0 failures |
| Camera/occlusion sweep | 251,208 checks, 0 failures |
| Cutaway, portal and grid | 38,067 checks, 0 failures |
| Discovery | 299 checks, 0 failures |
| GridMap floor collision | 17 checks, 0 failures |
| Original 2D targeting and dual-weapon tests | 35 checks / 0 failures; both passed |
| Exporter safety tests | 3 tests passed |
| Dedicated 4.5.2 release Web export | Passed import, output and pack startup checks |
| Chromium browser smoke on that Web export | Opening/closing the first door, 360° rotation, cutaway toggle, movement and overhead view passed; no page or console errors |

The new regression checks mesh identity, transform and collision cell identity
before and after opening, crossing and closing both doors; floor AABB continuity
across all three doorway rows; frame dimensions and lack of collision; complete
direct-region preview without discovery; and fully opaque wall rendering. The
architecture movement suite still checks diagonal threshold traversal at
multiple camera angles and support on every route. The 2D suites retain their
previously documented ObjectDB shutdown warnings; no 2D code changed.
No version-specific behavior was observed in the 4.6.3 doorway regression;
the project target and exporter remain on 4.5.2.

## Remaining limits

- Rendering is at region granularity after a clear aperture sightline; it is
  not per-pixel portal clipping. Physical opaque walls hide off-axis parts of
  the preview. A procedural layout with complex concave rooms may need finer
  portal visibility and a topology rebuild when geometry changes.
- The visual frames intentionally do not alter collision or the current leaf
  mechanism. This preserves movement but leaves their collision silhouette
  defined by the existing partition returns.
- Browser smoke uses headless software WebGL and does not measure hardware GPU
  performance or cover every continuous camera/position combination.

## Repeatable checks

```sh
godot --headless --path . --script res://tests/doorway_geometry_regression_test.gd
godot --headless --path . --script res://tests/architecture_lab_test.gd
godot --headless --path . --script res://tests/cutaway_portal_grid_test.gd
godot --headless --path . --script res://tests/wall_occlusion_test.gd
godot --headless --path . --script res://tests/room_visibility_test.gd
godot --headless --path . --script res://tests/grid_floor_collision_test.gd
python3 -m unittest discover -s tests -p test_lab_export.py -v
python3 tools/export_architecture_lab.py --godot /path/to/godot-4.5.2
```
