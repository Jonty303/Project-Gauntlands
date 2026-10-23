extends Node2D

const Player = preload("res://scripts/player.gd")
const Goblin = preload("res://scripts/goblin.gd")
const Arrow = preload("res://scripts/arrow.gd")
const Hud = preload("res://scripts/hud.gd")

var player: CharacterBody2D
var goblins: Array = []
var arrows := 5
var events: Array[String] = []
var rng := RandomNumberGenerator.new()
var roll_count := 0
var actors: Node2D
var projectiles: Node2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("080a0d"))
	var room := Sprite2D.new()
	room.texture = preload("res://assets/room.png")
	room.centered = false
	add_child(room)
	# The playable feet area starts below the north wall face and stops before
	# the south wall cap: no actor can enter structural foreground occlusion.
	wall(Vector2(320, 64), Vector2(576, 32))
	wall(Vector2(320, 368), Vector2(576, 32))
	wall(Vector2(32, 216), Vector2(32, 304))
	wall(Vector2(608, 216), Vector2(32, 304))
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	player = Player.new()
	player.setup(self, "Player", Vector2(224, 264), "res://assets/adventurer.png")
	actors.add_child(player)
	for entry in [["Guard", Vector2(440, 156)], ["Chaser", Vector2(432, 292)]]:
		var goblin := Goblin.new()
		goblin.setup(self, entry[0], entry[1], "res://assets/goblin.png")
		goblins.append(goblin)
		actors.add_child(goblin)
	projectiles = Node2D.new()
	add_child(projectiles)
	var hud := Hud.new()
	hud.arena = self
	hud.z_index = 10
	add_child(hud)
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
	if Input.is_action_just_pressed("restart"):
		restart_encounter()

func restart_encounter() -> void:
	for arrow in projectiles.get_children():
		projectiles.remove_child(arrow)
		arrow.queue_free()
	player.reset_actor()
	for goblin in goblins:
		goblin.reset_actor()
	arrows = 5
	events.clear()
	# Repeatable encounter sequence: physical misses never consume an RPG roll.
	rng.seed = 101
	roll_count = 0
	log_event("Encounter reset | seed 101 | 12 HP / 5 arrows")

func log_event(message: String) -> void:
	events.append(message)
	while events.size() > 6:
		events.pop_front()
	print(message)

func melee_contacts(attacker: CharacterBody2D) -> void:
	var candidates: Array = goblins if attacker == player else [player]
	for defender in candidates:
		if defender.hp <= 0 or defender in attacker.contacts:
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
