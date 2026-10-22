# Project-Gauntlands

The default scene is the 2D combat prototype. On `experiment/architecture-lab`,
export the separate 3D visibility lab with:

```sh
python3 tools/export_architecture_lab.py
python3 -m http.server 8000 --bind 0.0.0.0 --directory build/architecture-lab
```

Requires Godot 4.5.2 stable and matching Web export templates.
See [Codespaces setup and controls](docs/WEB_ARCHITECTURE_LAB.md),
[iteration results](docs/ITERATION_3_RESULTS.md), and
[remaining acceptance work](docs/NEXT_ITERATION.md).
