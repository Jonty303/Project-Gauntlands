extends "res://scripts/actor.gd"

@export var detection_range := 360.0
@export var search_duration := 2.5
@export var pursuit_timeout := 12.0
var awareness := "idle"
var last_seen := Vector2.ZERO
var search_left := 0.0
var pursuit_left := 0.0
var path := PackedVector2Array()
var replan_left := 0.0
var route_revision := -1

func reset_actor() -> void:
	super.reset_actor()
	awareness = "idle"
	last_seen = spawn_point
	search_left = 0.0
	pursuit_left = 0.0
	path.clear()
	replan_left = 0.0
	route_revision = -1

func _physics_process(delta: float) -> void:
	if arena.escaped or hp <= 0:
		return
	velocity = Vector2.ZERO
	var sees_player: bool = arena.player.hp > 0 and position.distance_to(arena.player.position) <= detection_range and arena.clear_sight(position, arena.player.position)
	if sees_player:
		last_seen = arena.player.position
		awareness = "pursue"
		pursuit_left = pursuit_timeout
		search_left = search_duration
	elif awareness == "pursue":
		pursuit_left -= delta
		if position.distance_to(last_seen) <= 12 or pursuit_left <= 0:
			awareness = "search"
	elif awareness == "search":
		search_left -= delta
		if search_left <= 0:
			awareness = "home"
	if not is_attacking():
		if sees_player and position.distance_to(last_seen) <= 31.0:
			facing = position.direction_to(last_seen)
			begin_attack("sword")
		elif title != "Guard":
			if awareness == "pursue":
				navigate(last_seen, delta)
			elif awareness == "home":
				if position.distance_to(spawn_point) < 10:
					awareness = "idle"
				else:
					navigate(spawn_point, delta)
			elif awareness == "search":
				# Bounded local scan at the last reachable observation, no live target reads.
				facing = Vector2.RIGHT.rotated(floor(search_left * 4) * PI / 2)
	move_and_slide()
	tick_actor(delta)

func navigate(destination: Vector2, delta: float) -> void:
	if arena.motion_clear(self, destination):
		path.clear()
		velocity = position.direction_to(destination) * 54.0
	else:
		replan_left -= delta
		if replan_left <= 0 or route_revision != arena.door_revision:
			path = arena.dungeon.path_for(position, destination, feet.shape.radius)
			replan_left = 0.35
			route_revision = arena.door_revision
			# The starting cell centre can be behind the actor. Skip it only when
			# the next leg has physical clearance for this actor's circle.
			if path.size() > 1 and arena.motion_clear(self, path[1]):
				path.remove_at(0)
		while not path.is_empty() and position.distance_to(path[0]) < 3.0:
			path.remove_at(0)
		if path.is_empty():
			if awareness == "pursue":
				awareness = "search"
			elif awareness == "home":
				awareness = "idle"
			return
		velocity = position.direction_to(path[0]) * 54.0
	if velocity.length_squared() > 0:
		facing = velocity.normalized()
