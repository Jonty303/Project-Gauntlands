extends Node2D

const TEXTURE = preload("res://assets/room.png")
const REGIONS = [Rect2(48, 80, 544, 272), Rect2(592, 192, 224, 64), Rect2(752, 192, 64, 352), Rect2(848, 464, 544, 272), Rect2(816, 480, 32, 64)]
var cells: Dictionary = {}

func _ready() -> void:
	for region in REGIONS:
		for x in range(int(region.position.x), int(region.end.x), 16):
			for y in range(int(region.position.y), int(region.end.y), 16):
				cells[Vector2i(x, y)] = true
	var boundary: Dictionary = {}
	for cell in cells:
		for step in [Vector2i(16, 0), Vector2i(-16, 0), Vector2i(0, 16), Vector2i(0, -16)]:
			var neighbor: Vector2i = cell + step
			if not cells.has(neighbor):
				boundary[neighbor] = true
	for cell in boundary:
		get_parent().wall(Vector2(cell) + Vector2(8, 8), Vector2(16, 16))
	queue_redraw()

func _draw() -> void:
	# Original room composition remains intact; only the two doorway strips change.
	draw_texture(TEXTURE, Vector2.ZERO)
	draw_texture(TEXTURE, Vector2(800, 384))
	for cell in cells:
		if cell.x < 592 or (cell.x >= 848 and cell.y >= 464):
			continue
		var source := Rect2(48 + posmod(cell.x / 16, 8) * 16, 96 + posmod(cell.y / 16, 8) * 16, 16, 16)
		draw_texture_rect_region(TEXTURE, Rect2(Vector2(cell), Vector2(16, 16)), source)
	for cell in cells:
		if cell.x < 592 or (cell.x >= 848 and cell.y >= 464):
			continue
		for step in [Vector2i(16, 0), Vector2i(-16, 0), Vector2i(0, 16), Vector2i(0, -16)]:
			var neighbor: Vector2i = cell + step
			if not cells.has(neighbor):
				var source := Rect2(32, 96, 16, 16)
				if step.y != 0:
					source = Rect2(64 + posmod(cell.x / 16, 8) * 16, 64, 16, 16)
				draw_texture_rect_region(TEXTURE, Rect2(Vector2(neighbor), Vector2(16, 16)), source)
