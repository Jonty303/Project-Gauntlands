# Gauntlands architecture reference — experimental visibility lab

This is a branch-specific navigation guide for `experiment/architecture-lab`, not a proposal to migrate the lab into the playable game.

## Entry points and separation

- Godot engine: **4.5.2 stable**.
- `project.godot` retains `run/main_scene="res://scenes/main.tscn"`: the original **2D combat prototype**.
- Experimental 3D visibility scene: `res://scenes/grid_geometry_audit_25d.tscn`.
- Export the lab with `python3 tools/export_architecture_lab.py`, which stages a copy and does not alter the original startup scene.
- Serve `build/architecture-lab` on port 8000; `build/web` is the separate ordinary 2D export.

## System boundaries and invariants

- Floor, wall, door and character positions must use a consistent coordinate system.
- Collision and navigation must not depend on visual cutaway alpha.
- Room discovery is permanent after entry; temporary previews through open doors do not permanently discover rooms.
- Closed doors and walls block preview rays even when visually faded.
- An unrelated open door must not expose second-hop rooms.
- Wall cutaway grouping follows physically connected panels without crossing doorway gaps.
- Current lab behaviour documented in `docs/NEXT_ITERATION.md`: cutaway alpha 20%, fade 0.22 seconds; exterior grid patches mask undiscovered footprints and withdraw when dungeon floors render.
- Do not change combat or original 2D scenes as a side effect of lab visual work.

## Relevant existing documentation

- `docs/WEB_ARCHITECTURE_LAB.md`: Codespaces setup, controls, export and validation commands.
- `docs/NEXT_ITERATION.md`: current implementation state and remaining acceptance work.
- `docs/ITERATION_3_RESULTS.md` and subsequent iteration results: recorded tests and limitations.
- `AGENTS.md`: branch-specific development rules.

## Focused validation

From the repository root, with Godot 4.5.2 available as `godot`:

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/cutaway_portal_grid_test.gd
godot --headless --path . --script res://tests/wall_occlusion_test.gd
godot --headless --path . --script res://tests/room_visibility_test.gd
godot --headless --path . --script res://tests/architecture_lab_test.gd
godot --headless --path . --script res://tests/grid_floor_collision_test.gd
```

For cross-system regressions, use the 2D combat and dual-weapon tests listed in `docs/WEB_ARCHITECTURE_LAB.md`. For exporter changes, run `python3 -m unittest discover -s tests -p test_lab_export.py -v`. Browser smoke tests remain necessary for visual results; passing headless tests alone does not prove rendering correctness.

## Efficient task handoff

Before changing code: state the desired observable behaviour, affected scene/system, exclusions and acceptance tests. Inspect the smallest relevant code area. After changes: report files touched, test outcomes, anything unverified and whether a Web build was produced. Avoid repeated full-project analysis or exports unless justified.
