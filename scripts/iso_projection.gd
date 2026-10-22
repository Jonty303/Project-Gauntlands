extends RefCounted
## World coordinates remain Cartesian; only rendering uses diamond projection.
const SCALE_X := 0.82
const SCALE_Y := 0.41

static func project(point: Vector2) -> Vector2:
    return Vector2((point.x - point.y) * SCALE_X, (point.x + point.y) * SCALE_Y)

static func projected_direction(direction: Vector2) -> Vector2:
    return project(direction).normalized()
