extends Node2D

const DUNGEON_SIZE := Vector2(800.0, 540.0)
const WALL_THICKNESS := 24.0
const FLOOR_COLOR := Color("#242832")
const GRID_COLOR := Color("#343945")
const WALL_COLOR := Color("#596171")
const COVER_CENTER := Vector2(35.0, -95.0)
const COVER_SIZE := Vector2(28.0, 210.0)
const SECOND_COVER_CENTER := Vector2(-115.0, 85.0)
const SECOND_COVER_SIZE := Vector2(175.0, 28.0)
const NAV_CELL := 20.0
const ISO_VIEW = preload("res://scripts/iso_view.gd")
const CORRIDOR := Rect2(400.0, -45.0, 170.0, 90.0)
const CHAMBER := Rect2(570.0, -165.0, 310.0, 330.0)
var wall_rects: Array[Rect2] = []
var navigation_grid: AStarGrid2D

func _project(point: Vector2) -> Vector2:
    return Vector2((point.x - point.y) * 0.82, (point.x + point.y) * 0.41)

func _ready() -> void:
    _create_wall("NorthWall", Vector2(0, -DUNGEON_SIZE.y / 2.0), Vector2(DUNGEON_SIZE.x + WALL_THICKNESS, WALL_THICKNESS))
    _create_wall("SouthWall", Vector2(0, DUNGEON_SIZE.y / 2.0), Vector2(DUNGEON_SIZE.x + WALL_THICKNESS, WALL_THICKNESS))
    _create_wall("WestWall", Vector2(-DUNGEON_SIZE.x / 2.0, 0), Vector2(WALL_THICKNESS, DUNGEON_SIZE.y + WALL_THICKNESS))
    _create_wall("EastUpper", Vector2(400, -157.5), Vector2(24, 225))
    _create_wall("EastLower", Vector2(400, 157.5), Vector2(24, 225))
    _create_wall("CorridorNorth", Vector2(485, -57), Vector2(170, 24))
    _create_wall("CorridorSouth", Vector2(485, 57), Vector2(170, 24))
    _create_wall("ChamberNorth", Vector2(725, -165), Vector2(310, 24))
    _create_wall("ChamberSouth", Vector2(725, 165), Vector2(310, 24))
    _create_wall("ChamberEast", Vector2(880, 0), Vector2(24, 330))
    _create_wall("ChamberWestUpper", Vector2(570, -105), Vector2(24, 120))
    _create_wall("ChamberWestLower", Vector2(570, 105), Vector2(24, 120))
    _create_wall("CoverWall", COVER_CENTER, COVER_SIZE)
    _create_wall("SecondCoverWall", SECOND_COVER_CENTER, SECOND_COVER_SIZE)
    _build_navigation()
    var view := Node2D.new()
    view.name = "IsometricView"
    view.set_script(ISO_VIEW)
    add_child(view)
    view.call("configure", [Rect2(-DUNGEON_SIZE * 0.5, DUNGEON_SIZE), CORRIDOR, CHAMBER], wall_rects)
    for child in get_children():
        if child is CharacterBody2D:
            child.modulate.a = 0.0
    var camera := get_node_or_null("Camera2D") as Camera2D
    if camera != null:
        camera.ignore_rotation = true
        camera.rotation = 0.0
        camera.zoom = Vector2(1.05, 1.05)

func _process(delta: float) -> void:
    var hero := get_node_or_null("Player") as Node2D
    var camera := get_node_or_null("Camera2D") as Camera2D
    if hero != null and camera != null:
        camera.global_position = camera.global_position.lerp(_project(hero.global_position), minf(1.0, delta * 6.0))


func _build_navigation() -> void:
    navigation_grid = AStarGrid2D.new()
    navigation_grid.region = Rect2i(-19, -12, 64, 25)
    navigation_grid.cell_size = Vector2(NAV_CELL, NAV_CELL)
    navigation_grid.offset = Vector2.ZERO
    navigation_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    navigation_grid.update()
    for x in range(navigation_grid.region.position.x, navigation_grid.region.end.x):
        for y in range(navigation_grid.region.position.y, navigation_grid.region.end.y):
            var point := Vector2(x * NAV_CELL, y * NAV_CELL)
            var in_main: bool = absf(point.x) < 378.0 and absf(point.y) < 248.0
            var in_corridor: bool = point.x >= 380.0 and point.x < 585.0 and absf(point.y) < 27.0
            var in_chamber: bool = point.x >= 585.0 and point.x < 858.0 and absf(point.y) < 143.0
            if not (in_main or in_corridor or in_chamber) or _inside_cover(point, COVER_CENTER, COVER_SIZE) or _inside_cover(point, SECOND_COVER_CENTER, SECOND_COVER_SIZE):
                navigation_grid.set_point_solid(Vector2i(x, y), true)

func _inside_cover(point: Vector2, center: Vector2, size: Vector2) -> bool:
    var clearance := Vector2(18.0, 18.0)
    return Rect2(center - size / 2.0 - clearance, size + clearance * 2.0).has_point(point)

func navigation_step(from_position: Vector2, destination: Vector2) -> Vector2:
    var start := Vector2i(roundi(from_position.x / NAV_CELL), roundi(from_position.y / NAV_CELL))
    var finish := Vector2i(roundi(destination.x / NAV_CELL), roundi(destination.y / NAV_CELL))
    start = _nearest_open_cell(start)
    finish = _nearest_open_cell(finish)
    if start == finish:
        return destination
    var path := navigation_grid.get_point_path(start, finish)
    if path.size() < 2:
        return from_position
    return path[1]

func _nearest_open_cell(cell: Vector2i) -> Vector2i:
    var bounds := navigation_grid.region
    cell.x = clampi(cell.x, bounds.position.x, bounds.end.x - 1)
    cell.y = clampi(cell.y, bounds.position.y, bounds.end.y - 1)
    if not navigation_grid.is_point_solid(cell):
        return cell
    for radius in range(1, 6):
        for x in range(cell.x - radius, cell.x + radius + 1):
            for y in range(cell.y - radius, cell.y + radius + 1):
                var candidate := Vector2i(x, y)
                if bounds.has_point(candidate) and not navigation_grid.is_point_solid(candidate):
                    return candidate
    return cell

func _create_wall(wall_name: String, wall_position: Vector2, wall_size: Vector2) -> void:
    var wall := StaticBody2D.new()
    wall.name = wall_name
    wall.position = wall_position
    wall.collision_layer = 1
    wall.collision_mask = 0

    var shape := RectangleShape2D.new()
    shape.size = wall_size
    var collision := CollisionShape2D.new()
    collision.shape = shape
    wall.add_child(collision)
    add_child(wall)
    wall_rects.append(Rect2(wall_position - wall_size * 0.5, wall_size))

func _draw() -> void:
    pass # Rendered by IsometricView.
