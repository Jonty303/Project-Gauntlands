# Project Gauntlands — agent instructions

## Authority and scope
- Target **Godot 4.5.2 stable** unless a task explicitly changes the engine target.
- `main` is the authoritative 2D reboot. Do not migrate code from older 2D/2.5D/3D experiment branches unless the task explicitly asks for it.
- Historical prototypes are reference material, not dependencies. The final 3D architecture prototype is preserved at `archive/prototype-3d-final`.
- Read `DESIGN.md` before changing gameplay architecture or presentation rules.
- For the current combat-room pass, `docs/ITERATION_01.md` is the authoritative implementation contract. Implement its acceptance criteria and stop; do not expand into later milestones.
- Work only on the requested feature. Avoid unrelated refactors, speculative systems and broad rewrites.

## Product direction
- True **2D**, fixed 3/4 top-down presentation. Do not solve presentation with a 3D camera or 3D geometry.
- Pixel-art visual language with the proportions and grimy 3/4 dungeon direction defined in `DESIGN.md`; do not force the artwork to look tiny merely to satisfy a nominal grid size.
- World authoring may be tile/grid based, but actor movement is **free**, not tile-step movement.
- **Gamepad-first** controls; keyboard mirrors controller controls for development.
- Prefer 8-direction actor presentation. Gameplay vectors may remain continuous; do not arbitrarily rotate character pixel art.
- Use Y-sorting/explicit 2D draw order for scenery depth.
- Occluding scenery stays opaque. Preserve actor readability with a dedicated higher-layer outline/silhouette system when appropriate; do not reintroduce the 3D transparency/cutaway approach.
- Avoid accidentally placing required interactables in structurally occluded foreground/south-wall areas. Deliberate prop-based concealment (for example a switch behind a pillar or rock) is valid level design.

## Architecture
- Keep simulation/gameplay state separate from visuals wherever practical.
- Prefer small reusable scenes/components and data-driven Resources for weapons, enemies, loot and interactables when those systems are introduced.
- Keep collision, navigation, line of sight, discovery and rendering/occlusion as separate concerns.
- Dungeon topology should eventually understand rooms, corridors and doors as logical regions/connections rather than only painted tiles.
- Do not build procedural generation until the hand-authored combat-room milestone proves room scale, movement and combat readability.
- Avoid premature framework building. Introduce abstractions when the current milestone needs them.

## Iteration discipline
- Implement one bounded gameplay/design change per iteration wherever practical.
- Inspect relevant files before editing and preserve established behaviour unless the task explicitly changes it.
- Prefer the smallest implementation that proves the design question.
- Do not add inventory, town, save systems, codex, loot tables, character creation or elaborate lighting during the initial combat-room milestone unless explicitly requested.
- Keep commits small and descriptive.

## Validation
- Validate changed GDScript before committing.
- Minimum project validation after code/scene changes:
  `godot --headless --editor --path . --quit`
- Run the narrowest relevant automated tests first when tests exist; run broader checks only when shared systems changed.
- Never claim a test was run if it was not.
- Report changed files, validation actually performed, results and remaining risks.
