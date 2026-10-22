extends Node3D
## Geometry audit: every floor, wall and opening derives from ONE cell occupancy map.
## No independently authored world-space wall endpoints.
const CELL: float = 2.0
const WALL_HEIGHT: float = 2.8
const WALL_THICKNESS: float = 0.22
var occupied: Dictionary = {}
var room_by_cell: Dictionary = {}
const RoomVisibility = preload("res://scripts/room_visibility_25d.gd")
const RenderVisibility = preload("res://scripts/room_render_visibility_25d.gd")
const Occlusion = preload("res://scripts/wall_occlusion_25d.gd")
const WALL_OCCLUDED_ALPHA := 0.20
const DOOR_OCCLUDED_ALPHA := 0.28
const FADE_SECONDS := 0.22
var visibility := RoomVisibility.new()
var discovered_rooms: Dictionary = {}
const ROOM_NEIGHBORS := {0:[1],1:[0,2],2:[1]}
var wall_records: Array[Dictionary] = []
var hero: CharacterBody3D
var camera: Camera3D
var camera_yaw: float = 45.0
var cutaway: bool = true
var top_down: bool = false
var floor_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var door_material: StandardMaterial3D
var doors: Array[Dictionary] = []
var floor_grid: GridMap
var floor_visuals: Dictionary = {}
var floor_origin: Vector3 = Vector3.ZERO

func _ready() -> void:
    floor_material = _material(Color("#51524d"))
    wall_material = _material(Color("#8a8980"))
    door_material = _material(Color("#5c4430"))
    _define_layout()
    visibility.configure(room_by_cell, ROOM_NEIGHBORS, 0)
    discovered_rooms = visibility.discovered
    _build_floor_grid()
    _build_boundary_walls()
    _build_doorway_returns()
    _build_doors()
    _build_hero()
    _build_camera_and_light()
    _build_label()
    _refresh_discovery_visuals()
    _update_camera()
    _update_visibility(1.0)

func _define_layout() -> void:
    # Chamber cells -7..-2 and 2..7; corridor -1..1.
    # The only source of truth is this set of occupied integer cells.
    for x in range(-7,8):
        for z in range(-2,3):
            if x <= -2 or x >= 2 or absi(z) <= 1:
                occupied[Vector2i(x,z)] = true
                room_by_cell[Vector2i(x,z)] = 0 if x <= -2 else (2 if x >= 2 else 1)

func _build_floor_grid() -> void:
    var library := MeshLibrary.new()
    library.create_item(0)
    library.set_item_name(0,"2m floor")
    var tile := BoxMesh.new()
    tile.size = Vector3(CELL,0.18,CELL)
    tile.material = floor_material
    # Collision-only GridMap tile: visible floor uses separate MeshInstance3D.
    var collision_tile := BoxMesh.new()
    collision_tile.size = Vector3(CELL,0.18,CELL)
    collision_tile.material = _material(Color(0,0,0,0))
    collision_tile.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    library.set_item_mesh(0,collision_tile)
    var floor_shape := BoxShape3D.new()
    floor_shape.size = Vector3(CELL,0.18,CELL)
    # MeshLibrary expects alternating Shape3D/Transform3D entries.
    library.set_item_shapes(0,[floor_shape,Transform3D.IDENTITY])
    var grid := GridMap.new()
    floor_grid = grid
    grid.name = "AuthoritativeFloorGrid"
    grid.mesh_library = library
    grid.cell_size = Vector3(CELL,CELL,CELL)
    grid.cell_center_x = true
    grid.cell_center_y = true
    grid.cell_center_z = true
    add_child(grid)
    # Measure the actual GridMap transform instead of assuming its cell origin.
    floor_origin = grid.to_global(grid.map_to_local(Vector3i.ZERO))
    print("Measured GridMap origin: ", floor_origin)
    for key in occupied:
        var cell: Vector2i = key
        var map_cell := Vector3i(cell.x,0,cell.y)
        grid.set_cell_item(map_cell,0)
        # Floor mesh is rendered separately: GridMap remains permanent collision.
        var floor_visual := MeshInstance3D.new()
        floor_visual.mesh = tile
        floor_visual.position = grid.map_to_local(map_cell)
        grid.add_child(floor_visual)
        floor_visuals[cell] = floor_visual
        var actual_center: Vector3 = grid.to_global(grid.map_to_local(map_cell))
        var expected_center := floor_origin+Vector3(float(cell.x)*CELL,0,float(cell.y)*CELL)
        assert(actual_center.distance_to(expected_center) < 0.001,"GridMap floor centre disagrees with wall coordinate convention")

func _build_boundary_walls() -> void:
    # An edge exists if and only if one side is occupied and the other is void.
    # Adjacent floor cells NEVER receive a separating wall. This removes the
    # previous hard-coded doorway partitions that obstructed the corridor.
    var unique_edges: Dictionary = {}
    var vertices: Dictionary = {}
    for key in occupied:
        var cell: Vector2i = key
        for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
            var neighbor: Vector2i = cell+offset
            if occupied.has(neighbor):
                continue
            var edge_x: int = cell.x*2+offset.x
            var edge_z: int = cell.y*2+offset.y
            var along_x: bool = offset.y != 0
            var edge_key := "%d:%d:%d" % [edge_x,edge_z,int(along_x)]
            assert(not unique_edges.has(edge_key),"Duplicate boundary edge")
            unique_edges[edge_key] = true
            var midpoint := floor_origin+Vector3(float(edge_x)*CELL*0.5,0,float(edge_z)*CELL*0.5)
            var owner: int = room_by_cell[cell]
            var outward := Vector3(float(offset.x),0,float(offset.y))
            _wall_piece(midpoint,along_x,owner,outward)
            # Corners are derived from wall edges, not independently placed.
            var tangent := Vector3(CELL*0.5,0,0) if along_x else Vector3(0,0,CELL*0.5)
            for endpoint in [midpoint-tangent,midpoint+tangent]:
                var vertex_key := "%0.2f:%0.2f" % [endpoint.x,endpoint.z]
                if not vertices.has(vertex_key):
                    vertices[vertex_key] = {"point":endpoint,"owners":[],"normals":[]}
                var vertex: Dictionary = vertices[vertex_key]
                vertex["owners"].append(owner)
                vertex["normals"].append(outward)
    for key in vertices:
        var vertex: Dictionary = vertices[key]
        _corner_fill(vertex["point"],vertex["owners"],vertex["normals"])
    print("Geometry audit: %d floor cells, %d unique exposed edges, %d corner joins" % [occupied.size(),unique_edges.size(),vertices.size()])

func _corner_fill(at: Vector3, owners: Array, normals: Array) -> void:
    # Fills the thickness-sized square at an edge intersection.
    # A single box at each unique vertex prevents cracks without overshooting.
    var solid := StaticBody3D.new()
    solid.position = at+Vector3(0,WALL_HEIGHT*0.5,0)
    add_child(solid)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(WALL_THICKNESS,WALL_HEIGHT,WALL_THICKNESS)
    shape.shape = box
    solid.add_child(shape)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = box.size
    visual.mesh = mesh
    visual.material_override = wall_material
    solid.add_child(visual)
    _register_wall(visual,at,owners,normals)

func _wall_piece(at: Vector3,along_x: bool,owner: int,outward: Vector3) -> void:
    # Each endpoint already owns a thickness-wide corner box. Stop at its face.
    var span: float = CELL-WALL_THICKNESS
    var size := Vector3(span,WALL_HEIGHT,WALL_THICKNESS) if along_x else Vector3(WALL_THICKNESS,WALL_HEIGHT,span)
    var solid := StaticBody3D.new()
    solid.position = at+Vector3(0,WALL_HEIGHT*0.5,0)
    add_child(solid)
    var collider := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    collider.shape = box
    solid.add_child(collider)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = wall_material
    solid.add_child(visual)
    _register_wall(visual,at,[owner],[outward])

func _register_wall(visual: MeshInstance3D,at: Vector3,owners: Array,normals: Array) -> void:
    assert(owners.size() == 1 or owners.size() == normals.size(), "Wall normals need explicit owners")
    var material := _material(Color(0.54,0.53,0.50,1.0))
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    visual.material_override = material
    wall_records.append({"visual":visual,"center":at,"owners":owners,"normals":normals,"material":material,"alpha":1.0})

func _build_doorway_returns() -> void:
    # Internal partitions belong to the room graph, not the exterior boundary.
    # Door opening: z=-0.875..+0.875; corridor spans z=-3..+3.
    # Both returns terminate exactly at the jamb, without overlapping the door.
    for x in [-3.0,3.0]:
        for side in [-1.0,1.0]:
            # The exterior corner fills the final half-thickness at the junction.
            var length: float = (3.0-WALL_THICKNESS*0.5-0.875)
            var z: float = side*(0.875+length*0.5)
            var at: Vector3 = floor_origin+Vector3(x,0,z)
            var owner: int = 0 if x < 0.0 else 2
            var outward := Vector3.RIGHT if x < 0.0 else Vector3.LEFT
            _partition_piece(at,Vector3(WALL_THICKNESS,WALL_HEIGHT,length),[owner,1],[outward,-outward])

func _partition_piece(at: Vector3,size: Vector3,owners: Array,normals: Array) -> void:
    var solid := StaticBody3D.new()
    solid.position = at+Vector3(0,WALL_HEIGHT*0.5,0)
    add_child(solid)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    solid.add_child(shape)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    solid.add_child(visual)
    _register_wall(visual,at,owners,normals)

func _build_doors() -> void:
    # Both door centres use the measured GridMap origin, as do the walls.
    # Interior partitions on either side leave exactly a 1.75m opening.
    for x in [-3.0,3.0]:
        var root := StaticBody3D.new()
        root.position = floor_origin+Vector3(x,1.18,0)
        root.name = "Door_%d" % int(x)
        add_child(root)
        var visual := MeshInstance3D.new()
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.13,2.36,1.75)
        visual.mesh = mesh
        var instance_material := _material(Color(0.36,0.27,0.19,1.0))
        instance_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        visual.material_override = instance_material
        root.add_child(visual)
        var collider := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = mesh.size
        collider.shape = box
        root.add_child(collider)
        doors.append({"body":root,"visual":visual,"collider":collider,"closed":true,"center":root.position,"material":instance_material,"alpha":1.0,"normals":[Vector3.RIGHT,Vector3.LEFT],"rooms":[0,1] if x < 0.0 else [1,2]})

func _current_room() -> int:
    return visibility.locate(floor_grid.to_local(hero.global_position), CELL)

func _toggle_nearby_door() -> void:
    for door in doors:
        var centre: Vector3 = door["center"]
        if hero.position.distance_to(centre-Vector3(0,1.18,0)) > 2.3:
            continue
        var now_closed: bool = not door["closed"]
        door["closed"] = now_closed
        var visual: MeshInstance3D = door["visual"]
        var collider: CollisionShape3D = door["collider"]
        visual.visible = now_closed and RenderVisibility.can_render(door["rooms"], discovered_rooms)
        collider.set_deferred("disabled",not now_closed)
        return

func _build_hero() -> void:
    hero = CharacterBody3D.new()
    hero.position = floor_origin+Vector3(-10,0.12,0)
    hero.floor_snap_length = 0.3
    add_child(hero)
    var visual := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.34
    capsule.height = 1.8
    visual.mesh = capsule
    visual.material_override = _material(Color("#62b2c6"))
    visual.position.y = 0.9
    hero.add_child(visual)
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.34
    shape.height = 1.8
    collision.shape = shape
    collision.position.y = 0.9
    hero.add_child(collision)

func _build_camera_and_light() -> void:
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 19.0
    camera.current = true
    add_child(camera)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-30,0)
    sun.light_energy = 1.7
    add_child(sun)
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#1e2630")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#b2bdca")
    env.ambient_light_energy = 0.75
    world.environment = env
    add_child(world)

func _build_label() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)
    var label := Label.new()
    label.position = Vector2(16,16)
    label.text = "VISIBILITY LAB | WASD move | Q/E rotate | F open door | C translucent walls | T top-down\nOnly walls obstructing the player fade; discovery and collision stay independent."
    ui.add_child(label)

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    return mat

func _physics_process(_delta: float) -> void:
    var input := Input.get_vector("move_left","move_right","move_up","move_down")
    # Yaw defines screen-relative motion even when the camera looks straight down.
    var angle := deg_to_rad(camera_yaw)
    var right := Vector3(cos(angle),0,-sin(angle))
    var back := Vector3(sin(angle),0,cos(angle))
    var planar := (right*input.x+back*input.y).normalized()*5.0
    hero.velocity.x = planar.x
    hero.velocity.z = planar.z
    hero.velocity.y -= 20.0*_delta
    hero.move_and_slide()
    _update_camera()
    _current_room()
    if visibility.discover_current():
        _refresh_discovery_visuals()
    _update_visibility(_delta)

func _update_camera() -> void:
    var angle := deg_to_rad(camera_yaw)
    if top_down:
        camera.global_position = hero.global_position+Vector3(0,28,0)
        camera.look_at(hero.global_position, Vector3(-sin(angle),0,-cos(angle)))
        return
    var elevation := deg_to_rad(24.0)
    camera.global_position = hero.global_position+Vector3(sin(angle)*cos(elevation),sin(elevation),cos(angle)*cos(elevation))*26.0
    camera.look_at(hero.global_position+Vector3(0,0.8,0))

func _refresh_discovery_visuals() -> void:
    # Rendering policy consumes discovery; neither opacity nor camera can reveal rooms.
    for cell in floor_visuals:
        floor_visuals[cell].visible = RenderVisibility.can_render([room_by_cell[cell]], discovered_rooms)
    for record in wall_records:
        record["visual"].visible = RenderVisibility.can_render(record["owners"], discovered_rooms)
    for door in doors:
        door["visual"].visible = bool(door["closed"]) and RenderVisibility.can_render(door["rooms"], discovered_rooms)

func _update_visibility(delta: float) -> void:
    var targets := Occlusion.player_targets(camera, hero.global_position)
    var segments := Occlusion.sight_segments(camera, targets)
    for record in wall_records:
        var fade: bool = cutaway and Occlusion.obstructs(record["visual"], segments)
        _transition_opacity(record, WALL_OCCLUDED_ALPHA if fade else 1.0, delta)
    for door in doors:
        var fade: bool = cutaway and door["closed"] and Occlusion.obstructs(door["visual"], segments)
        _transition_opacity(door, DOOR_OCCLUDED_ALPHA if fade else 1.0, delta)

func _transition_opacity(record: Dictionary, target: float, delta: float) -> void:
    # Restart from the displayed alpha when a rotation or room transition interrupts.
    if record.get("target", -1.0) != target:
        record["target"] = target
        record["start_alpha"] = record["alpha"]
        record["elapsed"] = 0.0
    record["elapsed"] = minf(float(record["elapsed"]) + delta, FADE_SECONDS)
    var weight := smoothstep(0.0, 1.0, float(record["elapsed"]) / FADE_SECONDS)
    record["alpha"] = lerpf(float(record["start_alpha"]), target, weight)
    var material: StandardMaterial3D = record["material"]
    var color := material.albedo_color
    color.a = record["alpha"]
    material.albedo_color = color

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_F:
        _toggle_nearby_door()
    elif event.keycode == KEY_Q:
        camera_yaw -= 45.0
    elif event.keycode == KEY_E:
        camera_yaw += 45.0
    elif event.keycode == KEY_C:
        cutaway = not cutaway
    elif event.keycode == KEY_T:
        top_down = not top_down
