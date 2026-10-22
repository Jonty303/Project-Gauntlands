extends Node3D
## Geometry audit: every floor, wall and opening derives from ONE cell occupancy map.
## No independently authored world-space wall endpoints.
const CELL: float = 2.0
const WALL_HEIGHT: float = 2.8
const WALL_THICKNESS: float = 0.22
var occupied: Dictionary = {}
var wall_records: Array[Dictionary] = []
var hero: CharacterBody3D
var camera: Camera3D
var camera_yaw: float = 45.0
var cutaway: bool = false
var floor_material: StandardMaterial3D
var wall_material: StandardMaterial3D

func _ready() -> void:
    floor_material = _material(Color("#51524d"))
    wall_material = _material(Color("#8a8980"))
    _define_layout()
    _build_floor_grid()
    _build_boundary_walls()
    _build_hero()
    _build_camera_and_light()
    _build_label()
    _update_camera()
    _update_visibility()

func _define_layout() -> void:
    # Chamber cells -7..-2 and 2..7; corridor -1..1.
    # The only source of truth is this set of occupied integer cells.
    for x in range(-7,8):
        for z in range(-2,3):
            if x <= -2 or x >= 2 or absi(z) <= 1:
                occupied[Vector2i(x,z)] = true

func _build_floor_grid() -> void:
    var library := MeshLibrary.new()
    library.create_item(0)
    library.set_item_name(0,"2m floor")
    var tile := BoxMesh.new()
    tile.size = Vector3(CELL,0.18,CELL)
    tile.material = floor_material
    library.set_item_mesh(0,tile)
    var grid := GridMap.new()
    grid.name = "AuthoritativeFloorGrid"
    grid.mesh_library = library
    grid.cell_size = Vector3(CELL,CELL,CELL)
    add_child(grid)
    for key in occupied:
        var cell: Vector2i = key
        grid.set_cell_item(Vector3i(cell.x,0,cell.y),0)

func _build_boundary_walls() -> void:
    # Each outer edge is emitted once. Interior edges are empty except
    # doorway partitions: a 2m centre opening and solid side spans.
    for key in occupied:
        var cell: Vector2i = key
        for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
            var neighbor: Vector2i = cell+offset
            var is_outer: bool = not occupied.has(neighbor)
            var doorway_partition: bool = false
            if offset == Vector2i(1,0) and (cell.x == -2 or cell.x == 1):
                doorway_partition = cell.y != 0
            if offset == Vector2i(-1,0) and (cell.x == -1 or cell.x == 2):
                doorway_partition = cell.y != 0
            if not is_outer and not doorway_partition:
                continue
            # Only the chamber side emits the shared partition.
            if doorway_partition and (cell.x == -1 or cell.x == 2):
                continue
            var center := Vector3(float(cell.x)*CELL,0,float(cell.y)*CELL)
            var along_x: bool = offset.y != 0
            var edge_center := center+Vector3(float(offset.x)*CELL*0.5,0,float(offset.y)*CELL*0.5)
            _wall_piece(edge_center,along_x)

func _wall_piece(at: Vector3,along_x: bool) -> void:
    var size := Vector3(CELL,WALL_HEIGHT,WALL_THICKNESS) if along_x else Vector3(WALL_THICKNESS,WALL_HEIGHT,CELL)
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
    wall_records.append({"visual":visual,"center":at})

func _build_hero() -> void:
    hero = CharacterBody3D.new()
    hero.position = Vector3(-10,0,0)
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
    camera.size = 21.0
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
    label.text = "GEOMETRY AUDIT | WASD move | Q/E rotate | C hide foreground walls\nWalls and floors use identical integer grid coordinates. Cutaway starts OFF."
    ui.add_child(label)

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    return mat

func _physics_process(_delta: float) -> void:
    var input := Input.get_vector("move_left","move_right","move_up","move_down")
    var right := camera.global_transform.basis.x
    var forward := -camera.global_transform.basis.z
    right.y = 0
    forward.y = 0
    hero.velocity = (right.normalized()*input.x-forward.normalized()*input.y).normalized()*5.0
    hero.move_and_slide()
    _update_camera()
    _update_visibility()

func _update_camera() -> void:
    var angle := deg_to_rad(camera_yaw)
    var elevation := deg_to_rad(24.0)
    camera.global_position = hero.global_position+Vector3(sin(angle)*cos(elevation),sin(elevation),cos(angle)*cos(elevation))*26.0
    camera.look_at(hero.global_position+Vector3(0,0.8,0))

func _update_visibility() -> void:
    var toward_camera := camera.global_position-hero.global_position
    for record in wall_records:
        var position: Vector3 = record["center"]
        var visual: MeshInstance3D = record["visual"]
        visual.visible = not (cutaway and (position-hero.global_position).dot(toward_camera)>0.0)

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_Q:
        camera_yaw -= 45.0
    elif event.keycode == KEY_E:
        camera_yaw += 45.0
    elif event.keycode == KEY_C:
        cutaway = not cutaway
