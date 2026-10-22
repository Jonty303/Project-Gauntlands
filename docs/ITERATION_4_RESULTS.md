# Architecture lab iteration 4 — camera-aware wall occlusion

22 October 2026, based on `245355a`, on `experiment/architecture-lab`.
The active scene is still `scenes/grid_geometry_audit_25d.tscn`.

## Behavior and architecture

Walls that intersect the view of the player fade to **20% opacity** over **0.22s**.
Non-obstructing walls, including far-side walls, remain opaque. Closed door leaves
use the existing **28% opacity** only when they obstruct; open leaves remain hidden.
Each wall segment, corner join and doorway return is evaluated independently.
There is no transparent room-wide shell and no geometry in an open doorway.

Three responsibilities are separated:

- `room_visibility_25d.gd` owns logical room/corridor IDs, reciprocal adjacency,
  stable cell ownership and permanent session discovery. Camera changes never
  change discovery. The existing graph query remains available to discovery
  consumers, but no longer requests whole sets of foreground wall fades.
- `room_render_visibility_25d.gd` decides whether a discovered room's visual can
  render. Shared boundaries render when either owner is discovered. Undiscovered
  floors, walls and closed doors remain hidden, independently of alpha.
- `wall_occlusion_25d.gd` performs read-only camera-to-target segment queries
  against the bounds of each rendered mesh. The lab adapter changes alpha only.

The camera is orthographic: sight rays must be parallel through the target,
rather than converging at the camera position. Nine samples cover the player's
feet, torso and head across the capsule's width. Each finite ray stops at its
target, so a wall behind that target cannot request fading. Intersection tests
run in each wall mesh's local space and therefore do not depend on wall normals
or orientation. This includes internal partitions, returns and corner pieces.
No collision ray, collision layer change or physics-shape mutation is involved.

This intentionally supersedes iterations 2/3's normal-based 4% wall fading and
one-hop fade eligibility. Discovery still uses the logical floor regions and
graph. Occlusion now considers actual obstruction by any rendered wall; graph
distance alone never makes a wall transparent. The lab's only relevant target is
the player. The query accepts a target list for future *visible* relevant objects,
but this iteration adds no objects or gameplay.

The vertical overhead camera keeps its yaw/movement mapping, but no longer fades
walls solely because of yaw: an unobstructed top-down player view leaves walls
solid. Switching views and interrupting a fade preserve the displayed alpha and
smoothly reach the new target in 0.22s.

Floor occupancy, wall dimensions, bodies, shapes, doorway openings, movement,
input, camera placement, collision masks and door interaction are unchanged.
There are no enemies or navigation agents in this lab; the visibility code cannot
alter line-of-sight or navigation collision. The original 2D scripts/scenes,
source project settings and exporter are unchanged.

## Regression coverage

`wall_occlusion_test.gd` replaces obsolete normal/whole-room alpha expectations
with an independent slab-intersection oracle. It sweeps 0–360° in 15° increments
at nine positions (centre, four sides, four corners) in each of the three regions.
It checks every wall's alpha/material, hidden visuals, permanent discovery and
physics snapshots. Additional checks cover rotated internal segments, far-side
and off-sightline segments, clear door openings, leaf/return separation, overhead
yaw, smooth midpoint/reversal, and cutaway disabled.

`room_visibility_test.gd` retains graph, discovery, boundary jitter and door-state
checks. Its old normal-based occlusion assertions moved to the new obstruction
suite. `architecture_lab_test.gd` still runs production movement and all 16
rotating edge/diagonal doorway routes. The wall-push test now explicitly places
the camera on the obstructing side and verifies the new 20% fade.

## Validation

Target engine: **Godot 4.5.2 stable** (`6ce3de25a`). Cloud engine: **4.6.3 stable**
(`7d41c59c4`). Project compatibility remains unchanged.

| Check | Result |
| --- | --- |
| Wall occlusion, both versions | 238,884 assertions, 0 failures each |
| Architecture movement/geometry, both versions | 3,598 checks, 0 failures each |
| Room discovery, 4.5.2 | 293 checks, 0 failures |
| Floor collision, 4.5.2 | 17 checks, 0 failures |
| Original 2D targeting, 4.5.2 | 35 checks, 0 failures |
| Original 2D dual weapon, 4.5.2 | 0 failures |
| Python export safety | 3 tests passed |
| 4.5.2 release Web export | HTML/JS/WASM/PCK generated; exported default scene boots the lab |
| Chromium / plain HTTP port 8000 | Lab rendered; full rotation, overhead and movement; no console errors or warnings |
| GDScript parsing, both versions | All 29 scripts passed |
| 4.5.2 editor import outside command sandbox | Exit 0, no errors; regenerated missing UID warnings |

The two 2D test suites retain their previously documented ObjectDB shutdown leak
warnings. No version-specific occlusion or movement difference was observed.
The repeated assertions above cover a bounded layout/camera matrix, not that
many independent scenarios. All 11 geometry, hero construction, movement and
camera-placement functions are byte-identical to the branch baseline. No 2D
production files or project/export configuration changed.

The real export used the unchanged dedicated helper and official 4.5.2 Web
templates. Its pack boot verified 69 floor cells, 44 exterior edges and 44 joins.
The near-wall screenshot showed the obstructing segment translucent, its adjacent
segments and far wall solid, and the capsule still blocked at the wall.
Chromium used WebGL 2 via software rendering on a plain local HTTP server, with
the single-thread build. The browser check is a visual smoke test, not exhaustive
interactive acceptance of every corner and doorway or a hardware-GPU benchmark.

Commands (use the desired engine binary for `godot`):

```sh
godot --headless --path . --script res://tests/wall_occlusion_test.gd
godot --headless --path . --script res://tests/room_visibility_test.gd
godot --headless --path . --script res://tests/architecture_lab_test.gd
godot --headless --path . --script res://tests/grid_floor_collision_test.gd
godot --headless --path . --script res://tests/combat_targeting_test.gd
godot --headless --path . --script res://tests/dual_weapon_test.gd
python3 -m unittest discover -s tests -p test_lab_export.py -v
python3 tools/export_architecture_lab.py --godot /path/to/godot-4.5.2
```

## Limits

The query uses exact boxes for the current box-mesh walls; arbitrary concave mesh
bounds would be conservative and need a more precise visual intersection model.
Nine silhouette samples are practical for this capsule and wall layout, not an
exhaustive pixel-coverage algorithm. The finite camera sweep and existing routes
do not exhaust continuous positions or arbitrary procedural/transformed layouts.
Combat migration remains out of scope.
