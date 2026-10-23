extends SceneTree
const SCENE = preload("res://scenes/grid_geometry_audit_25d.tscn")
const Occlusion = preload("res://scripts/wall_occlusion_25d.gd")
const RenderPolicy = preload("res://scripts/room_render_visibility_25d.gd")
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

func piece(at: Vector3, size: Vector3) -> Dictionary:
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.position = at
    root.add_child(visual)
    return {"visual":visual}

func topology() -> void:
    var records: Array[Dictionary] = []
    # Five panels and six joins, each panel 1.78m plus .22m joins.
    for x in range(5):
        records.append(piece(Vector3(x*2,1.4,0),Vector3(1.78,2.8,0.22)))
    for x in range(6):
        records.append(piece(Vector3(x*2-1,1.4,0),Vector3(0.22,2.8,0.22)))
    Occlusion.connect_panels(records,0.22)
    var window := Occlusion.cutaway_window(records,[[Vector3(4,1,4),Vector3(4,1,-1)]])
    for index in range(5):
        check(window.has(index) == (index >= 1 and index <= 3), "One obstruction produces exactly three panels")
    for index in range(5,11):
        check(window.has(index) == (index >= 6 and index <= 9), "Window includes joins without opaque slivers")
    var shifted := Occlusion.cutaway_window(records,[[Vector3(2,1,4),Vector3(2,1,-1)]])
    check(shifted.has(0) and shifted.has(1) and shifted.has(2) and not shifted.has(3), "Window follows target movement")
    records[3].visual.visible = false
    window = Occlusion.cutaway_window(records,[[Vector3(4,1,4),Vector3(4,1,-1)]])
    check(not window.has(3), "Expansion cannot reveal hidden neighbour")
    for record in records:
        record.visual.free()
    records = [piece(Vector3(0,1.4,0),Vector3(1.78,2.8,0.22)),piece(Vector3(1,1.4,0),Vector3(0.22,2.8,0.22)),piece(Vector3(1,1.4,1),Vector3(0.22,2.8,1.78)),piece(Vector3(-3,1.4,0),Vector3(1.78,2.8,0.22))]
    Occlusion.connect_panels(records,0.22)
    window = Occlusion.cutaway_window(records,[[Vector3(0,1,4),Vector3(0,1,-1)]])
    check(window.has(0) and window.has(1) and window.has(2), "Expansion wraps a connected corner")
    check(not window.has(3), "Expansion never jumps a doorway gap")
    for record in records:
        record.visual.free()

func place(room: int, x: float, z: float = 0.0) -> void:
    lab.hero.position = lab.floor_origin + Vector3(x,0.09,z)
    check(lab._current_room() == room, "Fixture is in correct logical room")
    lab.visibility.discover_current()
    lab._refresh_discovery_visuals()
    lab._update_camera()

func preview_count(room: int) -> int:
    var count := 0
    for cell in lab.floor_visuals:
        if lab.room_by_cell[cell] == room and lab.floor_visuals[cell].visible:
            count += 1
    return count

func run() -> void:
    topology()
    lab = SCENE.instantiate()
    root.add_child(lab)
    lab.set_physics_process(false)
    place(0,-4.0)
    check(preview_count(1) == 0 and preview_count(2) == 0, "Closed doors conceal unentered rooms")
    for cell in lab.floor_visuals:
        check(lab.exterior_grid.concealed_background[cell].visible == not lab.floor_visuals[cell].visible, "Hidden room footprint stays covered by background grid")
    var discovery: Dictionary = lab.discovered_rooms.duplicate()
    lab._toggle_nearby_door()
    check(preview_count(1) > 0 and lab.visible_rooms.has(1), "Opening immediately previews corridor before entry")
    for cell in lab.floor_visuals:
        check(lab.exterior_grid.concealed_background[cell].visible == not lab.floor_visuals[cell].visible, "Portal preview withdraws only its visible floor background")
    check(lab.discovered_rooms == discovery and not lab.visibility.rooms[1].discovered, "Preview does not discover corridor")
    check(preview_count(2) == 0, "Closed second door conceals far chamber")
    var eye: Vector3 = lab.hero.global_position + Vector3(0,1,0)
    var inside: Vector3 = lab.floor_origin + Vector3(0,1.09,0)
    var concealed: Vector3 = lab.floor_origin + Vector3(-2,1.09,2.5)
    check(RenderPolicy.preview_visible([1],inside,eye,0,lab.wall_records,lab.doors), "Sight ray passes through open aperture")
    check(not RenderPolicy.preview_visible([1],concealed,eye,0,lab.wall_records,lab.doors), "Doorway return blocks around-jamb preview")
    var blocker := piece(lab.floor_origin+Vector3(-1,1.4,0),Vector3(0.22,2.8,2))
    blocker.visual.visible = false
    var blocked_walls: Array[Dictionary] = lab.wall_records.duplicate()
    blocked_walls.append(blocker)
    check(not RenderPolicy.preview_visible([1],inside,eye,0,blocked_walls,lab.doors), "Hidden solid beyond an open aperture blocks preview")
    blocker.visual.free()
    lab._transition_opacity(lab.doors[1],0.28,0.22)
    check(not RenderPolicy.clear_sight(eye,lab.floor_origin+Vector3(10,1.09,0),lab.wall_records,lab.doors), "Faded closed door still blocks sight")
    # Fading cannot turn a solid wall into a portal or bypass a closed door.
    for wall in lab.wall_records:
        lab._transition_opacity(wall,0.20,0.22)
    check(not RenderPolicy.preview_visible([1],concealed,eye,0,lab.wall_records,lab.doors), "Faded return still blocks preview sight")
    for yaw in range(0,361,15):
        lab.camera_yaw = yaw
        lab._update_camera()
        lab._refresh_discovery_visuals()
        lab._update_visibility(0.22)
        check(preview_count(1) > 0 and preview_count(2) == 0, "Camera rotation preserves bounded portal preview")
        check(lab.discovered_rooms == discovery, "Camera rotation cannot discover preview")
        check(lab.doors[1].closed and not lab.doors[1].collider.disabled, "Concealed closed door retains collision")
    # Opening a second, unrelated portal cannot recursively reveal room 2.
    lab.doors[1].closed = false
    lab._refresh_discovery_visuals()
    check(preview_count(2) == 0, "Unrelated open door cannot reveal a second-hop room")
    lab.doors[1].closed = true
    # Move beside the wall: rays to the corridor have to cross solid returns.
    place(0,-4.0,4.0)
    check(preview_count(1) == 0, "Walls conceal corridor when doorway is out of sight")
    place(0,-4.0)
    lab._toggle_nearby_door()
    check(preview_count(1) == 0, "Closing immediately removes undiscovered preview")
    lab._toggle_nearby_door()
    place(1,2.0)
    lab._toggle_nearby_door()
    check(preview_count(2) > 0 and not lab.discovered_rooms.has(2), "Far chamber previews before crossing second doorway")
    lab._toggle_nearby_door()
    check(preview_count(2) == 0, "Second door closing conceals unentered chamber")
    place(2,4.0)
    place(1,2.0)
    check(preview_count(2) > 0 and lab.discovered_rooms.has(2), "Entered room remains discovered after leaving and closing")
    # Grid covers only exterior tiles, is lower than floor, and is visual only.
    var grid: MeshInstance3D = lab.exterior_grid
    var transform_before: Transform3D = grid.global_transform
    for child in grid.get_children():
        check(child is MeshInstance3D and child.get_child_count() == 0, "Background grid patches have no physics nodes")
    for cell in grid.concealed_background:
        check(grid.concealed_background[cell].visible == not lab.floor_visuals[cell].visible, "Grid never overlays a rendered dungeon floor")
    for cell in grid.exterior_cells:
        check(not lab.occupied.has(cell), "Exterior mesh excludes every dungeon cell")
    var vertices: PackedVector3Array = grid.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    for vertex in vertices:
        check(is_equal_approx(vertex.y,lab.floor_origin.y-0.2), "Grid is below floor without z-fighting")
    check(is_equal_approx(grid.material_override.get_shader_parameter("cell_size"),lab.CELL), "Grid matches tile spacing")
    for yaw in [0.0,90.0,180.0,270.0]:
        lab.camera_yaw = yaw
        lab._update_camera()
        check(grid.global_transform == transform_before, "Grid remains anchored during rotation")
    lab.hero.position.x += 0.5
    lab._update_camera()
    check(grid.global_transform == transform_before, "Grid remains anchored during camera follow")
    lab.free()
    print("Cutaway/portal/grid: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)
