extends Node3D
## Isolated 3D architecture test. Existing 2D scenes and combat remain untouched.
const SPEED := 5.0
const DEBUG_OVERLAY = preload("res://scripts/debug_overlay_25d.gd")
const WALL_HEIGHT := 3.1
var hero: CharacterBody3D
var camera: Camera3D
var goblins: Array[CharacterBody3D] = []
var light_enabled := true

func _ready() -> void:
    # Enlarged interconnected layout: 26x19 main room, 6x5 corridor, 11x13 chamber.
    _make_box("Floor", Vector3(0,-0.18,0), Vector3(26,0.35,19), Color("#343b43"), false)
    _make_box("CorridorFloor", Vector3(16,-0.18,0), Vector3(6,0.35,5), Color("#343b43"), false)
    _make_box("SecondFloor", Vector3(24.5,-0.18,0), Vector3(11,0.35,13), Color("#343b43"), false)
    _make_box("NorthWall", Vector3(0,1.55,-9.5), Vector3(26.5,WALL_HEIGHT,0.45), Color("#77796f"))
    _make_box("SouthWall", Vector3(0,1.55,9.5), Vector3(26.5,WALL_HEIGHT,0.45), Color("#77796f"))
    _make_box("WestWall", Vector3(-13,1.55,0), Vector3(0.45,WALL_HEIGHT,19), Color("#77796f"))
    for z in [-6.0,6.0]:
        _make_box("EastDoorJamb", Vector3(13,1.55,z), Vector3(0.45,WALL_HEIGHT,7), Color("#77796f"))
    for z in [-2.7,2.7]:
        _make_box("CorridorWall", Vector3(16,1.55,z), Vector3(6.2,WALL_HEIGHT,0.4), Color("#77796f"))
    for z in [-4.5,4.5]:
        _make_box("SecondDoorJamb", Vector3(19,1.55,z), Vector3(0.45,WALL_HEIGHT,4), Color("#77796f"))
    _make_box("SecondNorth", Vector3(24.5,1.55,-6.5), Vector3(11,WALL_HEIGHT,0.45), Color("#77796f"))
    _make_box("SecondSouth", Vector3(24.5,1.55,6.5), Vector3(11,WALL_HEIGHT,0.45), Color("#77796f"))
    _make_box("SecondEast", Vector3(30,1.55,0), Vector3(0.45,WALL_HEIGHT,13), Color("#77796f"))
    _make_box("Pillar", Vector3(-3,1.15,-3), Vector3(1.1,2.3,1.1), Color("#666d6c"))
    hero = _make_actor("Hero", Vector3(-5,0,1), Color("#587b9c"))
    for position in [Vector3(1,0,-2),Vector3(3,0,2),Vector3(16,0,0)]:
        goblins.append(_make_actor("Goblin",position,Color("#769557")))
    camera = Camera3D.new()
    camera.name = "IsometricCamera"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 13.0
    camera.current = true
    add_child(camera)
    camera.position = hero.global_position + Vector3(12,17,12)
    camera.look_at(hero.global_position + Vector3(0,0.7,0), Vector3.UP)
    var overlay := CanvasLayer.new()
    overlay.name = "DeveloperOverlay"
    overlay.set_script(DEBUG_OVERLAY)
    overlay.call("configure", camera, hero)
    add_child(overlay)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-35,0)
    sun.light_energy = 0.5
    add_child(sun)
    var ambient := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#151b23")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#717d87")
    environment.ambient_light_energy = 0.45
    ambient.environment = environment
    add_child(ambient)
    var torch := OmniLight3D.new()
    torch.name = "Torch"
    torch.position = Vector3(-5,2.8,-5.9)
    torch.light_color = Color("#ffb35f")
    torch.light_energy = 2.2
    torch.omni_range = 8.0
    add_child(torch)

func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("move_left","move_right","move_up","move_down")
    # Screen-relative movement: derive the ground-plane axes from the camera.
    var right: Vector3 = camera.global_basis.x
    var up: Vector3 = -camera.global_basis.z
    right.y = 0.0
    up.y = 0.0
    right = right.normalized()
    up = up.normalized()
    var motion: Vector3 = (right * direction.x - up * direction.y).normalized()
    hero.velocity = motion * SPEED
    hero.move_and_slide()
    var target := hero.global_position + Vector3(12,17,12)
    camera.global_position = camera.global_position.lerp(target, minf(1.0,delta*7.0))

func _make_box(label: String, location: Vector3, size: Vector3, tint: Color, solid: bool = true) -> void:
    var body := StaticBody3D.new()
    body.name = label
    body.position = location
    add_child(body)
    var mesh := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    mesh.mesh = shape
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 1.0
    mesh.material_override = material
    body.add_child(mesh)
    if solid:
        var collider := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        collider.shape = box
        body.add_child(collider)

func _make_actor(label: String, location: Vector3, tint: Color) -> CharacterBody3D:
    var actor := CharacterBody3D.new()
    actor.name = label
    actor.position = location
    actor.collision_layer = 2
    actor.collision_mask = 3
    add_child(actor)
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    collider.shape = capsule
    collider.position.y = 0.9
    actor.add_child(collider)
    var body := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.35
    capsule_mesh.height = 1.8
    body.mesh = capsule_mesh
    body.position.y = 0.9
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    body.material_override = material
    actor.add_child(body)
    return actor
