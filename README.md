# Project Gauntlands

Gauntlands is a Godot 4.5.2 top-down 2D action-RPG project.

The current main branch is the clean 2D reboot. Earlier prototypes remain preserved on archive/experiment branches, including `archive/prototype-3d-final`.

## Iteration 01 — Two-Goblin Combat Room

Two stone rooms connected by an L-shaped corridor, with framed doors at both
ends. Room A retains the stationary Guard and slower Chaser; the corridor and
Room B each contain another mobile goblin. Existing actor art, attack timing,
movement and controls are preserved.

Approach doors or the brass wall button on Room A's north wall and press F / Y.
Doors cannot close on living actors. Closed doors and walls block movement,
arrows, sword contacts and sight/target eligibility. Goblins only pursue when
they can see the player; no advanced pathfinding or discovery system is added.

Each death drops one stack: 50% five gold, 50% one to three arrows. Walk within
18px to collect it. The wall button resets all enemies, preserves loot and
resources, and defers any spawn within 24px of the player until clear.
Dead enemies never automatically respawn. Start / R starts a new encounter,
resetting gold, ammunition, doors, loot, enemies and transient combat state.
Starting ammunition is exported on the encounter, defaulting to 10 arrows.

### Controls

| Action | Controller (Xbox names) | Keyboard |
| --- | --- | --- |
| Move | Left stick | WASD |
| Sword | A (bottom face button) | J |
| Bow | X (left face button) | K |
| Lock / unlock | R3 (right-stick click) | L |
| Previous / next target | Right stick left / right | Q / E |
| Interact with door / wall button | Y (top face button) | F |
| Reset encounter, including after death | Start / Menu | R |

Tap sword/bow for one attack. Holding a target-cycle direction switches once;
return the stick to centre before switching again. Locking selects the nearest
visible living goblin; cycling follows stable enemy order. Selected target death
selects the other living goblin, but never starts an attack automatically.
Unlocked attacks follow movement facing; locked attacks face the target while
allowing movement/backpedalling. Arrows travel straight and never home.

### Timing and combat diagnostics

Player sword: 0.24s windup, 0.14s contact window, recovery to 0.68s.
Goblin sword: 0.50s windup, 0.14s contact window, recovery to 1.30s.
Melee contacts require centres within 34px and a 130-degree forward arc, and
resolve only once per defender per swing. Goblins begin swings within 31px and
commit their facing during windup so moving away can evade them.
Bow releases at 0.32s, recovers at 0.72s and consumes one of ten starting arrows on
release. Projectiles travel at 290px/s, using swept collision checks against
walls and living goblins.

Only valid physical contacts roll `d20 + 5` against defence 11 (goblin) or 10
(player). A failed roll is a dodge. Hits deal 2–4 player damage or 3–4 goblin
damage; natural 20 adds one critical damage. Each restart reseeds the local RNG
to 101 for reproducible tuning; physical misses never advance the RNG.
HP defaults are player 12 / each goblin 7. Dead goblins stop colliding and
remain dead until the wall button is used. Restart clears the whole encounter.

The HUD displays health, ammunition, target, actor states, gold
and the last six events. Full events also print to Godot's output. The original
art uses four facing rows with discrete idle, walking, sword, bow, hurt and death
poses; see [asset provenance](assets/ATTRIBUTION.md).

Run the project in Godot 4.5.2 or use:

```sh
godot --path .
```

Validate project import/GDScript with:

```sh
godot --headless --editor --path . --quit
```

Run deterministic encounter checks (real physics ticks and injected keyboard /
controller events; no controller hardware required):

```sh
godot --headless --path . --script res://tests/encounter_test.gd
godot --headless --path . --script res://tests/iteration_02_test.gd
```

On restricted Windows hosts, use `--log-file` with a writable temporary path
if Godot cannot access its usual per-user log directory. Hardware controller
feel and visual combat readability still need a human playtest.
