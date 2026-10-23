extends "res://scripts/actor.gd"

func _physics_process(delta: float) -> void:
	if hp <= 0:
		respawn_left -= delta
		if respawn_left <= 0.0:
			reset_actor()
			arena.log_event(title + " respawned")
		return
	velocity = Vector2.ZERO
	if arena.player.hp > 0:
		var offset: Vector2 = arena.player.position - position
		if not is_attacking():
			facing = offset.normalized()
			if offset.length() <= 31.0:
				begin_attack("sword")
			elif title == "Chaser":
				velocity = offset.normalized() * 54.0
	move_and_slide()
	tick_actor(delta)
