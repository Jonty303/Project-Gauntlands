# Combat Targeting V2

The next target is persistent while alive and within 450 units. When a
replacement is needed, select the nearest enemy in the 120-degree forward arc;
if that arc is empty, select the nearest enemy anywhere in range, including
behind the player. A new enemy entering the arc does not override a valid
selection. Overlapping enemies are eligible.

Q/E or the controller's left/right shoulder cycles the next target in angular
order, wrapping around. This works during an attack. A press commits that hold
to the selected enemy; subsequent cycling only changes the next selection.
The active enemy leaving selection range does not change the active commitment.
Its death or removal stops firing until release and repress, even if it respawns.
The next selection continues updating during a hold and after active-target death.
Starting a hold with no enemies retains the existing directional firing behaviour;
an enemy entering range becomes next without taking over that hold.

Gold inner ring and ACTIVE label identify the committed enemy. Cyan outer ring
and NEXT label identify the next selection. Both remain visible when they refer
to the same enemy.

The existing four goblins in main.tscn cover near, far, and flank positions;
their two-second respawn, projectile contact, RPG hit/miss/crit rolls, movement,
touch controls, and pose animation remain unchanged.

## Automated verification

With Godot 4.5.2 on PATH, from the repository directory:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/combat_targeting_test.gd
godot --headless --path . --quit-after 180
```

The test script exits nonzero on failed checks. It covers forward preference,
behind fallback, persistent selection, cycling during attacks, range changes,
death/removal/respawn, exhausted holds, release/repress, no-target firing,
overlapping enemies, movement/gait, projectile contact, 1000 seeded RPG rolls,
four scene goblins, and shoulder bindings.

In a restricted environment, add `--log-file <writable-absolute-path>`.

## Manual play check

1. Run the main scene. Move with WASD/arrows or the left stick; hold Space,
   left mouse, controller A, or the touch attack button.
2. Hold attack on A, cycle NEXT to B with E/right shoulder. Gold remains on A;
   cyan moves to B. Continue moving to check strafe/backpedal animation.
3. Let A die while still holding. Fire stops and B stays NEXT. Release/repress
   to attack B.
4. Let the shared active/next target die without cycling. Another living enemy
   becomes NEXT, including behind you, but firing stays stopped until repress.
5. Move a selected next enemy beyond 450 units; another eligible enemy becomes
   NEXT. Confirm both rings are visible when active and next coincide.

Headless checks cannot establish controller feel or visual readability; perform
the manual check in the editor before judging those.
