extends SceneTree

var arena
var failures := 0

func check(value: bool, message: String) -> void:
	if value:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func frames(count: int = 3) -> void:
	for i in range(count):
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func freeze_actors() -> void:
	for actor in [arena.player] + arena.goblins:
		actor.set_physics_process(false)

func run() -> void:
	arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	await frames()
	freeze_actors()
	var player = arena.player
	var mobile = arena.goblins[1]
	var door = arena.interactables[0]
	var secret = arena.interactables[7]
	var entrance = arena.interactables[8]
	var chest = arena.interactables[9]
	var reward = arena.interactables[10]
	var spike = arena.traps[0]
	var arrow_trap = arena.traps[1]
	check(arena.dungeon.ROOMS.size() == 5, "five rooms including one secret")
	check(not arena.escaped and player.position.distance_to(entrance.position) > 48, "safe start does not escape")
	check(not arena.exploration.remembered.has(Vector2i(848, 944)) and not arena.point_visible(reward.position), "secret contents initially unknown")
	check(not arena.point_visible(arena.goblins[2].position) and arena.goblins[2] not in arena.eligible_targets(), "closed connection hides enemy and lock")
	player.position = Vector2(576, 224)
	door.set_open(true)
	await frames()
	arena.exploration.refresh()
	check(arena.point_visible(Vector2(720, 224)), "open aperture reveals straight corridor")
	check(not arena.point_visible(Vector2(784, 400)), "bend still conceals lower corridor")
	check(not arena.exploration.remembered.has(Vector2i(784, 400)), "bend does not discover unseen cells")
	door.set_open(false)
	await frames()
	arena.exploration.refresh()
	check(arena.exploration.remembered.has(Vector2i(704, 224)) and not arena.point_visible(Vector2(720, 224)), "static memory persists without live sight")
	var hidden_drop = load("res://scripts/pickup.gd").new()
	hidden_drop.arena = arena
	hidden_drop.position = Vector2(720, 224)
	arena.loot.add_child(hidden_drop)
	arena.exploration._process(0.1)
	check(not hidden_drop.visible, "remembered region does not show live pickups")
	var unseen_arrow = load("res://scripts/arrow.gd").new()
	unseen_arrow.arena = arena
	unseen_arrow.position = arena.goblins[3].position - Vector2(20, 0)
	arena.projectiles.add_child(unseen_arrow)
	var known_events: Array = arena.events.duplicate()
	unseen_arrow._physics_process(0.1)
	check(arena.goblins[3].hp < 7 and arena.events == known_events, "unseen projectile impact cannot leak enemy state through HUD log")
	await frames()
	for item in arena.interactables:
		if item is StaticBody2D and not item.is_button:
			item.set_open(true)
	await frames()
	for room in arena.dungeon.ROOMS:
		check(not arena.dungeon.path_for(Vector2(224, 264), room.get_center(), 7).is_empty(), "small actor route reaches room " + str(room.position))
	check(arena.dungeon.path_for(Vector2(400, 224), Vector2(1100, 576), 34).is_empty(), "oversized footprint cannot traverse 64px corridor")
	check(not arena.footprint_clear(Vector2(608, 224), 34) and arena.footprint_clear(Vector2(608, 224), 7), "clearance uses body radius")
	mobile.feet.shape.radius = 34
	mobile.position = door.position + Vector2(40, 0)
	door.activate()
	check(door.opened, "large actor edge overlap prevents door closure")
	mobile.position = Vector2(552, 224)
	player.position = Vector2(720, 224)
	mobile.set_physics_process(true)
	await frames(90)
	check(mobile.position.x < 592, "oversized moving creature physically stays outside narrow doorway")
	mobile.set_physics_process(false)
	mobile.feet.shape.radius = 7
	mobile.reset_actor()
	# Actual AI follows a remembered position around a bend; hidden player motion
	# must not rewrite that observation.
	player.position = Vector2(784, 240)
	mobile.position = Vector2(720, 224)
	mobile.set_physics_process(true)
	await frames(4)
	check(mobile.awareness == "pursue", "sight acquires player")
	mobile.last_seen = Vector2(784, 352)
	player.position = Vector2(1100, 600)
	var observation: Vector2 = mobile.last_seen
	await frames(150)
	check(mobile.last_seen == observation and mobile.position.y > 245, "pursuit rounds bend toward last observation, not hidden player")
	mobile.set_physics_process(false)
	mobile.position = Vector2(624, 224)
	mobile.last_seen = Vector2(576, 224)
	mobile.awareness = "pursue"
	mobile.pursuit_left = 12
	mobile.search_left = mobile.search_duration
	door.set_open(false)
	await frames()
	mobile.set_physics_process(true)
	await frames(200)
	check(mobile.awareness != "pursue" and mobile.position.x >= 623, "closed route ends bounded search without threshold pushing")
	player.position = Vector2(580, 224)
	door.set_open(true)
	await frames(15)
	check(mobile.awareness == "pursue" and mobile.position.x < 624, "reopening and renewed sight resume pursuit")
	mobile.set_physics_process(false)
	arena.restart_encounter()
	await frames()
	freeze_actors()
	player.position = Vector2(1120, 712)
	check(arena.nearby_interactable() != secret, "secret has no distant revealing prompt")
	player.position = Vector2(1120, 740)
	check(arena.nearby_interactable() == secret, "nearby loose masonry can be examined")
	secret.activate()
	await frames()
	check(secret.opened and secret.revealed and arena.clear_sight(Vector2(1120, 720), Vector2(1120, 960)), "secret reveals and opens physical connection")
	player.position = chest.position + Vector2(0, 30)
	chest.activate()
	chest.activate()
	check(arena.gold == 20 and chest.opened, "ordinary chest grants gold once")
	player.position = reward.position + Vector2(0, 30)
	reward.activate()
	check(arena.gold == 55, "secret chest grants configurable reward")
	var remembered_count: int = arena.exploration.remembered.size()
	arena.request_respawns()
	check(arena.gold == 55 and chest.opened and reward.opened and secret.revealed and arena.exploration.remembered.size() == remembered_count, "enemy-only reset preserves rewards secret discovery")
	# Reach alone must not allow interaction through masonry.
	chest.reset_run()
	chest.position = Vector2(1408, 680)
	player.position = Vector2(1376, 680)
	chest.activate()
	check(not chest.opened and arena.nearby_interactable() != chest, "wall blocks chest interaction")
	chest.position = Vector2(2720, 576)
	# Hazard pressure and susceptibility are independent, with late contacts.
	arena.restart_encounter()
	await frames()
	freeze_actors()
	player.position = spike.position
	player.pressure_sensitive = false
	await frames(40)
	check(spike.phase == "armed", "non-triggering creature does not press the plate")
	player.pressure_sensitive = true
	var before_hp: int = player.hp
	await frames(12)
	check(spike.phase == "warning" and player.hp == before_hp, "spikes telegraph before damage")
	var trap_time: float = spike.elapsed
	arena.request_respawns()
	check(spike.phase == "warning" and spike.elapsed == trap_time, "enemy-only reset leaves trap timing intact")
	await frames(27)
	check(player.hp == before_hp - 3, "spikes apply deterministic damage once")
	await frames(10)
	check(player.hp == before_hp - 3, "standing on active spikes cannot damage every frame")
	mobile.position = spike.position + Vector2(16, 0)
	await frames(3)
	check(mobile.hp == 4, "late enemy arrival hits same raised spikes")
	mobile.position = mobile.spawn_point
	player.position = player.spawn_point
	await frames(200)
	check(spike.phase == "armed", "spikes cool down and rearm")
	player.hazard_susceptible = false
	player.position = spike.position
	await frames(40)
	check(spike.phase == "active" and player.hp == before_hp - 3, "unaffected fixture can trigger but takes no damage")
	player.hazard_susceptible = true
	player.position = player.spawn_point
	spike.reset_run()
	mobile.hp = 3
	mobile.position = spike.position
	var drops: int = arena.loot.get_child_count()
	await frames(45)
	check(mobile.hp == 0 and arena.loot.get_child_count() == drops + 1, "trap death creates exactly one goblin drop")
	await frames(15)
	check(arena.loot.get_child_count() == drops + 1, "active trap does not duplicate death loot")
	arena.restart_encounter()
	await frames()
	freeze_actors()
	# Trigger with enemy; a different susceptible creature is first in the lane.
	mobile.position = arrow_trap.position
	player.position = Vector2(784, 320)
	await frames(55)
	check(player.hp == 9 and arena.arrows == 10, "enemy-triggered physical arrow hits player without spending ammunition")
	check(arrow_trap.phase != "armed", "arrow trap cannot fire every frame")
	arena.restart_encounter()
	await frames()
	freeze_actors()
	player.position = arrow_trap.position
	mobile.position = Vector2(784, 320)
	await frames(55)
	check(mobile.hp == 4 and player.hp == 12, "player-triggered arrow hits intervening enemy first")
	arena.restart_encounter()
	await frames()
	freeze_actors()
	player.position = arrow_trap.position
	mobile.position = Vector2(784, 320)
	mobile.hazard_susceptible = false
	await frames(65)
	check(mobile.hp == 7 and player.hp == 12 and arena.projectiles.get_child_count() == 0, "immune blocking body consumes trap arrow")
	mobile.hazard_susceptible = true
	# Swept, high-speed projectile must hit a closed door even in one long tick.
	var shot = load("res://scripts/arrow.gd").new()
	shot.arena = arena
	shot.hazard = true
	shot.position = Vector2(576, 224)
	shot.direction = Vector2.RIGHT
	arena.projectiles.add_child(shot)
	shot._physics_process(0.5)
	check(shot.finished, "swept trap arrow hits closed door")
	await frames()
	# Escape freezes every simulation path, and summary snapshots gold.
	arena.restart_encounter()
	await frames()
	freeze_actors()
	player.position = entrance.position + Vector2(0, 28)
	entrance.activate()
	check(arena.escaped and arena.escaped_gold == 0 and player.hp > 0, "zero-gold escape with living enemies")
	arena.restart_encounter()
	player.position = entrance.position + Vector2(0, 28)
	arena.gold = 55
	spike.phase = "warning"
	spike.elapsed = 0.2
	var frozen_shot = load("res://scripts/arrow.gd").new()
	frozen_shot.arena = arena
	frozen_shot.position = Vector2(300, 250)
	arena.projectiles.add_child(frozen_shot)
	entrance.activate()
	var frozen_drop = load("res://scripts/pickup.gd").new()
	frozen_drop.arena = arena
	frozen_drop.position = player.position
	arena.loot.add_child(frozen_drop)
	var old_position: Vector2 = mobile.position
	var old_timer: float = spike.elapsed
	player.take_damage(99)
	arena.fire_arrow(player)
	mobile.set_physics_process(true)
	await frames(100)
	check(arena.escaped_gold == 55 and arena.gold == 55 and player.hp == 12 and mobile.position == old_position and spike.elapsed == old_timer and frozen_shot.position == Vector2(300, 250) and frozen_shot.lifetime == 0, "escape freezes health combat movement traps and summary")
	check(not frozen_drop.collected, "escape freezes automatic pickup collection")
	freeze_actors()
	Input.action_press("restart")
	await frames(3)
	Input.action_release("restart")
	freeze_actors()
	check(not arena.escaped and arena.gold == 0 and arena.arrows == 10 and player.hp == 12 and not secret.revealed and not chest.opened and not reward.opened and spike.phase == "armed" and arrow_trap.phase == "armed" and arena.pending_respawns.is_empty() and arena.loot.get_child_count() == 0 and mobile.awareness == "idle" and arena.projectiles.get_child_count() == 0, "full restart restores entire run")
	check(not arena.exploration.remembered.has(Vector2i(848, 944)) and player.targeting.target == null, "full restart clears discovery and lock")
	print("ITERATION 03 TEST RESULT: %d failures" % failures)
	quit(1 if failures else 0)
