extends Node2D

# Observation geometry only: no discovery memory or illumination here.
@export var view_distance := 440.0
var arena: Node2D
var origin := Vector2.INF
var revision := -1
var cached_range := -1.0
var polygon := PackedVector2Array()
var wall_faces: Array[PackedVector2Array] = []
var wall_corners: Array[Vector2] = []

func _ready() -> void:
	# Adjacent collision tiles share straight-edge vertices. Only topology corners
	# need extra rays; retain diagonal contacts as well as convex/concave corners.
	var counts: Dictionary = {}
	var tiles: Dictionary = {}
	for box in arena.sight_blockers:
		tiles[box.position] = true
		for point in [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]:
			counts[point] = counts.get(point, 0) + 1
	for point: Vector2 in counts:
		var diagonal: bool = (tiles.has(point) and tiles.has(point - Vector2(16, 16))) or (tiles.has(point - Vector2(16, 0)) and tiles.has(point - Vector2(0, 16)))
		if counts[point] == 1 or counts[point] == 3 or (counts[point] == 2 and diagonal):
			wall_corners.append(point)

func invalidate() -> void:
	origin = Vector2.INF

func refresh() -> bool:
	if origin == arena.player.position and revision == arena.door_revision and cached_range == view_distance:
		return false
	origin = arena.player.position
	revision = arena.door_revision
	cached_range = view_distance
	var angles: Array[float] = []
	# Circle samples bound range; corner rays preserve narrow apertures and bends.
	for i in range(360):
		angles.append(-PI + TAU * i / 360.0)
	for corner in wall_corners:
		if origin.distance_to(corner) <= view_distance:
			add_angle(corner, angles)
	for item in arena.interactables:
		if item is StaticBody2D and not item.is_button and not item.opened:
			add_corner_angles(item.door_rect(), angles)
	angles.sort()
	polygon.clear()
	wall_faces.clear()
	for angle in angles:
		var end := origin + Vector2.from_angle(angle) * view_distance
		var query := PhysicsRayQueryParameters2D.create(origin, end, 1)
		query.hit_from_inside = true
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		polygon.append(end if hit.is_empty() else hit.position)
	# Many corner rays land on the same straight wall. Remove redundant points
	# before scan conversion; retain aperture corners and circular range edges.
	var outline := PackedVector2Array()
	for point in polygon:
		if not outline.is_empty() and outline[-1].distance_to(point) < 0.001:
			continue
		while outline.size() >= 2:
			var leg := outline[-1] - outline[-2]
			var next := point - outline[-1]
			if absf(leg.cross(next)) > 0.001 * leg.length() or leg.dot(next) < 0:
				break
			outline.remove_at(outline.size() - 1)
		outline.append(point)
	polygon = outline
	project_wall_faces()
	return true

func add_corner_angles(box: Rect2, angles: Array[float]) -> void:
	if origin.distance_to(origin.clamp(box.position, box.end)) > view_distance:
		return
	for corner in [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]:
		add_angle(corner, angles)

func add_angle(corner: Vector2, angles: Array[float]) -> void:
	var angle := (corner - origin).angle()
	for offset in [-0.0001, 0.0, 0.0001]:
		angles.append(wrapf(angle + offset, -PI, PI))

func project_wall_faces() -> void:
	# Project only observed horizontal wall edges into their north-wall artwork.
	# These polygons never participate in gameplay sight or target eligibility.
	for box in arena.sight_blockers:
		if origin.y <= box.end.y or origin.distance_to(origin.clamp(box.position, box.end)) > view_distance:
			continue
		var height := 16.0
		for room in arena.dungeon.ROOMS:
			if is_equal_approx(box.end.y, room.position.y) and box.position.x >= room.position.x and box.end.x <= room.end.x:
				height = 48.0
		for i in range(polygon.size()):
			var a := polygon[i]
			var b := polygon[(i + 1) % polygon.size()]
			if absf(a.y - box.end.y) > 0.001 or absf(b.y - box.end.y) > 0.001:
				continue
			var left := maxf(box.position.x, minf(a.x, b.x))
			var right := minf(box.end.x, maxf(a.x, b.x))
			if right - left < 0.001:
				continue
			# Snap tiny ray epsilon errors on wall art only to avoid memory seams.
			if absf(left - roundf(left)) < 0.1:
				left = roundf(left)
			if absf(right - roundf(right)) < 0.1:
				right = roundf(right)
			wall_faces.append(PackedVector2Array([Vector2(left, box.end.y), Vector2(right, box.end.y), Vector2(right, box.end.y - height), Vector2(left, box.end.y - height)]))

func can_see(point: Vector2) -> bool:
	# Exact query shares the mask's origin, range and blockers, without polygon
	# approximation at the circular limit. Memory and brightness never grant sight.
	var from: Vector2 = arena.player.position
	return from.distance_to(point) <= view_distance and arena.clear_sight(from, point)

func actor_visible(actor: CharacterBody2D) -> bool:
	# Observe the physical footprint, not a single sprite origin or its tall art.
	var radius: float = actor.feet.shape.radius * 0.8
	for offset in [Vector2.ZERO, Vector2(radius, 0), Vector2(-radius, 0), Vector2(0, radius), Vector2(0, -radius)]:
		if can_see(actor.position + offset):
			return true
	return false
