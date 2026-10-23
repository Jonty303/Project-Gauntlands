extends CharacterBody2D

var hazard_susceptible := true
var pressure_sensitive := true
var arena: Node2D
var title := "Player"
var max_hp := 12
var hp := 12
var spawn_point := Vector2.ZERO
var facing := Vector2.DOWN
var state := "idle"
var elapsed := 0.0
var animation_clock := 0.0
var respawn_left := 0.0
var hurt_left := 0.0
var contacts: Array = []
var released := false
var sprite: Sprite2D
var feet: CollisionShape2D

func setup(owner_arena: Node2D, actor_title: String, location: Vector2, art: String) -> void:
	arena = owner_arena
	title = actor_title
	spawn_point = location
	position = location
	if title != "Player":
		max_hp = 7
	hp = max_hp
	collision_layer = 2 if title == "Player" else 4
	collision_mask = 7
	feet = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	feet.shape = circle
	add_child(feet)
	sprite = Sprite2D.new()
	sprite.texture = load(art)
	sprite.hframes = 12
	sprite.vframes = 4
	sprite.position = Vector2(0, -18)
	add_child(sprite)
	update_art()

func is_attacking() -> bool:
	return state == "sword" or state == "bow"

func begin_attack(kind: String) -> void:
	state = kind
	elapsed = 0.0
	contacts.clear()
	released = false
	velocity = Vector2.ZERO

func tick_actor(delta: float) -> void:
	animation_clock += delta
	hurt_left = maxf(0.0, hurt_left - delta)
	if hp <= 0:
		return
	if is_attacking():
		elapsed += delta
		if state == "bow":
			if elapsed >= 0.32 and not released:
				released = true
				arena.fire_arrow(self)
			if elapsed >= 0.72:
				state = "idle"
		else:
			var active_start := 0.24 if title == "Player" else 0.50
			var active_end := active_start + 0.14
			if elapsed >= active_start and elapsed < active_end:
				arena.melee_contacts(self)
			if elapsed >= active_end and not released:
				released = true
				if contacts.is_empty():
					arena.contact_event(self, title + " sword: PHYSICAL MISS (range/arc)")
			if elapsed >= (0.68 if title == "Player" else 1.30):
				state = "idle"
	else:
		state = "walk" if velocity.length() > 1.0 else "idle"
	update_art()

func take_damage(amount: int) -> void:
	if arena.escaped or hp <= 0:
		return
	hp = maxi(0, hp - amount)
	hurt_left = 0.16
	if hp == 0:
		state = "dead"
		velocity = Vector2.ZERO
		collision_layer = 0
		collision_mask = 0
		if title == "Player" or arena.point_visible(position):
			arena.log_event(title + (" died; restart encounter" if title == "Player" else " died; use wall button to respawn"))
		if title != "Player":
			arena.drop_loot(self)
			arena.player.targeting.validate(arena.eligible_targets())
	update_art()

func reset_actor() -> void:
	position = spawn_point
	hp = max_hp
	state = "idle"
	elapsed = 0.0
	animation_clock = 0.0
	respawn_left = 0.0
	hurt_left = 0.0
	contacts.clear()
	released = false
	facing = Vector2.DOWN
	velocity = Vector2.ZERO
	collision_layer = 2 if title == "Player" else 4
	collision_mask = 7
	update_art()

func update_art() -> void:
	var direction := 0
	if absf(facing.x) > absf(facing.y):
		direction = 2 if facing.x > 0 else 3
	elif facing.y < 0:
		direction = 1
	var frame_index := 0
	match state:
		"walk": frame_index = 1 + int(animation_clock * 9.0) % 4
		"sword":
			var contact := 0.24 if title == "Player" else 0.50
			frame_index = 5 if elapsed < contact else (6 if elapsed < contact + 0.14 else 7)
		"bow": frame_index = 8 if elapsed < 0.32 else 9
		"dead": frame_index = 11
	if hurt_left > 0.0 and hp > 0:
		frame_index = 10
	sprite.frame = direction * 12 + frame_index
	sprite.modulate = Color(1.4, 0.85, 0.75) if hurt_left > 0 else Color.WHITE
