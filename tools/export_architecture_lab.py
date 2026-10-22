#!/usr/bin/env python3
"""Export the lab from an isolated copy; never edit the working project's settings."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCENE = "res://scenes/grid_geometry_audit_25d.tscn"


def run(*command):
    result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout, end="", flush=True)
    # Godot can return zero after an import/parser/export error.
    if result.returncode or re.search(r"(?:SCRIPT ERROR:|ERROR:)", result.stdout):
        raise RuntimeError(f"Godot failed: {command}")
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    args = parser.parse_args()
    executable = shutil.which(args.godot)
    if not executable:
        parser.error("Godot not found; pass --godot /path/to/godot or set GODOT")
    executable = str(Path(executable).resolve())
    version = run(executable, "--version").strip()
    if not version.startswith("4.5.2.stable."):
        parser.error(f"Expected Godot 4.5.2 stable, found {version}")
    build = ROOT / "build"
    build.mkdir(exist_ok=True)
    destination = build / "architecture-lab"
    # Keep staging on the same filesystem for directory renames. Failed exports
    # leave the last successful build intact; TemporaryDirectory cleans failures.
    with tempfile.TemporaryDirectory(prefix="lab-export-", dir=build) as temporary:
        stage = Path(temporary) / "project"
        shutil.copytree(ROOT, stage, ignore=shutil.ignore_patterns(
            ".git", ".godot", "build", "__pycache__"))
        project = stage / "project.godot"
        settings, count = re.subn(r'^run/main_scene=.*$', f'run/main_scene="{SCENE}"',
                                 project.read_text(encoding="utf-8"), flags=re.MULTILINE)
        if count != 1:
            raise RuntimeError("Expected exactly one run/main_scene setting")
        project.write_text(settings, encoding="utf-8")
        # Dedicated single-thread Web preset works with a plain port-8000 server.
        (stage / "export_presets.cfg").write_text('''[preset.0]
name="Architecture Lab Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path=""

[preset.0.options]
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
progressive_web_app/enabled=false
''', encoding="utf-8")
        output = Path(temporary) / "output"
        output.mkdir()
        run(executable, "--headless", "--path", str(stage), "--editor", "--import")
        run(executable, "--headless", "--path", str(stage), "--export-release",
            "Architecture Lab Web", str(output / "index.html"))
        for suffix in ("html", "js", "wasm", "pck"):
            artifact = output / f"index.{suffix}"
            if not artifact.is_file() or not artifact.stat().st_size:
                raise RuntimeError(f"Missing/empty export: {artifact.name}")
        # Run the exported pack without a scene argument: this verifies its actual
        # startup scene, rather than merely checking our temporary source config.
        boot = run(executable, "--headless", "--path", str(output),
                   "--main-pack", str(output / "index.pck"), "--quit-after", "3")
        if "Geometry audit: 69 floor cells" not in boot:
            raise RuntimeError("Exported pack did not launch the architecture lab")
        backup = Path(temporary) / "previous"
        if destination.exists():
            destination.rename(backup)
        try:
            output.rename(destination)
        except BaseException:
            if backup.exists():
                backup.rename(destination)
            raise
    print(f"Lab export verified: {destination / 'index.html'}")
    print("Serve: python3 -m http.server 8000 --bind 0.0.0.0 --directory build/architecture-lab")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, KeyboardInterrupt) as error:
        raise SystemExit(f"Lab export stopped: {error}")
