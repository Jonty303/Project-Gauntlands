# Architecture lab iteration 3 — 22 October 2026

Based on `0f04aeb` and the validation follow-up `a717d4c` on
`experiment/architecture-lab`. No combat migration or gameplay changes.

## Changes

- Added an isolated, one-command lab Web exporter. Source `project.godot` and
  `export_presets.cfg` retain their original contents. See
  [Codespaces export and port 8000 instructions](WEB_ARCHITECTURE_LAB.md).
- Overhead view now follows the chosen yaw, including Q/E rotation. Movement and
  foreground classification use that same yaw in both views. The previous
  overhead camera ignored yaw and used a 0.01m offset to avoid a vertical look-at;
  this made cutaway facing switch to a fixed world direction when toggling T.
  The new vertical camera supplies an explicit up vector instead.
- Added 16 production-physics doorway routes: both doors, both travel directions,
  both opening edges (0.035m capsule clearance), and both diagonal approaches.
  These rotate every four physics frames, faster than the 0.22-second fade,
  and cover both overhead and angled view. They check support, passage, discovery,
  floor visibility, door toggles and closed-door blocking after rotation.
- Added overhead consistency checks at eight yaw angles in each room, preserving
  displayed alpha, eligible-owner wall/door targets, ownership and collision.
- Repaired stale 2D targeting test setup: instantiate the current goblin script's
  CharacterBody2D base, disable its physics callback during fixture placement,
  and call the projectile's current physics callback instead of removed `_process`.
  Production 2D scripts and scenes are unchanged.

## Validation actually performed

Engine: **4.5.2.stable.official.6ce3de25a**, Windows. Tests ran outside the command
sandbox because its restrictions caused engine startup/editor data errors.
Portable editor data and official matching Web templates were kept outside the repo.

| Check | Result |
| --- | --- |
| Room visibility | 5,568 checks, 0 failures |
| Architecture geometry/movement | 3,598 checks, 0 failures |
| Grid floor collision | 17 checks, 0 failures |
| 2D combat targeting | 35 checks, 0 failures after fixture repair |
| 2D dual weapon | 0 failures |
| Export success/failure/interrupt safety | 3 tests passed |
| All 26 GDScript parser checks | Passed |
| Headless editor import | Exit 0, no errors or warnings |
| Actual release Web export | Passed; HTML, JS, WASM and PCK present |
| Exported pack default startup | Booted lab; 69 floor cells, 44 edges, 44 joins |
| Browser on plain HTTP port 8000 | Lab rendered; initial room and overhead rotation checked; no browser console errors/warnings observed |

The two 2D suites emit an ObjectDB leak warning at shutdown despite their passing
assertions; their asynchronous effect/timer cleanup remains a separate limitation.
The initial targeting test stopped on stale APIs before the fixture repair; its
final 35-check run completed. A timeout exit alone was not counted as a pass.

The export safety tests mock the engine to inject failure and Ctrl+C, verifying
byte-identical source settings, preservation of the old lab build and the 2D build,
and removal of staging. The real engine export independently verifies successful
pack startup. The source main scene remains `res://scenes/main.tscn`.

## Remaining acceptance work

The browser check is a visual smoke test, not an exhaustive review of every room,
corner, transparency sorting case or doorway at every orientation. Complete those
interactive checks before considering combat migration. Codespaces itself was
not available in this session; the same Python exporter and plain port-8000 HTTP
workflow were validated locally on Windows. No other engine version was tested
in this iteration. Transformed/procedural layouts remain out of scope.
