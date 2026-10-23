# Gauntlands — Iteration 02: Rooms, Doors and Loot

## Objective

Extend the existing playable combat prototype with a second room, an L-shaped corridor, interactive doors, collectible loot, and an enemy respawn mechanism.

**Important:** Preserve the existing visual style, combat mechanics, controls, HUD and player behaviour. Do not redesign or replace working systems.

Use Godot 4.5.2 stable.

Before implementation, read `AGENTS.md`, `DESIGN.md` and the existing Iteration 01 specification.

## 1. Dungeon layout

Create a small dungeon consisting of:

- Two rectangular rooms.
- One L-shaped corridor connecting them.
- A door at each end of the corridor.
- Solid walls with collision.

The player starts in Room A.

### Enemy placement

- Preserve the two existing goblins in Room A, including their current behaviour.
- Add one goblin approximately halfway along the L-shaped corridor.
- Add one goblin in Room B.

Total: four goblins.

All enemies must use the existing combat and AI systems.

## 2. Doors

Each corridor entrance must have an interactive door.

**Appearance**

- A visible doorframe integrated into the wall.
- A distinct closed-door graphic.
- An identifiable open state.
- Match the existing grimy dark-fantasy pixel-art aesthetic.

Door swing animations are not required.

**Behaviour**

- Doors start closed.
- The player can interact with a door when nearby.
- Interaction toggles between open and closed.
- Closed doors block player movement, enemy movement, projectiles and line of sight.
- Open doors allow movement, projectiles and line of sight.
- Doors must not close while occupied by the player or an enemy.

Use a simple interaction prompt and a keyboard interaction key, preferably `E`, with an appropriate gamepad binding.

## 3. Goblin death and loot

When a goblin dies, it remains dead until explicitly respawned.

Each goblin drops exactly one loot stack, selected randomly:

| Loot type | Quantity |
|---|---|
| Gold | 5 pieces |
| Arrows | Randomly 1–3 |

Use an equal 50/50 probability between gold and arrows.

Loot should appear on the floor near the goblin's death location.

**Loot collection**

- Each drop is represented by a single visible pickup.
- Gold and arrows must be visually distinguishable.
- Loot is collected automatically when the player moves close enough.
- Gold increases the player's gold total.
- Arrows increase the player's available ammunition.
- A collected pickup disappears.
- A pickup must not be collectable more than once.

Do not implement a full inventory system yet.

## 4. Ammunition and gold tracking

Extend the existing HUD to show:

- Current HP / maximum HP.
- Available arrows.
- Total collected gold.
- Existing combat information.

Arrows are a consumable resource.

- Each successfully fired arrow consumes one unit of ammunition.
- A missed shot still consumes an arrow.
- Attempting to shoot with zero arrows must not create a projectile.
- Melee attacks remain available when ammunition is exhausted.
- Collecting arrows immediately replenishes the ammunition count.

Use a configurable starting ammunition value of **10 arrows**.

Gold and ammunition totals persist through enemy respawns, but reset when the player starts a new game.

## 5. Enemy respawn button

Place a visible, wall-mounted button in Room A, preferably near the starting area.

The button must:

- Be visually identifiable and accessible.
- Show an interaction prompt when the player approaches.
- Activate using the same interaction controls as doors.
- Respawn all four goblins at their original spawn locations.
- Restore their HP and reset their AI state.
- Allow repeated activation.

**Respawn rules**

- Living goblins are reset to their original spawn positions and full HP.
- Dead goblins are restored.
- Existing uncollected loot remains on the floor.
- Collected loot does not reappear merely because the button was pressed.
- Newly killed goblins generate new loot drops.
- Avoid spawning an enemy directly on top of the player; defer that individual respawn until its spawn location is clear.

Do not implement automatic enemy respawning.

## 6. Visual and interaction requirements

Maintain the established 3/4 top-down pixel-art presentation.

Doors, doorframes, loot and the wall button should be legible at normal gameplay zoom.

Avoid programmer-art placeholders in the final implementation. Follow the project's existing asset policy.

Maintain consistent collision boundaries, depth sorting and floor/wall alignment throughout both rooms and the corridor.

## 7. Acceptance criteria

The implementation is complete when:

- [ ] Player starts in Room A with the existing two goblins.
- [ ] An L-shaped corridor connects Room A to Room B.
- [ ] Both doors can be opened and closed.
- [ ] Both doors have clearly visible frames.
- [ ] Closed doors block movement, attacks and line of sight.
- [ ] The corridor goblin and Room B goblin function correctly.
- [ ] Dead goblins remain dead indefinitely until reset.
- [ ] Every goblin death creates exactly one gold or arrow stack.
- [ ] Loot can be collected once and updates the HUD.
- [ ] Firing arrows consumes ammunition.
- [ ] Ranged attacks cannot fire with zero ammunition.
- [ ] The wall button restores the goblins without resetting gold or arrows.
- [ ] Uncollected loot survives enemy respawns.
- [ ] Existing combat, targeting, movement and restart behaviour still works.

## 8. Implementation instructions

1. Inspect the current implementation and reuse existing systems.
2. Create `docs/ITERATION_02.md` containing this specification.
3. Implement in small, logical changes.
4. Avoid unrelated refactoring and architectural changes.
5. Run Godot headless import and script validation.
6. Run existing automated tests where available.
7. Add focused automated tests where practical for ammunition, loot and respawn state.
8. Report the files changed, validation results and anything requiring manual gameplay testing.

Do not begin Iteration 03 or add unrelated gameplay features.

**Target outcome:** A small, fully traversable dungeon in which the player can open doors, fight four goblins, collect gold and ammunition, and repeatedly reset the encounters using an in-world button.
