extends "res://scripts/actor.gd"

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	velocity = Vector2.ZERO
	if arena.player.hp > 0 and arena.clear_sight(position, arena.player.position):
		var offset: Vector2 = arena.player.position - position
		if not is_attacking():
			facing = offset.normalized()
			if offset.length() <= 31.0:
				begin_attack("sword")
			elif title != "Guard":
				velocity = offset.normalized() * 54.0
	move_and_slide()
	tick_actor(delta)
