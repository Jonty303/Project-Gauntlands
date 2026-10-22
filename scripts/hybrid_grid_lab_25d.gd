extends Node3D
## Hybrid test: GridMap floors; snapped wall scenes with persistent collision.
const CELL := 2.0
const HEIGHT := 2.8
const THICK := 0.24
var player: CharacterBody3D
var camera: Camera3D
var yaw := 45.0
var cutaway := true
var wall_parts: Array[Dictionary] = []
var solid_mat: StandardMaterial3D
var faded_mat: StandardMaterial3D

func _ready() -> void:
    solid_mat = _mat(Color("#77756f"))
    faded_mat = _mat(Color(0.55,0.55,0.53,0.14))
    faded_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    faded_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    var floor_mat := _mat(Color("#484944"))
    var library := MeshLibrary.new()
    library.create_item(0)
    library.set_item_name(0,"Stone floor")
    var tile := BoxMesh.new()
    tile.size = Vector3(CELL,0.2,CELL)
    tile.material = floor_mat
    library.set_item_mesh(0,tile)
    var floor_grid := GridMap.new()
    floor_grid.name = "FloorGridMap"
    floor_grid.cell_size = Vector3(CELL,CELL,CELL)
    floor_grid.mesh_library = library
    add_child(floor_grid)
    # Two 12x10m chambers connected by a 6x4m corridor.
    for x in range(-7,8):
        for z in range(-2,3):
            if x <= -2 or x >= 2 or absi(z) <= 1:
                floor_grid.set_cell_item(Vector3i(x,0,z),0)
    # Centre-line perimeter, with an exact 2m gap at each doorway.
    _wall(Vector3(-15,0,-5),Vector3(-3,0,-5))
    _wall(Vector3(-15,0,5),Vector3(-3,0,5))
    _wall(Vector3(-15,0,-5),Vector3(-15,0,5))
    _wall(Vector3(-3,0,-5),Vector3(-3,0,-1))
    _wall(Vector3(-3,0,1),Vector3(-3,0,5))
    _wall(Vector3(-3,0,-2),Vector3(3,0,-2))
    _wall(Vector3(-3,0,2),Vector3(3,0,2))
    _wall(Vector3(3,0,-5),Vector3(3,0,-1))
    _wall(Vector3(3,0,1),Vector3(3,0,5))
    _wall(Vector3(3,0,-5),Vector3(15,0,-5))
    _wall(Vector3(3,0,5),Vector3(15,0,5))
    _wall(Vector3(15,0,-5),Vector3(15,0,5))
    # Explicit structural posts hide wall termination seams.
    for x in [-15,-3,3,15]:
        for z in [-5,5]:
            _post(Vector3(x,0,z))
    for x in [-3,3]:
        for z in [-2,2]:
            _post(Vector3(x,0,z))
    for x in [-3,3]:
        for z in [-1,1]:
            _post(Vector3(x,0,z),0.3)
    player = CharacterBody3D.new()
    player.position = Vector3(-9,0,0)
    add_child(player)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    body.mesh = capsule
    body.position.y = 0.9
    body.material_override = _mat(Color("#59abc5"))
    player.add_child(body)
    var shape := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.35
    capsule_shape.height = 1.8
    shape.shape = capsule_shape
    shape.position.y = 0.9
    player.add_child(shape)
    camera = Camera3D.new()
    camera.current = true
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 20.0
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
    label.text = "HYBRID GRID LAB | WASD move | Q/E rotate | C cutaway\nThin walls, 2m doors, persistent collision."
    canvas.add_child(label)
    _update_camera()
    _update_cutaway()

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    return material

func _wall(a: Vector3,b: Vector3) -> void:
    var span := b-a
    var horizontal := absf(span.x) > absf(span.z)
    var size := Vector3(span.length(),HEIGHT,THICK) if horizontal else Vector3(THICK,HEIGHT,span.length())
    var center := (a+b)*0.5
    var solid := StaticBody3D.new()
    solid.position = center+Vector3(0,HEIGHT*0.5,0)
    add_child(solid)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    solid.add_child(collision)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = solid_mat
    solid.add_child(visual)
    var cap := MeshInstance3D.new()
    var cap_mesh := BoxMesh.new()
    cap_mesh.size = Vector3(size.x,0.07,size.z)
    cap.mesh = cap_mesh
    cap.position.y = HEIGHT*0.5+0.035
    cap.material_override = _mat(Color("#a7a296"))
    solid.add_child(cap)
    wall_parts.append({"visual":visual,"cap":cap,"center":center,"a":a,"b":b})

func _post(at: Vector3,width: float = 0.38) -> void:
    var root := StaticBody3D.new()
    root.position = at+Vector3(0,HEIGHT*0.5,0)
    add_child(root)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(width,HEIGHT,width)
    visual.mesh = mesh
    visual.material_override = solid_mat
    root.add_child(visual)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(width,HEIGHT,width)
    shape.shape = box
    root.add_child(shape)
    wall_parts.append({"visual":visual,"cap":null,"center":at,"a":at,"b":at})

func _physics_process(_delta: float) -> void:
    var input := Input.get_vector("move_left","move_right","move_up","move_down")
    var right := camera.global_transform.basis.x
    var forward := -camera.global_transform.basis.z
    right.y = 0
    forward.y = 0
    player.velocity = (right.normalized()*input.x-forward.normalized()*input.y).normalized()*5.0
    player.move_and_slide()
    _update_camera()
    _update_cutaway()

func _update_camera() -> void:
    var angle := deg_to_rad(yaw)
    var elevation := deg_to_rad(24.0)
    camera.global_position = player.global_position+Vector3(sin(angle)*cos(elevation),sin(elevation),cos(angle)*cos(elevation))*26.0
    camera.look_at(player.global_position+Vector3(0,0.8,0))

func _update_cutaway() -> void:
    var direction := camera.global_position-player.global_position
    for wall in wall_parts:
        var center: Vector3 = wall["center"]
        var front := (center-player.global_position).dot(direction) > 0.0
        var visual: MeshInstance3D = wall["visual"]
        visual.material_override = faded_mat if cutaway and front else solid_mat
        var cap: Variant = wall["cap"]
        if cap != null:
            cap.visible = not (cutaway and front)

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_Q:
        yaw -= 45.0
    elif event.keycode == KEY_E:
        yaw += 45.0
    elif event.keycode == KEY_C:
        cutaway = not cutaway
