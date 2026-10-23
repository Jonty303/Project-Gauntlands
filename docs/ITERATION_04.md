# Gauntlands — Iteration 04: Character Art & Animation

## Status and scope

**Preparation only — 2026-10-23. No art production or game implementation is authorized by this document.** Subsequent work must be explicitly requested one milestone at a time, beginning with A.

Base: completed `iteration-03` tip `88644ca4e58ba92b61e9523a7ed78a0b15486b4d`, including the merged visibility/pause refinement. Work only on `iteration-04`. Do not change or merge `main`. This preparation adds only this specification.

Read [AGENTS.md](../AGENTS.md), [DESIGN.md](../DESIGN.md), [Iteration 03](ITERATION_03.md) and its [validation record](ITERATION_03_VALIDATION.md). Earlier iteration contracts remain historical baselines. The four-direction scope below is a bounded art milestone, not a change to the longer-term preference for eight-direction presentation.

## Art direction and reference provenance

Use the approved adventurer, goblin, skeleton and troll concept sheets from [Game System Design](https://chatgpt.com/c/6adb6dbb-34d0-83eb-ab7d-505df6e30c6d) as the visual reference set. Target gritty, grounded dark fantasy in the established fixed 3/4 top-down, true-2D pixel-art language: convincing anatomy and material wear, restrained colour, readable silhouettes and weapons, and detail that survives actual gameplay scale. Preserve the approved character identities and proportions. Avoid clean toy-like replacements, generic placeholder art, arbitrary sprite rotation or forcing detail into a nominal tiny grid.

Skeleton and troll are **reference only**. Do not create their production animations, enemies, statistics or mechanics. The large, slow, club-bearing troll concept is not authorization for regeneration or any new gameplay.

Reference availability: the conversation reader exposed text references but no source image attachments during preparation. Exact visual details and source dimensions could not be verified. Before Milestone A production, retrieve the approved original sheets or request them from the user; do not silently substitute newly invented designs or claim a visual match without seeing them.

For later assets, record source sheet/file identifiers, conversation/source link, creator or generation tool/model when known, creation date when known, prompts/settings when available, edits and exports, and usage rights/licence or any unresolved provenance. Do not invent missing metadata. Keep original references distinct from derived production frames, retain editable source where available, and record which sheet each character follows. Reference sheets are style/design evidence, not automatically ready-to-import animation atlases.

## Milestone A — ONE-direction goblin quality proof

After separate authorization, produce a small, production-quality goblin preview in one fixed direction only. Choose and record the direction that best demonstrates the approved design and sword action; keep it identical across every clip.

Required clips:

| Clip | Required visual result |
| --- | --- |
| Idle | Stable identity, readable stance and a clean restrained loop. |
| Walk | Coherent weight transfer and foot placement; seamless loop without pivot drift. |
| Sword windup | Clear anticipation matching the existing attack preparation interval. |
| Sword contact | Readable sword action aligned with the existing active/contact window. |
| Sword recovery | Convincing return to readiness within the existing recovery interval. |
| Hurt | Recognizable reaction without adding stun, invulnerability or a gameplay delay. |
| Death | Clear, non-looping collapse/final pose without changing death, collision removal, loot or respawn timing. |

Deliver transparent frames, a labelled contact sheet, and an animated preview with both actual gameplay scale and enlarged inspection views. Show the sword phases together as one continuous attack as well as identifiable phase boundaries. Include a static comparison against the approved goblin sheet and a representative existing dungeon background. A preview must not replace gameplay assets or require a game-code change.

**Hard visual quality checkpoint:** stop after this preview. The user must approve its reference fidelity, readability, anatomy, palette/materials, alignment and motion before expanding directions, producing the adventurer or integrating assets. Automated checks do not replace that approval. If rejected, revise only this one-direction proof. Do not batch-generate the rest of the cast or launch a large implementation task.

## Frame and timing format

- Production frames: lossless RGBA PNG with real transparent background; no baked checkerboard, scene background, labels, reference-sheet borders or opaque matte.
- Use one fixed canvas size for all goblin frames, including the full sword reach and death pose. No per-frame auto-cropping or resizing. Choose and record dimensions from the approved reference and gameplay-scale preview; dimensions/frame counts are not claimed to have been agreed in the unavailable conversation images.
- Use a consistent ground/feet pivot, pixel scale, camera angle and orientation. Body movement within the frame is intentional animation, not canvas or origin drift. Include enough transparent padding to avoid clipping.
- Name frames deterministically, for example `goblin/<direction>/<clip>_000.png`, with contiguous zero-based indices. Keep clip names and direction names explicit.
- Supply a small manifest/table recording canvas dimensions, pivot coordinates, direction, ordered frame files, per-frame durations, loop/non-loop behaviour, and windup/contact/recovery boundaries. If an atlas is also supplied, use uniform cells and record rows/columns, padding and frame order; individual PNGs remain inspectable.
- Determine durations from the unchanged iteration-03 gameplay state/timing values before previewing. Document that mapping; do not invent new combat timings or change the simulation to suit frame counts. Use frame holds or sampling within the existing phase durations.
- Gameplay remains the timing authority. Future rendering follows current simulation state; animation callbacks must not create extra damage, defer contact, alter attack availability or govern death/respawn. Hurt/death presentation must accommodate existing transitions.
- Inspect transparency edges, temporal consistency, equipment/hand continuity, loop seams, clipping and foot alignment. Do not mirror asymmetric equipment blindly.

## Milestone B — four-direction goblin

Only after explicit Milestone A approval and a separate request: extend the approved goblin to four directional views with the same clips, quality, scale, anchor and timing contract. Record their mapping to the existing facing vectors; do not change movement, aim, attack arcs or lock-on mechanics to match the art. Review directional transitions and consistency before any separately authorized minimal visual integration. No eight-direction expansion in this milestone.

## Milestone C — adventurer

Only after the goblin milestone is accepted and separately requested: apply the same approved art and frame workflow to the adventurer, consistent with its approved concept sheet. Cover idle, movement, sword phases, bow draw/release/recovery, hurt and death as required by existing player states. Retain gamepad-first free movement, facing/target tracking and finite ammunition. Bow release must coincide with existing projectile creation, never a new timing invented for animation. Confirm directional scope and preview quality before expanding production.

Optional effects come **last**, after both character milestones are accepted, and only when requested. Effects must remain cosmetic and must not obscure contact readability, visibility or targeting. No effects pipeline or new combat feature in this preparation.

## Preservation contract

Keep Godot **4.5.2 stable** and all existing simulation behaviour unchanged:

- All combat timings, attack windows, cooldowns, recovery, damage/resolution, projectile speed/release, ammunition, health, death, loot and respawn/reset semantics.
- Collision footprints, navigation clearance and doorway fit remain independent of sprite canvas, sword extent and visual height. No new root motion or collision derived from art.
- Dungeon geometry/art, doors, rooms/corridors, chests, secret, discovery/current sight, opaque scenery, remembered layout and entrance escape.
- Target eligibility, HUD/markers and silhouettes must never reveal unseen actors. New frames obey existing visibility and draw order.
- Guard/mobile AI, perception, pursuit, search and blocked-route behaviour.
- Creature-neutral spike/arrow traps and their warning/contact/cooldown timing.
- Pause ownership, frozen simulation/timers, menu input consumption, restart confirmation and controller/keyboard bindings. Future animation playback must also freeze correctly.
- No new species, RPG/progression, inventory, lighting, procedural generation, framework work or historical-prototype imports.

## Acceptance and validation

### Preparation acceptance

- [ ] Branch starts at the exact completed iteration-03 tip recorded above.
- [ ] Only `docs/ITERATION_04.md` is added; no art, code, scene, resource or project-setting changes.
- [ ] Specification commit is published on `iteration-04`; `main` remains unchanged.
- [ ] Final report provides commit SHA and a bounded Milestone A handoff.

Verify the remote parent, changed-file list and branch refs. No runtime test rerun is needed for this documentation-only preparation, and no art validation is claimed.

### Milestone A acceptance gate

- [ ] Approved source sheets are available and provenance is recorded.
- [ ] Exactly one goblin direction contains every required clip, with real transparency and consistent canvas/pivot.
- [ ] Reference comparison demonstrates the approved gritty identity at gameplay scale.
- [ ] Loops and transitions are coherent; no flicker, unintended scale drift, clipping or equipment mutation.
- [ ] Sword anticipation, contact and recovery visibly map to the existing timings.
- [ ] Contact sheet, animated playback, timing manifest and dungeon-background comparison are supplied.
- [ ] User explicitly approves visual quality; approval/revision notes are recorded before B or integration.

### Later integration regression requirements

Reuse the existing suites; do not weaken assertions to accommodate new art. Before and after any separately authorized integration, run Godot 4.5.2 import validation and the existing suites:

```text
godot --headless --editor --path . --quit
godot --headless --path . --fixed-fps 60 --script res://tests/encounter_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/iteration_02_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/iteration_03_test.gd
godot --headless --path . --fixed-fps 60 --script res://tests/visibility_pause_test.gd
godot --path . --fixed-fps 60 --script res://tests/iteration_03_visual.gd -- <output-directory>
git diff --check
```

The iteration-03 record reports 40 combat, 112 Iteration 02, 50 Iteration 03 and 29 visibility/pause checks passing. These are historical results, not tests run for this preparation.

Use matched before/after captures at the same viewport, camera, actor positions and simulation phases. Compare start room, open aperture, corridor/bend, remembered and unseen space, secret, chest states, traps, entrance/escape and pause/confirmation. Inspect actor scale, feet/ground placement, weapon reach versus actual contact, Y-sort/occlusion, target/health markers and information leaks. Add focused preview captures of each animation phase and direction, including a mid-action pause/resume; no broad test framework is required.

Record actual commands/results and inspect rendered output, not just import success. Human review remains required for animation quality, controller feel and gameplay readability. Existing pending human playtesting from Iteration 03 is not implicitly signed off.

## Next bounded handoff

On `iteration-04`, read this specification and the repository guidance. Perform Milestone A only: obtain the approved concept sheets, produce one-direction goblin transparent aligned frames and previews for idle, walk, sword windup/contact/recovery, hurt and death, with provenance and unchanged timing mapping. Do not modify gameplay or integrate assets. Stop at the visual quality checkpoint for user review; do not start B, C or optional effects.
