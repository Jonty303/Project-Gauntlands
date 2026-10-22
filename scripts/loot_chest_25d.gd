extends Node3D
## Simple one-time loot chest with context-sensitive interaction.
var opened := false
var lid: Node3D

func _ready() -> void:
    var wood := StandardMaterial3D.new()
    wood.albedo_color = Color("#684326")
    var iron := StandardMaterial3D.new()
    iron.albedo_color = Color("#b2a06c")
    var base := MeshInstance3D.new()
    var base_mesh := BoxMesh.new()
    base_mesh.size = Vector3(1.3, 0.7, 0.8)
    base.mesh = base_mesh
    base.position.y = 0.38
    base.material_override = wood
    add_child(base)
    lid = Node3D.new()
    lid.position = Vector3(0, 0.75, 0.35)
    add_child(lid)
    var top := MeshInstance3D.new()
    var top_mesh := BoxMesh.new()
    top_mesh.size = Vector3(1.35, 0.24, 0.86)
    top.mesh = top_mesh
    top.position.z = -0.35
    top.material_override = wood
    lid.add_child(top)
    var latch := MeshInstance3D.new()
    var latch_mesh := BoxMesh.new()
    latch_mesh.size = Vector3(0.18, 0.26, 0.07)
    latch.mesh = latch_mesh
    latch.position = Vector3(0, 0.48, -0.45)
    latch.material_override = iron
    add_child(latch)

func interact(actor: Node3D) -> bool:
    if opened or actor.global_position.distance_to(global_position) > 2.0:
        return false
    opened = true
    create_tween().tween_property(lid, "rotation:x", -1.2, 0.35)
    return true
