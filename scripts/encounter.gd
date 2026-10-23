extends Node2D

const Player = preload("res://scripts/player.gd")
const Goblin = preload("res://scripts/goblin.gd")
const Arrow = preload("res://scripts/arrow.gd")
const Hud = preload("res://scripts/hud.gd")

var dungeon: Node2D
var exploration: Node2D
var sight: Node2D
var sight_blockers: Array[Rect2] = []
var pause_menu: CanvasLayer
var traps: Array = []
var escaped := false
var escaped_gold := 0
var door_revision := 0
var player: CharacterBody2D
var goblins: Array = []
@export var starting_ammunition := 10
var arrows := 10
var gold := 0
var loot: Node2D
var interactables: Array = []
var pending_respawns: Array = []
var loot_rng := RandomNumberGenerator.new()
var camera: Camera2D
var events: Array[String] = []
var rng := RandomNumberGenerator.new()
var roll_count := 0
var actors: Node2D
var projectiles: Node2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("080a0d"))
	dungeon = preload("res://scripts/dungeon.gd").new()
	add_child(dungeon)
	loot = Node2D.new()
	add_child(loot)
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	player = Player.new()
	player.setup(self, "Player", Vector2(224, 264), "res://assets/adventurer.png")
	actors.add_child(player)
	for entry in [["Guard", Vector2(440, 156)], ["Chaser", Vector2(432, 292)], ["Corridor", Vector2(784, 352)], ["Room B", Vector2(1120, 576)]]:
		var goblin := Goblin.new()
		goblin.setup(self, entry[0], entry[1], "res://assets/goblin.png")
		goblins.append(goblin)
		actors.add_child(goblin)
	projectiles = Node2D.new()
	add_child(projectiles)
	for location in [Vector2(608, 224), Vector2(832, 512), Vector2(224, 90)]:
		var item = preload("res://scripts/interactable.gd").new()
		item.arena = self
		item.position = location
		item.is_button = location == Vector2(224, 90)
		add_child(item)
		interactables.append(item)
	for location in [Vector2(1408, 592), Vector2(1632, 592), Vector2(2208, 592), Vector2(2432, 592), Vector2(1120, 768)]:
		var door = preload("res://scripts/interactable.gd").new()
		door.arena = self
		door.position = location
		if location == Vector2(1120, 768):
			door.secret = true
			door.horizontal = true
		add_child(door)
		interactables.append(door)
	for entry in [["entrance", Vector2(144, 64), 0], ["chest", Vector2(2720, 576), 20], ["chest", Vector2(1120, 1056), 35]]:
		var item = preload("res://scripts/reward.gd").new()
		item.arena = self
		item.kind = entry[0]
		item.position = entry[1]
		item.gold_amount = entry[2]
		actors.add_child(item)
		interactables.append(item)
	for entry in [["spike", Vector2(1904, 592)], ["arrow", Vector2(784, 400)]]:
		var trap = preload("res://scripts/trap.gd").new()
		trap.arena = self
		trap.kind = entry[0]
		trap.position = entry[1]
		add_child(trap)
		traps.append(trap)
	camera = Camera2D.new()
	camera.position = Vector2(320, 280)
	add_child(camera)
	sight = preload("res://scripts/sight.gd").new()
	sight.arena = self
	add_child(sight)
	exploration = preload("res://scripts/exploration.gd").new()
	exploration.arena = self
	exploration.z_index = 5
	add_child(exploration)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var hud := Hud.new()
	hud.arena = self
	hud.z_index = 10
	canvas.add_child(hud)
	pause_menu = preload("res://scripts/pause_menu.gd").new()
	pause_menu.arena = self
	add_child(pause_menu)
	# Observed dynamic art stays readable above the static fog.
	actors.z_index = 6
	loot.z_index = 6
	projectiles.z_index = 6
	for item in interactables + traps:
		if item.get_parent() == self:
			item.z_index = 6
	restart_encounter()

func wall(location: Vector2, dimensions: Vector2) -> void:
	sight_blockers.append(Rect2(location - dimensions / 2, dimensions))
	var body := StaticBody2D.new()
	body.position = location
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = dimensions
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		if escaped or player.hp <= 0:
			restart_encounter()
		else:
			pause_menu.open_menu()
			pause_menu.request_restart()
			return
	if simulation_stopped():
		return
	camera.position = Vector2(maxf(320, player.position.x), maxf(280, player.position.y + 16))
	for goblin in pending_respawns.duplicate():
		if player.position.distance_to(goblin.spawn_point) > 24:
			goblin.reset_actor()
			pending_respawns.erase(goblin)
	if player.hp > 0 and Input.is_action_just_pressed("interact"):
		var item = nearby_interactable()
		if item != null:
			item.activate()

func restart_encounter() -> void:
	if pause_menu != null:
		pause_menu.reset()
	escaped = false
	escaped_gold = 0
	for arrow in projectiles.get_children():
		projectiles.remove_child(arrow)
		arrow.queue_free()
	player.reset_actor()
	for goblin in goblins:
		goblin.reset_actor()
	arrows = starting_ammunition
	gold = 0
	pending_respawns.clear()
	for drop in loot.get_children():
		loot.remove_child(drop)
		drop.queue_free()
	for item in interactables:
		item.reset_run()
	for trap in traps:
		trap.reset_run()
	exploration.reset()
	events.clear()
	# Repeatable encounter sequence: physical misses never consume an RPG roll.
	rng.seed = 101
	roll_count = 0
	log_event("Encounter reset | seed 101 | 12 HP / %d arrows" % arrows)

func log_event(message: String) -> void:
	events.append(message)
	while events.size() > 6:
		events.pop_front()
	print(message)

func melee_contacts(attacker: CharacterBody2D) -> void:
	var candidates: Array = goblins if attacker == player else [player]
	for defender in candidates:
		if defender.hp <= 0 or defender in attacker.contacts or not clear_sight(attacker.position, defender.position):
			continue
		var offset: Vector2 = defender.position - attacker.position
		if offset.length() <= 34.0 and attacker.facing.dot(offset.normalized()) >= cos(deg_to_rad(65.0)):
			attacker.contacts.append(defender)
			resolve_contact(attacker, defender, "Sword" if attacker == player else attacker.title + " swing")

func resolve_contact(attacker: CharacterBody2D, defender: CharacterBody2D, weapon: String) -> void:
	if simulation_stopped() or attacker.hp <= 0 or defender.hp <= 0:
		return
	roll_count += 1
	var natural := rng.randi_range(1, 20)
	var attack := natural + 5
	var defence := 10 if defender == player else 11
	var prefix := "%s: contact -> %d vs %d -> " % [weapon, attack, defence]
	if attack < defence:
		contact_event(defender, prefix + "DODGE (0 damage)")
		return
	var damage := rng.randi_range(2, 4) if attacker == player else rng.randi_range(3, 4)
	var critical := natural == 20
	if critical:
		damage += 1
	contact_event(defender, prefix + ("CRIT" if critical else "HIT") + " -> %s -%d HP" % [defender.title, damage])
	defender.take_damage(damage)

func fire_arrow(shooter: CharacterBody2D) -> void:
	if simulation_stopped() or arrows <= 0 or shooter.hp <= 0:
		return
	arrows -= 1
	var arrow := Arrow.new()
	arrow.arena = self
	arrow.direction = shooter.facing.normalized()
	# Start at the feet plane so the swept ray and body footprints agree. Art
	# draws the shaft at hand height. No homing/collision based on target lock.
	arrow.position = shooter.position
	projectiles.add_child(arrow)
	log_event("Bow: RELEASE -> %d arrows remain" % arrows)

func clear_sight(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func eligible_targets() -> Array:
	return goblins.filter(func(g): return g.hp > 0 and actor_visible(g))

func nearby_interactable():
	var closest = null
	var distance := 48.0
	for item in interactables:
		var d: float = player.position.distance_to(item.position)
		if item is StaticBody2D and item.secret and not item.revealed and d > 32.0:
			continue
		if d < distance and interactable_visible(item) and interaction_reachable(item):
			closest = item
			distance = d
	return closest

func drop_loot(goblin: CharacterBody2D) -> void:
	var drop = preload("res://scripts/pickup.gd").new()
	drop.arena = self
	drop.position = goblin.position
	drop.kind = "gold" if loot_rng.randi_range(0, 1) == 0 else "arrows"
	drop.quantity = 5 if drop.kind == "gold" else loot_rng.randi_range(1, 3)
	loot.add_child(drop)

func request_respawns() -> void:
	if simulation_stopped():
		return
	for goblin in goblins:
		if player.position.distance_to(goblin.spawn_point) <= 24:
			if goblin not in pending_respawns:
				pending_respawns.append(goblin)
		else:
			goblin.reset_actor()
			pending_respawns.erase(goblin)
	log_event("Goblins reset; occupied spawn points deferred")

func point_visible(point: Vector2) -> bool:
	return player != null and sight.can_see(point)

func actor_visible(actor: CharacterBody2D) -> bool:
	return sight.actor_visible(actor)

func interaction_reachable(item: Node2D) -> bool:
	var query := PhysicsRayQueryParameters2D.create(player.position, item.position, 1)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == item

func interactable_visible(item: Node2D) -> bool:
	if player.position.distance_to(item.position) > sight.view_distance:
		return false
	return interaction_reachable(item)

func footprint_clear(point: Vector2, radius: float) -> bool:
	# Geometric clearance uses collision footprints, independent of sprite size.
	for x in range(int(floor((point.x - radius) / 16)), int(floor((point.x + radius) / 16)) + 1):
		for y in range(int(floor((point.y - radius) / 16)), int(floor((point.y + radius) / 16)) + 1):
			var cell := Vector2i(x * 16, y * 16)
			var nearest := point.clamp(Vector2(cell), Vector2(cell) + Vector2(16, 16))
			if not dungeon.cells.has(cell) and point.distance_to(nearest) < radius:
				return false
	for item in interactables:
		if item is StaticBody2D and not item.is_button and not item.opened:
			var box: Rect2 = item.door_rect()
			if point.distance_to(point.clamp(box.position, box.end)) < radius:
				return false
	return true

func motion_clear(actor: CharacterBody2D, destination: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = actor.feet.shape
	query.transform = Transform2D(0, actor.position)
	query.motion = destination - actor.position
	query.collision_mask = 1
	var result := get_world_2d().direct_space_state.cast_motion(query)
	return result[0] >= 1.0

func escape_run() -> void:
	if simulation_stopped() or player.hp <= 0:
		return
	escaped = true
	escaped_gold = gold
	player.targeting.target = null
	for actor in [player] + goblins:
		actor.velocity = Vector2.ZERO
	log_event("Escaped with %d gold" % escaped_gold)

func resolve_hazard(source: Node2D, target: CharacterBody2D, damage_kind: String, base_amount: int) -> void:
	if simulation_stopped() or target.hp <= 0:
		return
	# Physical contact is established by the caller. This compact request is the
	# future mitigation seam; hazard contacts never roll weapon accuracy.
	var request := {"source": source, "target": target, "kind": damage_kind, "amount": base_amount}
	var message: String
	if not target.hazard_susceptible:
		message = damage_kind + ": contact -> INAPPLICABLE -> " + target.title
	else:
		var amount := maxi(0, int(request.amount))
		message = "%s: contact -> %s -%d HP" % [damage_kind, target.title, amount]
		target.take_damage(amount)
	if target == player or point_visible(target.position):
		log_event(message)
	else:
		print(message)

func contact_event(defender: CharacterBody2D, message: String) -> void:
	# A projectile may travel beyond current sight. Keep diagnostics in output,
	# but do not use the HUD as remote enemy surveillance.
	if defender == player or point_visible(defender.position):
		log_event(message)
	else:
		print(message)

func simulation_stopped() -> bool:
	return escaped or get_tree().paused
