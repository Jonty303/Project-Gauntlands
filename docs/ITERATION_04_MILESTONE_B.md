# Iteration 04 — Milestone B review record

Date: 2026-10-23. Status: **four-direction art delivered; user approval pending**.

The user approved the revised Milestone A goblin with "looks good", then said
"go ahead" after being told Milestone B meant four-direction goblin animation.
Base: `iteration-04` at `b87e979d62abe5a547ee56ae9f1bcc11ac152aab`.
Followed AGENTS.md, DESIGN.md and the Milestone B scope in ITERATION_04.md.

## Deliverables

[Four-direction review package](../assets/prototypes/iteration-04/goblin/four-direction/README.md):
90 new transparent north/south/west frames, plus all 30 approved east frames
preserved byte-for-byte. Each direction covers idle, walk, sword
windup/contact/recovery, hurt and death on the same 96×96 canvas and (40,72)
ground anchor. Timings match Milestone A and the unchanged goblin gameplay.

The standalone HTML provides synchronized four-view inspection, all five clips,
pause/scrub/frame stepping/slow motion, and native-scale dungeon playback with
direction cycling and optional walk travel. Contact sheets, animated GIF,
timing/facing/source manifest, original source images and exact prompts accompany
the frames. No replacement is connected to the game.

## Validation actually performed

- Inspected generated directions, corrected north hurt source, contact sheets
  and rendered browser preview for scale, foot placement and directional identity.
- Replaced north hurt frames after identifying a shield-side continuity error.
  No mirroring was used to generate new directions.
- Checked 120 PNGs: 30 per direction; RGBA, 96×96, binary alpha, nonempty bounds,
  grounded bottom edge at 72 and at least 2px transparent output margin.
- Compared all 30 east PNG bytes against the approved baseline: unchanged.
- Retained complete source poses using gutter-aware cropping. Corrected a north
  row-boundary spillover that initially put part of the raised attack sword under
  a walking frame. Recorded horizontal stance/alignment adjustments in manifest.
- Verified the 1300ms sword timing and 500/640ms phase boundaries, 160ms hurt and
  4/9-second walk cadence; death remains an offline presentation duration only.
- Headless Microsoft Edge loaded the standalone file with all 120 images and no
  JavaScript page errors. Walk advanced through frames 0–5; every clip loaded;
  sword contact displayed at 570ms, death held its last pose at 720ms, and sword
  stopped at 1300ms. Four direction selections produced distinct renders.
  Pause preserved time and single-frame stepping advanced correctly.
- The automatic review GIF contains 42 synchronized frames, with three walk
  cycles and a final death inspection hold. GIF delays are rounded for its format.
- Final asset bounds/alpha checks and `git diff --check` passed before commit.

No GDScript, scene, live atlas, collision shape or project setting changed.
Godot regression suites were not rerun for this unintegrated art-only milestone.
The four existing suites and integration visual comparisons in ITERATION_04.md
remain required for a future integration request. No historical test results
are claimed as new executions here.

## Review and preservation

User approval of Milestone A is recorded in ITERATION_04_MILESTONE_A.md.
Milestone B awaits visual review, especially head/body scale, limb/weapon
continuity, north attack readability, walk footfalls and directional transitions.
Passing export/playback checks does not imply production visual approval.

Gameplay, existing combat timings, footprints, dungeon/visibility/pause/AI/traps,
and controller bindings are preserved. Skeleton/troll remain reference only.
No adventurer work, effects, integration or merge to main. Stop for review.
