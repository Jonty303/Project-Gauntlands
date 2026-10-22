extends RefCounted
## Read-only visual obstruction queries. No physics rays, collision or room mutation.

static func player_targets(camera: Camera3D, feet: Vector3) -> Array[Vector3]:
    var targets: Array[Vector3] = []
    # Sample the capsule silhouette, not just its origin on the floor.
    var right := camera.global_basis.x.normalized()
    for height in [0.15, 0.9, 1.65]:
        for offset in [-0.34, 0.0, 0.34]:
            targets.append(feet + Vector3.UP * height + right * offset)
    return targets

static func sight_segments(camera: Camera3D, targets: Array[Vector3]) -> Array:
    var segments: Array = []
    for target in targets:
        # Orthographic rays are parallel through each target, not convergent on
        # the camera position. This also handles the genuinely vertical view.
        var start := camera.global_position
        if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
            var back := camera.global_basis.z.normalized()
            var depth := (camera.global_position - target).dot(back)
            if depth <= camera.near:
                continue
            start = target + back * (depth - camera.near)
        segments.append([start, target])
    return segments

static func obstructs(visual: MeshInstance3D, segments: Array) -> bool:
    if not visual.is_visible_in_tree():
        return false
    var inverse := visual.global_transform.affine_inverse()
    var bounds := visual.get_aabb()
    for segment in segments:
        # Transform into each segment's own space; wall orientation is irrelevant.
        # The finite endpoint excludes geometry behind the relevant object.
        if bounds.intersects_segment(inverse * segment[0], inverse * segment[1]) != null:
            return true
    return false
