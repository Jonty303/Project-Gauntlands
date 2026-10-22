# Architecture lab iteration 2 — 22 October 2026

## Implementation

The working lab remains `scenes/grid_geometry_audit_25d.tscn`. Run it directly:

```sh
godot --path . res://scenes/grid_geometry_audit_25d.tscn
```

WASD moves, Q/E rotates, F opens/closes a nearby door, C toggles cutaway,
and T toggles the overhead view. The main scene and combat prototype are unchanged.

`room_visibility_25d.gd` owns logical session state independently of rendering and
physics. The layout supplies cell ownership and an explicit reciprocal graph:
starting chamber 0 ↔ corridor 1 ↔ far chamber 2. Each record has an ID, discovery
flag and neighbour list. Only room 0 starts discovered. Discovery persists for the
lifetime of the lab instance; a new instance starts a new session.

The hero's position is converted into the floor GridMap's local coordinate space.
Logical cell ownership determines its room; camera position, rendered visibility,
wall collision and door state never determine ownership. A 1mm tolerance around
the previous cell holds ownership during numerical jitter at a threshold. Moving
beyond it changes ownership in either direction. Off-floor samples retain the
last valid room without discovering another region. The tolerance handles local
boundaries only; it is never used to infer graph adjacency.

Only the current room and its **discovered, directly connected** neighbours are
eligible to fade. Layout wall normals are paired with their owning rooms,
including shared corners and doorway returns. Previously the independent owner
and normal lists could borrow an undiscovered or ineligible room's normal.
Doors now also carry explicit owner/normal pairs instead of inferring direction
from world X and current-room special cases. For shared geometry, any eligible
owner's camera-facing side may request fading. Such a boundary may be visible
from its discovered owner while the room beyond remains hidden.

Discovery gates floor, wall and closed-door meshes. Foreground classification
uses the horizontal direction to the camera and the existing dot-product cutoff
of 0.1. Eligible foreground walls target 0.04 alpha; closed doors target 0.28;
other surfaces target 1.0. Hidden open doors do not request fading. A smoothstep
transition completes in 0.22 seconds and restarts from the displayed alpha when
interrupted. This replaces exponential interpolation that took longer to settle.

The rendering adapter only changes mesh visibility and material alpha. Floor
GridMap cells, wall bodies/shapes, dimensions, collision layers and masks are
unchanged. Only the existing door interaction toggles its collider. Future
layouts can supply different IDs, cells, graph connections and owned normals
without adding distance-based room logic.

## Automated validation

Target: **Godot 4.5.2** (`6ce3de25a`). Also tested the cloud-installed **4.6.3**
(`7d41c59c4`). `project.godot` compatibility settings remain unchanged.

Run on either version:

```sh
godot --headless --path . --script res://tests/room_visibility_test.gd
godot --headless --path . --script res://tests/architecture_lab_test.gd
godot --headless --path . --script res://tests/grid_floor_collision_test.gd
godot --headless --path . --check-only --script res://scripts/room_visibility_25d.gd
godot --headless --path . --check-only --script res://scripts/grid_geometry_audit_25d.gd
godot --headless --path . --check-only --script res://tests/room_visibility_test.gd
godot --headless --path . --editor --quit
```

For restricted cloud runs, use writable `XDG_DATA_HOME`, `XDG_CONFIG_HOME`,
`XDG_CACHE_HOME` and an absolute `--log-file` outside the repository.

| Suite | Godot 4.5.2 | Godot 4.6.3 |
| --- | --- | --- |
| Room visibility | 5,448 checks, 0 failures | 5,448 checks, 0 failures |
| Architecture geometry/movement | 2,334 checks, 0 failures | 2,334 checks, 0 failures |
| Grid floor collision | 17 checks, 0 failures | 17 checks, 0 failures |

The new suite checks initial hidden meshes and graph records, entry/exit for all
three regions, permanent discovery, one-hop eligibility, non-adjacent exclusion,
shared-face ownership, eight camera angles in every room, closed/open doors,
exact transition timing, interrupted fades, and collision snapshots before,
during and after fades. A synthetic layout proves that a distant graph neighbour
is eligible while a physically close non-neighbour is not. Both doorway
thresholds are sampled in both directions with sub-millimetre jitter.

The existing architecture suite exercises production movement through both doors
in both directions at five camera angles, support every physics frame, blocking
by closed doors and faded walls, open-door passage, doorway alignment and
non-overlapping geometry. The floor suite raycasts all 69 cells, including hidden
regions. Neither engine version showed a lab regression or version-specific
behavior in these checks.

Headless editor scans completed on both versions with sandbox socket-listen
errors; the first 4.6.3 run also reported unwritable editor settings paths before
writable XDG directories were supplied. Direct GDScript checks are reported
separately: all 26 scripts passed on both versions. The earlier iteration 1
mixed-indentation errors did not reproduce in this checkout. An editor exit code
alone is not treated as proof of a clean run.

## Remaining verification

These are headless tests: interactive visual review of transparency sorting,
subjective foreground readability and rendered seams remains outstanding.
Movement tests cover the lab's existing identity-transform layout and center-line
doorway routes, not every possible trajectory or transformed/procedural layout.
Do not migrate this experiment into the playable combat prototype yet.
