extends Node3D
## Procedural prototype animation; independent of combat and AI decisions.
@export var is_hero := false
var actor: CharacterBody3D
var clock := 0.0
var attack_remaining := 0.0
var hit_remaining := 0.0
var bow: Node3D

func _ready() -> void:
    actor = get_parent() as CharacterBody3D
    if is_hero:
        _make_bow()

func play_attack() -> void:
    attack_remaining = 0.42

func play_hit() -> void:
    hit_remaining = 0.24

func _process(delta: float) -> void:
    if actor == null:
        return
    clock += delta
    attack_remaining = maxf(0.0, attack_remaining - delta)
    hit_remaining = maxf(0.0, hit_remaining - delta)
    var speed := Vector2(actor.velocity.x, actor.velocity.z).length()
    var stride := clampf(speed / (5.0 if is_hero else 3.5), 0.0, 1.0)
    var phase := clock * (10.0 if is_hero else 13.0)
    var swing := sin(phase) * 0.55 * stride
    for child in actor.get_children():
        if not child is MeshInstance3D:
            continue
        var part := child as MeshInstance3D
        if part.name.begins_with("LeftLeg"):
            part.rotation.x = swing
        elif part.name.begins_with("RightLeg"):
            part.rotation.x = -swing
        elif part.name.begins_with("LeftArm"):
            part.rotation.x = -swing * 0.65
        elif part.name.begins_with("RightArm"):
            part.rotation.x = swing * 0.65
        elif part.name == "Torso":
            part.position.y = 1.04 + sin(phase * 2.0) * 0.035 * stride + sin(clock * 2.1) * 0.012
            part.rotation.z = (0.13 if hit_remaining > 0.0 else 0.0)
    var right_arm := actor.get_node_or_null("RightArm") as MeshInstance3D
    var left_arm := actor.get_node_or_null("LeftArm") as MeshInstance3D
    if attack_remaining > 0.0:
        var progress := 1.0 - attack_remaining / 0.42
        if is_hero:
            if left_arm != null:
                left_arm.rotation.x = -1.0
            if right_arm != null:
                right_arm.rotation.x = -1.2 + (0.9 if progress > 0.48 else 0.0)
        elif right_arm != null:
            right_arm.rotation.x = -1.5 + progress * 2.7
    if hit_remaining > 0.0:
        if right_arm != null:
            right_arm.rotation.z = -0.45
    elif right_arm != null:
        right_arm.rotation.z = 0.0
    if bow != null:
        bow.rotation.x = -0.3 if attack_remaining > 0.0 else 0.0

func _make_bow() -> void:
    bow = Node3D.new()
    bow.name = "Bow"
    bow.position = Vector3(-0.56, 1.12, -0.2)
    actor.add_child(bow)
    var wood := StandardMaterial3D.new()
    wood.albedo_color = Color("#775235")
    for offset in [-0.31, 0.0, 0.31]:
        var segment := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(0.055, 0.39, 0.06)
        segment.mesh = box
        segment.position = Vector3(absf(offset) * 0.3, offset, 0)
        segment.material_override = wood
        bow.add_child(segment)
    var string_mesh := MeshInstance3D.new()
    var thin := CylinderMesh.new()
    thin.top_radius = 0.008
    thin.bottom_radius = 0.008
    thin.height = 0.93
    string_mesh.mesh = thin
    string_mesh.position = Vector3(0.11, 0, 0)
    var thread := StandardMaterial3D.new()
    thread.albedo_color = Color("#c6bfa2")
    string_mesh.material_override = thread
    bow.add_child(string_mesh)
