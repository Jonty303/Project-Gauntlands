extends Node3D
## Prototype concealed pressure-plate spike trap. Red outline is a debug clue.
signal triggered(damage: int)
@export var damage := 20
@export var reset_seconds := 2.5
var hero: CharacterBody3D
var cooldown := 0.0
var spikes: Node3D
var active := false
var elapsed := 0.0

func configure(player: CharacterBody3D) -> void:
    hero = player

func _ready() -> void:
    var border_mat := StandardMaterial3D.new()
    border_mat.albedo_color = Color("#b93336")
    border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    for i in range(4):
        var line := MeshInstance3D.new()
        var cube := BoxMesh.new()
        cube.size = Vector3(2.1, 0.025, 0.055) if i < 2 else Vector3(0.055, 0.025, 2.1)
        line.mesh = cube
        line.position = Vector3(0, 0.035, -1.03 if i == 0 else 1.03) if i < 2 else Vector3(-1.03 if i == 2 else 1.03, 0.035, 0)
        line.material_override = border_mat
        add_child(line)
    spikes = Node3D.new()
    spikes.name = "Spikes"
    spikes.position.y = -0.75
    add_child(spikes)
    var metal := StandardMaterial3D.new()
    metal.albedo_color = Color("#a5a8a5")
    metal.metallic = 0.6
    for x in [-0.65, 0.0, 0.65]:
        for z in [-0.65, 0.0, 0.65]:
            var point := MeshInstance3D.new()
            var cone := CylinderMesh.new()
            cone.top_radius = 0.0
            cone.bottom_radius = 0.13
            cone.height = 0.75
            point.mesh = cone
            point.position = Vector3(x, 0.4, z)
            point.material_override = metal
            spikes.add_child(point)

func _physics_process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    if active:
        elapsed += delta
        if elapsed >= 0.85:
            active = false
            var retract := create_tween()
            retract.tween_property(spikes, "position:y", -0.75, 0.25)
    if hero == null or cooldown > 0.0:
        return
    var offset := hero.global_position - global_position
    if absf(offset.x) <= 0.95 and absf(offset.z) <= 0.95:
        cooldown = reset_seconds
        elapsed = 0.0
        active = true
        var rise := create_tween()
        rise.tween_property(spikes, "position:y", 0.0, 0.12)
        triggered.emit(damage)
