# Goblin — Milestone A review prototype

**Awaiting user visual approval. One east-facing view only; no game integration.**

Open `preview.html` directly in a browser. Choose a clip, pause, scrub, step or
slow playback to inspect the frames. `animation-preview.gif` is a convenient
automatic review reel: idle, three walk cycles, sword, hurt and death. Its final
corpse hold and replay are review controls. The HTML/manifest are the timing
reference; GIF delays are rounded to the format's centisecond precision.

- `east/`: 30 transparent RGBA PNGs, six per clip, all 96×96.
- `manifest.json`: frame order/durations, phase boundaries and export anchors.
- `contact-sheet.png`: labelled frames and ground line at 2× nearest neighbour.
- `reference-comparison.png`: approved sheet, original/new actor scale and 3× details.
- `source/generated-atlas.png`: unmodified imagegen result, 1536×1024 RGBA.
- `source/walk-revision.png`: six revised walk poses, 1536×1024 RGBA.
- `PROMPT.txt`: exact production prompt used with the reference sheet.
- `WALK_REVISION_PROMPT.txt`: exact targeted walking revision prompt.
- `export.mjs`: offline mechanical export/review assembly; requires Node + sharp.
  Run from any directory with `node <path-to-export.mjs>`. If sharp is not on
  the module path, set `GAUNTLANDS_SHARP` to its installed package path.

No Godot scene, script, resource, import settings or live sprite atlas references
this directory. The existing `assets/goblin.png` is unchanged.

## Frame contract

The ground pivot is **(40,72)**, measured from the top-left of a fixed 96×96
canvas. Visible pixels end at row 71; row 72 is the ground plane. A future
visual-only integration would place the canvas at actor ground minus this pivot;
the 7px collision radius must remain independent. No integration is performed.

Original poses share one 1:4 nearest-neighbour sampling grid from the generated image.
The revised walk uses one shared 171×114 sampling grid from its 1536×1024
three-column/two-row source, yielding a similar 37–38px character height.
The generated atlas did not honour the requested 1280px height or exact cell
spacing. The exporter therefore uses the actual 1024px height and recorded
source bounds, translates feet to the common pivot, and gives falling poses a
rear-foot pivot so the torso can collapse forward. It does not scale individual
poses, rotate limbs, invent in-between frames or redraw anatomy. Alpha is
thresholded at 128 to remove soft fringes, with transparent RGB cleared. Every
export has only alpha 0/255 and at least a 2px transparent outer margin.

## Existing timing mapping

Source: `scripts/actor.gd` and `scripts/goblin.gd` at baseline commit
`9a9c7cbbcce9736a58a5cb57d6c67c556aa73bc8`.

| Clip | Preview timing | Gameplay relationship |
| --- | --- | --- |
| Idle | 6×200ms; loops | Cosmetic breathing only; no existing idle duration. |
| Walk | 6×(4000/54)ms; loops | Existing four poses at 9fps imply a 4/9-second cycle; movement stays 54px/s. |
| Sword windup | attack_000/001, 250ms each | Existing goblin anticipation 0–500ms. |
| Sword contact | attack_002/003, 70ms each | Existing active window 500–640ms. |
| Sword recovery | attack_004/005, 330ms each | Existing recovery 640–1300ms. |
| Hurt | 6×(160/6)ms; holds final | Existing hurt flash is 160ms, without stun or attack cancellation. |
| Death | 100/100/100/100/100/220ms, holds final | Offline 720ms visual study only. Existing death, collision removal and loot are immediate. No new gameplay/death/respawn timer. |

Gameplay must remain authoritative if integration is later requested. The preview
does not invoke damage, projectiles, movement, AI or any game state.

## Provenance

- Approved reference: `assets/concepts/wide_dark_pixel_art_game_asset_sheet_illustration.png`.
- Reference Git blob: `3c7cdb72f859f889ddccc0581b333c3cac44f8d3`.
- User committed the four approved sheets in `9a9c7cbbcce9736a58a5cb57d6c67c556aa73bc8`
  and explicitly authorized Milestone A in this chat on 2026-10-23.
- Conversation/design source: [Game System Design](https://chatgpt.com/c/6adb6dbb-34d0-83eb-ab7d-505df6e30c6d).
- Derivative artwork created on 2026-10-23 using the built-in OpenAI imagegen
  tool, with the approved goblin sheet attached as the sole image reference and
  transparent background requested. The initial generation was followed by one
  targeted walk revision using that atlas as reference; no API/CLI fallback.
- Tool result identifier: `exec-09cd40c7-cfc8-40b3-8648-9bd15f0e1a5e.png`.
  The exact underlying model identifier/seed/settings were not exposed.
- Walk revision tool result: `exec-870ec930-ea7b-4b4f-b71e-70edf5e9b4ac.png`,
  generated on 2026-10-23 in response to the user's observation that the goblin
  did not appear to walk. All non-walk PNG frames remain byte-for-byte unchanged.
- Export edits: common nearest-neighbour sampling, hard alpha, crop/translation,
  PNG export, preview composition and GIF encoding, as recorded above.
- Original concept creator/model/date and a formal reference licence are not
  supplied by repository metadata. User approval establishes the intended design
  input; it does not establish a third-party licence. No new licence assertion
  or transfer of rights is made here. Keep this provenance with the derivatives.
- Dungeon background and old goblin are unchanged project artwork described in
  `assets/ATTRIBUTION.md`; they appear only in offline comparisons.

## Review checkpoint

The preview now opens on Walk. Turn **Show walking travel** off to inspect the
in-place cycle, or leave it on to see the actor move at the existing 54px/s.
Travel is an offline preview aid only. The six replacement poses show contact,
passing and push-off for each half-cycle; the full cycle remains 4/9 seconds.

Approve or revise this direction's design fidelity, anatomy/head/ear stability,
shield and sword continuity, breathing/walk loops, foot contact, sword recovery
and death silhouette at 1× and enlarged scale. This is an AI-generated prototype;
small pose-to-pose contour/detail changes require human judgement, even though
the canvases and foot alignment are mechanically consistent.

Do not proceed to four directions, the adventurer, effects or game integration
until the user approves this visual checkpoint and authorizes the next milestone.
