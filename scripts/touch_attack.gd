extends Control
## Hold-to-fire touch button, supports independent joystick touch.

signal attack_changed(pressed: bool)
var active_touch: int = -1
var mouse_active: bool = false
var pressed: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and active_touch == -1:
            active_touch = event.index
            _set_pressed(true)
            accept_event()
        elif not event.pressed and event.index == active_touch:
            active_touch = -1
            _set_pressed(false)
            accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        mouse_active = event.pressed
        _set_pressed(mouse_active)
        accept_event()

func _set_pressed(value: bool) -> void:
    if pressed == value:
        return
    pressed = value
    attack_changed.emit(pressed)
    queue_redraw()

func _draw() -> void:
    var center := size / 2.0
    draw_circle(center, 55.0, Color(0.55, 0.27, 0.18, 0.80 if pressed else 0.43))
    draw_arc(center, 53.0, 0.0, TAU, 48, Color("#f0d6a0"), 3.0)
    draw_line(center + Vector2(-19, 0), center + Vector2(19, 0), Color("#f0d6a0"), 4.0)
    draw_line(center + Vector2(10, -8), center + Vector2(19, 0), Color("#f0d6a0"), 4.0)
    draw_line(center + Vector2(10, 8), center + Vector2(19, 0), Color("#f0d6a0"), 4.0)
