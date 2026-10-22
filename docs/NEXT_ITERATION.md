# Architecture lab: next iteration

Continue on `experiment/architecture-lab`. Keep experiments separate from the
playable combat prototype and retain Godot 4.5.2 compatibility.

## Current state

Iteration 3 adds isolated [lab Web export](WEB_ARCHITECTURE_LAB.md), consistent
overhead yaw/movement/fading, and rotating edge/diagonal doorway regressions.
See [iteration 3 results](ITERATION_3_RESULTS.md) for validation and limitations.

Iteration 2 implements modular graph-based discovery, owned foreground normals
for walls and doors, stable logical floor-region ownership, and 0.22-second
opacity transitions. The active lab is `scenes/grid_geometry_audit_25d.tscn`.
See [iteration 2 results](ITERATION_2_RESULTS.md) for architecture, commands,
regression coverage, version results and limitations; the earlier geometry work
is recorded in [iteration 1 results](ITERATION_1_RESULTS.md).

Physical geometry and collision remain the tested iteration 1 system. The
visibility module never changes collision. New room layouts must supply explicit
reciprocal adjacency, unique room IDs, logical cell ownership, and matching
room/normal pairs for shared surfaces; do not infer adjacency from distance.

## Remaining acceptance work

1. Inspect the lab interactively in Godot 4.5.2. Review hidden rooms, shared
   boundaries, alpha sorting, corners, doorway returns and foreground readability
   at every camera orientation. Automated headless checks do not certify rendered
   appearance.
2. Visually review diagonal and edge-of-opening movement, including rotations
   during transitions and door toggles. Iteration 3 automates these routes with
   production physics; full interactive appearance review remains outstanding.
3. Before supporting transformed or procedural layouts, extend the geometry and
   visibility tests with those layouts and coordinate transforms.
4. Keep all three regression suites passing: room visibility, architecture lab,
   and GridMap floor collision. Preserve 4.5.2 compatibility and report behavior
   differences on other engine versions.
5. Do not migrate the architecture into the playable combat scene until the
   remaining visual checks are completed. No new gameplay is part of this work.
