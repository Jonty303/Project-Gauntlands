# Iteration 01 — Two-Goblin Combat Room

## Status
**Authoritative implementation specification for the next Codex pass.**

Read `AGENTS.md` and `DESIGN.md` before implementation. Implement this document as one bounded vertical slice. Do not redesign the game or expand the scope.

## Goal
Replace the programmer-art movement test with the first recognisable Gauntlands combat sandbox: one visually convincing 3/4 top-down dungeon room, a properly animated player, two deliberately simple goblins, persistent target lock, sword and limited-ammunition bow combat, low/meaningful HP, RPG combat resolution, death/restart, enemy respawn and detailed combat diagnostics.

The design question is:

> Can one or two basic goblins already feel dangerous and readable while the player moves, locks targets, shoots from range and fights up close?

This is a **playtest harness**, not a production content system.

## Visual target

### Perspective and proportions
Use true 2D with a fixed 3/4 top-down view.

The target visual grammar is:
- near-square readable floor stones/cells;
- chunky masonry with substantial visible vertical wall faces;
- clear room boundary against dark/black exterior void;
- character scale large enough for equipment and attack animation to read;
- compact tactical room scale rather than a huge empty arena;
- free movement over the floor.

Do not use isometric diamond movement/geometry. Do not use 3D nodes/camera/geometry.

### Art direction
The room and actors should already look like a game rather than debug primitives:
- dark/grimy fantasy pixel art;
- irregular/cracked stone floor;
- worn/stained/damaged wall masonry;
- restrained moss/damp/dirt variation;
- muted palette with strong actor readability;
- goblins in ragged/crude equipment;
- player presented as a readable adventurer rather than a blob.

Avoid a clean/cute/mobile-cartoon aesthetic. Avoid excessive visual noise.

### Asset policy
Prefer suitable freely usable assets if they can be legally included in the repository and their licence permits redistribution/modification. Record source URL/name and licence in a small attribution file when attribution or provenance is relevant.

If no coherent suitable free set is immediately available, create simple original placeholder pixel art that follows the target proportions and palette. **Do not spend the iteration building an asset pipeline or browsing indefinitely for perfect art.**

Do not copy commercial-game artwork or unlicensed reference art.

## Room
Create one hand-authored rectangular/square dungeon room.

Required:
- proper stone floor artwork;
- substantial stone perimeter walls with collision;
- dark/black void outside the room;
- enough space to manoeuvre around two enemies while still feeling compact.

Explicitly absent:
- doors;
- pillars;
- chests;
- traps;
- secrets;
- multiple rooms;
- fog/discovery;
- procedural generation;
- elaborate lighting.

No important gameplay object should be hidden behind foreground wall art.

## Player

### Movement
- Smooth free analogue movement with left stick.
- WASD equivalent.
- Player must be clearly faster than the mobile goblin.
- Collision footprint should represent the feet/body position, not the entire visible sprite.
- Player remains within room collision.

### Presentation/animation
Provide readable states at minimum:
- idle;
- movement/walk;
- sword attack;
- bow attack;
- hurt/hit reaction if practical without expanding scope;
- death.

Directional presentation should be sufficient to make facing/attacking understandable. Prefer 8-direction if the chosen/created asset supports it cleanly; 4-direction plus mirroring is acceptable for this iteration if that produces a more coherent result. Do not rotate pixel character art continuously.

## Target lock
Implement target lock now because two enemies make it testable.

Required behaviour:
- R3/right-stick press toggles lock.
- If unlocked, R3 acquires an eligible living goblin.
- If locked, R3 releases the lock.
- Right-stick left/right cycles between living eligible goblins.
- Provide keyboard equivalents.
- Show a clear but restrained marker on the current target.
- Dead/respawning goblins cannot remain selected.
- If a selected goblin dies, select another living eligible goblin if one exists; otherwise clear the lock.
- Manual target switching must be deterministic.

When locked:
- combat facing tracks the selected target;
- player movement remains controlled by left stick/WASD;
- player can retreat/backpedal and move laterally while maintaining combat facing.

When unlocked:
- movement/facing behaves as normal free movement.

Lock-on is **not** an auto-hit system. Sword range and arrow trajectory still matter.

## Player weapons

### Sword
The player can make a close-range sword attack.

Requirements:
- visible wind-up/swing/recovery;
- attack has a defined active/contact window;
- only targets physically in valid melee range/arc during that window can be resolved as contacts;
- swinging out of range is a physical miss and deals no damage;
- prevent accidental repeated damage from one swing;
- movement during attack may be reduced/controlled if needed for readable animation, but do not freeze the entire game.

### Bow
The player can fire arrows.

Requirements:
- visible bow draw/raise, release and recovery;
- arrow projectile spawns at the release point in the animation, not immediately on initial button press;
- arrow travels physically through the room;
- arrow can miss;
- arrow is consumed when fired;
- begin each encounter/restart with a deliberately limited supply. Use **5 arrows** as the Iteration 01 default.
- HUD displays arrows remaining.
- when arrows reach zero, bow attack must not create another projectile.

The exact prototype buttons for sword/bow are implementation choices, but document them in the README/HUD. Do not create a large permanent weapon/equipment framework merely to support two test attacks.

## Combat resolution

### Principle
Resolve combat in two stages:
1. **Physical validity** — did the swing/projectile actually reach/intersect the target?
2. **RPG resolution** — given valid contact, what outcome/damage results from stats?

A physical miss must not roll as though contact occurred.

### Initial tuning
Use small integer values that make combat dangerous and easy to reason about. Starting values are tuning defaults, not lore:
- Player max HP: **12**
- Player starting arrows: **5**
- Each goblin max HP: **7**
- Player sword successful hit: roughly **2–4 damage**
- Player arrow successful hit: roughly **2–4 damage**
- Goblin successful hit: roughly **3–4 damage**

Implement a lightweight attack-vs-defence/random resolution sufficient to demonstrate RPG outcomes. Keep it inspectable and deterministic enough to debug. Do not build a full character-stat framework.

At minimum distinguish/log:
- physical miss;
- valid contact followed by RPG outcome;
- successful hit + damage;
- critical hit if implemented.

If implementing dodge/glance/block is straightforward, they may be represented as RPG outcomes, but do not expand the feature merely to add them.

## Goblins

There are exactly **two** goblins. They share basic combat mechanics but have deliberately different movement behaviour.

### Goblin A — Guard
- Stationary at its spawn point.
- Does not chase the player.
- Faces/reacts to the player as needed.
- If the player enters its melee attack range, it can attack.
- Uses the same HP/damage/RPG-resolution concepts as the other goblin.

Purpose: predictable test target for bow, sword range and combat resolution.

### Goblin B — Chaser
- Detects/engages the player and moves toward them.
- Movement speed must be **noticeably slower than the player**, so the player can create distance by moving well.
- Stops/positions appropriately to make a melee swing rather than simply overlapping the player.
- Attacks when in melee range.
- No advanced pathfinding/tactics are required in this empty room.

Purpose: test movement under pressure, retreating, ranged attacks and close combat.

### Goblin melee
At minimum:
- approach/idle as appropriate;
- readable attack wind-up;
- active swing/contact timing;
- recovery/cooldown;
- physical range check;
- RPG resolution after valid contact;
- death state.

Do not make goblin damage occur continuously merely because bodies overlap.

## Death, respawn and restart

### Goblin death
When either goblin reaches 0 HP:
- enter a visible death/dead state;
- stop attacking/colliding as a live combatant;
- remove it from target eligibility;
- after **5 seconds**, respawn that goblin independently at its original spawn position with full HP and normal behaviour.

One goblin's respawn must not depend on the other goblin dying.

### Player death
When player reaches 0 HP:
- enter a visible dead state;
- stop normal combat input;
- show an obvious restart prompt/control;
- allow restart by controller and keyboard without closing/relaunching the game;
- restart resets the encounter: player position/HP/arrows, both goblins at their original positions/full HP, target state and transient projectiles/combat state.

Do not require editor restart or application relaunch.

## HUD and combat diagnostics
Keep a development HUD visible during this iteration.

### Always-visible summary
Show at minimum:
- Player HP / max HP;
- arrows remaining;
- current lock target or `None`;
- Guard HP / max HP and current state;
- Chaser HP / max HP and current state.

Optional useful fields:
- player state;
- distance to current target;
- chaser distance to player;
- current attack/cooldown state.

### Combat event log
Show a small rolling text log of recent combat events. It should make the two-stage resolution observable.

Examples of the intended information:
- `Sword: PHYSICAL MISS`
- `Sword: contact -> attack 14 vs defence 11 -> HIT -> 3 damage`
- `Arrow: contact -> attack 9 vs defence 11 -> MISS/DODGE`
- `Chaser: swing contact -> HIT -> Player -4 HP`
- `Guard died; respawn in 5.0s`

Exact wording/roll formula may differ, but the log must expose enough information to tune and diagnose combat.

Keep the log bounded so it does not grow indefinitely.

## Architecture constraints
Keep this implementation intentionally small.

Good separation:
- actor health/combat state;
- player input/movement;
- target-lock selection;
- attack/projectile logic;
- goblin behaviour;
- HUD/debug presentation.

Reuse small components where it genuinely reduces duplication between the two goblins, but do not create a speculative general-purpose RPG framework.

Gameplay state must not depend on animation frame rate. Use explicit timing/state transitions/signals as appropriate.

## Explicit non-goals
Do **not** add:
- doors or additional rooms;
- pillars/occlusion-outline implementation;
- procedural generation;
- inventory/equipment UI;
- loot;
- town;
- Codex UI/system;
- save/load;
- character creation;
- levelling UI;
- advanced enemy tactics/pathfinding;
- traps/chests/interactables;
- fog of war/discovery;
- elaborate dynamic lighting;
- audio system;
- content-scale weapon/enemy abstractions;
- migration of old prototype code unless a tiny isolated idea is explicitly useful and cleaner than new code.

## Acceptance criteria
Iteration 01 is complete only when all of the following are true:

1. Project opens/runs under Godot 4.5.2 without parser/load errors.
2. The old blob/debug-square presentation has been replaced by a coherent 2D 3/4 dungeon room and recognisable animated player/goblins.
3. Player moves freely with controller and WASD and is visibly faster than the Chaser.
4. Exactly two goblins exist: stationary Guard and slower mobile Chaser.
5. R3 locks/unlocks; right-stick left/right can switch between both living goblins; keyboard equivalents work.
6. Current target is visibly marked.
7. Sword has visible attack timing and cannot damage a target outside its physical range/active swing.
8. Bow visibly releases a physical projectile and ammunition decreases from a default of 5.
9. No arrow is fired at zero ammunition.
10. Both goblins have readable melee attacks with timed contact rather than overlap damage.
11. RPG resolution occurs only after physically valid contact and the result is shown in combat diagnostics.
12. Player HP, arrows, target, both goblin HP/states and recent combat events are visible.
13. Either goblin can die and independently respawns at its own spawn point after 5 seconds.
14. Player can die and restart the whole encounter in-game without closing the application.
15. Restart restores player HP/arrows/position and both goblins and clears transient combat/projectile/target state.
16. No doors, pillars, procedural dungeon systems or other explicit non-goals have been added.

## Validation
Before committing:
1. Run:
   `godot --headless --editor --path . --quit`
2. Fix parser/resource-load errors.
3. Run the game if the environment permits and manually exercise the acceptance criteria that can be tested interactively.
4. Report exactly what was and was not tested.

## Codex completion report
When finished, respond with:
- concise summary of implementation;
- changed/added files;
- exact controls;
- asset provenance/licence, if external assets were used;
- validation commands actually run and results;
- acceptance criteria not manually verified;
- remaining known issues/risks.

Then **stop**. Do not start Iteration 02 or add speculative features.
