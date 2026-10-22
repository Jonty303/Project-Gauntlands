extends Node3D
## Layout-driven architecture test: one global set of wall spans, no per-room wall overlaps.
const HEIGHT := 3.0
const THICKNESS := 0.32
var walls: Array[Dictionary] = []
var materials: Dictionary = {}
var cutaway_enabled := true
var camera: Camera3D
var hero: CharacterBody3D
var camera_yaw := 45.0
var faded_material: StandardMaterial3D

func _ready() -> void:
    _setup_materials()
    # Adjacent rooms share their connecting boundaries. Every wall is emitted once.
    _floor(Vector3(-8, 0, 0), Vector2(12, 10))
    _floor(Vector3(0, 0, 0), Vector2(4, 3))
    _floor(Vector3(8, 0, 0), Vector2(12, 10))
    # Left room: X -14..-2, Z -5..5. Right: X 2..14.
    _wall(Vector3(-14,0,-5), Vector3(-2,0,-5))
    _wall(Vector3(-14,0,5), Vector3(-2,0,5))
    _wall(Vector3(-14,0,-5), Vector3(-14,0,5))
    _wall(Vector3(-2,0,-5), Vector3(-2,0,-0.85))
    _wall(Vector3(-2,0,0.85), Vector3(-2,0,5))
    _wall(Vector3(-2,0,-1.5), Vector3(2,0,-1.5))
    _wall(Vector3(-2,0,1.5), Vector3(2,0,1.5))
    _wall(Vector3(2,0,-5), Vector3(2,0,-0.85))
    _wall(Vector3(2,0,0.85), Vector3(2,0,5))
    _wall(Vector3(2,0,-5), Vector3(14,0,-5))
    _wall(Vector3(2,0,5), Vector3(14,0,5))
    _wall(Vector3(14,0,-5), Vector3(14,0,5))
    _build_junctions()
    _door_marker(Vector3(-2,0,0))
    _door_marker(Vector3(2,0,0))
    hero = CharacterBody3D.new()
    hero.position = Vector3(-8, 0, 0)
    add_child(hero)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.32
    capsule.height = 1.7
    body.mesh = capsule
    body.position.y = 0.85
    body.material_override = materials["hero"]
    hero.add_child(body)
    var shape := CollisionShape3D.new()
    var collider := CapsuleShape3D.new()
    collider.radius = 0.32
    collider.height = 1.7
    shape.shape = collider
    shape.position.y = 0.85
    hero.add_child(shape)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 18.0
    camera.current = true
    add_child(camera)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_energy = 1.8
    add_child(sun)
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#202832")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#a9b2c0")
    env.ambient_light_energy = 0.8
    environment.environment = env
    add_child(environment)
    _add_help()
    _update_camera()
    _update_cutaway()

func _setup_materials() -> void:
    faded_material = StandardMaterial3D.new()
    faded_material.albedo_color = Color(0.55,0.58,0.57,0.12)
    faded_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    faded_material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    for entry in [["floor","#3c4650"],["wall","#7d817b"],["cap","#c6c3a9"],["hero","#5e9bb9"],["door","#80512d"]]:
        var material := StandardMaterial3D.new()
        material.albedo_color = Color(entry[1])
        materials[entry[0]] = material

func _floor(center: Vector3, dimensions: Vector2) -> void:
    _mesh_box("Floor", center + Vector3(0,-0.12,0), Vector3(dimensions.x,0.24,dimensions.y), materials["floor"], false)

func _wall(a: Vector3, b: Vector3) -> void:
    var vector := b-a
    var along_x := absf(vector.x) > absf(vector.z)
    var length := vector.length()
    var midpoint := (a+b)*0.5
    var dimensions := Vector3(length, HEIGHT, THICKNESS) if along_x else Vector3(THICKNESS,HEIGHT,length)
    var solid := StaticBody3D.new()
    solid.name = "Wall"
    solid.position = midpoint + Vector3(0,HEIGHT*0.5,0)
    add_child(solid)
    var mesh := MeshInstance3D.new()
    var geometry := BoxMesh.new()
    geometry.size = dimensions
    mesh.mesh = geometry
    mesh.material_override = materials["wall"]
    solid.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = dimensions
    collision.shape = shape
    solid.add_child(collision)
    # Cap is visual-only and remains opaque when the wall face fades.
    var cap := MeshInstance3D.new()
    var top := BoxMesh.new()
    top.size = Vector3(dimensions.x,0.07,dimensions.z)
    cap.mesh = top
    cap.position.y = HEIGHT*0.5 + 0.035
    cap.material_override = materials["cap"]
    solid.add_child(cap)
    walls.append({"node":solid,"face":mesh,"a":a,"b":b,"center":midpoint})

func _build_junctions() -> void:
    # Cover each unique perpendicular corner with one thickness-sized column.
    # Wall centre lines end at the joint; caps do not extend past endpoints.
    var junctions: Dictionary = {}
    for wall in walls:
        for point in [wall["a"], wall["b"]]:
            var position: Vector3 = point
            var key := "%0.3f:%0.3f" % [position.x, position.z]
            if not junctions.has(key):
                junctions[key] = {"position":position,"horizontal":false,"vertical":false}
            var record: Dictionary = junctions[key]
            var a: Vector3 = wall["a"]
            var b: Vector3 = wall["b"]
            if absf(a.x-b.x) > absf(a.z-b.z):
                record["horizontal"] = true
            else:
                record["vertical"] = true
    for key in junctions:
        var record: Dictionary = junctions[key]
        if not (bool(record["horizontal"]) and bool(record["vertical"])):
            continue
        var point: Vector3 = record["position"]
        _mesh_box("CornerJunction", point + Vector3(0,HEIGHT*0.5,0), Vector3(THICKNESS,HEIGHT,THICKNESS), materials["wall"], true)
        _mesh_box("CornerCap", point + Vector3(0,HEIGHT+0.035,0), Vector3(THICKNESS,0.07,THICKNESS), materials["cap"], false)

func _mesh_box(label: String, center: Vector3, size: Vector3, material: Material, solid: bool) -> void:
    var root: Node3D = StaticBody3D.new() if solid else Node3D.new()
    root.name = label
    root.position = center
    add_child(root)
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = material
    root.add_child(visual)

func _door_marker(at: Vector3) -> void:
    _mesh_box("DoorThreshold", at + Vector3(0,0.035,0), Vector3(0.3,0.07,1.7), materials["door"], false)

func _physics_process(delta: float) -> void:
    var input := Input.get_vector("move_left","move_right","move_up","move_down")
    var right := camera.global_transform.basis.x
    var forward := -camera.global_transform.basis.z
    right.y = 0
    forward.y = 0
    hero.velocity = (right.normalized()*input.x + forward.normalized()*(-input.y)).normalized()*5.0
    hero.move_and_slide()
    _update_camera()
    _update_cutaway()

func _update_camera() -> void:
    var yaw := deg_to_rad(camera_yaw)
    var elevation := deg_to_rad(24.0)
    var offset := Vector3(sin(yaw)*cos(elevation),sin(elevation),cos(yaw)*cos(elevation))*26.0
    camera.global_position = hero.global_position + offset
    camera.look_at(hero.global_position + Vector3(0,0.7,0))

func _update_cutaway() -> void:
    var view := camera.global_position - hero.global_position
    for wall in walls:
        var center: Vector3 = wall["center"]
        var a: Vector3 = wall["a"]
        var b: Vector3 = wall["b"]
        var normal := Vector3(-(b-a).z,0,(b-a).x).normalized()
        var toward_view := (center-hero.global_position).dot(view)
        var foreground := toward_view > 0.0 and absf(normal.dot(view.normalized())) > 0.15
        var face: MeshInstance3D = wall["face"]
        if cutaway_enabled and foreground:
            face.material_override = faded_material
        else:
            face.material_override = materials["wall"]

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_Q:
        camera_yaw -= 45.0
    elif event.keycode == KEY_E:
        camera_yaw += 45.0
    elif event.keycode == KEY_C:
        cutaway_enabled = not cutaway_enabled

func _add_help() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)
    var label := Label.new()
    label.position = Vector2(16,16)
    label.text = "ARCHITECTURE LAB | WASD move | Q/E rotate 45 degrees | C cutaway on/off\nStandalone geometry test; combat dungeon is unchanged."
    ui.add_child(label)
