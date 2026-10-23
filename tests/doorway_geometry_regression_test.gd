extends SceneTree
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

func floor_footprint() -> Dictionary:
    var result: Dictionary = {}
    for cell in lab.floor_visuals:
        var visual: MeshInstance3D = lab.floor_visuals[cell]
        result[cell] = [visual.get_instance_id(),visual.mesh.get_instance_id(),visual.global_transform,lab.floor_grid.get_cell_item(Vector3i(cell.x,0,cell.y))]
    return result

func same_floor(before: Dictionary, message: String) -> void:
    check(lab.floor_visuals.size() == 69 and lab.floor_grid.get_used_cells().size() == 69, message + ": all tiles remain allocated")
    check(floor_footprint() == before, message + ": floor meshes, transforms and collision cells remain unchanged")

func region_floors(room: int) -> int:
    var count := 0
    for cell in lab.floor_visuals:
        if lab.room_by_cell[cell] == room and lab.floor_visuals[cell].visible:
            count += 1
    return count

func run() -> void:
    lab = SCENE.instantiate()
    root.add_child(lab)
    lab.set_physics_process(false)
    var floor_before := floor_footprint()
    same_floor(floor_before,"Initial geometry")
    # Every floor edge across each doorway must meet without a seam at the same
    # height. This includes all three z rows, not just the centre walking line.
    for door in lab.doors:
        for z in [-1,0,1]:
            var x: int = -2 if door == lab.doors[0] else 1
            var left: MeshInstance3D = lab.floor_visuals[Vector2i(x,z)]
            var right: MeshInstance3D = lab.floor_visuals[Vector2i(x+1,z)]
            var left_bounds: AABB = left.global_transform * left.get_aabb()
            var right_bounds: AABB = right.global_transform * right.get_aabb()
            check(absf(left_bounds.end.x-right_bounds.position.x) < 0.0001, "Neighbour floor meshes meet at doorway without horizontal gap")
            check(absf(left_bounds.position.y-right_bounds.position.y) < 0.0001 and absf(left_bounds.end.y-right_bounds.end.y) < 0.0001, "Neighbour floor meshes share top and bottom planes")
            check(absf(door.center.x-left_bounds.end.x) < 0.0001, "Doorway plane aligns with floor seam")
    # Visual-only frame adds a lintel over the door leaf and posts beside its
    # aperture. No shape narrows the 1.75m opening or changes door interaction.
    var frame_records := []
    for record in lab.wall_records:
        if record.get("visual_only",false):
            frame_records.append(record)
            check(not record.visual.get_parent() is CollisionObject3D and record.visual.get_parent().get_child_count() == 1, "Frame has no collision body or shape")
    check(frame_records.size() == 6, "Exactly three substantial frame pieces per door")
    for door in lab.doors:
        var matching := []
        for record in frame_records:
            if absf(record.center.x-door.center.x) < 0.001:
                matching.append(record)
        check(matching.size() == 3, "Each doorway has two jambs and one header")
        var header: Dictionary = matching[0]
        for record in matching:
            if record.visual.mesh.size.y < lab.WALL_HEIGHT:
                header = record
        var header_size: Vector3 = header.visual.mesh.size
        check(is_equal_approx(header_size.y,lab.WALL_HEIGHT-door.visual.mesh.size.y), "Header fills leaf-to-wall height gap")
        check(is_equal_approx(header.visual.global_position.y-header_size.y*0.5,lab.floor_origin.y+door.visual.mesh.size.y), "Header bottom meets top of door opening")
        check(header_size.z >= door.visual.mesh.size.z + 0.6-0.0001, "Header spans opening and substantial jamb widths")
        for record in matching:
            if record == header:
                continue
            var size: Vector3 = record.visual.mesh.size
            check(is_equal_approx(size.y,lab.WALL_HEIGHT) and size.z >= 0.30-0.0001, "Substantial jamb spans full wall height")
            check(absf(record.center.z-door.center.z) - size.z*0.5 >= door.visual.mesh.size.z*0.5-0.0001, "Jamb remains outside clear opening")
    # All directly connected physical wall panels have filled joins. When the
    # rooms render and cutaway is disabled they form continuous opaque surfaces.
    for room in [0,1,2]:
        lab.hero.position = lab.floor_origin + Vector3([-10.0,0.0,10.0][room],0.09,0)
        lab._current_room()
        lab.visibility.discover_current()
    lab._refresh_discovery_visuals()
    lab.cutaway = false
    lab._update_visibility(0.22)
    for index in range(lab.wall_records.size()):
        var record: Dictionary = lab.wall_records[index]
        check(record.visual.visible and is_equal_approx(record.alpha,1.0), "Fully discovered wall surface is visible and opaque")
        check(record.material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "Opaque wall uses depth-rendered material")
        if record.get("visual_only",false) or record.join:
            continue
        var touches_join := false
        for neighbour in record.neighbours:
            if lab.wall_records[neighbour].join and not lab.wall_records[neighbour].get("visual_only",false):
                touches_join = true
        check(touches_join, "Opaque physical wall span has a filled adjoining joint")
    same_floor(floor_before,"After discovery and opacity changes")
    # A fresh session isolates temporary preview from permanent discovery.
    lab.free()
    lab = SCENE.instantiate()
    root.add_child(lab)
    lab.set_physics_process(false)
    floor_before = floor_footprint()
    for index in [0,1]:
        var from_room: int = index
        var to_room: int = index+1
        var door: Dictionary = lab.doors[index]
        lab.hero.position = door.center + Vector3(-1.0,-1.09,0)
        lab._current_room()
        lab.visibility.discover_current()
        lab._refresh_discovery_visuals()
        check(lab.visibility.current_room == from_room, "Hero stands outside closed door in logical source room")
        var discovered_before: Dictionary = lab.discovered_rooms.duplicate()
        lab._toggle_nearby_door()
        await frame()
        same_floor(floor_before,"Door opened")
        var expected_tiles: int = 9 if to_room == 1 else 30
        check(region_floors(to_room) == expected_tiles, "Every adjoining floor tile previews as one continuous region")
        check(not lab.discovered_rooms.has(to_room) and lab.discovered_rooms == discovered_before, "Preview does not discover adjoining room")
        check(not door.closed and door.collider.disabled, "Open leaf collision behaves as before")
        lab.hero.position.x = door.center.x + 1.0
        lab._current_room()
        lab.visibility.discover_current()
        lab._refresh_discovery_visuals()
        check(region_floors(from_room) > 0 and region_floors(to_room) == expected_tiles, "Both sides remain continuous across crossing")
        same_floor(floor_before,"Door threshold crossed")
        lab.hero.position.x = door.center.x - 1.0
        lab._current_room()
        lab._toggle_nearby_door()
        await frame()
        check(region_floors(to_room) == expected_tiles, "Discovered floor stays intact after closing door")
        check(door.closed and not door.collider.disabled, "Closing restores original leaf collision")
        same_floor(floor_before,"Door closed")
    lab.free()
    print("Doorway geometry: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)
