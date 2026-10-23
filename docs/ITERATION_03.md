# Gauntlands — Iteration 03: Discovery, Pursuit and Dungeon Escape

## Objective

Plan a compact, hand-authored dungeon loop: explore about five rooms, discover connections, evade pursuing creatures, collect chest gold, survive traps and escape through the entrance.

**Status: implemented following separate authorization; visibility and pause refinement approved on 2026-10-23.** The original preparation was documentation-only. Acceptance boxes remain pending human playtesting; automated evidence is recorded in [validation](ITERATION_03_VALIDATION.md).

Use Godot 4.5.2 stable. Read [agent instructions](../AGENTS.md), [design baseline](../DESIGN.md) and [Iteration 02](ITERATION_02.md). Preserve existing art, free movement, combat timing, targeting, HUD, finite ammunition and gamepad-first controls except for the explicit changes below.

Base: completed iteration-02 commit `060a91288da3e63770d7f704478882a052662540`. Work on `iteration-03`; do not merge to main. Prior iteration documents remain historical contracts.

## 1. Dungeon layout

Use five rooms total as the planning default: four ordinary rooms including Room A, plus one secret room. Corridors are separate logical regions and do not count as rooms. This interprets the requested approximate room count without adding a sixth required room.

Suggested topology (placement may change to preserve readable scale):

- Entrance doorway leads outside from Room A.
- Room A connects through the existing bent corridor to Room B.
- Room B connects to Room C; Room C connects to Room D.
- A concealed connection from Room B leads to the secret room.
- Place a restored spike trap in Room C and one arrow trap along a corridor.
- Place an ordinary chest in Room D and a reward chest in the secret room.

Keep all ordinary rooms reachable and the return route to the entrance usable. No procedural generation, level transitions or larger campaign. Preserve Room A's Guard/Chaser distinction and the four existing goblins as the baseline population; additional enemies are optional tuning, not required scope. A large-creature test fixture can prove doorway exclusion without adding a new species.

## 2. Doors, discovery and visibility

Keep collision, traversability, line of sight, discovery and presentation separate.

- Ordinary doors start closed and retain F / gamepad Y interaction. Do not use E, which already cycles targets.
- Closed doors block movement, sight, melee contact and projectiles. Open doors allow these subject to physical clearance.
- An occupied doorway cannot close on a living actor.
- Initially discover Room A and its visible entrance/door faces only. Unexplored regions and their contents must not be exposed.
- Opening a door permits sight through its aperture; it does not reveal the whole connected dungeon or see around corridor bends.
- Discover connected space as the player obtains an unobstructed view or enters it. Remember discovered static layout until a full restart.
- Previously discovered space may remain dimly visible as remembered layout. Enemies, pickups and interactive state updates require current visibility; discovery memory is not live surveillance.
- Walls, closed doors and bends obstruct current visibility. No target lock, marker or outline may reveal an unseen enemy or secret room.
- Preserve opaque scenery. Structural occlusion and actor silhouettes must not bypass discovery or sight rules.

## 3. Enemy awareness, search and pursuit

Extend the existing direct sight-based pursuit only as needed for this dungeon.

- Unaware creatures acquire the player through unobstructed sight within their configured detection range; undiscovered status alone does not disable enemy simulation.
- Mobile creatures that see the player pursue through connected rooms/corridors and open doors when their collision footprint fits.
- On losing sight, retain the last observed player position, navigate toward it where reachable, search locally for a short configurable duration, then return to idle/home behaviour. Do not track the player's hidden live position.
- Reacquiring sight resumes pursuit. The stationary Guard remains stationary and uses its existing attack behaviour.
- Closed doors block pursuit. Automatic door opening, breaking doors, hearing and group alerts are deferred.
- Use actual doorway clearance and creature footprint, not sprite dimensions or player/enemy identity. Oversized creatures stop or use another valid open route; never clip or teleport through.
- If a door closes or the route becomes invalid, stop/replan or finish a bounded search. Do not push forever at a blocked threshold.
- Opening a connection later allows eligible creatures to pursue on renewed detection; crossing a room boundary must not reset awareness.

## 4. Entrance escape and restart

Represent the entrance with readable doorway posts and a nearby F / Y escape prompt. Spawn safely inside, outside automatic completion range; use explicit interaction so starting a run cannot immediately end it.

Escape is allowed while alive, including with zero gold, enemies alive or the secret undiscovered. On escape:

- End active play and display a clear escaped message and the gold collected this run.
- Freeze combat, enemy movement, trap timers and collection so the summary cannot change or the player die behind it.
- Offer Start / Menu and R to restart, matching existing controls.
- A full restart returns to Room A with initial HP/ammunition, zero gold, closed doors, undiscovered regions, hidden secret, unopened chests, restored enemies and rearmed traps.
- Clear projectiles, pickups, locks, awareness/search timers, pending respawns and the previous summary.

Death remains distinct from successful escape and retains restart. No town, bank, persistent currency or save system.

## 5. Chests and gold

Use the existing interaction prompt and F / Y action for nearby reachable chests. Do not interact through walls or closed doors.

- Closed and opened states must be visually distinct.
- Each chest grants a fixed, configurable positive gold amount directly to the existing run total, once per full run. Show concise feedback and update the HUD.
- Repeated or held interaction cannot duplicate rewards.
- Chest contents remain collected through enemy-only resets.
- Full restart restores chests and resets gold.
- Preserve existing goblin gold/arrow drops and automatic pickup behaviour.

No inventory, equipment, random loot tables, keys or chest minigames.

## 6. One secret room

Use one concealed door with a subtle nearby visual clue. Planning default: a nearby F / Y interaction reveals and opens it; no stat roll or new search command.

Before discovery, suppress the room, its contents, target markers and revealing prompts from outside the clue's immediate interaction range. Once opened, the connection follows ordinary visibility, collision and creature-clearance rules. The secret room is optional for escape and contains the reward chest. Full restart conceals it again; enemy-only reset does not.

## 7. Spike and corridor arrow traps

Restore spike-trap gameplay in the current 2D presentation; do not import old prototype architecture. Add one corridor arrow trap.

Both traps affect **any susceptible living creature**, including player and enemies, regardless of faction. Trigger eligibility and ability to suffer damage are distinct: determine physical contact and susceptibility explicitly, rather than assuming every enemy is immune or every overlap takes damage.

### Spike trap

A creature stepping onto the armed pressure area triggers a visible activation with a brief readable warning, an active spike window and a cooldown/rearm phase. Any susceptible creature contacting the raised spikes can be hurt, including one arriving after activation. Resolve at most one contact per creature per activation; standing on it cannot cause damage every frame. An occupant may trigger a later cycle after rearming. The active window, warning and cooldown are configurable.

### Corridor arrow trap

A pressure trigger fires one physical arrow down a readable corridor lane after a warning. The projectile uses swept collision, hits the first blocking surface/creature, and is consumed on contact or expiry. Walls and closed doors stop it. The triggering creature need not be the victim; another creature in the lane can be hit. Cooldown prevents frame-by-frame firing. Trap shots neither consume player ammunition nor grant recoverable ammunition in this pass.

### Damage contract and future compatibility

Use the existing separation of physical contact and damage resolution:

1. Establish a valid spike contact or arrow collision.
2. Check whether this target can be affected by this hazard.
3. Resolve a compact damage request containing source/hazard identity, target, damage kind and base amount.
4. Apply the resolved amount through the shared actor health/death path, preserving loot and death behaviour.

Default planning behaviour is deterministic damage for a susceptible physical trap hit, with modest configurable damage. Do not automatically apply the weapon attack accuracy roll to standing on spikes. Log physical misses, inapplicable/immune contacts and applied damage distinctly.

Leave a small resolution seam for a later RPG pass to introduce mitigation or other outcomes. Do not add attributes, classes, armour/resistance tables, saving throws, progression, character creation or a generic RPG framework now. Existing actors may all be susceptible; use a test fixture to prove an unaffected target takes no damage. Immunity does not imply a projectile passes through a physically blocking body.

## 8. Reset and preservation rules

The existing wall button remains an enemy-only reset: restore enemies and clear their awareness/search state while preserving player resources, discovery, door/secret/chest state and uncollected loot. Avoid respawning on the player, retain deferred spawns, and do not duplicate drops. Traps are not reset by this button; safely position authored spawns outside trap footprints.

Full restart resets the entire run as specified above. Trap deaths use the same one-drop-per-enemy-death rule as combat deaths.

## 9. Acceptance criteria

- [ ] Five-room default layout (including one secret) is traversable, with usable return route.
- [ ] Door opening reveals only legitimately visible connected space; bends/closed doors conceal what is beyond them.
- [ ] Discovered static layout persists, but unseen actors/items are not leaked by HUD, locks or silhouettes.
- [ ] Small mobile enemies pursue through open doors and around corridor bends.
- [ ] Oversized creatures cannot pass narrow doors; occupied doors cannot close.
- [ ] Losing sight leads to last-known-position search, not hidden-player tracking; reacquisition and blocked-route recovery work.
- [ ] Entrance interaction ends the run with stable gold summary, including a zero-gold escape.
- [ ] Chests grant gold once and obey interaction reach/visibility.
- [ ] Exactly one optional secret room remains concealed until revealed.
- [ ] Spike and arrow traps can damage susceptible players and enemies.
- [ ] Inapplicable/immune targets remain unharmed; trap damage is bounded per activation/projectile.
- [ ] Trap arrows collide with scenery/closed doors and do not consume player arrows.
- [ ] Full restart clears all new state; enemy-only reset preserves exploration/rewards.
- [ ] Existing combat, movement, art, ammunition, loot and controller bindings regressions pass.

## 10. Original implementation sequence

Historical handoff sequence from branch preparation; implementation was subsequently authorized.

1. Inspect the baseline and keep existing working systems.
2. Extend the hand-authored layout and minimal logical region/door connections.
3. Add discovery/current visibility and verify no information leaks.
4. Add bounded awareness/search/navigation and size-aware door traversal.
5. Add escape summary, chests and secret interaction using existing controls.
6. Add shared trap contact/damage handling, spike cycle and corridor projectile.
7. Integrate reset semantics and focused tests; complete [validation record](ITERATION_03_VALIDATION.md).
8. Stop at these acceptance criteria; leave the character/RPG pass for a separate iteration.

Tunable values (gold amounts, hazard damage/timing, sight/search distances) should be chosen during implementation/playtesting and recorded in validation. They do not authorize additional systems.

## 11. Approved visibility and pause refinement — 2026-10-23

- Discovery is persistent knowledge of static layout, reset only by a full restart.
- Current line of sight is geometric observation through open apertures, bounded by a configurable range. Walls, closed doors and bends block it. Memory never grants target eligibility, live HUD information or interactive state updates.
- Lighting is a separate brightness concern. This pass adds no light sources, falloff or light-dependent detection. Visible artwork keeps its existing brightness; remembered layout is dimmed independently.
- Use geometry-clipped current visibility rather than the original 16px cell mask. Update on player movement, door revision and range changes. Wall-art projection may reveal only an observed wall face; it must never grant gameplay sight behind that wall.
- Escape / Start / Menu and the HUD Pause button open a menu during active play. Resume returns to the same simulation state. Restart Run requires confirmation, initially focused on Cancel. R also requests confirmation during active play; R and Start retain direct restart on death/escape screens.
- Pausing freezes movement, combat phases, projectiles, damage, AI/search, traps, pickups and pending respawns. Menus remain responsive. Resume must not advance timers by paused wall-clock time or reuse a menu press as an attack.
- Controller menu navigation uses D-pad up/down, A to select, B to back/cancel. Keyboard uses arrow keys, Enter and Escape. Mouse buttons also work.
- Future inventory must acquire its own pause reason when opened and release it when closed. Simulation resumes only after all pause reasons clear. No inventory, equipment or item-management system is added here.
