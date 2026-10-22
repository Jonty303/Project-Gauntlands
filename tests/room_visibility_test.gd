extends SceneTree
## Deterministic visibility regression; production movement is covered by architecture_lab_test.
const SCENE = preload("res://scenes/grid_geometry_audit_25d.tscn")
const Visibility = preload("res://scripts/room_visibility_25d.gd")
var checks := 0
var failures := 0
var lab: Node3D

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func enter(room: int) -> void:
    lab.hero.position = lab.floor_origin + Vector3([-10.0, 0.0, 10.0][room], 0.09, 0)
    check(lab._current_room() == room, "Logical region owns hero in room %d" % room)
    lab.visibility.discover_current()
    lab._refresh_discovery_visuals()
    lab._update_camera()

func collision_state(node: Node) -> Array:
    var result: Array = []
    if node is CollisionObject3D:
        result.append([node.get_instance_id(), node.collision_layer, node.collision_mask, node.transform])
    if node is CollisionShape3D:
        result.append([node.get_instance_id(), node.disabled, node.shape, node.transform])
    if node is GridMap:
        result.append([node.get_used_cells(), node.collision_layer, node.collision_mask, node.mesh_library.get_item_shapes(0)])
    for child in node.get_children():
        result.append_array(collision_state(child))
    return result

func run() -> void:
    lab = SCENE.instantiate()
    root.add_child(lab)
    lab.set_physics_process(false)
    check(lab.discovered_rooms.keys() == [0], "Only starting room discovered")
    check(lab.visibility.rooms.size() == 3, "Every room and corridor has a unique record")
    for id in [0, 1, 2]:
        var room: Dictionary = lab.visibility.rooms[id]
        check(room.id == id and room.discovered == (id == 0), "Initial room record")
        check(room.neighbours == [[1], [0, 2], [1]][id], "Explicit reciprocal neighbours")
    for cell in lab.floor_visuals:
        check(lab.floor_visuals[cell].visible == (lab.room_by_cell[cell] == 0), "Initial floor discovery")
    for wall in lab.wall_records:
        check(wall.visual.visible == wall.owners.has(0), "No undiscovered-only walls visible")
    check(lab.doors[0].visual.visible and not lab.doors[1].visual.visible, "Only starting boundary door visible")
    enter(0)
    check(lab.visibility.eligible_rooms() == [0], "Undiscovered neighbour cannot fade")
    lab.camera_yaw = 90.0
    lab._update_camera()
    lab._update_visibility(0.22)
    check(is_equal_approx(lab.doors[0].alpha, 0.28), "Starting room east door faces east camera")
    lab.camera_yaw = 270.0
    lab._update_camera()
    lab._update_visibility(0.22)
    check(is_equal_approx(lab.doors[0].alpha, 1.0), "Undiscovered corridor cannot fade west face")
    for wall in lab.wall_records:
        if wall.owners.has(0) and wall.owners.has(1):
            check(is_equal_approx(wall.alpha, 1.0), "Partition cannot borrow undiscovered owner's normal")
    enter(1)
    check(lab.visibility.eligible_rooms() == [1, 0], "Only discovered one-hop neighbour eligible")
    enter(2)
    enter(1)
    enter(0)
    check(lab.discovered_rooms.size() == 3, "Discovery persists after leaving each room")
    for room in lab.visibility.rooms.values():
        check(room.discovered, "Room record retains discovery")
    for floor_visual in lab.floor_visuals.values():
        check(floor_visual.visible, "Discovered floors remain visible")

    # Each boundary is crossed in both directions, including sub-millimetre jitter.
    for boundary in [0, 1]:
        for direction in [1, -1]:
            var from_room: int = boundary if direction == 1 else boundary + 1
            var to_room: int = boundary + 1 if direction == 1 else boundary
            enter(from_room)
            var x: float = lab.doors[boundary].center.x
            lab.hero.position.x = x - direction * 0.01
            check(lab._current_room() == from_room, "Approach owns correct side")
            for jitter in [0.0, 0.0004, -0.0004, 0.0008, -0.0008]:
                lab.hero.position.x = x + jitter
                check(lab._current_room() == from_room, "Threshold jitter retains ownership")
            lab.hero.position.x = x + direction * 0.002
            check(lab._current_room() == to_room, "Crossing threshold changes ownership")
    # Same graph policy at arbitrary physical separation: no distance inference.
    var logic := Visibility.new()
    logic.configure({Vector2i.ZERO:0, Vector2i(1000, 0):1, Vector2i(1, 0):2}, {0:[1],1:[0,2],2:[1]}, 0)
    for point in [Vector3(2001,0,1), Vector3(3,0,1), Vector3(1,0,1)]:
        logic.locate(point, 2.0)
        logic.discover_current()
    check(logic.eligible_rooms() == [0,1], "Far neighbour eligible, near non-neighbour excluded")

    for room in [0, 1, 2]:
        enter(room)
        var expected_rooms: Array = [[0,1], [1,0,2], [2,1]][room]
        check(lab.visibility.eligible_rooms() == expected_rooms, "Graph fade eligibility")
        var before := collision_state(lab)
        for yaw in [0.0,45.0,90.0,135.0,180.0,225.0,270.0,315.0]:
            lab.camera_yaw = yaw
            lab._update_camera()
            check(lab._current_room() == room, "Camera cannot change room ownership")
            lab._update_visibility(0.22)
            var view := Vector3(sin(deg_to_rad(yaw)),0,cos(deg_to_rad(yaw)))
            for wall in lab.wall_records:
                var fade := false
                for index in range(wall.normals.size()):
                    var owner: int = wall.owners[0] if wall.owners.size() == 1 else wall.owners[index]
                    fade = fade or (expected_rooms.has(owner) and wall.normals[index].dot(view) > 0.1)
                check(is_equal_approx(wall.alpha, 0.04 if fade else 1.0), "Wall opacity follows eligible owner's normal")
                check(is_equal_approx(wall.material.albedo_color.a, wall.alpha), "Rendered wall alpha")
            for door in lab.doors:
                var front := (expected_rooms.has(door.rooms[0]) and view.x > 0.1) or (expected_rooms.has(door.rooms[1]) and view.x < -0.1)
                check(is_equal_approx(door.alpha, 0.28 if front else 1.0), "Closed door camera-facing opacity")
            check(collision_state(lab) == before, "All collision unchanged after rotation and fade")
            var wall_alphas: Array = lab.wall_records.map(func(record): return record.alpha)
            var door_alphas: Array = lab.doors.map(func(record): return record.alpha)
            lab.top_down = true
            lab._update_camera()
            lab._update_visibility(0.0)
            check(lab.wall_records.map(func(record): return record.alpha) == wall_alphas, "Overhead toggle has no alpha jump")
            lab._update_visibility(0.22)
            check(lab.wall_records.map(func(record): return record.alpha) == wall_alphas, "Overhead preserves selected wall facing")
            check(lab.doors.map(func(record): return record.alpha) == door_alphas, "Overhead preserves selected door facing")
            var expected_right := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
            check(lab.camera.global_basis.x.is_equal_approx(expected_right), "Overhead camera follows selected yaw")
            check(lab._current_room() == room and collision_state(lab) == before, "Overhead preserves ownership and collision")
            lab.top_down = false
            lab._update_camera()
        lab.cutaway = false
        lab._update_visibility(0.22)
        for wall in lab.wall_records:
            check(is_equal_approx(wall.alpha, 1.0), "Cutaway off restores opacity")
        lab.cutaway = true
        lab.camera_yaw = 0
        lab._update_camera()
        lab._update_visibility(0.11)
        var transitioning := 0
        for wall in lab.wall_records:
            if wall.alpha < 1.0:
                transitioning += 1
                check(is_equal_approx(wall.alpha, 0.52), "Smooth transition halfway after 0.11s")
        check(transitioning > 0, "Exercise timed transition")
        lab._update_visibility(0.11)
        for wall in lab.wall_records:
            check(is_equal_approx(wall.alpha, 0.04) or is_equal_approx(wall.alpha, 1.0), "Fade completes in 0.22s")
        check(collision_state(lab) == before, "Collision preserved through intermediate alpha")
    # Interrupted fades preserve displayed alpha; completion is independent of step size.
    var sample: Dictionary = lab.wall_records[0]
    lab._transition_opacity(sample, 1.0, 0.22)
    lab._transition_opacity(sample, 0.04, 0.11)
    lab._transition_opacity(sample, 1.0, 0.0)
    check(is_equal_approx(sample.alpha, 0.52), "Interrupted fade has no opacity jump")
    lab._transition_opacity(sample, 1.0, 0.22)
    for step in range(22):
        lab._transition_opacity(sample, 0.04, 0.01)
    check(is_equal_approx(sample.alpha, 0.04), "Small steps also complete in 0.22s")
    for index in [0, 1]:
        var door: Dictionary = lab.doors[index]
        lab.hero.position = door.center + Vector3(-1, -1.09, 0)
        lab._toggle_nearby_door()
        await process_frame
        check(not door.closed and not door.visual.visible and door.collider.disabled, "Open door hides and allows passage")
        var before := collision_state(lab)
        lab._update_visibility(0.22)
        check(is_equal_approx(door.alpha, 1.0), "Open door not foreground-faded")
        check(collision_state(lab) == before, "Fade does not re-enable open door collision")
        lab._toggle_nearby_door()
        await process_frame
        check(door.closed and door.visual.visible and not door.collider.disabled, "Closing restores door")
    lab.free()
    print("Room visibility: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
