extends SceneTree

var arena
var output := ""

func _initialize() -> void:
	call_deferred("run")

func capture(label: String, location: Vector2) -> void:
	arena.player.position = location
	for i in range(5):
		await physics_frame
	arena.exploration.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output.path_join(label + ".png"))
	assert(error == OK)

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Run with a renderer and -- <existing output directory>")
		quit(1)
		return
	output = args[0]
	arena = load("res://scenes/main.tscn").instantiate()
	root.add_child(arena)
	for actor in [arena.player] + arena.goblins:
		actor.set_physics_process(false)
	await capture("01-start", arena.player.spawn_point)
	arena.interactables[0].set_open(true)
	await capture("02-aperture", Vector2(576, 224))
	await capture("03-arrow-lane", Vector2(784, 360))
	await capture("04-secret-clue", Vector2(1120, 740))
	arena.interactables[7].set_open(true)
	await capture("05-secret-chest", Vector2(1120, 1080))
	arena.interactables[10].activate()
	await capture("06-open-chest", Vector2(1120, 1080))
	arena.traps[0].set_physics_process(false)
	arena.traps[0].phase = "active"
	arena.traps[0].queue_redraw()
	await capture("07-spikes", Vector2(1860, 592))
	await capture("08-entrance", Vector2(144, 92))
	arena.interactables[8].activate()
	await capture("09-escaped", Vector2(144, 92))
	arena.restart_encounter()
	await capture("10-before-pause", arena.player.spawn_point)
	arena.pause_menu.open_menu()
	await capture("11-paused", arena.player.spawn_point)
	arena.pause_menu.request_restart()
	await capture("12-restart-confirm", arena.player.spawn_point)
	arena.pause_menu.reset()
	arena.interactables[0].set_open(true)
	await capture("13-discover-corridor", Vector2(576, 224))
	arena.interactables[0].set_open(false)
	await capture("14-remember-corridor", Vector2(576, 224))
	print("VISUAL CAPTURES: 14 saved")
	quit()
