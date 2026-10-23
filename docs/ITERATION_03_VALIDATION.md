# Iteration 03 validation

## Implementation status — 2026-10-23

Implemented on `iteration-03` following explicit implementation authorization.
Verified the committed planning branch at `bbc89121a50cfbadcaefb6b7d56c94c59d4307d1`,
based on completed Iteration 02 `060a91288da3e63770d7f704478882a052662540`.
Read AGENTS.md, DESIGN.md and the Iteration 01/02/03 contracts before editing.
Iteration 03 remained authoritative; earlier specification files are unchanged.
No character progression, inventory, new species or external assets were added.

The supplied OneDrive directory rejected creation of a checkout. Implementation
and validation used the other permitted local workspace, under the session's
Codex visualizations directory in `Project-Gauntlands`.

## Actual validation

Engine: `4.5.2.stable.official.6ce3de25a`, extracted from the user's existing
Godot 4.5.2 Windows download. A portable `_sc_` marker kept editor data beside
the engine outside the repository. Commands used absolute writable log paths.

```text
godot --version
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/encounter_test.gd
godot --headless --path . --script res://tests/iteration_02_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/encounter_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/iteration_02_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/iteration_03_test.gd
godot --path . --fixed-fps 60 --script res://tests/iteration_03_visual.gd -- <output-directory>
git diff --check
```

- Final editor import / GDScript validation: passed, no script/resource errors.
- Combat regressions: **40 checks, zero failures**.
- Iteration 02 regressions: **112 checks, zero failures**.
- Iteration 03: **50 checks, zero failures**.
- Nine rendered captures saved; original and corrected captures inspected.
- Whitespace/diff check: passed.

The first ordinary-speed combat run missed the initial injected keyboard press
and its dependent cycle assertion. The test helper now waits for a process-frame
boundary and flushes buffered input before counting physics ticks. Assertions
and gameplay input mappings were not changed. The ordinary-speed suite then
passed, as did the final fixed-rate run. Earlier development import errors from
Windows text encoding/line endings were corrected before final validation.

The rendered run used NVIDIA OpenGL compatibility rendering. This sandbox
reported an unwritable per-user shader cache; rendering and capture still
succeeded. Portable headless import and tests had no such runtime error.

## Evidence by area

| Area | Evidence / result |
| --- | --- |
| Layout | Grid routes from Room A to all five room centres; existing continuous movement through the L corridor into Room B still passes. |
| Discovery | Closed connection hides enemy/lock; aperture exposes straight corridor but not bend; static memory persists; hidden pickups and remote projectile impacts do not leak through HUD. |
| Clearance | Radius-7 route succeeds; radius-34 route fails in 64px passage; actual oversized mobile actor stays outside doorway; edge overlap prevents closure. |
| Awareness | Sight acquisition, movement around bend toward stored observation, no hidden-position updates, bounded blocked-route search and renewed pursuit after reopening. Guard and attack timing regressions pass. |
| Rewards / secret | Nearby clue only; revealed physical connection; one-time 20/35 gold chests; wall blocks interaction; enemy reset preserves rewards and exploration. |
| Spikes | Warning before damage, one contact per activation, late enemy entry, rearm, separate trigger eligibility and susceptibility, immune fixture, one death/drop. |
| Arrow trap | Enemy triggers/player victim and inverse, intervening creature absorbs first hit, immune body stops arrow, swept closed-door collision, cooldown, unchanged player ammunition. |
| Escape | Zero/nonzero gold with enemies alive; frozen health, movement, in-flight projectile, running trap timer and pickup collection; stable snapshot. |
| Reset | Restart action clears run state, discovery, rewards, secret, traps, projectiles, loot, locks and awareness; enemy-only reset preserves trap phase/timer and rewards; old deferred-spawn suite passes. |
| Rendering | Start room, open aperture, arrow lane, secret clue, closed/open chest, raised spikes, entrance and escape summary inspected. Chest/player draw order corrected; health bars no longer draw across the end summary. |

## Implementation and tuning

- `dungeon.gd`: original room art reused for four ordinary rooms plus secret;
  separate floor geometry, room rectangles and corridors; footprint-specific
  navigation grids invalidated by door changes.
- `exploration.gd`: 16px visibility cells, 440px sight, static memory dimmed by
  86%, refresh every 0.08s. Dynamic visibility is checked separately; hidden
  simulation continues. No transparency or revealing silhouette is introduced.
- `goblin.gd`: 360px detection, unchanged 54px/s speed, 12s maximum pursuit of a
  lost observation, 2.5s local scan, reachable home return. Replans at 0.35s or
  immediately on door revision. Guard stays stationary.
- `reward.gd` / interactions: F/Y, under 48px reach, secret clue within 32px;
  20 and 35 gold configurable chest amounts. Explicit entrance escape.
- `trap.gd` / shared arrow and health paths: warning 0.55s, active 0.65s,
  cooldown 2.5s, damage 3. Swept arrow speed remains 290px/s, expiry 3s.
  Trigger sensitivity and hazard susceptibility are independent actor flags;
  existing actors default to susceptible. No weapon accuracy roll for hazards.
- Existing player/actor/projectile/pickup/HUD code adds completion and visibility
  guards; original sprites, input mappings, combat timings, ammo and loot stay.
- `iteration_03_test.gd` supplies focused regression fixtures;
  `iteration_03_visual.gd` reproduces the nine capture positions/states.

## Outstanding manual validation

No physical controller hardware was exercised. Automated injected controller
bindings pass, but analogue feel, trap warning fairness, pursuit/escape feel,
secret clue subtlety and balance need human playtesting. Captures are scripted
scene setups, not evidence of a complete human five-room playthrough. Full
acceptance boxes in the original spec are intentionally not signed off solely
from automation. No known failing automated check remains. No merge to main.


## Approved visibility and pause refinement — 2026-10-23

Implemented after explicit approval of the inspection plan, based on Iteration 03
`5342451893811525df171e91833570b4b18d2275`.

### Behaviour

- `sight.gd` owns geometric observation: 440px configurable range, wall/door
  corner rays, and a full-resolution polygon. It refreshes on player movement,
  door revision or range change. Redundant collinear vertices are removed.
- `exploration.gd` owns persistent static discovery and fog rendering. Memory
  uses conservative 4px samples; the current mask is not restricted to that grid.
  Remembered terrain is darkened by 55%, replacing the original 86%. Changing
  this value cannot grant sight. No torch, falloff or illumination system exists.
- Visible north-wall segments project into their existing tall artwork without
  granting gameplay sight behind the wall. Five samples across an actor's
  physical footprint allow partial observation; locks, HUD and actor rendering
  use the same eligibility rule. Dynamic objects never enter memory.
- `pause_menu.gd` keeps UI responsive while the SceneTree simulation is paused.
  Named pause owners support a future inventory screen without introducing it.
  Shared gameplay mutation paths also reject damage/actions during pause.
- Escape, Start/Menu and the HUD Pause button open the menu. R requests restart
  confirmation during active play. Start/R retain direct restart after death or
  escape. Escape on an end screen does not restart. Restart confirmation defaults
  to Cancel. Menu presses must release before simulation resumes.
- Updated README, DESIGN, agent guidance and Iteration 03 status/requirements.

### Validation actually performed

Godot 4.5.2 stable, portable local runtime:

- Headless editor import/GDScript validation: passed.
- Existing combat suite: 40 checks, zero failures.
- Existing Iteration 02 suite: 112 checks, zero failures.
- Existing Iteration 03 suite: 50 checks, zero failures.
- New `tests/visibility_pause_test.gd`: 29 checks, zero failures.
- All four suites used `--headless --fixed-fps 60 --script res://tests/<suite>.gd`.
- The new suite samples the aperture mask against blocked sight, checks corners,
  wall memory seams, partial actor visibility/target eligibility, door revision,
  range and brightness independence, restart memory, combat/AI/trap/projectile/
  pickup/respawn freeze, overlapping inventory/menu pause reasons, restart
  confirmation, controller navigation and input consumption on resume.
- Fourteen renderer captures were produced. Start, aperture, corridor, secret,
  chest states, traps, entrance/escape, pause, confirmation and remembered-space
  views were inspected; wall-memory seams found in review were corrected.
- A local 60-position Room A microbenchmark of observation plus memory refresh
  measured about 6.3ms median / 6.8ms maximum after removing redundant tile-corner
  rays and polygon vertices. This is not a full gameplay frame-rate benchmark.
- `git diff --check`: passed.

No physical controller was exercised. Human playtesting remains necessary for
visual preference, controller feel and full-run performance. Rendered validation
reported the same sandbox shader-cache warning as the original iteration; all
captures succeeded. No code was imported from historical prototypes.
