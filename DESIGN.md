# Gauntlands — 2D reboot baseline

## Design thesis
Gauntlands should be **simple to read and deep to play**. Mechanical interaction, exploration, enemy behaviour and meaningful dungeon decisions matter more than rendering complexity.

## Presentation baseline
- Godot 4.5.2, true 2D.
- Fixed 3/4 top-down pixel-art view with a darker, grimier fantasy tone rather than a cute aesthetic.
- 32x32 px base design grid initially. Re-evaluate only after testing real combat scale.
- Smooth free movement over a tile-authored world; do not constrain actors to tile steps.
- Prefer 8-direction character animation. Targeting and projectile vectors may be continuous.
- Scenery uses Y-sort/draw order to create depth.

## Occlusion and readability
Occlusion is a readability problem, not a reason to make the environment transparent.

- Player: when genuinely obscured by foreground scenery, show a restrained outline/silhouette on an overlay above the occluder.
- Current combat target: may receive the same treatment while it remains legitimately known/trackable.
- Unknown or unseen enemies: never reveal them merely because the outline system exists.
- Required interactables (keys, chests, mandatory levers/buttons, exits and similar) must not be accidentally hidden by unavoidable structural foreground/south-wall occlusion.
- Deliberate concealment behind a discrete prop such as a pillar, rock, statue or bookcase is allowed and can be used for secrets/exploration.
- Keep occluding spans modest; an outline is a fallback for readability, not permission to cover the player for long periods.

## Controls and combat direction
- Controller is the primary design target; keyboard is a development-equivalent input method.
- Left stick / WASD: movement.
- Combat remains real-time.
- Intended targeting model from the prototype: a visible/eligible enemy can receive a lock; pressing/holding attack commits facing/attacks to the selected target; shoulder inputs can cycle targets; target transitions must remain predictable.
- RPG hit/miss/crit and weapon behaviour can exist beneath the action presentation.
- Do not implement the full combat system until movement and room scale feel correct.

## World model
The visual tilemap is not the whole dungeon model. Future dungeon generation should represent logical rooms, corridors and door connections separately from their rendered tiles. Discovery, enemy perception/LOS, collision/navigation and visual occlusion remain independent systems.

## First milestone: 2D Combat Room
Build this progressively rather than all at once:
1. One hand-authored room, player, walls/collision and camera. Make movement feel correct first.
2. Add one goblin and targeting/attack/damage/death.
3. Add a second room, door and discovery/visibility behaviour.
4. Add an occluding pillar and prove Y-sort plus actor outline behaviour.
5. Add one trap/chest/interactable.

The milestone is successful when this tiny space is enjoyable and readable. Only then expand into procedural generation, inventory, town, codex and broader progression.

## Explicitly deferred
- Procedural dungeon generation
- Inventory/equipment UI
- Town systems
- Save/progression architecture
- Codex
- Large loot tables
- Character creation
- Elaborate lighting
- Content-scale enemy/weapon production

## Historical prototypes
Older branches are retained as learning/reference material. Do not copy their architecture wholesale. In particular, 3D cutaway/transparency/portal-rendering solutions solve problems the 2D reboot intentionally avoids.
