extends Node2D

const TEXTURE = preload("res://assets/room.png")
const REGIONS = [Rect2(48, 80, 544, 272), Rect2(592, 192, 224, 64), Rect2(752, 192, 64, 352), Rect2(848, 464, 544, 272), Rect2(816, 480, 32, 64)]
const ROOMS = [Rect2(48, 80, 544, 272), Rect2(848, 464, 544, 272), Rect2(1648, 464, 544, 272), Rect2(2448, 464, 544, 272), Rect2(848, 944, 544, 272)]
const EXTRA_REGIONS = [Rect2(1392, 560, 256, 64), Rect2(2192, 560, 256, 64), Rect2(1088, 736, 64, 208), Rect2(112, 48, 64, 32)]
var cells: Dictionary = {}
var navigation_cache: Dictionary = {}
var revision := -1

func _ready() -> void:
	for region in REGIONS + ROOMS.slice(2) + EXTRA_REGIONS:
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
	# Reuse the original room compositions; corridor strips cut the new apertures.
	draw_texture(TEXTURE, Vector2.ZERO)
	for offset in [Vector2(800, 384), Vector2(1600, 384), Vector2(2400, 384), Vector2(800, 864)]:
		draw_texture(TEXTURE, offset)
	for cell in cells:
		if in_room(Vector2(cell)):
			continue
		var source := Rect2(48 + posmod(cell.x / 16, 8) * 16, 96 + posmod(cell.y / 16, 8) * 16, 16, 16)
		draw_texture_rect_region(TEXTURE, Rect2(Vector2(cell), Vector2(16, 16)), source)
	for cell in cells:
		if in_room(Vector2(cell)):
			continue
		for step in [Vector2i(16, 0), Vector2i(-16, 0), Vector2i(0, 16), Vector2i(0, -16)]:
			var neighbor: Vector2i = cell + step
			if not cells.has(neighbor):
				var source := Rect2(32, 96, 16, 16)
				if step.y != 0:
					source = Rect2(64 + posmod(cell.x / 16, 8) * 16, 64, 16, 16)
				draw_texture_rect_region(TEXTURE, Rect2(Vector2(neighbor), Vector2(16, 16)), source)

func in_room(point: Vector2) -> bool:
	for room in ROOMS:
		if room.has_point(point):
			return true
	return false

func path_for(from: Vector2, to: Vector2, radius: float) -> PackedVector2Array:
	var arena = get_parent()
	if revision != arena.door_revision:
		navigation_cache.clear()
		revision = arena.door_revision
	if not navigation_cache.has(radius):
		var grid := AStarGrid2D.new()
		grid.region = Rect2i(0, 0, 190, 78)
		grid.cell_size = Vector2(16, 16)
		grid.offset = Vector2(8, 8)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.update()
		for x in range(190):
			for y in range(78):
				var id := Vector2i(x, y)
				var point := Vector2(id * 16) + Vector2(8, 8)
				grid.set_point_solid(id, not cells.has(id * 16) or not arena.footprint_clear(point, radius))
		navigation_cache[radius] = grid
	var nav: AStarGrid2D = navigation_cache[radius]
	var a := Vector2i(floor(from.x / 16), floor(from.y / 16))
	var b := Vector2i(floor(to.x / 16), floor(to.y / 16))
	if not nav.is_in_boundsv(a) or not nav.is_in_boundsv(b) or nav.is_point_solid(a) or nav.is_point_solid(b):
		return PackedVector2Array()
	return nav.get_point_path(a, b)
