extends SceneTree

var arena
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func frames(count: int = 3) -> void:
	for i in range(count):
		await physics_frame

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func joy(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func run() -> void:
	arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	await frames()
	var player = arena.player
	var menu = arena.pause_menu
	var door = arena.interactables[0]
	for actor in [player] + arena.goblins:
		actor.set_physics_process(false)
	player.position = Vector2(576, 224)
	door.set_open(true)
	await frames()
	arena.exploration.refresh()
	check(Geometry2D.is_point_in_polygon(Vector2(720, 224), arena.sight.polygon), "mask sees through open aperture")
	check(not Geometry2D.is_point_in_polygon(Vector2(784, 400), arena.sight.polygon), "mask does not wrap around bend")
	# Compare terrain geometry against exact observation around doorway edges.
	var leaks := 0
	for x in range(620, 820, 4):
		for y in range(180, 440, 4):
			var point := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(point, arena.sight.polygon) and not arena.point_visible(point):
				leaks += 1
	check(leaks == 0, "aperture mask samples never reveal blocked space")
	var missing_wall_cells := 0
	for x in range(640, 752, 4):
		if not arena.exploration.remembered.has(Vector2i(x, 180)):
			missing_wall_cells += 1
	check(missing_wall_cells == 0, "remembered north wall has no seams between collision tiles")
	var peeking_actor = arena.goblins[2]
	peeking_actor.position = Vector2(784, 264)
	check(not arena.point_visible(peeking_actor.position) and arena.actor_visible(peeking_actor) and peeking_actor in arena.eligible_targets(), "partly visible footprint can be seen and targeted at a bend")
	var memory_count: int = arena.exploration.remembered.size()
	door.set_open(false)
	await frames(1)
	arena.exploration.refresh()
	check(not Geometry2D.is_point_in_polygon(Vector2(720, 224), arena.sight.polygon), "door revision immediately removes live sight")
	check(not arena.actor_visible(peeking_actor) and peeking_actor not in arena.eligible_targets(), "closed door suppresses partial actor visibility and targeting")
	check(arena.exploration.remembered.size() >= memory_count, "closing door preserves static discovery")
	arena.exploration.memory_dim = 0.0
	check(not arena.point_visible(Vector2(720, 224)), "memory brightness cannot grant sight")
	arena.exploration.memory_dim = 0.55
	door.set_open(true)
	await frames()
	var previous: PackedVector2Array = arena.sight.polygon.duplicate()
	player.position += Vector2(0, 1)
	arena.exploration.refresh()
	check(previous != arena.sight.polygon, "one-pixel movement refreshes geometry without an 80ms timer")
	arena.sight.view_distance = 80.0
	arena.exploration.refresh()
	check(not arena.point_visible(Vector2(720, 224)), "configurable sight range remains independent of brightness")
	arena.sight.view_distance = 440.0
	arena.restart_encounter()
	await frames()
	check(not arena.exploration.remembered.has(Vector2i(704, 224)), "full restart forgets corridor discovery")
	await process_frame
	# Freeze real processing, not just an overlay, during an attack and trap cycle.
	for actor in [player] + arena.goblins:
		actor.set_physics_process(true)
	player.begin_attack("bow")
	player.elapsed = 0.2
	arena.traps[0].phase = "warning"
	arena.traps[0].elapsed = 0.2
	arena.goblins[1].awareness = "search"
	arena.goblins[1].search_left = 2.0
	var shot = load("res://scripts/arrow.gd").new()
	shot.arena = arena
	shot.position = Vector2(300, 300)
	arena.projectiles.add_child(shot)
	var drop = load("res://scripts/pickup.gd").new()
	drop.arena = arena
	drop.position = player.position
	arena.loot.add_child(drop)
	var pending = arena.goblins[3]
	pending.hp = 0
	arena.pending_respawns.append(pending)
	key(KEY_ESCAPE, true)
	Input.flush_buffered_events()
	check(paused and menu.panel.visible, "Escape opens the pause menu")
	var position_before: Vector2 = arena.goblins[1].position
	var search_before: float = arena.goblins[1].search_left
	var hp_before: int = player.hp
	var elapsed_before: float = player.elapsed
	var shot_before: Vector2 = shot.position
	var timer_before: float = arena.traps[0].elapsed
	var gold_before: int = arena.gold
	var ammo_before: int = arena.arrows
	key(KEY_ESCAPE, false)
	player.take_damage(3)
	arena.fire_arrow(player)
	await frames(90)
	check(player.hp == hp_before and player.elapsed == elapsed_before and arena.arrows == ammo_before, "pause freezes damage, attack phase and ammunition")
	check(arena.goblins[1].position == position_before and arena.goblins[1].search_left == search_before, "pause freezes AI movement and awareness timers")
	check(shot.position == shot_before and arena.traps[0].elapsed == timer_before, "pause freezes projectiles and trap timers")
	check(arena.gold == gold_before and pending.hp == 0 and pending in arena.pending_respawns, "pause freezes pickup collection and pending respawns")
	menu.request_restart()
	check(menu.confirming and player.elapsed == elapsed_before, "Restart Run requires confirmation")
	menu.resume_or_cancel()
	check(not menu.confirming and paused and menu.panel.visible, "cancel returns to the paused menu")
	# Inventory is a pause owner seam only; no inventory gameplay is introduced.
	menu.set_paused(&"inventory", true)
	menu.set_paused(&"inventory", false)
	await frames()
	check(paused, "closing inventory cannot release menu pause")
	menu.set_paused(&"inventory", true)
	menu.resume_or_cancel()
	await frames()
	check(paused, "closing menu cannot release inventory pause")
	menu.set_paused(&"inventory", false)
	await frames(4)
	check(not paused and player.elapsed > elapsed_before and player.elapsed < elapsed_before + 0.15, "last pause release resumes without a time jump")
	arena.restart_encounter()
	await frames()
	await process_frame
	joy(JOY_BUTTON_START, true)
	Input.flush_buffered_events()
	check(paused and menu.panel.visible and player.hp == 12, "controller Start pauses during active play")
	joy(JOY_BUTTON_START, false)
	await frames(3)
	# UI accept A shares the sword binding; it must not swing on resume.
	joy(JOY_BUTTON_A, true)
	Input.flush_buffered_events()
	await frames(3)
	joy(JOY_BUTTON_A, false)
	Input.flush_buffered_events()
	await frames(5)
	check(not paused and not menu.panel.visible and player.state != "sword", "controller Resume consumes the shared attack press")
	menu.open_menu()
	joy(JOY_BUTTON_DPAD_DOWN, true)
	Input.flush_buffered_events()
	joy(JOY_BUTTON_DPAD_DOWN, false)
	check(menu.restart_button.has_focus(), "controller D-pad navigates pause options")
	joy(JOY_BUTTON_A, true)
	Input.flush_buffered_events()
	joy(JOY_BUTTON_A, false)
	check(menu.confirming and menu.resume_button.has_focus(), "controller restart defaults confirmation to Cancel")
	joy(JOY_BUTTON_DPAD_DOWN, true)
	Input.flush_buffered_events()
	joy(JOY_BUTTON_DPAD_DOWN, false)
	joy(JOY_BUTTON_A, true)
	Input.flush_buffered_events()
	joy(JOY_BUTTON_A, false)
	await frames(4)
	check(not paused and arena.gold == 0 and arena.arrows == 10 and player.position == player.spawn_point, "confirmed menu restart restores the run")
	player.take_damage(99)
	key(KEY_ESCAPE, true)
	Input.flush_buffered_events()
	key(KEY_ESCAPE, false)
	await frames(2)
	check(player.hp == 0, "Escape on death screen cannot accidentally restart")
	joy(JOY_BUTTON_START, true)
	Input.flush_buffered_events()
	joy(JOY_BUTTON_START, false)
	await frames(4)
	check(player.hp == 12 and not menu.panel.visible, "Start retains restart on death screen")
	print("VISIBILITY / PAUSE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
