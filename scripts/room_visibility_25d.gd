extends RefCounted
## Logical session state only: no rendering or physics nodes.
const BOUNDARY_EPSILON := 0.001
var rooms: Dictionary = {}
var room_by_cell: Dictionary = {}
var discovered: Dictionary = {}
var current_room := -1
var previous_cell := Vector2i.ZERO
var has_previous_cell := false

func configure(cells: Dictionary, adjacency: Dictionary, starting_room: int) -> void:
    rooms.clear()
    discovered.clear()
    has_previous_cell = false
    room_by_cell = cells.duplicate()
    for id in adjacency:
        rooms[id] = {"id":id, "discovered":id == starting_room, "neighbours":adjacency[id].duplicate()}
        for neighbour in adjacency[id]:
            assert(adjacency.has(neighbour) and adjacency[neighbour].has(id), "Room graph must be reciprocal")
    for id in cells.values():
        assert(rooms.has(id), "Every logical floor cell needs a room")
    current_room = starting_room
    discovered[starting_room] = true

func locate(grid_position: Vector3, cell_size: float) -> int:
    # GridMap has centered cells: local_to_map uses floor(position / cell_size).
    # Retain ownership within 1mm of the previous cell's boundary to absorb jitter.
    var point := Vector2(grid_position.x, grid_position.z)
    if has_previous_cell:
        var bounds := Rect2(Vector2(previous_cell) * cell_size, Vector2.ONE * cell_size)
        if bounds.grow(BOUNDARY_EPSILON).has_point(point):
            return current_room
    var cell := Vector2i(floori(point.x / cell_size), floori(point.y / cell_size))
    if not room_by_cell.has(cell):
        return current_room # Off-floor numerical samples must not invent ownership.
    previous_cell = cell
    has_previous_cell = true
    current_room = int(room_by_cell[cell])
    return current_room

func discover_current() -> bool:
    if discovered.has(current_room):
        return false
    discovered[current_room] = true
    rooms[current_room]["discovered"] = true
    return true

func eligible_rooms() -> Array:
    var eligible: Array = []
    if not rooms.has(current_room):
        return eligible
    for id in [current_room] + rooms[current_room]["neighbours"]:
        if discovered.has(id):
            eligible.append(id)
    return eligible

func faces_camera(owners: Array, normals: Array, toward_camera: Vector3) -> bool:
    var eligible := eligible_rooms()
    for index in range(normals.size()):
        var owner: int = owners[0] if owners.size() == 1 else owners[index]
        if eligible.has(owner) and normals[index].dot(toward_camera) > 0.1:
            return true
    return false
