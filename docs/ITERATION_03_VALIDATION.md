# Iteration 03 validation

## Preparation status

Documentation and branch preparation only, 2026-10-23. Gameplay is not implemented and no Iteration 03 gameplay test has been run.

Baseline: iteration-02 at `060a91288da3e63770d7f704478882a052662540`. Its [validation record](ITERATION_02_VALIDATION.md) reports passing import and automated suites, with manual controller feel, visual preference and balance still requiring playtesting. Those historical results are not new test results.

Preparation review: read AGENTS.md, DESIGN.md, Iteration 02 specification/validation, README and existing actor/projectile damage paths. The supplied workspace was empty and was not a Git checkout; repository work uses GitHub directly, leaving other local checkouts untouched. Confirm the published diff contains only the five planned Markdown files and the branch descends from the baseline before reporting completion.

## Planned implementation checks — not run

Use Godot 4.5.2 stable:

```text
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/encounter_test.gd
godot --headless --path . --script res://tests/iteration_02_test.gd
git diff --check
```

Add a focused Iteration 03 test suite during implementation; no such suite is created by this preparation task.

| Area | Required evidence | Status |
| --- | --- | --- |
| Layout/discovery | All ordinary rooms reachable; closed door and corridor bend conceal beyond; remembered layout persists without live actor/item leaks | Not run |
| Door clearance | F/Y toggle, occupied close rejected, fitting creature crosses, oversized fixture blocked, route invalidation handled | Not run |
| Awareness | Acquire, pursue across regions, lose sight, visit last known position, bounded search, reacquire, return idle; stationary Guard preserved | Not run |
| Escape | Alive escape with zero/nonzero gold and enemies alive; stable summary; no damage/collection after completion | Not run |
| Chests/secret | One-time gold, repeated input safe, wall reach blocked, clue/reveal works, hidden contents/markers do not leak | Not run |
| Spike trap | Player/enemy contact, late entry during active window, one hit per cycle, cooldown/rearm, unaffected fixture, death/loot once | Not run |
| Arrow trap | Player/enemy trigger and victims, swept collision, wall/door block, first hit consumed, cooldown, no ammunition change | Not run |
| Reset | Enemy-only reset preserves rewards/discovery; full restart clears summary, secret, chests, traps, arrows, pickups, AI and deferred spawns | Not run |
| Regressions | Existing combat timing, physical/RPG separation, targeting, controls, resources, loot and death/restart | Not run |
| Manual | Physical gamepad, five-room readability, opaque scenery, trap warning fairness, pursuit/escape feel and balance | Not run |

Record actual commands, engine version, failures/fixes, screenshots inspected, chosen tuning and remaining manual limitations when implementation occurs. Do not mark acceptance criteria complete based on documentation review.
