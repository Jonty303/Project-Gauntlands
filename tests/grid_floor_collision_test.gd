extends SceneTree
## Run: godot --headless --path . --script res://tests/grid_floor_collision_test.gd

const SCENE = preload("res://scenes/grid_geometry_audit_25d.tscn")
var lab: Node3D
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func frame() -> void:
	await physics_frame
	await process_frame

func supported() -> bool:
	return lab.hero.is_on_floor() and absf(lab.hero.global_position.y - 1.09) < 0.02

func _run() -> void:
	lab = SCENE.instantiate()
	root.add_child(lab)
	lab.camera_yaw = 0.0
	lab._update_camera()
	await frame()
	await frame()
	var shapes: Array = lab.floor_grid.mesh_library.get_item_shapes(0)
	print("Floor shapes: ", shapes, "; size: ", shapes[0].size if shapes.size() > 0 else Vector3.ZERO, "; hero mask: ", lab.hero.collision_mask,
		"; grid layer: ", lab.floor_grid.collision_layer)
	check(shapes.size() == 2 and shapes[0] is BoxShape3D,
		"MeshLibrary must retain a floor shape and its transform")
	check(shapes.size() == 2 and shapes[0] is BoxShape3D and shapes[0].size.is_equal_approx(Vector3(2, 0.18, 2)) and shapes[1] == Transform3D.IDENTITY, "Floor shape must match the tile dimensions and local transform")
	check((lab.hero.collision_mask & lab.floor_grid.collision_layer) != 0,
		"Player mask must include the floor layer")
	check(lab.hero.motion_mode == CharacterBody3D.MOTION_MODE_GROUNDED
		and lab.hero.up_direction == Vector3.UP, "Player must use grounded motion with Y up")
	# Probe every cell, including undiscovered rooms whose visuals are hidden.
	var hits := 0
	for key in lab.occupied:
		var center: Vector3 = lab.floor_grid.to_global(
			lab.floor_grid.map_to_local(Vector3i(key.x, 0, key.y)))
		var query := PhysicsRayQueryParameters3D.create(
			center + Vector3.UP, center - Vector3.UP, lab.hero.collision_mask,
			[lab.hero.get_rid()])
		var hit := lab.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider == lab.floor_grid \
				and absf(hit.position.y - 1.09) < 0.001:
			hits += 1
	check(hits == lab.occupied.size(), "All 69 floor cells must collide at the visible surface; got %d" % hits)
	for i in range(15):
		await frame()
	check(supported(), "Player must settle on the initial discovered room floor")
	print("Settled player position: ", lab.hero.global_position)
	# Exercise real input and move_and_slide across cell seams in the starting room.
	for action in ["move_right", "move_down", "move_left", "move_up"]:
		var start: Vector3 = lab.hero.global_position
		var stayed_supported := true
		Input.action_press(action)
		for i in range(36):
			await frame()
			stayed_supported = stayed_supported and supported()
		Input.action_release(action)
		check(stayed_supported, "Player must remain supported throughout " + action)
		check(Vector2(lab.hero.position.x - start.x, lab.hero.position.z - start.z).length() > 2.5,
			"Input must actually move the player: " + action)
	# Walk through existing doors into both other rooms, exercising discovery refresh.
	Input.action_press("move_right")
	var stayed_supported := true
	for i in range(240):
		if _near_closed_door():
			lab._toggle_nearby_door()
		await frame()
		stayed_supported = stayed_supported and supported()
	Input.action_release("move_right")
	check(stayed_supported, "Player must remain supported through doorways and discovery")
	check(lab.discovered_rooms.size() == 3 and lab._current_room() == 2,
		"Player must reach and discover the far room")
	for i in range(30):
		await frame()
	check(supported(), "Player must remain supported after stopping")
	print("Final player position: ", lab.hero.global_position)
	print("Floor collision: %d checks, %d failures" % [checks, failures])
	lab.queue_free()
	await process_frame
	quit(1 if failures else 0)

func _near_closed_door() -> bool:
	for door in lab.doors:
		if door.closed and lab.hero.position.distance_to(door.center - Vector3(0, 1.18, 0)) <= 2.3:
			return true
	return false
