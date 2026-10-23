extends RefCounted
## Render policy only. Open-door previews never write discovery or physics state.
static func can_render(owners: Array, discovered: Dictionary) -> bool:
    for owner in owners:
        if discovered.has(owner):
            return true
    return false

static func through_portal(eye: Vector3, target: Vector3, door: Dictionary) -> bool:
    # Door mesh local X is its thickness, Z its aperture width. Testing the plane
    # rather than a proximity radius prevents revealing around a jamb or corner.
    var visual: MeshInstance3D = door["visual"]
    var inverse := visual.global_transform.affine_inverse()
    var start: Vector3 = inverse * eye
    var end: Vector3 = inverse * target
    var dx := end.x - start.x
    if absf(dx) < 0.000001:
        return false
    var t := -start.x / dx
    if t <= 0.0 or t >= 1.0:
        return false
    var crossing := start.lerp(end, t)
    var bounds := visual.get_aabb()
    return crossing.y > bounds.position.y and crossing.y < bounds.end.y and crossing.z > bounds.position.z and crossing.z < bounds.end.z

static func clear_sight(eye: Vector3, target: Vector3, walls: Array[Dictionary], doors: Array[Dictionary], excluded: MeshInstance3D = null) -> bool:
    # Visual alpha/visibility are deliberately ignored: hidden/faded walls and
    # closed doors are still solid sight blockers. No enemy LOS system is changed.
    for record in walls:
        var visual: MeshInstance3D = record["visual"]
        if visual == excluded:
            continue
        var inverse := visual.global_transform.affine_inverse()
        if visual.get_aabb().intersects_segment(inverse * eye, inverse * target) != null:
            return false
    for door in doors:
        if not door["closed"] or door["visual"] == excluded:
            continue
        var visual: MeshInstance3D = door["visual"]
        var inverse := visual.global_transform.affine_inverse()
        if visual.get_aabb().intersects_segment(inverse * eye, inverse * target) != null:
            return false
    return true

static func rendered_rooms(discovered: Dictionary, current_room: int, eye: Vector3, walls: Array[Dictionary], doors: Array[Dictionary]) -> Dictionary:
    # Decide an entire room's rendering from the aperture sightline. Per-tile
    # sight samples produced holes in the shared floor and isolated wall pieces.
    var rooms := discovered.duplicate()
    for door in doors:
        if door["closed"]:
            continue
        var side: int = door["rooms"].find(current_room)
        if side < 0:
            continue
        var adjoining: int = door["rooms"][1 - side]
        var target: Vector3 = door["center"] + door["normals"][side] * 0.25
        target.y = eye.y
        if through_portal(eye, target, door) and clear_sight(eye, target, walls, doors):
            rooms[adjoining] = true
    return rooms

static func preview_visible(owners: Array, target: Vector3, eye: Vector3, current_room: int, walls: Array[Dictionary], doors: Array[Dictionary], excluded: MeshInstance3D = null) -> bool:
    # Only direct portals from the player's current room. An open door elsewhere
    # cannot reveal unrelated rooms, and this does not recurse through door chains.
    for door in doors:
        if door["closed"] or not door["rooms"].has(current_room):
            continue
        var adjoining: int = door["rooms"][1] if door["rooms"][0] == current_room else door["rooms"][0]
        if owners.has(adjoining) and through_portal(eye, target, door) and clear_sight(eye, target, walls, doors, excluded):
            return true
    return false
