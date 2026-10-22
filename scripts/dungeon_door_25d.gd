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
        hinge.add_child(body)
        var mesh := MeshInstance3D.new()
        var slab := BoxMesh.new()
        slab.size = Vector3(width - 0.06, 2.55, 0.17)
        mesh.mesh = slab
        var wood := StandardMaterial3D.new()
        wood.albedo_color = Color("#63462e")
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
        panels.append(hinge)

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
