extends SceneTree
const SCENE = preload("res://scenes/grid_geometry_audit_25d.tscn")
const Occlusion = preload("res://scripts/wall_occlusion_25d.gd")
var lab: Node3D
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        if failures < 15:
            push_error(message)

# Independent slab oracle for the lab's axis-aligned boxes. Finite parameter
# interval [0,1] rules out walls beyond the player or behind the camera.
func intersects_box(box: AABB, start: Vector3, end: Vector3) -> bool:
    var lo := 0.0
    var hi := 1.0
    var direction := end - start
    for axis in range(3):
        if absf(direction[axis]) < 0.000001:
            if start[axis] < box.position[axis] or start[axis] > box.end[axis]:
                return false
        else:
            var a: float = (box.position[axis] - start[axis]) / direction[axis]
            var b: float = (box.end[axis] - start[axis]) / direction[axis]
            lo = maxf(lo, minf(a, b))
            hi = minf(hi, maxf(a, b))
            if lo > hi:
                return false
    return true

func expected_obstruction(visual: MeshInstance3D) -> bool:
    if not visual.visible:
        return false
    var bounds: AABB = visual.global_transform * visual.get_aabb()
    for height in [0.15, 0.9, 1.65]:
        for side in [-0.34, 0.0, 0.34]:
            var target: Vector3 = lab.hero.global_position + Vector3(0,height,0) + lab.camera.global_basis.x * side
            # Project the camera's plane through this target (orthographic).
            var depth: float = lab.camera.global_basis.z.dot(lab.camera.global_position - target) - lab.camera.near
            var origin: Vector3 = target + lab.camera.global_basis.z * depth
            if intersects_box(bounds, origin, target):
                return true
    return false

func oracle_window() -> Dictionary:
    # Seeds still use the independent ray/slab oracle. Topology expansion is
    # checked separately by hard-coded straight/corner/door-gap fixtures.
    var seeds: Dictionary = {}
    for index in range(lab.wall_records.size()):
        if expected_obstruction(lab.wall_records[index].visual):
            if lab.wall_records[index].join:
                for panel in Occlusion.adjacent_panels(index,lab.wall_records):
                    seeds[panel] = true
            else:
                seeds[index] = true
    var result := seeds.duplicate()
    for seed in seeds:
        for panel in Occlusion.adjacent_panels(seed,lab.wall_records):
            result[panel] = true
    for panel in result.keys():
        for neighbour in lab.wall_records[panel].neighbours:
            if lab.wall_records[neighbour].join:
                result[neighbour] = true
    for index in result.keys():
        if not lab.wall_records[index].visual.visible:
            result.erase(index)
    return result

func collision_state(node: Node) -> Array:
    var result: Array = []
    if node is CollisionObject3D:
        result.append([node.get_instance_id(),node.collision_layer,node.collision_mask,node.transform])
    if node is CollisionShape3D:
        result.append([node.get_instance_id(),node.disabled,node.shape,node.transform])
    if node is GridMap:
        result.append([node.get_used_cells(),node.mesh_library.get_item_shapes(0),node.collision_layer,node.collision_mask])
    for child in node.get_children():
        result.append_array(collision_state(child))
    return result

func synthetic_segments() -> void:
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(3,3,0.2)
    visual.mesh = mesh
    root.add_child(visual)
    var ray: Array = [[Vector3(0,0,5),Vector3(0,0,-2)]]
    check(Occlusion.obstructs(visual,ray), "Horizontal internal wall obstructs")
    visual.rotation.y = PI / 4.0
    check(Occlusion.obstructs(visual,ray), "Rotated internal wall obstructs regardless of normal")
    visual.rotation.y = PI / 2.0
    check(Occlusion.obstructs(visual,ray), "Perpendicular segment edge also obstructs")
    visual.position.z = -5
    check(not Occlusion.obstructs(visual,ray), "Far-side wall behind endpoint stays solid")
    visual.position.z = 8
    check(not Occlusion.obstructs(visual,ray), "Wall behind camera stays solid")
    visual.position = Vector3(4,0,0)
    check(not Occlusion.obstructs(visual,ray), "Camera-side wall off sightline stays solid")
    visual.position = Vector3.ZERO
    visual.visible = false
    check(not Occlusion.obstructs(visual,ray), "Hidden geometry cannot request a fade")
    visual.free()

func run() -> void:
    synthetic_segments()
    lab = SCENE.instantiate()
    root.add_child(lab)
    lab.set_physics_process(false)
    var total_faded := 0
    var total_solid := 0
    # Centre, each wall and all four corners in each region. Near boundaries leave
    # .1m beyond capsule clearance. Includes internal partition and corner pieces.
    for room in [0,1,2]:
        var center_x: float = [-9.0,0.0,9.0][room]
        var extent_x: float = 2.45 if room == 1 else 5.45
        var extent_z: float = 2.45 if room == 1 else 4.45
        lab.hero.position = lab.floor_origin + Vector3(center_x,0.09,0)
        lab._current_room()
        lab.visibility.discover_current()
        lab._refresh_discovery_visuals()
        for x in [-extent_x,0.0,extent_x]:
            for z in [-extent_z,0.0,extent_z]:
                lab.hero.position = lab.floor_origin + Vector3(center_x+x,0.09,z)
                check(lab._current_room() == room, "Wall/corner sample stays in logical room")
                var discovered: Dictionary = lab.discovered_rooms.duplicate()
                var physics_before := collision_state(lab)
                for yaw in range(0,361,15):
                    lab.camera_yaw = float(yaw)
                    lab._update_camera()
                    lab._update_visibility(0.22)
                    var expected_window := oracle_window()
                    for index in range(lab.wall_records.size()):
                        var wall: Dictionary = lab.wall_records[index]
                        var expected := 0.20 if expected_window.has(index) else 1.0
                        check(is_equal_approx(wall.alpha,expected), "Per-segment obstruction at room %s, position %s, yaw %s" % [room,lab.hero.position,yaw])
                        check(is_equal_approx(wall.material.albedo_color.a,expected), "Material matches obstruction alpha")
                        check(wall.visual.visible == lab.RenderVisibility.can_render(wall.owners, discovered), "Fading never reveals hidden walls")
                        if expected < 1.0:
                            total_faded += 1
                        else:
                            total_solid += 1
                    for door in lab.doors:
                        check(is_equal_approx(door.alpha,0.28 if expected_obstruction(door.visual) else 1.0), "Door is independently occlusion-tested")
                    check(lab.discovered_rooms == discovered and lab._current_room() == room, "Rotation cannot discover rooms or change ownership")
                    for cell in lab.floor_visuals:
                        check(lab.floor_visuals[cell].visible == discovered.has(lab.room_by_cell[cell]), "Rotation cannot reveal undiscovered floors")
                    check(collision_state(lab) == physics_before, "Occlusion leaves physics untouched")
                lab.top_down = true
                lab._update_camera()
                var before: Array = lab.wall_records.map(func(wall): return wall.alpha)
                lab._update_visibility(0.0)
                check(before == lab.wall_records.map(func(wall): return wall.alpha), "View change has no abrupt alpha jump")
                lab._update_visibility(0.22)
                for wall in lab.wall_records:
                    check(is_equal_approx(wall.alpha,1.0), "Unobstructed overhead walls stay solid")
                for overhead_yaw in [0.0,45.0,90.0,135.0,180.0,225.0,270.0,315.0]:
                    lab.camera_yaw = overhead_yaw
                    lab._update_camera()
                    var angle := deg_to_rad(overhead_yaw)
                    check(lab.camera.global_basis.x.is_equal_approx(Vector3(cos(angle),0,-sin(angle))), "Overhead yaw still matches movement basis")
                    lab._update_visibility(0.22)
                    check(lab.wall_records.all(func(wall): return is_equal_approx(wall.alpha,1.0)), "Overhead rotation introduces no obstruction")
                    check(lab.discovered_rooms == discovered and collision_state(lab) == physics_before, "Overhead rotation preserves discovery and physics")
                lab.top_down = false
    check(total_faded > 0 and total_solid > total_faded, "Only a subset of individual walls fade")
    # Look directly through the opening: closed leaf obstructs, returns do not.
    for door in lab.doors:
        lab.hero.position = door.center + Vector3(-1.0,-1.09,0)
        lab._current_room()
        lab._refresh_discovery_visuals()
        lab.camera_yaw = 90
        lab._update_camera()
        lab._update_visibility(0.22)
        check(is_equal_approx(door.alpha,0.28), "Closed leaf obstructs doorway view")
        for wall in lab.wall_records:
            if is_equal_approx(wall.center.x,door.center.x):
                check(is_equal_approx(wall.alpha,1.0), "Jamb/return independently stays solid beside clear opening")
        lab._toggle_nearby_door()
        await process_frame
        lab._update_visibility(0.22)
        check(not door.visual.visible and door.collider.disabled and is_equal_approx(door.alpha,1.0), "Open doorway has no leaf obstruction")
    lab.cutaway = false
    lab._update_visibility(0.22)
    for wall in lab.wall_records:
        check(is_equal_approx(wall.alpha,1.0), "Cutaway switch restores all wall opacity")
    # Exact smooth duration and reversal; separate from obstruction classification.
    var sample: Dictionary = lab.wall_records[0]
    lab._transition_opacity(sample,0.20,0.11)
    check(is_equal_approx(sample.alpha,0.60), "Fade reaches midpoint smoothly")
    lab._transition_opacity(sample,1.0,0.0)
    check(is_equal_approx(sample.alpha,0.60), "Interrupt preserves displayed alpha")
    lab._transition_opacity(sample,1.0,0.22)
    check(is_equal_approx(sample.alpha,1.0), "Reversal completes in 0.22 seconds")
    lab.free()
    print("Wall occlusion: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)
