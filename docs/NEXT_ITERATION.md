# Architecture lab: next iteration

Continue on `experiment/architecture-lab`, retaining Godot 4.5.2 compatibility.
Do not migrate combat or modify the original 2D game.

## Current state

Iteration 5 adds connected-panel windows around direct occluders, player-sight
previews through directly adjoining open doors, and a world-aligned exterior grid.
See [iteration 5 results](ITERATION_5_RESULTS.md) for implementation and validation.
The active scene remains `scenes/grid_geometry_audit_25d.tscn`.

Discovery is permanent on entry. Temporary portal visibility is independent of
it. Closed doors and walls block preview rays even if visually faded; unrelated
open doors never reveal second-hop rooms. Cutaway expansion follows physical panel
connections without crossing door gaps, using 20% wall alpha and 0.22s transitions.
Grid background patches conceal unknown layout footprints and withdraw wherever
dungeon floors render. Physical geometry and movement remain unchanged.

The isolated [lab Web exporter](WEB_ARCHITECTURE_LAB.md) still targets 4.5.2,
leaving the original main scene and ordinary Web build untouched.

## Remaining work

1. Review continuous grazing angles and preview boundaries interactively. Current
   previews sample tile/segment centres rather than clipping individual pixels.
2. For moving/procedural walls, rebuild the cutaway topology and extend tests for
   transformed, non-box or concave geometry. Keep visibility queries read-only
   with respect to collision, navigation and enemy sight.
3. Keep all five architecture suites and exporter safety checks passing. Retain
   2D regressions and report any engine-version differences.
4. Do not migrate these experiments into combat without a separate reviewed task.
