extends Node2D

# Static discovery memory and fog presentation. This is not illumination.
const CELL := 4
@export_range(0.0, 1.0) var memory_dim := 0.55
var arena: Node2D
var remembered: Dictionary = {}
var mask_view: SubViewport
var painter: Node2D
var fog: Sprite2D

func _ready() -> void:
	mask_view = SubViewport.new()
	mask_view.size = Vector2i(672, 592)
	mask_view.disable_3d = true
	mask_view.transparent_bg = true
	mask_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(mask_view)
	painter = Node2D.new()
	mask_view.add_child(painter)
	painter.draw.connect(draw_mask)
	fog = Sprite2D.new()
	fog.centered = false
	fog.texture = mask_view.get_texture()
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
render_mode unshaded;
uniform float memory_dim = 0.55;
void fragment() {
    vec4 mask = texture(TEXTURE, UV);
    float alpha = mask.r > 0.5 ? 0.0 : (mask.g > 0.5 ? memory_dim : 1.0);
    COLOR = vec4(0.0314, 0.0392, 0.0510, alpha);
}"""
	var material_instance := ShaderMaterial.new()
	material_instance.shader = shader
	fog.material = material_instance
	add_child(fog)

func reset() -> void:
	remembered.clear()
	# Room A's static composition is initially known; no live state is stored.
	for x in range(32, 608, CELL):
		for y in range(48, 384, CELL):
			remembered[Vector2i(x, y)] = true
	arena.sight.invalidate()

func _process(_delta: float) -> void:
	if arena.player == null:
		return
	refresh()
	for actor in arena.goblins:
		actor.visible = arena.actor_visible(actor)
	for container in [arena.loot, arena.projectiles]:
		for item in container.get_children():
			item.visible = arena.point_visible(item.position)
	for item in arena.interactables:
		item.visible = arena.interactable_visible(item)
	for trap in arena.traps:
		trap.visible = arena.point_visible(trap.position)
	fog.position = (arena.camera.position - Vector2(336, 296)).floor()
	fog.material.set_shader_parameter("memory_dim", memory_dim)
	painter.queue_redraw()

func refresh() -> void:
	if arena.sight.refresh():
		remember_polygon(arena.sight.polygon)
		for face in arena.sight.wall_faces:
			remember_polygon(face)
	painter.queue_redraw()

func remember_polygon(points: PackedVector2Array) -> void:
	# Memory is rasterized conservatively; live sight uses the full-resolution
	# geometry polygon. Discovery never expands to fill a partly visible cell.
	if points.size() < 3:
		return
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	for y in range(int(floor(bounds.position.y / CELL)) * CELL, int(bounds.end.y), CELL):
		var cuts: Array[float] = []
		var scan := float(y) + CELL * 0.5
		for i in range(points.size()):
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			if (a.y <= scan and b.y > scan) or (b.y <= scan and a.y > scan):
				cuts.append(a.x + (scan - a.y) * (b.x - a.x) / (b.y - a.y))
		cuts.sort()
		for i in range(0, cuts.size() - 1, 2):
			for x in range(int(ceil((cuts[i] - 0.001) / CELL)) * CELL, int(cuts[i + 1] + 0.001) - CELL + 1, CELL):
				var cell := Vector2i(x, y)
				if remembered.has(cell):
					continue
				var inside := true
				for corner in [Vector2(x, y), Vector2(x + CELL, y), Vector2(x, y + CELL), Vector2(x + CELL, y + CELL)]:
					if not Geometry2D.is_point_in_polygon(corner.move_toward(Vector2(x + CELL * 0.5, y + CELL * 0.5), 0.001), points):
						inside = false
						break
				if inside:
					remembered[cell] = true

func draw_mask() -> void:
	var start: Vector2 = (arena.camera.position - Vector2(336, 296)).floor()
	painter.draw_set_transform(-start)
	# Batch adjacent memory into strips; live entities never enter this texture.
	var left := int(floor(start.x / CELL)) * CELL
	var right := int(start.x + 672) + CELL
	for y in range(int(floor(start.y / CELL)) * CELL, int(start.y + 592) + CELL, CELL):
		var run := -2147483648
		for x in range(left, right + CELL, CELL):
			var known := x < right and remembered.has(Vector2i(x, y))
			if known and run == -2147483648:
				run = x
			elif not known and run != -2147483648:
				painter.draw_rect(Rect2(run, y, x - run, CELL), Color.GREEN)
				run = -2147483648
	if arena.sight.polygon.size() >= 3:
		painter.draw_colored_polygon(arena.sight.polygon, Color.YELLOW)
	for face in arena.sight.wall_faces:
		painter.draw_colored_polygon(face, Color.YELLOW)
