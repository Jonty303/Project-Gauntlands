extends SceneTree
## Godot 4.5.2: --headless --path . --script res://tests/architecture_lab_test.gd
const SCENE = preload("res://scenes/grid_geometry_audit_25d.tscn")
var lab: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func frame() -> void:
    await physics_frame
    await process_frame

func supported() -> bool:
    return lab.hero.is_on_floor() and absf(lab.hero.position.y - (lab.floor_origin.y + 0.09)) < 0.02

func walk(direction: Vector3, frames: int) -> bool:
    # Convert world direction to camera-relative input, exercising production physics.
    var right: Vector3 = lab.camera.global_basis.x
    var back: Vector3 = lab.camera.global_basis.z
    right.y = 0
    back.y = 0
    var input := Vector2(direction.dot(right.normalized()), direction.dot(back.normalized()))
    for entry in [["move_right", input.x], ["move_left", -input.x], ["move_down", input.y], ["move_up", -input.y]]:
        if entry[1] > 0.0001:
            Input.action_press(entry[0], entry[1])
    var stable := true
    for i in range(frames):
        await frame()
        stable = stable and supported()
    for action in ["move_right", "move_left", "move_down", "move_up"]:
        Input.action_release(action)
    return stable

func geometry() -> void:
    var bounds: Array[AABB] = []
    for record in lab.wall_records:
        var visual: MeshInstance3D = record.visual
        var body: StaticBody3D = visual.get_parent()
        var size: Vector3 = visual.mesh.size
        bounds.append(AABB(body.position - size * 0.5, size))
    var overlaps := 0
    for i in range(bounds.size()):
        for j in range(i + 1, bounds.size()):
            var overlap := bounds[i].intersection(bounds[j])
            if overlap.size.x > 0.001 and overlap.size.y > 0.001 and overlap.size.z > 0.001:
                overlaps += 1
    check(overlaps == 0, "Wall solids must meet without overlapping: %d overlaps" % overlaps)
    for door in lab.doors:
        var center: Vector3 = door.center
        var cell: Vector3i = lab.floor_grid.local_to_map(center)
        check(lab.occupied.has(Vector2i(cell.x, cell.z)) and lab.occupied.has(Vector2i(cell.x - 1, cell.z)), "Door must bridge occupied floor cells")
        check(is_equal_approx(center.x, lab.floor_origin.x + float(cell.x) * lab.CELL - lab.CELL * 0.5), "Door must align with shared floor edge")
        for side in [-1.0, 1.0]:
            var count := 0
            for box in bounds:
                var jamb: float = center.z + side * 0.875
                if absf(box.get_center().x - center.x) < 0.001 and (absf(box.position.z - jamb) < 0.001 or absf(box.end.z - jamb) < 0.001):
                    count += 1
            check(count == 1, "Each doorway jamb needs exactly one return")

func run() -> void:
    for yaw in [0.0, 45.0, 135.0, 225.0, 315.0]:
        lab = SCENE.instantiate()
        root.add_child(lab)
        lab.camera_yaw = yaw
        lab._update_camera()
        for i in range(15):
            await frame()
        if yaw == 0.0:
            geometry()
        check(supported(), "Initial support at yaw %s" % yaw)
        for cell in lab.floor_visuals:
            check(lab.floor_visuals[cell].visible == (lab.room_by_cell[cell] == 0), "Undiscovered floor must stay hidden")
        # Follow the center line across both doors; first attempt each while closed.
        for door in lab.doors:
            var distance: float = door.center.x - lab.hero.position.x
            check(await walk(Vector3.RIGHT, int((distance + 1.0) * 12.0)), "Support while approaching closed door")
            check(lab.hero.position.x < door.center.x - 0.35 and lab.hero.position.x > door.center.x - 0.5, "Closed door blocks movement at its face")
            check(not door.collider.disabled, "Closed door collider remains enabled")
            lab._toggle_nearby_door()
            await frame()
            check(door.collider.disabled and not door.closed, "Opening disables door collision")
            check(await walk(Vector3.RIGHT, 24), "Support through open doorway")
            check(lab.hero.position.x > door.center.x + 1.0, "Open door permits passage")
            lab._toggle_nearby_door()
            await frame()
            check(not door.collider.disabled and door.closed, "Closing restores door collision")
        check(lab._current_room() == 2 and lab.discovered_rooms.size() == 3, "Movement discovers corridor and second room")
        # Push against the north boundary, then repeat with fading disabled.
        check(await walk(Vector3.FORWARD, 90), "Support near room boundary")
        var stopped: Vector3 = lab.hero.position
        check(absf(stopped.z - (lab.floor_origin.z - 5.0 + 0.11 + 0.34)) < 0.03, "Boundary wall blocks movement")
        for cutaway in [true, false]:
            lab.cutaway = cutaway
            lab._update_visibility(1.0)
            var faded := 0
            for record in lab.wall_records:
                var body: StaticBody3D = record.visual.get_parent()
                check(body.collision_layer == 1, "Visibility must preserve wall collision layer")
                for child in body.get_children():
                    if child is CollisionShape3D:
                        check(not child.disabled, "Visibility must preserve wall shape")
                if record.alpha < 0.05:
                    faded += 1
            check(not cutaway or faded > 0, "Exercise translucent walls")
            check(await walk(Vector3.FORWARD, 12), "Support while pushing wall")
            check(lab.hero.position.distance_to(stopped) < 0.02, "Wall blocks regardless of transparency")
        # Return through both doors to confirm discovery persists across reverse transitions.
        check(await walk(Vector3.BACK, 48), "Support returning to door center line")
        for index in [1, 0]:
            var door: Dictionary = lab.doors[index]
            var distance: float = lab.hero.position.x - door.center.x
            await walk(Vector3.LEFT, maxi(0, int((distance - 1.2) * 12.0)))
            lab._toggle_nearby_door()
            await frame()
            check(await walk(Vector3.LEFT, 36), "Support during reverse doorway transition")
        check(lab._current_room() == 0 and lab.discovered_rooms.size() == 3, "Discovery persists on return")
        print("Completed movement and collision checks at yaw ", yaw)
        lab.queue_free()
        await process_frame
    print("Architecture lab: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
