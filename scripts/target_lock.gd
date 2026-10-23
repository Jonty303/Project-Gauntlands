extends RefCounted

var target: CharacterBody2D

func living(goblins: Array) -> Array:
	return goblins.filter(func(g): return g.hp > 0)

func toggle(player: CharacterBody2D, goblins: Array) -> void:
	if target != null:
		target = null
		return
	var choices := living(goblins)
	choices.sort_custom(func(a, b): return player.position.distance_squared_to(a.position) < player.position.distance_squared_to(b.position))
	if not choices.is_empty():
		target = choices[0]

func cycle(goblins: Array, direction: int) -> void:
	var choices := living(goblins)
	if choices.is_empty():
		target = null
		return
	var index := choices.find(target)
	target = choices[posmod(index + direction, choices.size())] if index >= 0 else choices[0]

func validate(goblins: Array) -> void:
	if target != null and (target.hp <= 0 or target not in goblins):
		var choices := living(goblins)
		target = choices[0] if not choices.is_empty() else null
