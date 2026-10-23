extends Node2D

var arena: Node2D
var summary: Label
var log_label: Label
var death_prompt: Label
var interaction_prompt: Label

func label_at(location: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = location
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _ready() -> void:
	label_at(Vector2(32, 7), 18, Color("c8b996")).text = "GAUNTLANDS   /   THE FORGOTTEN HOLD"
	label_at(Vector2(34, 31), 10, Color("837e70")).text = "ITERATION 02     •     ROOMS, DOORS AND LOOT"
	summary = label_at(Vector2(32, 389), 10, Color("d7cbb0"))
	log_label = label_at(Vector2(32, 440), 11, Color("b8b7aa"))
	label_at(Vector2(32, 525), 11, Color("a09b8c")).text = "MOVE  LS / WASD     SWORD  A / J     BOW  X / K     LOCK  R3 / L"
	label_at(Vector2(32, 542), 11, Color("a09b8c")).text = "CYCLE RS / Q,E   INTERACT Y / F   RESTART Start / R"
	interaction_prompt = label_at(Vector2(32, 365), 12, Color("eedbc0"))
	death_prompt = label_at(Vector2(140, 205), 20, Color("eedbc0"))
	death_prompt.text = "YOU DIED\nStart / R — restart encounter"

func _process(_delta: float) -> void:
	var player = arena.player
	var target = player.targeting.target
	var target_name: String = target.title if target != null else "None"
	summary.text = "HP %d / 12    ARROWS %d    GOLD %d    LOCK %s    [%s]\n" % [player.hp, arena.arrows, arena.gold, target_name, player.state]
	for index in range(arena.goblins.size()):
		var goblin = arena.goblins[index]
		if index == 2:
			summary.text += "\n"
		summary.text += "%s %d/7 %s   " % [goblin.title, goblin.hp, goblin.state]
	var item = arena.nearby_interactable()
	interaction_prompt.text = "F / Y: " + item.prompt() if item != null and player.hp > 0 else ""
	log_label.text = "\n".join(arena.events)
	death_prompt.visible = player.hp <= 0
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 48), Color("080a0d"))
	draw_rect(Rect2(0, 385, 640, 175), Color("080a0d"))
	draw_rect(Rect2(24, 385, 592, 134), Color("101318"))
	draw_line(Vector2(24, 385), Vector2(616, 385), Color("5a5040"))
	if arena.player.hp <= 0:
		draw_rect(Rect2(124, 197, 392, 76), Color(0.04, 0.035, 0.03, 0.95))
	for actor in [arena.player] + arena.goblins:
		if actor.hp <= 0:
			continue
		var point: Vector2 = arena.get_canvas_transform() * actor.position + Vector2(-12, -39)
		draw_rect(Rect2(point, Vector2(24, 3)), Color("1b1717"))
		draw_rect(Rect2(point, Vector2(24.0 * actor.hp / actor.max_hp, 2)), Color("a57754") if actor == arena.player else Color("8e4842"))
	var target = arena.player.targeting.target
	if target != null and target.hp > 0:
		var point: Vector2 = arena.get_canvas_transform() * target.position + Vector2(0, -47)
		draw_polyline(PackedVector2Array([point + Vector2(-4, -3), point + Vector2(0, 1), point + Vector2(4, -3)]), Color("e0c37d"), 1.0)
		draw_arc(arena.get_canvas_transform() * target.position, 11.0, 0.0, TAU, 16, Color("bca66c"), 1.0)
