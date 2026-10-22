# Architecture lab: next iteration

Continue on `experiment/architecture-lab`. Keep experiments separate from the
playable combat prototype and retain Godot 4.5.2 compatibility.

## Current state

Iteration 4 separates discovery, render eligibility and per-segment occlusion.
Visible walls obstructing the player fade to 20%, closed obstructing door leaves
to 28%, over 0.22 seconds. Far-side and other non-obstructing walls remain solid.
The old normal/whole-room cutaway rules are superseded. See
[iteration 4 results](ITERATION_4_RESULTS.md) for design, tests and limitations.

The active lab is `scenes/grid_geometry_audit_25d.tscn`. Floor geometry, wall
segments, door openings, collision and movement remain unchanged. The isolated
[lab Web exporter](WEB_ARCHITECTURE_LAB.md) still uses the 4.5.2 compatibility target
and leaves the original 2D main scene and Web build alone.

## Remaining acceptance work

1. Continue interactive review of alpha sorting and continuous grazing angles at
   walls/corners. Automated sweeps cover 15-degree increments, not every pixel.
2. Before procedural/transformed layouts or non-box walls, extend geometry and
   occlusion tests. Supply explicit room IDs, logical cell ownership and graph
   connectivity for discovery. Do not infer discovery or rendering from alpha.
3. If adding relevant occlusion targets later, explicitly gate them by visibility
   before supplying their positions. No such gameplay objects are added now.
4. Keep occlusion, room discovery, architecture movement, floor collision, 2D
   regression and exporter safety tests passing. Report engine-version differences.
5. Do not migrate this experiment into the combat prototype without a separate
   reviewed task. No new gameplay is part of this iteration.
