# Iteration 02 validation

Validated with Godot 4.5.2 stable (`6ce3de25a`) on Windows.

Commands (using `C:/Godot4/Godot_v4.5.2-stable_win64_console.exe` and
`--log-file` paths under `%TEMP%` on this host):

```text
godot --headless --editor --path . --quit
godot --headless --path . --script res://tests/encounter_test.gd
godot --headless --path . --script res://tests/iteration_02_test.gd
git diff --check
```

- Import/script validation: no parser or resource-load errors; exit 0.
- Existing combat suite, updated for ten arrows/four goblins/manual respawn:
  zero failures. Covers original keyboard/controller bindings, movement,
  collision, targeting, sword/arrow timing and physical/RPG separation,
  goblin combat, death and restart.
- Iteration 02 suite: zero failures. Covers both door states and occupancy,
  sight, melee/projectile blocking, physical player blocking, F/Y interaction,
  enemy perception/pursuit, one stack per death, both loot quantities,
  automatic single collection, resource preservation, button activation,
  deferred resets, new-game cleanup, and continuous corridor traversal.
- Rendered test run with `-- --capture`: screenshots inspected for Room A,
  corridor and Room B; original textures and actor sprites retained.
- Whitespace validation: passed.

Host limitations: Godot reports an inaccessible Windows root certificate store
and cannot save its per-user editor settings outside the writable workspace.
These host errors are separate from project import/script validation.

Manual playtesting remains necessary for controller feel, visual preference,
and combat balance across the larger layout. Automated controller events do
not replace a physical gamepad playtest. Enemies retain simple direct pursuit
with sight checks; advanced navigation around unseen corners is out of scope.

The pre-existing `.png.import` working-tree changes were not included.
No original image assets were modified. New art provenance is recorded in
`assets/ATTRIBUTION.md`.
