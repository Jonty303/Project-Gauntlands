# Project Gauntlands

Gauntlands is a Godot 4.5.2 top-down 2D action-RPG project.

The current main branch is the clean 2D reboot. Earlier prototypes remain preserved on archive/experiment branches, including `archive/prototype-3d-final`.

## Iteration 03 — Discovery, Pursuit and Dungeon Escape

Implemented on `iteration-03`, based on completed Iteration 02
(`060a91288da3e63770d7f704478882a052662540`). See the authoritative
[specification](docs/ITERATION_03.md) and [validation record](docs/ITERATION_03_VALIDATION.md).
Character/RPG progression remains deferred.

Four ordinary stone rooms and one optional secret room form a hand-authored
return-and-escape loop. Room A retains the stationary Guard and slower Chaser;
the bent corridor and Room B retain their goblins. Existing actor art, attack
timing, free movement, finite ammunition and control bindings are preserved.

Press F / Y near doors, chests, loose masonry or the entrance stairway. Opening
a door reveals only space in sight; bends and closed doors conceal the rest.
Explored static layout is remembered dimly; hidden creatures, pickups and
interactive state are not shown. Mobile goblins detect within 360px, pursue
through fitting open connections, search their last observation for 2.5s, then
return home where reachable. They do not open doors or track hidden movement.

Room D's chest grants 20 gold; the secret reward grants 35. Each pays once per
run. Room C has a spike plate; the bent corridor has an arrow pressure plate.
Both warn for 0.55s, have a 0.65s active phase and a 2.5s cooldown. Susceptible
players and enemies take 3 deterministic damage per activation/contact. Trap
arrows are physical projectiles and do not consume or restore ammunition.

The north entrance in Room A allows explicit escape while alive, even with no
gold or enemies remaining. The summary freezes the run and displays collected
gold. Start / R begins a fresh run, restoring exploration, doors, chests, secret,
traps, resources, actors and transient state. The brass wall button remains an
enemy-only reset and preserves exploration, rewards, doors, traps and loot.

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
| Interact / open chest / examine clue / escape | Y (top face button) | F |
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
godot --headless --path . --fixed-fps 60 --script res://tests/iteration_03_test.gd
```

On restricted Windows hosts, use `--log-file` with a writable temporary path
if Godot cannot access its usual per-user log directory. Hardware controller
feel and visual combat readability still need a human playtest.

Optional reproducible visual captures (requires a renderer and an existing
output folder):

```sh
godot --path . --fixed-fps 60 --script res://tests/iteration_03_visual.gd -- /absolute/output/folder
```
