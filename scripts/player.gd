extends CharacterBody2D

@export var move_speed: float = 150.0
@export var acceleration: float = 1100.0
@export var deceleration: float = 1400.0

var facing := Vector2.DOWN

@onready var facing_line: Line2D = $Facing

func _physics_process(delta: float) -> void:
    var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var target_velocity := input_vector * move_speed
    var rate := acceleration if input_vector != Vector2.ZERO else deceleration
    velocity = velocity.move_toward(target_velocity, rate * delta)

    if input_vector != Vector2.ZERO:
        facing = input_vector.normalized()

    move_and_slide()
    _update_facing_indicator()

func _update_facing_indicator() -> void:
    facing_line.points = PackedVector2Array([Vector2.ZERO, facing * 16.0])
