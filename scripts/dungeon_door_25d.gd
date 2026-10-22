extends Node3D
## Reusable hinged dungeon door. Place at the centre of an opening.
@export var opening_width := 1.5
@export var double_door := false
@export var interaction_range := 2.5
@export var swing_speed := 2.5
var opened := false
var swing_sign := 1.0
var progress := 0.0
var panels: Array[Node3D] = []
var blockers: Array[CollisionShape3D] = []

func _ready() -> void:
    _build()
    _build_frame()

func _build() -> void:
    var count := 2 if double_door else 1
    var width := opening_width / float(count)
    for i in range(count):
        var hinge := Node3D.new()
        hinge.name = "Hinge%d" % i
        hinge.position.x = -opening_width * 0.5 if i == 0 else opening_width * 0.5
        add_child(hinge)
        var body := StaticBody3D.new()
        body.name = "Leaf%d" % i
        body.position.x = width * 0.5 if i == 0 else -width * 0.5
        body.position.y = 1.55
        hinge.add_child(body)
        var mesh := MeshInstance3D.new()
        var slab := BoxMesh.new()
        slab.size = Vector3(width - 0.06, 3.1, 0.17)
        mesh.mesh = slab
        var wood := StandardMaterial3D.new()
        wood.albedo_color = Color("#49301e")
        wood.roughness = 0.95
        mesh.material_override = wood
        body.add_child(mesh)
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = slab.size
        collider.shape = shape
        body.add_child(collider)
        blockers.append(collider)
        for y in [-0.75, 0.75]:
            var iron := MeshInstance3D.new()
            var band := BoxMesh.new()
            band.size = Vector3(width - 0.1, 0.13, 0.21)
            iron.mesh = band
            iron.position.y = y
            var metal := StandardMaterial3D.new()
            metal.albedo_color = Color("#292c30")
            iron.material_override = metal
            body.add_child(iron)
        # Raised timber boards and a central iron pull.
        for j in range(3):
            var plank := MeshInstance3D.new()
            var plank_box := BoxMesh.new()
            plank_box.size = Vector3((width - 0.10) / 3.0 - 0.035, 2.85, 0.035)
            plank.mesh = plank_box
            plank.position = Vector3((float(j) - 1.0) * (width - 0.10) / 3.0, 0, 0.105)
            var plank_mat := StandardMaterial3D.new()
            plank_mat.albedo_color = Color("#735038") if j % 2 == 0 else Color("#62412b")
            plank.material_override = plank_mat
            body.add_child(plank)
        var handle := MeshInstance3D.new()
        var handle_mesh := BoxMesh.new()
        handle_mesh.size = Vector3(0.11, 0.3, 0.12)
        handle.mesh = handle_mesh
        handle.position = Vector3(width * (0.32 if i == 0 else -0.32), 0, 0.17)
        var handle_mat := StandardMaterial3D.new()
        handle_mat.albedo_color = Color("#b09b72")
        handle.material_override = handle_mat
        body.add_child(handle)
        panels.append(hinge)

func _build_frame() -> void:
    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color("#a1a094")
    stone.roughness = 1.0
    for side in [-1.0, 1.0]:
        var jamb := MeshInstance3D.new()
        jamb.name = "StoneJamb"
        var block := BoxMesh.new()
        block.size = Vector3(0.28, 3.1, 0.48)
        jamb.mesh = block
        jamb.position = Vector3(side * (opening_width * 0.5 + 0.13), 1.55, 0)
        jamb.material_override = stone
        add_child(jamb)
    var lintel := MeshInstance3D.new()
    lintel.name = "StoneLintel"
    var beam := BoxMesh.new()
    beam.size = Vector3(opening_width + 0.54, 0.26, 0.52)
    lintel.mesh = beam
    lintel.position.y = 3.1
    lintel.material_override = stone
    add_child(lintel)

func interact(actor: Node3D) -> void:
    if actor.global_position.distance_to(global_position) > interaction_range:
        return
    if not opened:
        # Local Z identifies the approach side. Swing to the opposite side.
        var approach := to_local(actor.global_position)
        swing_sign = -1.0 if approach.z > 0.0 else 1.0
        opened = true
    else:
        opened = false

func _physics_process(delta: float) -> void:
    var target := 1.0 if opened else 0.0
    progress = move_toward(progress, target, delta * swing_speed)
    for i in range(panels.size()):
        var leaf_sign := 1.0 if i == 0 else -1.0
        panels[i].rotation.y = progress * swing_sign * leaf_sign * PI * 0.5
    # Disable collision once sufficiently open, preventing a stationary open leaf
    # from becoming an invisible obstruction across the passage.
    for collider in blockers:
        collider.disabled = progress > 0.9
