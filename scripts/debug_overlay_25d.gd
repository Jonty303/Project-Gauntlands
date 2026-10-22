extends CanvasLayer
## Temporary developer HUD; reusable as a basis for combat/AI diagnostics.
var camera: Camera3D
var hero: CharacterBody3D
var stats: Label
var zoom_label: Label
var panel: PanelContainer

func configure(active_camera: Camera3D, active_hero: CharacterBody3D) -> void:
    camera = active_camera
    hero = active_hero

func _ready() -> void:
    panel = PanelContainer.new()
    panel.name = "DebugPanel"
    panel.position = Vector2(12, 12)
    add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var heading := Label.new()
    heading.text = "GAUNTLANDS | DEBUG"
    column.add_child(heading)
    stats = Label.new()
    column.add_child(stats)
    var zoom_row := HBoxContainer.new()
    column.add_child(zoom_row)
    var minus := Button.new()
    minus.text = "Zoom -"
    minus.pressed.connect(_zoom_out)
    zoom_row.add_child(minus)
    zoom_label = Label.new()
    zoom_row.add_child(zoom_label)
    var plus := Button.new()
    plus.text = "Zoom +"
    plus.pressed.connect(_zoom_in)
    zoom_row.add_child(plus)
    var hint := Label.new()
    hint.text = "F3: toggle debug | +/-: zoom"
    column.add_child(hint)
    _refresh()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_F3:
        panel.visible = not panel.visible
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
        _zoom_in()
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
        _zoom_out()
        get_viewport().set_input_as_handled()

func _zoom_in() -> void:
    if camera != null:
        camera.size = maxf(6.0, camera.size - 2.0)
    _refresh()

func _zoom_out() -> void:
    if camera != null:
        camera.size = minf(40.0, camera.size + 2.0)
    _refresh()

func _process(_delta: float) -> void:
    if panel.visible:
        _refresh()

func _refresh() -> void:
    if stats == null or camera == null or hero == null:
        return
    var p := hero.global_position
    stats.text = "FPS: %d\nPosition: %.1f, %.1f, %.1f\nSpeed: %.2f m/s" % [Engine.get_frames_per_second(), p.x, p.y, p.z, hero.velocity.length()]
    zoom_label.text = "%.0f" % camera.size
