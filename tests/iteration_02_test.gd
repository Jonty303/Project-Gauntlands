extends SceneTree

var failures := 0
var arena

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func frames(count: int = 3) -> void:
	for i in range(count):
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	await frames()
	for g in arena.goblins:
		g.set_physics_process(false)
	var player = arena.player
	var door = arena.interactables[0]
	check(arena.goblins.size() == 4 and arena.arrows == 10 and arena.gold == 0, "four goblins and initial resources")
	for entry in [[arena.interactables[0], Vector2(580, 224), Vector2(636, 224)], [arena.interactables[1], Vector2(808, 512), Vector2(860, 512)]]:
		var gate = entry[0]
		check(not arena.clear_sight(entry[1], entry[2]), "closed door blocks sight")
		gate.activate()
		await frames()
		check(arena.clear_sight(entry[1], entry[2]), "open door passes sight")
		player.position = gate.position
		gate.activate()
		check(gate.opened, "player occupancy prevents closure")
		player.position = Vector2(224, 264)
		arena.goblins[0].position = gate.position
		gate.activate()
		check(gate.opened, "enemy occupancy prevents closure")
		arena.goblins[0].reset_actor()
		gate.activate()
		await frames()
		check(not gate.opened, "clear door closes")
	# Exercise actual interaction mappings and collision, not just direct methods.
	player.position = Vector2(576, 224)
	Input.action_press("move_right")
	await frames(30)
	Input.action_release("move_right")
	check(player.position.x < 594, "closed door physically blocks player")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F
	key.pressed = true
	Input.parse_input_event(key)
	await frames()
	key.pressed = false
	Input.parse_input_event(key)
	await frames()
	check(door.opened, "F interacts with nearby door")
	player.position = Vector2(576, 224)
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_Y
	joy.pressed = true
	Input.parse_input_event(joy)
	await frames()
	joy.pressed = false
	Input.parse_input_event(joy)
	await frames()
	check(not door.opened, "Y interacts with nearby door")
	var mobile = arena.goblins[2]
	mobile.position = Vector2(624, 224)
	player.position = Vector2(580, 224)
	mobile.set_physics_process(true)
	await frames(20)
	check(mobile.position == Vector2(624, 224), "closed door prevents enemy perception and pursuit")
	door.set_open(true)
	await frames(12)
	check(mobile.position.x < 624, "corridor goblin uses existing pursuit when door opens")
	mobile.set_physics_process(false)
	mobile.reset_actor()
	door.set_open(false)
	await frames()
	player.position = Vector2(592, 224)
	arena.goblins[0].position = Vector2(624, 224)
	player.facing = Vector2.RIGHT
	player.contacts.clear()
	arena.melee_contacts(player)
	check(arena.roll_count == 0, "closed door blocks melee")
	arena.fire_arrow(player)
	await frames(15)
	check(arena.projectiles.get_child_count() == 0 and arena.roll_count == 0 and arena.arrows == 9, "closed door absorbs arrow and spends ammunition")
	arena.arrows = 0
	arena.fire_arrow(player)
	check(arena.projectiles.get_child_count() == 0, "empty bow cannot fire")
	player.position = Vector2(224, 264)
	arena.goblins[0].reset_actor()
	arena.loot_rng.seed = 202
	var kinds: Dictionary = {}
	for i in range(40):
		var g = arena.goblins[0]
		g.reset_actor()
		var before: int = arena.loot.get_child_count()
		g.take_damage(99)
		g.take_damage(99)
		check(arena.loot.get_child_count() == before + 1, "one stack per death, duplicate damage ignored")
		var drop = arena.loot.get_child(-1)
		kinds[drop.kind] = true
		check(drop.quantity == 5 if drop.kind == "gold" else drop.quantity >= 1 and drop.quantity <= 3, "loot quantity within contract")
	check(kinds.size() == 2, "both loot types generated")
	var drops: int = arena.loot.get_child_count()
	arena.gold = 17
	arena.arrows = 2
	player.position = Vector2(224, 112)
	key.pressed = true
	Input.parse_input_event(key)
	await frames()
	key.pressed = false
	Input.parse_input_event(key)
	await frames()
	check(arena.loot.get_child_count() == drops and arena.gold == 17 and arena.arrows == 2, "respawn preserves floor loot and resources")
	for g in arena.goblins:
		check(g.hp == 7 and g.position == g.spawn_point and g.state == "idle", "reset restores enemy position HP and AI")
	var drop = arena.loot.get_child(0)
	var expected_gold: int = arena.gold
	var expected_arrows: int = arena.arrows
	for item in arena.loot.get_children():
		if item.kind == "gold":
			expected_gold += item.quantity
		else:
			expected_arrows += item.quantity
	player.position = drop.position
	await frames()
	check(arena.gold == expected_gold and arena.arrows == expected_arrows and arena.loot.get_child_count() == 0, "automatic pickup updates both totals once")
	arena.request_respawns()
	check(arena.pending_respawns.has(arena.goblins[0]), "occupied spawn defers individual reset")
	check(arena.loot.get_child_count() == 0, "collected loot does not return on reset")
	player.position = Vector2(224, 264)
	await frames()
	check(arena.pending_respawns.is_empty(), "deferred spawn completes once clear")
	arena.goblins[0].take_damage(99)
	check(arena.loot.get_child_count() == 1, "new death after reset creates new loot")
	arena.restart_encounter()
	check(arena.gold == 0 and arena.arrows == 10 and arena.loot.get_child_count() == 0 and not door.opened, "new game resets resources loot and doors")
	for g in arena.goblins:
		g.collision_layer = 0
		g.collision_mask = 0
	# Drive actual movement through both doorways and around the elbow.
	for gate in arena.interactables.slice(0, 2):
		gate.set_open(true)
	player.position = Vector2(560, 224)
	for leg in [["move_right", 122], ["move_down", 157], ["move_right", 100]]:
		Input.action_press(leg[0])
		await frames(leg[1])
		Input.action_release(leg[0])
		await frames()
	check(player.position.x > 900 and player.position.y > 480, "continuous traversal through L corridor into Room B")
	if "--capture" in OS.get_cmdline_user_args():
		for point in [Vector2(224, 264), Vector2(784, 352), Vector2(1100, 576)]:
			player.position = point
			await frames()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("TEMP") + "/gauntlands-%d.png" % int(point.x))
	print("ITERATION 02 TEST RESULT: %d failures" % failures)
	quit(1 if failures else 0)
