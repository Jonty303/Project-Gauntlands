# Gauntlands — 2D reboot baseline

## Design thesis
Gauntlands should be **simple to read and deep to play**. It is a 2D dungeon explorer with consequential, Souls-like encounters: even an ordinary goblin should be threatening early on because health, ammunition and mistakes matter.

Combat combines **physical action** with **RPG resolution**. Position, range, collision and timing determine whether an attack can connect; character/enemy statistics then resolve the quality and consequence of that contact.

## Presentation baseline
- Godot 4.5.2, true 2D.
- Fixed 3/4 top-down pixel-art view.
- Visual target: chunky, highly legible dungeon architecture with near-square floor cells, substantial vertical wall faces and readable actor scale.
- Tone: grounded dark fantasy — cracked/irregular stone, damaged and stained masonry, restrained moss/damp, debris, rusty ironwork and wear. More detailed and grimy than clean retro dungeon tiles, but never so noisy that combatants disappear into the environment.
- Treat grid size as an authoring aid rather than a visual goal. Preserve the agreed proportions/readability rather than forcing artwork to look tiny because of a nominal 32 px grid.
- Smooth free movement over a tile-authored world; actors are not tile-step constrained.
- Prefer directional character animation rather than arbitrary rotation of pixel art. Continuous gameplay/targeting vectors are allowed.
- Scenery uses explicit draw order/Y-sorting where needed.

## Combat philosophy
Early numbers should remain deliberately compressed. A single low-tier enemy can kill an inexperienced character in only a few successful attacks. Progression should make familiar enemies more manageable without making carelessness irrelevant.

### Physical layer
- Sword attacks have a real range/arc/timing window and can miss because the enemy is not physically in the attack.
- Arrows are physical projectiles and can miss or strike scenery.
- Animation timing must correspond to gameplay timing; damage/projectile creation does not occur arbitrarily at button press.

### RPG layer
When a physically valid attack reaches a target, RPG statistics resolve the outcome and damage. The system should support outcomes such as hit, critical hit, dodge/block/glance or similar as mechanics evolve.

During development, expose the resolution pipeline in debug/combat output so tuning can distinguish a physical miss from a statistical outcome.

Keep the numerical scale compact unless playtesting proves otherwise.

## Target lock and movement
Target selection is separate from attacking.

- R3 / right-stick press: acquire an eligible target or release the current lock.
- Right-stick left/right while locked: cycle between eligible targets.
- A clear marker identifies the current target.
- When locked, the actor faces/tracks the target for combat presentation. Movement remains player-controlled and should support advancing, retreating/backpedalling and lateral repositioning around the target.
- When unlocked, movement/facing returns to normal free movement.
- Attacks use the current target as intent/assistance but still obey physical range, collision and attack timing. Lock-on must not guarantee a hit.
- Keyboard development controls must provide equivalents for lock/unlock and target cycling.

## Weapons and resources
The initial proof uses a sword and bow.

- Sword: close-range attack with visible wind-up/swing/recovery and a defined contact window.
- Bow: visible draw/raise, release and recovery; create the arrow at the release moment.
- Arrows are a limited resource. Firing consumes one arrow. Do not silently provide unlimited ammunition.
- Exact final equipment/input architecture remains open; Iteration 01 controls may be prototype mappings and must not over-engineer a permanent weapon framework.

## Death and encounter reset
Rapid iteration is part of the game-development loop.
- Player death must not require closing/relaunching the game. Provide an in-game restart action and controller/keyboard restart input.
- Test enemies may respawn independently after a short delay so combat can be repeated without reloading the scene.

## Occlusion and readability
Occlusion is a readability problem, not a reason to make the environment transparent.
- Player: when genuinely obscured by foreground scenery, show a restrained outline/silhouette on an overlay above the occluder.
- Current combat target may receive the same treatment while legitimately known/trackable.
- Unknown/unseen enemies must never be revealed merely because an outline system exists.
- Required interactables must not be accidentally hidden by unavoidable structural foreground/south-wall occlusion.
- Deliberate concealment behind discrete props is allowed.
- Keep occluding spans modest.

Occlusion mechanics are not required in Iteration 01 because that room deliberately contains no pillars/doors/large foreground props.

## World model
The visual tilemap is not the whole dungeon model. Future generation should represent logical rooms, corridors and door connections separately from rendered tiles. Discovery, enemy perception/LOS, collision/navigation and visual occlusion remain independent concerns.

## Current milestone
On `iteration-03`, the planned milestone is defined in [Iteration 03](docs/ITERATION_03.md), based on completed Iteration 02. It covers a compact five-room dungeon, discovery, size-aware pursuit, entrance escape, chests, one secret room and creature-neutral traps.

This preparation changes documentation only. Gameplay implementation requires a separate request. Preserve the existing combat and presentation baseline; the character/RPG expansion, procedural generation, inventory, town, save systems and Codex remain deferred. Trap damage should preserve physical-contact/resolution separation without introducing new RPG systems.

## Longer-term progression
The player should gain power both through character progression and through knowledge of enemies. The planned Codex can eventually expose learned weaknesses, behaviours and increasingly precise statistics, but the Codex itself is deferred.

## Historical prototypes
Older branches are retained as learning/reference material. Do not copy their architecture wholesale. In particular, 3D cutaway/transparency/portal-rendering solutions solve problems the 2D reboot intentionally avoids.
