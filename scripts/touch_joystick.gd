extends Control
## Floating touch joystick, anchored near the lower-left corner.
signal direction_changed(direction: Vector2)

@export var radius: float = 58.0
var direction: Vector2 = Vector2.ZERO
var active_touch: int = -1
var mouse_active: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and active_touch == -1:
            active_touch = event.index
            _set_direction(event.position)
            accept_event()
        elif not event.pressed and event.index == active_touch:
            active_touch = -1
            _set_direction(size / 2.0)
            accept_event()
    elif event is InputEventScreenDrag and event.index == active_touch:
        _set_direction(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        mouse_active = event.pressed
        _set_direction(event.position if mouse_active else size / 2.0)
        accept_event()
    elif event is InputEventMouseMotion and mouse_active:
        _set_direction(event.position)
        accept_event()

func _set_direction(local_position: Vector2) -> void:
    direction = (local_position - size / 2.0) / radius
    direction = direction.limit_length(1.0)
    if direction.length() < 0.15:
        direction = Vector2.ZERO
    direction_changed.emit(direction)
    queue_redraw()

func _draw() -> void:
    var center := size / 2.0
    draw_circle(center, radius + 12.0, Color(0.12, 0.15, 0.20, 0.38))
    draw_arc(center, radius, 0, TAU, 64, Color(0.85, 0.85, 0.85, 0.65), 2.0, true)
    draw_circle(center + direction * radius, 23.0, Color(0.83, 0.75, 0.54, 0.80))
