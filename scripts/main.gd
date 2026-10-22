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
var navigation_grid: AStarGrid2D

func _ready() -> void:
    _create_wall("NorthWall", Vector2(0, -DUNGEON_SIZE.y / 2.0), Vector2(DUNGEON_SIZE.x + WALL_THICKNESS, WALL_THICKNESS))
    _create_wall("SouthWall", Vector2(0, DUNGEON_SIZE.y / 2.0), Vector2(DUNGEON_SIZE.x + WALL_THICKNESS, WALL_THICKNESS))
    _create_wall("WestWall", Vector2(-DUNGEON_SIZE.x / 2.0, 0), Vector2(WALL_THICKNESS, DUNGEON_SIZE.y + WALL_THICKNESS))
    _create_wall("EastWall", Vector2(DUNGEON_SIZE.x / 2.0, 0), Vector2(WALL_THICKNESS, DUNGEON_SIZE.y + WALL_THICKNESS))
    _create_wall("CoverWall", COVER_CENTER, COVER_SIZE)
    _create_wall("SecondCoverWall", SECOND_COVER_CENTER, SECOND_COVER_SIZE)
    _build_navigation()

func _build_navigation() -> void:
    navigation_grid = AStarGrid2D.new()
    navigation_grid.region = Rect2i(-19, -12, 39, 25)
    navigation_grid.cell_size = Vector2(NAV_CELL, NAV_CELL)
    navigation_grid.offset = Vector2.ZERO
    navigation_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    navigation_grid.update()
    for x in range(navigation_grid.region.position.x, navigation_grid.region.end.x):
        for y in range(navigation_grid.region.position.y, navigation_grid.region.end.y):
            var point := Vector2(x * NAV_CELL, y * NAV_CELL)
            if _inside_cover(point, COVER_CENTER, COVER_SIZE) or _inside_cover(point, SECOND_COVER_CENTER, SECOND_COVER_SIZE):
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

func _draw() -> void:
    var floor_rect := Rect2(-DUNGEON_SIZE / 2.0, DUNGEON_SIZE)
    draw_rect(floor_rect, FLOOR_COLOR)
    for x in range(-400, 401, 40):
        draw_line(Vector2(x, -270), Vector2(x, 270), GRID_COLOR)
    for y in range(-270, 271, 40):
        draw_line(Vector2(-400, y), Vector2(400, y), GRID_COLOR)

    var half := DUNGEON_SIZE / 2.0
    var t := WALL_THICKNESS
    draw_rect(Rect2(-half.x - t / 2.0, -half.y - t / 2.0, DUNGEON_SIZE.x + t, t), WALL_COLOR)
    draw_rect(Rect2(-half.x - t / 2.0, half.y - t / 2.0, DUNGEON_SIZE.x + t, t), WALL_COLOR)
    draw_rect(Rect2(-half.x - t / 2.0, -half.y - t / 2.0, t, DUNGEON_SIZE.y + t), WALL_COLOR)
    draw_rect(Rect2(half.x - t / 2.0, -half.y - t / 2.0, t, DUNGEON_SIZE.y + t), WALL_COLOR)
    draw_rect(Rect2(COVER_CENTER - COVER_SIZE / 2.0, COVER_SIZE), WALL_COLOR)
    draw_rect(Rect2(SECOND_COVER_CENTER - SECOND_COVER_SIZE / 2.0, SECOND_COVER_SIZE), WALL_COLOR)

