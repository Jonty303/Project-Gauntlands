# Architecture lab iteration 1 — 22 October 2026

## Scope and findings

Validated `scenes/grid_geometry_audit_25d.tscn`, the current GridMap visibility lab targeted by floor fix `c3bba40`. The older `architecture_lab_25d.tscn` is not the scene changed by that fix.

Godot 4.5.2 measured the GridMap origin as (1, 1, 1). Floors, walls, door centers, and the hero consistently use that origin; floor tops are at Y = 1.09. No coordinate mismatch was reproduced in this scene at its existing identity root transform.

The floor fix is effective: alternating Shape3D/Transform3D MeshLibrary entries register collision for all 69 cells, including hidden rooms. No additional floor or player-physics repair was required.

The geometry test reproduced 108 positive-volume overlaps among wall boxes. Full-cell boundary spans extended into the corner boxes already placed at every endpoint. Doorway returns also extended into their exterior corner boxes. Boundary spans now stop at corner faces (CELL minus WALL_THICKNESS), and each return stops half a wall thickness before its exterior junction. The existing corner fills complete the geometry. Layout, wall thickness, doorway width, collision behavior, and transparency logic are preserved.

## Repeatable checks

Using Godot 4.5.2:

```powershell
godot --headless --path . --script res://tests/grid_floor_collision_test.gd
godot --headless --path . --script res://tests/architecture_lab_test.gd
godot --headless --path . --check-only --script res://scripts/grid_geometry_audit_25d.gd
godot --headless --path . --check-only --script res://tests/architecture_lab_test.gd
godot --headless --path . --editor --quit
```

If the default user log directory is unavailable, pass `--log-file` with an absolute writable path. The initial default-log launch crashed; rerunning with a workspace log successfully executed the tests.

- Existing floor test before and after repair: **17 checks, 0 failures**. Rays hit all 69 cells; real input moves the hero across floor seams and both doorways while checking support each frame.
- New architecture test before repair: **2,334 checks, 1 failure**, reporting 108 overlapping wall pairs.
- New architecture test after repair: **2,334 checks, 0 failures**. Tests yaw 0, 45, 135, 225, and 315 degrees using camera-relative input and the lab's production physics. Checks closed-door blocking, opening and closing collider states, passage, support, return trips, room discovery, hidden undiscovered floors, wall blocking with cutaway on/off, enabled wall colliders, doorway grid alignment, one return at each jamb, and absence of overlapping wall solids.
- Direct parser validation of the changed lab and new test: passed.
- Project-wide editor validation: attempted, but reports mixed-indentation parse errors in existing `scripts/player.gd:101` and `scripts/experiment_25d.gd:454`. These unrelated files remain unchanged. Editor-generated formatting changes were reverted.

## Remaining limitations

Runtime checks were headless. Rendered appearance, visual seams, and subjective transparency quality still need interactive inspection. No new floor, door, or movement failure was reproduced on the tested routes; the checks do not exhaust every possible trajectory or transformed scene-root configuration. Project-wide parser errors above remain outside this iteration's scope.

The original playable combat prototype was not modified. Do not migrate the lab until the remaining visual and regression checks in NEXT_ITERATION.md are satisfied.
