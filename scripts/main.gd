extends Node2D

const DUNGEON_SIZE := Vector2(800.0, 540.0)
const WALL_THICKNESS := 24.0
const FLOOR_COLOR := Color("#242832")
const GRID_COLOR := Color("#343945")
const WALL_COLOR := Color("#596171")

func _ready() -> void:
    _create_wall("NorthWall", Vector2(0, -DUNGEON_SIZE.y / 2.0), Vector2(DUNGEON_SIZE.x + WALL_THICKNESS, WALL_THICKNESS))
    _create_wall("SouthWall", Vector2(0, DUNGEON_SIZE.y / 2.0), Vector2(DUNGEON_SIZE.x + WALL_THICKNESS, WALL_THICKNESS))
    _create_wall("WestWall", Vector2(-DUNGEON_SIZE.x / 2.0, 0), Vector2(WALL_THICKNESS, DUNGEON_SIZE.y + WALL_THICKNESS))
    _create_wall("EastWall", Vector2(DUNGEON_SIZE.x / 2.0, 0), Vector2(WALL_THICKNESS, DUNGEON_SIZE.y + WALL_THICKNESS))

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
