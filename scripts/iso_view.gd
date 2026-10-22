extends Node2D
const Projection = preload("res://scripts/iso_projection.gd")
const TILE := 40.0
const WALL_HEIGHT := 76.0
const FLOOR := Color("#343b43")
const STONE := Color("#6e7476")
const SIDE := Color("#414b53")
const TOP := Color("#aaa69a")
const JOINT := Color("#424b53")

var actors: Array[Node2D] = []
var projectiles: Array[Node2D] = []
var wall_segments: Array[Rect2] = []
var floor_rooms: Array[Rect2] = []

func configure(room_rects: Array[Rect2], wall_rects: Array[Rect2]) -> void:
    floor_rooms = room_rects
    wall_segments = wall_rects
    queue_redraw()

func _ready() -> void:
    z_index = 1

func _process(_delta: float) -> void:
    actors.clear()
    projectiles.clear()
    for actor in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("enemies"):
        if actor is Node2D:
            actors.append(actor)
    for child in get_parent().get_children():
        if child.get_script() == preload("res://scripts/arrow.gd"):
            projectiles.append(child)
    queue_redraw()

func _diamond(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
    draw_colored_polygon(PackedVector2Array([
        Projection.project(a), Projection.project(b),
        Projection.project(c), Projection.project(d)
    ]), color)

func _draw() -> void:
    for room in floor_rooms:
        var x := room.position.x
        while x < room.end.x - 0.01:
            var y := room.position.y
            while y < room.end.y - 0.01:
                var x2: float = minf(x + TILE, room.end.x)
                var y2: float = minf(y + TILE, room.end.y)
                var shade: float = 0.91 if (int(floorf(x / TILE)) + int(floorf(y / TILE))) % 2 == 0 else 1.0
                _diamond(Vector2(x,y), Vector2(x2,y), Vector2(x2,y2), Vector2(x,y2), FLOOR * shade)
                y += TILE
            x += TILE
    # Sort raised architecture and figures by their projected floor depth.
    var items: Array[Dictionary] = []
    for wall in wall_segments:
        items.append({"depth": Projection.project(wall.end).y, "kind": "wall", "wall": wall})
    for actor in actors:
        items.append({"depth": Projection.project(actor.global_position).y, "kind": "actor", "actor": actor})
    for arrow in projectiles:
        items.append({"depth": Projection.project(arrow.global_position).y, "kind": "arrow", "actor": arrow})
    items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["depth"] < b["depth"])
    for item in items:
        match item["kind"]:
            "wall":
                _draw_wall(item["wall"])
            "actor":
                _draw_actor(item["actor"])
            "arrow":
                _draw_arrow(item["actor"])

func _draw_wall(wall: Rect2) -> void:
    var a := Projection.project(wall.position)
    var b := Projection.project(Vector2(wall.end.x, wall.position.y))
    var c := Projection.project(wall.end)
    var d := Projection.project(Vector2(wall.position.x, wall.end.y))
    var rise := Vector2(0, -WALL_HEIGHT)
    draw_colored_polygon(PackedVector2Array([b,c,c+rise,b+rise]), SIDE)
    draw_colored_polygon(PackedVector2Array([d,c,c+rise,d+rise]), STONE)
    draw_colored_polygon(PackedVector2Array([a+rise,b+rise,c+rise,d+rise]), TOP)
    for course in [0.25, 0.50, 0.75]:
        var lift := rise * course
        draw_line(b+lift,c+lift,JOINT,1.5)
        draw_line(d+lift,c+lift,JOINT,1.5)
    draw_line(a+rise,b+rise,Color("#c0b9a9"),2.0)
    draw_line(b+rise,c+rise,Color("#c0b9a9"),2.0)

func _draw_actor(actor: Node2D) -> void:
    var foot := Projection.project(actor.global_position)
    var is_hero: bool = actor.is_in_group("player")
    var skin := Color("#bca07c") if is_hero else Color("#718f53")
    var cloth := Color("#64736e") if is_hero else Color("#65543b")
    var shadow := Color(0.02,0.03,0.04,0.5)
    draw_set_transform(foot)
    draw_set_transform(Vector2(foot.x,foot.y+3),0,Vector2(1.0,0.40))
    draw_circle(Vector2.ZERO,17,shadow)
    draw_set_transform(foot)
    draw_line(Vector2(-7,-8),Vector2(-9,5),Color("#3c342d"),7)
    draw_line(Vector2(7,-8),Vector2(9,5),Color("#3c342d"),7)
    draw_colored_polygon(PackedVector2Array([Vector2(-15,-9),Vector2(-13,-33),Vector2(0,-38),Vector2(13,-33),Vector2(15,-9)]),cloth)
    draw_colored_polygon(PackedVector2Array([Vector2(-12,-30),Vector2(0,-37),Vector2(0,-10),Vector2(-12,-13)]),cloth.lightened(0.28))
    draw_line(Vector2(-13,-29),Vector2(-17,-15),skin.darkened(0.3),6)
    draw_line(Vector2(13,-29),Vector2(17,-15),skin.darkened(0.4),6)
    draw_circle(Vector2(0,-43),10,skin)
    draw_circle(Vector2(4,-44),7,skin.darkened(0.23))
    if is_hero:
        draw_colored_polygon(PackedVector2Array([Vector2(-11,-44),Vector2(-8,-53),Vector2(7,-53),Vector2(11,-44)]),Color("#a1a6a8"))
        draw_line(Vector2(-6,-45),Vector2(7,-45),Color("#32383a"),3)
    else:
        draw_colored_polygon(PackedVector2Array([Vector2(-8,-44),Vector2(-23,-49),Vector2(-12,-35)]),skin.darkened(0.12))
        draw_colored_polygon(PackedVector2Array([Vector2(8,-44),Vector2(23,-49),Vector2(12,-35)]),skin.darkened(0.12))
        draw_circle(Vector2(-4,-44),2,Color("#f0d392"))
        draw_circle(Vector2(5,-44),2,Color("#f0d392"))
    draw_set_transform(Vector2.ZERO)

func _draw_arrow(arrow: Node2D) -> void:
    var foot := Projection.project(arrow.global_position) + Vector2(0,-20)
    var direction := Projection.projected_direction(arrow.direction)
    draw_line(foot-direction*12,foot+direction*14,Color("#e4ca8e"),3)
    draw_line(foot+direction*12,foot+direction*19,Color("#f9f6e4"),4)
