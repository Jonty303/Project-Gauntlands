# Architecture lab: next iteration

Continue on `experiment/architecture-lab`, retaining Godot 4.5.2 compatibility.
Do not migrate combat or modify the original 2D game.

## Current state

Iteration 6 repairs the doorway/floor visual regression: open-door previews now
render complete adjoining floor regions, doorway frames define the openings, and
fully opaque walls use the depth-rendered material path. See
[iteration 6 results](ITERATION_6_RESULTS.md) for causes and validation. Iteration 5
introduced connected-panel cutaways, open-door previews and the exterior grid.
The active scene remains `scenes/grid_geometry_audit_25d.tscn`.

Discovery is permanent on entry. Temporary portal visibility is independent of
it. Closed doors and walls block preview rays even if visually faded; unrelated
open doors never reveal second-hop rooms. Cutaway expansion follows physical panel
connections without crossing door gaps, using 20% wall alpha and 0.22s transitions.
Grid background patches conceal unknown layout footprints and withdraw wherever
dungeon floors render. Opening a door never changes floor meshes or GridMap cells.
Physical geometry and movement remain unchanged.

The isolated [lab Web exporter](WEB_ARCHITECTURE_LAB.md) still targets 4.5.2,
leaving the original main scene and ordinary Web build untouched.

## Remaining work

1. Review continuous grazing angles and preview boundaries interactively. An
   aperture sightline renders the complete adjoining region; this is not per-pixel
   portal clipping, so opaque physical surfaces provide the local occlusion.
2. For moving/procedural walls, rebuild the cutaway topology and extend tests for
   transformed, non-box or concave geometry. Keep visibility queries read-only
   with respect to collision, navigation and enemy sight.
3. Keep the doorway geometry and existing architecture suites and exporter safety
   checks passing. Retain
   2D regressions and report any engine-version differences.
4. Do not migrate these experiments into combat without a separate reviewed task.
