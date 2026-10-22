# Architecture lab in Codespaces

Use **Godot 4.5.2 stable**, its matching standard export templates, and Python 3.
Install templates through Godot's **Editor > Manage Export Templates**, or extract
the official `Godot_v4.5.2-stable_export_templates.tpz` so its files are directly
inside `~/.local/share/godot/export_templates/4.5.2.stable/` on Linux. Downloads:
<https://github.com/godotengine/godot-builds/releases/tag/4.5.2-stable>.

From the repository root in Codespaces:

```sh
git switch experiment/architecture-lab
git pull --ff-only
python3 tools/export_architecture_lab.py
python3 -m http.server 8000 --bind 0.0.0.0 --directory build/architecture-lab
```

If the engine is not named `godot` on PATH, use:

```sh
python3 tools/export_architecture_lab.py --godot /absolute/path/to/godot
```

`GODOT=/absolute/path/to/godot python3 tools/export_architecture_lab.py` also works.
The script checks the engine version and fails if it is not 4.5.2 stable.

In Codespaces' **Ports** tab, forward port **8000**, then choose **Open in Browser**.
You should see **VISIBILITY LAB** and a blue capsule in a 3D room. Click the game
to focus keyboard input. WASD moves, Q/E rotates, F toggles a nearby door,
C toggles wall cutaway, and T switches overhead view. Q/E also rotates overhead.
The local equivalent is <http://localhost:8000>.

Stop the server with Ctrl+C before rebuilding, rerun the export command, then
restart the server. Hard-refresh the browser if it still displays an older build.
If port 8000 is already serving `build/web`, stop that server first: the lab's
directory is **build/architecture-lab**, not **build/web**. Port forwarding is a
development preview, not permanent website hosting.

## Why the ordinary export showed the 2D game

`project.godot` deliberately keeps `run/main_scene="res://scenes/main.tscn"`.
Running a lab scene in the editor or passing a scene to a desktop launch does
not change the startup scene stored in a normal Web export.

The helper copies the project into a temporary directory under `build`, changes
the main scene **only in that copy**, creates a single-thread Web preset, imports,
exports, checks the generated HTML/JS/WASM/PCK, and boots the exported pack without
a scene override to verify the lab really starts. Single-thread export works with
the plain Python server above, without custom cross-origin isolation headers.

Only a successful export replaces `build/architecture-lab`. A failed export or
Ctrl+C cleans the temporary copy and keeps the previous successful build. The
source settings and `build/web` are untouched. Forced process termination or a
machine shutdown can leave a `build/lab-export-*` temporary directory; the source
main scene still cannot be changed by that interruption. Avoid concurrent exports
to the same output directory.

The original 2D Web workflow remains:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --bind 0.0.0.0 --directory build/web
```

## Validation commands

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/wall_occlusion_test.gd
godot --headless --path . --script res://tests/room_visibility_test.gd
godot --headless --path . --script res://tests/architecture_lab_test.gd
godot --headless --path . --script res://tests/grid_floor_collision_test.gd
godot --headless --path . --script res://tests/combat_targeting_test.gd
godot --headless --path . --script res://tests/dual_weapon_test.gd
python3 -m unittest discover -s tests -p test_lab_export.py -v
```

Desktop lab launch, when a display is available:

```sh
godot --path . res://scenes/grid_geometry_audit_25d.tscn
```
