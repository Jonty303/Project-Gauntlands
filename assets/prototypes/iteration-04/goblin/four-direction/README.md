# Goblin — Milestone B four-direction review

**Awaiting user visual approval. Art prototype only; no game integration.**

Open `preview.html` directly in a browser. The synchronized panels show south,
west, north and the approved east at 3× nearest-neighbour scale. The dungeon
panel shows one native image pixel per world pixel, with direction selection or
automatic direction cycling. Walk travel is an offline preview aid at 54px/s;
it does not change game movement. Pause, scrub, step or slow playback to inspect
the same phase in every direction. `animation-preview.gif` is the automatic
review reel; its centisecond-rounded delays are not a new timing specification.

## Files and frame format

- `../walk12/<direction>/`: 48 revised walk PNGs, twelve per direction.
- `../south/`, `../west/`, `../north/`, `../east/`: all 120 previous PNGs,
  byte-for-byte unchanged. Their six-pose walks are retained as earlier versions;
  current playback uses `walk12/`. The 96 non-walk frames remain active.
- `manifest.json`: all 144 active frame paths, ordered clips, durations, source crops,
  ground alignment adjustments and directional mapping.
- `contact-<direction>.png`: all frames with phase labels/ground guides at 2×.
- `animation-preview.gif`: synchronized four-view idle/walk/sword/hurt/death reel.
- `../source/milestone-b-*.png`: unmodified generated source atlases.
- `../source/MILESTONE_B_*_PROMPT.txt`: exact prompts for every generation.
- `../export-four-directions.mjs`: offline mechanical export/preview assembly.
  Requires Node and sharp; set `GAUNTLANDS_SHARP` if sharp is outside the module
  search path. The original `export.mjs` remains the separate Milestone A exporter.

All production frames remain **96×96 RGBA** with ground anchor **(40,72)**,
real transparency and binary alpha (0/255). Visible grounded pixels end at row
71; row 72 is the ground plane. There is at least a 2px transparent outer margin.

New full atlases use one shared 1:4 nearest-neighbour grid per source. The north
hurt correction uses one shared 171×114 sampling grid from its 1536×1024 source,
matching the approximately 38px standing body height. No pose is individually
resized or mirrored. Source row/column gutters are located before extraction;
the north walk/attack second-column boundary is recorded separately to keep a
raised sword tip with the attack rather than below a walker's feet.

Poses are translated onto the ground anchor. Wide stances and west falling
poses can straddle that anchor rather than placing the exact midpoint of both
feet there. Small horizontal source-anchor adjustments, at most 8 native pixels,
retain the entire sword/corpse inside the fixed canvas; the manifest records
each adjustment. This is presentation alignment, not root motion or a change
to collision. Review those stances and directional transitions at native scale.

## Timings and facing mapping

Sword timing remains unchanged. Walk cadence and cosmetic hurt playback were
revised following explicit user feedback; gameplay timers remain unchanged:

| Clip | Duration / behaviour |
| --- | --- |
| Idle | 6×200ms, cosmetic breathing loop. |
| Walk | Twelve equal samples over 800ms, loops. Visual cadence only; movement remains 54px/s. |
| Sword | 500ms windup, 140ms contact, 660ms recovery; total 1300ms. |
| Hurt | Six frames over 400ms (40/60/100/100/60/40ms). Existing gameplay hurt timer remains 160ms; no added stun/cancellation. |
| Death | 720ms offline visual study, holds final pose; gameplay death remains immediate. |

Future selection must match the unchanged `scripts/actor.gd` rule:
`abs(x) > abs(y)` selects east for positive x and west otherwise; remaining
vectors select north for negative y and south otherwise. Diagonal ties select
the vertical direction. South=(0,1), west=(-1,0), north=(0,-1), east=(1,0).
Movement and combat vectors remain continuous. No selection code is integrated.

## Twelve-pose walk and ear alignment revision

The user rejected the initial gait as shuffling, requested more fluid/realistic
walking, noted ear misalignment, and found hurt too quick. The current preview
therefore uses twelve newly generated walking poses per direction and a slower
800ms gait, rather than repeating/interpolating the six old poses. These are
review assets, not a claim that natural walking has been accepted.

All directions are scaled to the approved east idle standing height, using one
common nearest-neighbour sampling grid per source sheet, never per-pose scaling.
The exact grid is recorded in each walk export entry. Foot support stays at the
shared ground row. Horizontal alignment follows the upper head/ear silhouette
instead of the midpoint between changing foot positions: north/south use x=40,
east x=44 and west x=36 to allow the side-facing forward head lean. Recorded
head-band centres stay within 0.5px of those anchors; integer export necessarily
rounds half-pixel centres. Small vertical bob and contour variation remain for
human motion review; this does not claim identical ear pixels in every frame.

The earlier six-pose sources and frame files remain intact for comparison.
Idle, sword, hurt and death PNGs are unchanged. The 400ms hurt duration is a
cosmetic preview decision only. A future integration must keep the 160ms
simulation timer, input responsiveness, attack/contact timing and movement;
it must allow cosmetic recovery to be interrupted by higher-priority actions
without adding stun, cancellation or an input queue.

## Provenance

Milestone A was approved after the revised walk at
`b87e979d62abe5a547ee56ae9f1bcc11ac152aab`. The user then explicitly authorized
Milestone B. All new art was generated on 2026-10-23 with built-in OpenAI
imagegen, using the approved goblin concept and approved east atlas as visual
references. The exact underlying model identifier/seed were not exposed.

| Source | Tool result identifier |
| --- | --- |
| South | `exec-37a732ae-bfba-4a4b-aad7-dc66aa3dde98.png` |
| West | `exec-8660aa23-4951-441e-9291-49ff0b9b214b.png` |
| North | `exec-ecca3e98-9ff3-43b4-ba0a-eab99412410a.png` |
| North hurt correction | `exec-2621fa72-6697-4f84-990c-5af4be9fb1a3.png` |

The initial north hurt poses changed shield sides. Those six poses were replaced
by a targeted generation preserving shield on screen-left and sword on
screen-right in the back view. The original source atlas is retained for audit;
its faulty hurt row is not used by any exported clip.

Four additional built-in imagegen calls on 2026-10-23 produced the twelve-pose
walks. Each used its corresponding earlier direction atlas as visual reference.
Exact prompts are in `../source/WALK12_<DIRECTION>_PROMPT.txt`; unmodified results
are retained as `../source/walk12-<direction>.png`.

| Revised walk source | Tool result identifier |
| --- | --- |
| South | `exec-acac3446-0a50-48ab-a44e-1e3cdfc32f9d.png` |
| West | `exec-3ce8c17e-f5a2-41dc-908e-9039c5c84330.png` |
| North | `exec-e85b6ae7-98b5-4865-81c2-f62ca96ea68e.png` |
| East | `exec-88d92640-647f-46a7-82bf-c81968dee7b8.png` |

Approved concept:
`assets/concepts/wide_dark_pixel_art_game_asset_sheet_illustration.png`,
Git blob `3c7cdb72f859f889ddccc0581b333c3cac44f8d3`, committed by the user in
`9a9c7cbbcce9736a58a5cb57d6c67c556aa73bc8`.
Design source: [Game System Design](https://chatgpt.com/c/6adb6dbb-34d0-83eb-ab7d-505df6e30c6d).
The existing room texture appears unchanged in the offline preview. Original
concept authorship/model/date and formal licence metadata remain unspecified;
the [Milestone A provenance](../README.md) and `assets/ATTRIBUTION.md` apply.
No new rights/licence claim is made.

## Review boundary

Review each direction's identity, anatomy, walking, sword phases, equipment
handedness, collapse and transitions at 1×/3×. AI-generated contour and pose
variation still require human judgement; technical checks do not approve them.
No Godot scene/script/import setting references these replacements. Game code,
collision, combat, visibility, pause, AI, traps, controls and live art remain
unchanged. Do not integrate, start the adventurer or add effects without the
next explicit request after this review.
