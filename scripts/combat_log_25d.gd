extends CanvasLayer
## Compact transient messages plus a toggleable translucent history.
var entries: Array[String] = []
var recent: Label
var history: RichTextLabel
var panel: PanelContainer
var elapsed := 0.0

func _ready() -> void:
    recent = Label.new()
    recent.position = Vector2(18, 0)
    recent.add_theme_color_override("font_color", Color("#e8e4d9"))
    recent.add_theme_color_override("font_shadow_color", Color("#11141a"))
    recent.add_theme_constant_override("shadow_offset_x", 1)
    recent.add_theme_constant_override("shadow_offset_y", 2)
    add_child(recent)
    panel = PanelContainer.new()
    panel.visible = false
    panel.position = Vector2(18, 0)
    panel.custom_minimum_size = Vector2(400, 210)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.07, 0.09, 0.72)
    style.set_corner_radius_all(7)
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)
    history = RichTextLabel.new()
    history.bbcode_enabled = false
    history.scroll_following = true
    history.custom_minimum_size = Vector2(385, 200)
    panel.add_child(history)
    _position_ui()
    get_viewport().size_changed.connect(_position_ui)

func _position_ui() -> void:
    var height := get_viewport().get_visible_rect().size.y
    recent.position = Vector2(18, height - 95)
    panel.position = Vector2(18, height - 245)

func add_message(message: String) -> void:
    if message.is_empty():
        return
    entries.append(message)
    if entries.size() > 60:
        entries.pop_front()
    recent.text = "\n".join(entries.slice(maxi(0, entries.size() - 3)))
    history.text = "\n".join(entries)
    elapsed = 0.0
    recent.modulate.a = 1.0

func _process(delta: float) -> void:
    elapsed += delta
    if not panel.visible:
        recent.modulate.a = clampf((5.5 - elapsed) / 1.5, 0.0, 1.0)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L:
        panel.visible = not panel.visible
        recent.visible = not panel.visible
        get_viewport().set_input_as_handled()
