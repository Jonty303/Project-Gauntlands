extends CanvasLayer

# Named owners prevent closing inventory from releasing a menu-owned pause.
var arena: Node2D
var reasons: Dictionary = {}
var panel: PanelContainer
var heading: Label
var resume_button: Button
var restart_button: Button
var confirming := false
var release_pending := false
const RELEASE_ACTIONS := ["sword", "bow", "interact", "lock_target", "target_left", "target_right", "restart", "pause", "ui_accept", "ui_cancel"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	panel = PanelContainer.new()
	panel.position = Vector2(160, 125)
	panel.custom_minimum_size = Vector2(320, 210)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("171b1d")
	style.border_color = Color("9c8965")
	style.set_border_width_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 20)
	column.add_child(heading)
	resume_button = Button.new()
	resume_button.custom_minimum_size.y = 42
	resume_button.pressed.connect(resume_or_cancel)
	column.add_child(resume_button)
	restart_button = Button.new()
	restart_button.custom_minimum_size.y = 42
	restart_button.pressed.connect(request_restart)
	column.add_child(restart_button)
	resume_button.focus_neighbor_top = resume_button.get_path_to(restart_button)
	resume_button.focus_neighbor_bottom = resume_button.get_path_to(restart_button)
	restart_button.focus_neighbor_top = restart_button.get_path_to(resume_button)
	restart_button.focus_neighbor_bottom = restart_button.get_path_to(resume_button)
	panel.hide()

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if arena.escaped or arena.player.hp <= 0:
			if event is InputEventJoypadButton:
				arena.restart_encounter()
		elif panel.visible:
			resume_or_cancel()
		else:
			open_menu()
	elif panel.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_or_cancel()
	elif panel.visible and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if restart_button.has_focus():
			request_restart()
		else:
			resume_or_cancel()
	elif panel.visible and (event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down")):
		get_viewport().set_input_as_handled()
		if resume_button.has_focus():
			restart_button.grab_focus()
		else:
			resume_button.grab_focus()

func set_paused(reason: StringName, enabled: bool) -> void:
	if enabled:
		reasons[reason] = true
		release_pending = false
		get_tree().paused = true
	else:
		reasons.erase(reason)
		if reasons.is_empty():
			# Wait for the confirming/cancelling press to release before simulation.
			release_pending = true

func _process(_delta: float) -> void:
	if not release_pending:
		return
	for action in RELEASE_ACTIONS:
		if Input.is_action_pressed(action) or Input.is_action_just_released(action):
			return
	release_pending = false
	get_tree().paused = false

func open_menu() -> void:
	if arena.escaped or arena.player.hp <= 0:
		return
	set_paused(&"menu", true)
	confirming = false
	panel.show()
	update_text()
	resume_button.grab_focus()

func resume_or_cancel() -> void:
	if confirming:
		confirming = false
		update_text()
		resume_button.grab_focus()
		return
	panel.hide()
	set_paused(&"menu", false)

func request_restart() -> void:
	if not confirming:
		confirming = true
		update_text()
		resume_button.grab_focus()
		return
	arena.restart_encounter()
	# UI accept is also sword on controller; consume its release.
	get_tree().paused = true
	release_pending = true

func reset() -> void:
	reasons.clear()
	confirming = false
	panel.hide()
	release_pending = false
	get_tree().paused = false

func update_text() -> void:
	heading.text = "RESTART THIS RUN?" if confirming else "PAUSED"
	resume_button.text = "Cancel" if confirming else "Resume"
	restart_button.text = "Restart — lose this run" if confirming else "Restart Run"
