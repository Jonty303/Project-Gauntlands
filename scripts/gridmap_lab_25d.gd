extends Node3D
## GridMap comparison: each cell is a whole modular piece, not a wall-centreline.
const CELL := 2.0
const WALL_HEIGHT := 3.0
var grid: GridMap
var player: CharacterBody3D
var camera: Camera3D
var yaw := 45.0
var cutaway := true
var wall_visuals: Array[Dictionary] = []
var wall_material: StandardMaterial3D
var faded_material: StandardMaterial3D

func _ready() -> void:
    wall_material = _material(Color("#777c78"))
    faded_material = _material(Color(0.55,0.59,0.58,0.13))
    faded_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    faded_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    var floor_material := _material(Color("#424a50"))
    var library := MeshLibrary.new()
    _library_item(library,0,"Floor",Vector3(CELL,0.24,CELL),floor_material,false)
    _library_item(library,1,"Wall",Vector3(CELL,WALL_HEIGHT,CELL),wall_material,true)
    grid = GridMap.new()
    grid.name = "ModularGrid"
    grid.mesh_library = library
    grid.cell_size = Vector3(CELL,CELL,CELL)
    grid.cell_center_x = true
    grid.cell_center_y = true
    grid.cell_center_z = true
    add_child(grid)
    # Cells: left room x=-7..-2, corridor x=-1..1, right room x=2..7.
    # Floor occupies z=-3..3 in rooms, z=-1..1 in corridor.
    for x in range(-7,8):
        var room := x <= -2 or x >= 2
        for z in range(-3,4):
            if room or absi(z) <= 1:
                grid.set_cell_item(Vector3i(x,0,z),0)
    # Wall positions are discrete; door gaps are empty cells in shared boundary.
    for x in range(-8,9):
        for z in [-4,4]:
            if x <= -2 or x >= 2:
                _place_wall(x,z)
    for z in range(-3,4):
        _place_wall(-8,z)
        _place_wall(8,z)
        if z != 0:
            _place_wall(-2,z)
            _place_wall(2,z)
    for x in [-1,0,1]:
        _place_wall(x,-2)
        _place_wall(x,2)
    # The GridMap floor uses a single shared material; wall cells are separated
    # visually into independent meshes for camera-aware transparency.
    player = CharacterBody3D.new()
    player.position = Vector3(-10,0,0)
    add_child(player)
    var player_mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    player_mesh.mesh = capsule
    player_mesh.position.y = 0.9
    player_mesh.material_override = _material(Color("#60b6cf"))
    player.add_child(player_mesh)
    var collider := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.35
    capsule_shape.height = 1.8
    collider.shape = capsule_shape
    collider.position.y = 0.9
    player.add_child(collider)
    camera = Camera3D.new()
    camera.current = true
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 24.0
    add_child(camera)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55,-30,0)
    light.light_energy = 1.7
    add_child(light)
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#202832")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#b2bdca")
    env.ambient_light_energy = 0.75
    world.environment = env
    add_child(world)
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var label := Label.new()
    label.position = Vector2(16,16)
    label.text = "GRIDMAP LAB | WASD move | Q/E rotate | C toggle wall cutaway\n2m modular cells; doorways are empty grid cells."
    canvas.add_child(label)
    _update_camera()

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    return mat

func _library_item(library: MeshLibrary, id: int, label: String, dimensions: Vector3, material: Material, collision: bool) -> void:
    library.create_item(id)
    library.set_item_name(id,label)
    var box := BoxMesh.new()
    box.size = dimensions
    box.material = material
    library.set_item_mesh(id,box)
    if collision:
        # Grid cell y=1 centres at 2m; offset 0.5m so wall base rests at y=0.
        library.set_item_mesh_transform(id,Transform3D(Basis.IDENTITY,Vector3(0,-0.5,0)))
    if collision:
        var shape := BoxShape3D.new()
        shape.size = dimensions
        library.set_item_shapes(id,[shape,Transform3D(Basis.IDENTITY,Vector3(0,-0.5,0))])

func _place_wall(x: int, z: int) -> void:
    var cell := Vector3i(x,1,z)
    if grid.get_cell_item(cell) != GridMap.INVALID_CELL_ITEM:
        return
    # Each wall cell is a complete solid module; no intersecting cap segments.
    grid.set_cell_item(cell,1)
    # A thin top accent illustrates perfectly aligned module seams.
    var accent := MeshInstance3D.new()
    var top := BoxMesh.new()
    top.size = Vector3(CELL,0.06,CELL)
    accent.mesh = top
    accent.material_override = _material(Color("#aeb0a4"))
    accent.position = Vector3(x*CELL, WALL_HEIGHT+0.03,z*CELL)
    add_child(accent)
    wall_visuals.append({"accent":accent,"position":Vector3(x*CELL,0,z*CELL),"cell":cell})

func _physics_process(_delta: float) -> void:
    var input := Input.get_vector("move_left","move_right","move_up","move_down")
    var right := camera.global_transform.basis.x
    var forward := -camera.global_transform.basis.z
    right.y = 0
    forward.y = 0
    player.velocity = (right.normalized()*input.x - forward.normalized()*input.y).normalized()*5.0
    player.move_and_slide()
    _update_camera()
    # GridMap renders a shared batch, so individual cell alpha is not directly editable.
    # For now toggle foreground wall cells off, preserving their physics caveat for evaluation.
    var to_camera := camera.global_position-player.global_position
    for wall in wall_visuals:
        var position: Vector3 = wall["position"]
        var foreground := (position-player.global_position).dot(to_camera) > 0.0
        var cell: Vector3i = wall["cell"]
        var show_wall := not (cutaway and foreground)
        var accent: MeshInstance3D = wall["accent"]
        accent.visible = show_wall
        # GridMap cell removal also removes collision: this is an explicit limitation.
        var existing := grid.get_cell_item(cell)
        if show_wall and existing == GridMap.INVALID_CELL_ITEM:
            grid.set_cell_item(cell,1)
        elif not show_wall and existing != GridMap.INVALID_CELL_ITEM:
            grid.set_cell_item(cell,GridMap.INVALID_CELL_ITEM)

func _update_camera() -> void:
    var angle := deg_to_rad(yaw)
    var elevation := deg_to_rad(24.0)
    camera.global_position = player.global_position + Vector3(sin(angle)*cos(elevation),sin(elevation),cos(angle)*cos(elevation))*32.0
    camera.look_at(player.global_position+Vector3(0,0.8,0))

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_Q:
        yaw -= 45.0
    elif event.keycode == KEY_E:
        yaw += 45.0
    elif event.keycode == KEY_C:
        cutaway = not cutaway
