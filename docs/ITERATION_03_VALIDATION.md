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
