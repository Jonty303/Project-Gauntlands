# Iteration 04 — Milestone A review record

Date: 2026-10-23. Status: **prototype delivered; user visual approval pending**.

The user explicitly authorized Milestone A after committing the approved concept
sheets. Read AGENTS.md, DESIGN.md, ITERATION_04.md, the Iteration 03 scope and its
validation record. Baseline: `iteration-04` at
`9a9c7cbbcce9736a58a5cb57d6c67c556aa73bc8`.

## Deliverables

[Review package](../assets/prototypes/iteration-04/goblin/README.md): one fixed
east-facing goblin, 30 aligned RGBA PNG frames covering idle, walk, sword
windup/contact/recovery, hurt and death; labelled contact sheet, animated GIF,
interactive HTML preview, approved-reference/dungeon comparison, frame/timing
manifest, original generated atlas and exact prompt. All additions are confined
to the prototype folder and this review record.

The HTML shows actual world-pixel scale and a 4× inspection view, with clip
selection, pause/replay, scrubbing, single-frame stepping and slow motion. Death
is a non-looping offline study; it does not postpone gameplay death. The GIF
automatically replays the review sequence and adds a final-pose inspection hold.

## Validation actually performed

- Inspected the approved goblin sheet, source atlas, exported contact sheet,
  reference/dungeon comparison and rendered browser preview.
- Checked all 30 PNGs: RGBA, 96×96, alpha values only 0/255, nonempty visible
  bounds, minimum 2px outer margin, and visible bottom edge at ground row 72.
- Verified sword durations total 1300ms, with boundaries at 500ms and 640ms;
  hurt is 160ms and the walk cycle retains the existing 4/9-second cadence.
- Standalone preview tested in headless Microsoft Edge from its local file:
  all five clips load, contact is displayed at 570ms, death holds frame 005 at
  720ms, sword stops at 1300ms, paused time remains stable, frame stepping works,
  and there are no JavaScript page errors.
- GIF decoded successfully: 42 frames at 1024×448, including repeated walk cycles.
- `git diff --check` and changed-file preservation review performed before commit.

The first browser launch was blocked by sandbox profile restrictions; a permitted
headless launch succeeded. A localhost attempt from that process could not reach
the sandbox server, so validation used the self-contained local HTML directly.
Neither issue required any project or game configuration change.

No game code, scene, collision, live artwork or engine settings changed. Godot
regression suites were not rerun because this is an unintegrated offline art
prototype. Existing combat/Iteration 02/Iteration 03/visibility-pause results in
ITERATION_03_VALIDATION.md remain historical evidence, not new test results.
Full integration would require the regression and visual comparisons specified
in ITERATION_04.md.

## Approval boundary

Canvases, alpha, clipping and ground alignment pass the mechanical checks.
Reference fidelity, contour/anatomical consistency, loop quality and motion need
the user's visual approval. Review face/ears, equipment stability, walk cadence
and the return to guard carefully; technical export checks do not sign those off.

Milestone B, adventurer production, effects and game integration have not begun.
`main` remains untouched. Stop here for review.

## Walk revision following user review — 2026-10-23

The user reported that walking was not perceptible while the other actions
looked okay. Replaced only the six walk poses with stronger strides, clearly
lifted feet in passing poses and push-off poses. Preserved the character's
equipment, right-facing view, fixed 96×96 canvas, (40,72) ground pivot and
4/9-second cycle. All 24 non-walk PNGs remain byte-for-byte unchanged.

The preview opens on Walk and offers **Show walking travel** to demonstrate the
gait across the unchanged dungeon artwork at 54px/s; the enlarged view remains
in-place for inspection. This is an offline presentation aid, not game integration.
The GIF and contact sheet were rebuilt. The new source and exact prompt are
retained with updated provenance.

Validation: six revised PNGs checked for RGBA/binary alpha, 96×96 dimensions,
unclipped bounds and the shared ground row. Standalone browser playback checked
for frame advancement, travel, pause and in-place mode, with no page errors.
No game runtime checks were needed; gameplay and the other action assets remain
unchanged. Visual approval of this revision is still pending.
