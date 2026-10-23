extends SceneTree

var arena
var failures := 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	# Startup may run several catch-up physics ticks in one rendered frame.
	# Give injected input a frame boundary before counting its physics ticks.
	await process_frame
	key(code, true)
	Input.flush_buffered_events()
	await process_frame
	await frames(2)
	key(code, false)
	await frames(2)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	await frames(3)
	for extra in arena.goblins.slice(2):
		extra.set_physics_process(false)
	var player = arena.player
	var guard = arena.goblins[0]
	var chaser = arena.goblins[1]
	check(arena.goblins.size() == 4 and player.hp == 12 and arena.arrows == 10, "initial encounter / four goblins")
	# Keep AI out of the way while exercising actual input and physics.
	guard.set_physics_process(false)
	chaser.set_physics_process(false)
	await tap(KEY_L)
	check(player.targeting.target != null, "keyboard lock acquires")
	var first = player.targeting.target
	await tap(KEY_E)
	check(player.targeting.target != first, "cycle right selects other living goblin")
	await tap(KEY_Q)
	check(player.targeting.target == first, "cycle left reverses deterministically")
	await tap(KEY_L)
	check(player.targeting.target == null, "keyboard lock toggles off")
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_RIGHT_STICK
	joy.pressed = true
	Input.parse_input_event(joy)
	await frames(2)
	check(player.targeting.target != null, "R3 input mapping acquires lock")
	joy.pressed = false
	Input.parse_input_event(joy)
	await frames(2)
	var selected = player.targeting.target
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_RIGHT_X
	stick.axis_value = 1.0
	Input.parse_input_event(stick)
	await frames(2)
	check(player.targeting.target != selected, "right-stick cycle mapping")
	await frames(15)
	check(player.targeting.target != selected, "held cycle does not repeat every frame")
	stick.axis_value = 0.0
	Input.parse_input_event(stick)
	await frames(2)
	player.targeting.target = guard
	var before: Vector2 = player.position
	key(KEY_A, true)
	await frames(30)
	key(KEY_A, false)
	await frames(2)
	check(player.position.x < before.x - 45 and player.facing.dot(player.position.direction_to(guard.position)) > 0.99, "free movement while locked preserves combat facing")
	key(KEY_A, true)
	await frames(150)
	key(KEY_A, false)
	await frames(2)
	check(player.position.x >= 54.5, "west wall contains feet footprint")
	key(KEY_W, true)
	await frames(150)
	key(KEY_W, false)
	await frames(2)
	check(player.position.y >= 86.5, "north wall collision")
	key(KEY_D, true)
	await frames(310)
	key(KEY_D, false)
	await frames(2)
	check(player.position.x <= 585.5, "east wall collision")
	key(KEY_S, true)
	await frames(170)
	key(KEY_S, false)
	await frames(2)
	check(player.position.y <= 345.5, "south wall prevents foreground occlusion")
	arena.restart_encounter()
	var analogue := InputEventJoypadMotion.new()
	analogue.axis = JOY_AXIS_LEFT_X
	analogue.axis_value = 0.5
	Input.parse_input_event(analogue)
	before = player.position
	await frames(30)
	var analogue_distance: float = player.position.x - before.x
	check(analogue_distance > 17 and analogue_distance < 24, "left stick produces proportional analogue movement")
	analogue.axis_value = 0.0
	Input.parse_input_event(analogue)
	await frames(2)
	arena.restart_encounter()
	player.position = Vector2(200, 200)
	player.facing = Vector2.LEFT
	await tap(KEY_J)
	await frames(45)
	check(arena.roll_count == 0 and guard.hp == 7 and chaser.hp == 7, "physical sword miss never rolls RPG")
	guard.position = Vector2(227, 200)
	player.facing = Vector2.RIGHT
	await tap(KEY_J)
	await frames(45)
	check(arena.roll_count == 1, "one sword contact rolls exactly once per defender")
	guard.position = Vector2(173, 200)
	player.facing = Vector2.RIGHT
	var rolls: int = arena.roll_count
	await tap(KEY_J)
	await frames(45)
	check(arena.roll_count == rolls, "target behind sword arc receives no roll")
	# Start in range but retreat before active window.
	guard.position = Vector2(227, 200)
	player.begin_attack("sword")
	await frames(7)
	guard.position = Vector2(280, 200)
	await frames(40)
	check(arena.roll_count == rolls, "range rechecked at contact, not attack start")
	arena.restart_encounter()
	player.position = Vector2(200, 156)
	player.facing = Vector2.RIGHT
	await tap(KEY_K)
	check(arena.arrows == 10 and arena.projectiles.get_child_count() == 0, "bow windup does not fire immediately")
	await frames(20)
	check(arena.arrows == 9 and arena.projectiles.get_child_count() == 1, "bow release spawns projectile and consumes one arrow")
	await frames(70)
	check(arena.roll_count == 1 and arena.projectiles.get_child_count() == 0, "swept arrow contacts guard and is removed")
	player.facing = Vector2.LEFT
	rolls = arena.roll_count
	for shot in range(9):
		await tap(KEY_K)
		await frames(45)
	await frames(60)
	check(arena.arrows == 0 and arena.roll_count == rolls, "ten-arrow limit; wall misses do not roll")
	await tap(KEY_K)
	await frames(45)
	check(arena.arrows == 0 and arena.projectiles.get_child_count() == 0, "zero ammunition prevents projectile")
	player.targeting.target = guard
	guard.take_damage(99)
	check(guard.hp == 0 and guard.collision_layer == 0 and player.targeting.target == chaser, "death disables collision and advances selected target")
	chaser.take_damage(99)
	check(player.targeting.target == null, "last target death clears lock")
	guard.set_physics_process(true)
	chaser.set_physics_process(true)
	await frames(310)
	check(guard.hp == 0 and chaser.hp == 0, "no automatic respawn after five seconds")
	arena.request_respawns()
	check(guard.hp == 7 and chaser.hp == 7, "explicit reset restores goblins")
	arena.restart_encounter()
	guard.set_physics_process(false)
	var chaser_start: Vector2 = chaser.position
	await frames(60)
	check(chaser.position.distance_to(chaser_start) < 56 and chaser.position.distance_to(chaser_start) > 50, "chaser speed 54 versus player 110")
	chaser.set_physics_process(false)
	guard.set_physics_process(true)
	player.position = guard.position + Vector2(0, 27)
	rolls = arena.roll_count
	await frames(20)
	check(arena.roll_count == rolls, "goblin windup precedes contact")
	await frames(20)
	check(arena.roll_count == rolls + 1, "goblin active window resolves one contact")
	await frames(20)
	check(arena.roll_count == rolls + 1, "goblin recovery cannot deal continuous overlap damage")
	# Escape a later telegraphed swing.
	await frames(22)
	player.position += Vector2(0, 90)
	rolls = arena.roll_count
	await frames(65)
	check(arena.roll_count == rolls, "escaping windup causes physical goblin miss")
	check(guard.position == guard.spawn_point, "guard remains stationary")
	# Exercise the mobile goblin's own approach -> windup -> contact -> recovery
	# sequence until actual combat damage kills the player.
	arena.restart_encounter()
	guard.set_physics_process(false)
	chaser.set_physics_process(true)
	chaser.position = player.position + Vector2(60, 0)
	await frames(50)
	check(chaser.state == "sword" and chaser.position.distance_to(player.position) >= 20.0, "chaser approaches then stops for a telegraphed swing")
	await frames(420)
	check(player.hp == 0 and player.state == "dead", "ordinary goblin combat can kill the player")
	chaser.set_physics_process(false)
	arena.restart_encounter()
	player.take_damage(99)
	var dead_position: Vector2 = player.position
	await tap(KEY_J)
	key(KEY_D, true)
	await frames(10)
	key(KEY_D, false)
	check(player.state == "dead" and player.position == dead_position, "death suppresses movement/combat input")
	# Dirty every transient field before exercising the actual restart input.
	var stray = load("res://scripts/arrow.gd").new()
	stray.arena = arena
	stray.position = Vector2(300, 300)
	arena.projectiles.add_child(stray)
	guard.take_damage(99)
	await tap(KEY_R)
	check(player.hp == 12 and player.position == player.spawn_point and arena.arrows == 10, "keyboard restart restores player HP/position/ammunition")
	check(guard.hp == 7 and chaser.hp == 7 and player.targeting.target == null and arena.projectiles.get_child_count() == 0 and arena.roll_count == 0, "restart restores enemies and clears targets/projectiles/combat rolls")
	guard.set_physics_process(false)
	chaser.set_physics_process(false)
	player.take_damage(99)
	joy.button_index = JOY_BUTTON_START
	joy.pressed = true
	Input.parse_input_event(joy)
	await frames(2)
	joy.pressed = false
	Input.parse_input_event(joy)
	await frames(2)
	check(player.hp == 12, "controller Start restarts after death")
	for index in range(20):
		arena.log_event("bounded log test %d" % index)
	check(arena.events.size() == 6, "combat log bounded to six events")
	arena.restart_encounter()
	player.targeting.target = guard
	await frames(2)
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png(OS.get_environment("TEMP") + "/gauntlands-iteration01.png")
		check(result == OK, "rendered encounter screenshot saved")
	print("COMBAT REGRESSION TEST RESULT: %d failures" % failures)
	quit(1 if failures > 0 else 0)
