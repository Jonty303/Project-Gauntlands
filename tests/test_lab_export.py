"""Failure/interrupt safety tests; actual Godot export is a separate integration check."""
import contextlib
import importlib.util
import io
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "lab_export", Path(__file__).resolve().parents[1] / "tools/export_architecture_lab.py")
EXPORT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(EXPORT)


class ExportSafety(unittest.TestCase):
    def exercise(self, failure=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = b'[application]\r\nrun/main_scene="res://scenes/main.tscn"\r\n'
            preset = b'original preset\r\n'
            (root / "project.godot").write_bytes(original)
            (root / "export_presets.cfg").write_bytes(preset)
            output = root / "build/architecture-lab"
            output.mkdir(parents=True)
            (output / "old-build.txt").write_text("previous successful export")
            ordinary = root / "build/web"
            ordinary.mkdir()
            (ordinary / "index.html").write_text("2D build")

            def fake_godot(*command):
                if "--version" in command:
                    return "4.5.2.stable.official.6ce3de25a\n"
                if "--import" in command:
                    stage = Path(command[command.index("--path") + 1])
                    self.assertIn(EXPORT.SCENE, (stage / "project.godot").read_text())
                    self.assertIn('variant/thread_support=false', (stage / "export_presets.cfg").read_text())
                if "--export-release" in command:
                    if failure:
                        raise failure
                    html = Path(command[-1])
                    for suffix in ("html", "js", "wasm", "pck"):
                        html.with_suffix("." + suffix).write_bytes(b"test artifact")
                if "--main-pack" in command:
                    return "Geometry audit: 69 floor cells"
                return ""

            with patch.object(EXPORT, "ROOT", root), patch.object(EXPORT, "run", side_effect=fake_godot), \
                 patch.object(sys, "argv", ["export", "--godot", sys.executable]), \
                 contextlib.redirect_stdout(io.StringIO()):
                if failure:
                    with self.assertRaises(type(failure)):
                        EXPORT.main()
                    self.assertEqual((output / "old-build.txt").read_text(), "previous successful export")
                else:
                    EXPORT.main()
                    self.assertTrue((output / "index.pck").is_file())
                    self.assertFalse((output / "old-build.txt").exists())
            self.assertEqual((root / "project.godot").read_bytes(), original)
            self.assertEqual((root / "export_presets.cfg").read_bytes(), preset)
            self.assertEqual((ordinary / "index.html").read_text(), "2D build")
            self.assertEqual(list((root / "build").glob("lab-export-*")), [])

    def test_success_replaces_only_lab_output(self):
        self.exercise()

    def test_export_failure_preserves_source_and_previous_build(self):
        self.exercise(RuntimeError("missing templates"))

    def test_interrupt_cleans_staging_and_preserves_previous_build(self):
        self.exercise(KeyboardInterrupt())


if __name__ == "__main__":
    unittest.main()
