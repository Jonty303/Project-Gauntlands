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

func walk(direction: Vector3, frames: int, rotate: bool = false) -> bool:
    var stable := true
    for i in range(frames):
        if rotate and i % 4 == 0:
            var event := InputEventKey.new()
            event.pressed = true
            event.keycode = KEY_E
            lab._unhandled_key_input(event)
            lab._update_camera()
        set_walk_input(direction)
        await frame()
        stable = stable and supported()
    for action in ["move_right", "move_left", "move_down", "move_up"]:
        Input.action_release(action)
    return stable

func set_walk_input(direction: Vector3) -> void:
    # Convert world direction to camera-relative input, exercising production physics.
    var right: Vector3 = lab.camera.global_basis.x
    var back: Vector3 = lab.camera.global_basis.z
    if lab.top_down:
        back = -lab.camera.global_basis.y
    right.y = 0
    back.y = 0
    var input := Vector2(direction.dot(right.normalized()), direction.dot(back.normalized()))
    for action in ["move_right", "move_left", "move_down", "move_up"]:
        Input.action_release(action)
    for entry in [["move_right", input.x], ["move_left", -input.x], ["move_down", input.y], ["move_up", -input.y]]:
        if entry[1] > 0.0001:
            Input.action_press(entry[0], entry[1])

func edge_routes() -> void:
    # Capsule radius .34 leaves .035m clearance at +/- .50 in the 1.75m opening.
    # Diagonals cross the opening center and approach opposite sides of the jamb.
    for index in [0, 1]:
        for direction in [-1.0, 1.0]:
            for route in [-0.5, 0.5, -0.3, 0.3]:
                lab = SCENE.instantiate()
                root.add_child(lab)
                var door: Dictionary = lab.doors[index]
                lab.hero.position = Vector3(door.center.x - direction * 1.5, lab.floor_origin.y + 0.09, door.center.z + route)
                for i in range(5):
                    await frame()
                var from_room: int = index if direction > 0 else index + 1
                var to_room: int = index + 1 if direction > 0 else index
                check(lab._current_room() == from_room, "Edge route starts in correct region")
                var discovered_before: int = lab.discovered_rooms.size()
                lab._toggle_nearby_door()
                await frame()
                check(not door.closed and door.collider.disabled, "Edge route opens door")
                lab.top_down = route > 0
                lab._update_camera()
                var diagonal: float = -route / 1.5 if absf(route) < 0.4 else 0.0
                check(await walk(Vector3(direction, 0, diagonal).normalized(), 38, true), "Supported while rotating through edge/diagonal route")
                check((lab.hero.position.x - door.center.x) * direction > 1.2, "Edge/diagonal route clears jamb")
                check(lab._current_room() == to_room, "Crossing while rotating changes region")
                check(lab.discovered_rooms.has(from_room) and lab.discovered_rooms.has(to_room), "Both crossed regions remain discovered")
                check(lab.discovered_rooms.size() >= discovered_before, "Rotation cannot revoke discovery")
                for cell in lab.floor_visuals:
                    check(lab.floor_visuals[cell].visible == lab.discovered_rooms.has(lab.room_by_cell[cell]), "Crossing updates discovered floor visibility")
                lab._toggle_nearby_door()
                await frame()
                check(door.closed and not door.collider.disabled, "Door closes after rotated passage")
                check(await walk(Vector3(-direction, 0, 0), 30, true), "Supported approaching closed door at edge")
                check((lab.hero.position.x - door.center.x) * direction > 0.35, "Closed door still blocks after rotations")
                lab.queue_free()
                await process_frame

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
    await edge_routes()
    print("Architecture lab: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
