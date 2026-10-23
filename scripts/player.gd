extends "res://scripts/actor.gd"

const Lock = preload("res://scripts/target_lock.gd")
var targeting := Lock.new()

func _physics_process(delta: float) -> void:
	if arena.escaped or hp <= 0:
		return
	if Input.is_action_just_pressed("lock_target"):
		targeting.toggle(self, arena.eligible_targets())
	if Input.is_action_just_pressed("target_left"):
		targeting.cycle(arena.eligible_targets(), -1)
	if Input.is_action_just_pressed("target_right"):
		targeting.cycle(arena.eligible_targets(), 1)
	targeting.validate(arena.eligible_targets())
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if targeting.target != null:
		facing = global_position.direction_to(targeting.target.global_position)
	elif movement.length_squared() > 0.01:
		facing = movement.normalized()
	if state == "idle" or state == "walk":
		if Input.is_action_just_pressed("sword"):
			begin_attack("sword")
		elif Input.is_action_just_pressed("bow"):
			if arena.arrows > 0:
				begin_attack("bow")
			else:
				arena.log_event("Bow: EMPTY — no arrow fired")
	velocity = movement * 110.0 * (0.55 if is_attacking() else 1.0)
	move_and_slide()
	tick_actor(delta)

func reset_actor() -> void:
	super.reset_actor()
	targeting.target = null
