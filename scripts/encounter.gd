extends Node2D

const Player = preload("res://scripts/player.gd")
const Goblin = preload("res://scripts/goblin.gd")
const Arrow = preload("res://scripts/arrow.gd")
const Hud = preload("res://scripts/hud.gd")

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
	add_child(preload("res://scripts/dungeon.gd").new())
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
	camera = Camera2D.new()
	camera.position = Vector2(320, 280)
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var hud := Hud.new()
	hud.arena = self
	hud.z_index = 10
	canvas.add_child(hud)
	restart_encounter()

func wall(location: Vector2, dimensions: Vector2) -> void:
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
	camera.position = Vector2(maxf(320, player.position.x), maxf(280, player.position.y + 16))
	for goblin in pending_respawns.duplicate():
		if player.position.distance_to(goblin.spawn_point) > 24:
			goblin.reset_actor()
			pending_respawns.erase(goblin)
	if player.hp > 0 and Input.is_action_just_pressed("interact"):
		var item = nearby_interactable()
		if item != null:
			item.activate()
	if Input.is_action_just_pressed("restart"):
		restart_encounter()

func restart_encounter() -> void:
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
		if not item.is_button:
			item.set_open(false)
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
	if attacker.hp <= 0 or defender.hp <= 0:
		return
	roll_count += 1
	var natural := rng.randi_range(1, 20)
	var attack := natural + 5
	var defence := 10 if defender == player else 11
	var prefix := "%s: contact -> %d vs %d -> " % [weapon, attack, defence]
	if attack < defence:
		log_event(prefix + "DODGE (0 damage)")
		return
	var damage := rng.randi_range(2, 4) if attacker == player else rng.randi_range(3, 4)
	var critical := natural == 20
	if critical:
		damage += 1
	log_event(prefix + ("CRIT" if critical else "HIT") + " -> %s -%d HP" % [defender.title, damage])
	defender.take_damage(damage)

func fire_arrow(shooter: CharacterBody2D) -> void:
	if arrows <= 0 or shooter.hp <= 0:
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
	return goblins.filter(func(g): return g.hp > 0 and clear_sight(player.position, g.position))

func nearby_interactable():
	var closest = null
	var distance := 48.0
	for item in interactables:
		var d: float = player.position.distance_to(item.position)
		if d < distance:
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
	for goblin in goblins:
		if player.position.distance_to(goblin.spawn_point) <= 24:
			if goblin not in pending_respawns:
				pending_respawns.append(goblin)
		else:
			goblin.reset_actor()
			pending_respawns.erase(goblin)
	log_event("Goblins reset; occupied spawn points deferred")
