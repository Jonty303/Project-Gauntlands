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

static func connect_panels(records: Array[Dictionary], thickness: float) -> void:
    # Rendering topology derived from touching mesh bounds, never physics state.
    # Tiny corner/join boxes connect panels but do not consume a panel of width.
    for record in records:
        var visual: MeshInstance3D = record["visual"]
        var bounds: AABB = visual.global_transform * visual.get_aabb()
        record["bounds"] = bounds
        record["join"] = maxf(bounds.size.x, bounds.size.z) <= thickness + 0.001
        record["neighbours"] = []
    for i in range(records.size()):
        for j in range(i + 1, records.size()):
            var bounds: AABB = records[i]["bounds"]
            if bounds.grow(0.001).intersects(records[j]["bounds"]):
                records[i]["neighbours"].append(j)
                records[j]["neighbours"].append(i)

static func adjacent_panels(index: int, records: Array[Dictionary]) -> Array:
    var result: Array = []
    var visited := {index:true}
    var pending: Array = records[index]["neighbours"].duplicate()
    while not pending.is_empty():
        var neighbour: int = pending.pop_back()
        if visited.has(neighbour):
            continue
        visited[neighbour] = true
        if records[neighbour]["join"]:
            pending.append_array(records[neighbour]["neighbours"])
        else:
            result.append(neighbour)
    return result

static func cutaway_window(records: Array[Dictionary], segments: Array) -> Dictionary:
    var seeds: Dictionary = {}
    for index in range(records.size()):
        if obstructs(records[index]["visual"], segments):
            if records[index]["join"]:
                for panel in adjacent_panels(index, records):
                    seeds[panel] = true
            else:
                seeds[index] = true
    var window := seeds.duplicate()
    # Exactly one panel hop from original obstructions, not a recursive flood.
    for seed in seeds:
        for panel in adjacent_panels(seed, records):
            window[panel] = true
    for panel in window.keys():
        for neighbour in records[panel]["neighbours"]:
            if records[neighbour]["join"]:
                window[neighbour] = true
    for index in window.keys():
        if not records[index]["visual"].is_visible_in_tree():
            window.erase(index)
    return window
