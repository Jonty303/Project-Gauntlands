extends Node3D
## Reusable rectangular dungeon module with precise door sockets.
## Local X is the corridor axis; openings cut into east/west walls.
@export var room_width := 11.0
@export var room_depth := 9.0
@export var west_opening := 0.0
@export var east_opening := 0.0
@export var stone_color := Color("#77796f")
@export var floor_color := Color("#343b43")
@export var discovered := false
const WALL_HEIGHT := 3.1
var occluding_walls: Array[StaticBody3D] = []

func _ready() -> void:
    _build()
    visible = discovered

func reveal() -> void:
    discovered = true
    visible = true

func _build() -> void:
    _box("Floor", Vector3(0,-0.18,0), Vector3(room_width,0.35,room_depth), floor_color, false)
    _box("NorthWall", Vector3(0,1.55,-room_depth*0.5), Vector3(room_width-0.45,WALL_HEIGHT,0.45), stone_color)
    _box("SouthWall", Vector3(0,1.55,room_depth*0.5), Vector3(room_width+0.45,WALL_HEIGHT,0.45), stone_color)
    _end_wall("West", -room_width*0.5, west_opening)
    _end_wall("East", room_width*0.5, east_opening)

func _end_wall(side: String, x: float, opening: float) -> void:
    if opening <= 0.0:
        _box(side+"Wall", Vector3(x,1.55,0), Vector3(0.45,WALL_HEIGHT,room_depth-0.45), stone_color)
        return
    var segment := (room_depth - 0.45 - opening) * 0.5
    if segment <= 0.0:
        return
    for sign in [-1.0,1.0]:
        var z: float = sign * (opening * 0.5 + segment * 0.5)
        _box(side+"Wall", Vector3(x,1.55,z), Vector3(0.45,WALL_HEIGHT,segment), stone_color)

func _box(label: String, location: Vector3, dimensions: Vector3, tint: Color, solid: bool = true) -> void:
    var body := StaticBody3D.new()
    body.name = label
    body.position = location
    add_child(body)
    var mesh := MeshInstance3D.new()
    mesh.name = "Visual"
    var geometry := BoxMesh.new()
    geometry.size = dimensions
    mesh.mesh = geometry
    if solid:
        var shader := Shader.new()
        shader.code = """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
uniform vec4 stone_color : source_color = vec4(0.47,0.48,0.44,1.0);
uniform vec4 holes[4];
uniform int hole_count = 0;
uniform float fade_strength = 0.0;
uniform float aspect_ratio = 1.77778;
void fragment() {
    ALBEDO = stone_color.rgb;
    ROUGHNESS = 1.0;
    float reveal = 0.0;
    for (int i = 0; i < 4; i++) {
        if (i >= hole_count) { break; }
        vec2 delta = SCREEN_UV - holes[i].xy;
        delta.x *= aspect_ratio;
        reveal = max(reveal, 1.0 - smoothstep(holes[i].z*0.55,holes[i].z,length(delta)));
    }
    ALPHA = 1.0 - 0.94 * reveal * fade_strength;
}
"""
        var wall_material := ShaderMaterial.new()
        wall_material.shader = shader
        wall_material.set_shader_parameter("stone_color", tint)
        mesh.material_override = wall_material
    else:
        var material := StandardMaterial3D.new()
        material.albedo_color = tint
        material.roughness = 1.0
        mesh.material_override = material
    body.add_child(mesh)
    if solid:
        occluding_walls.append(body)
        var edge := MeshInstance3D.new()
        edge.name = "StoneEdge"
        var cap := BoxMesh.new()
        cap.size = Vector3(dimensions.x+0.06,0.09,dimensions.z+0.06)
        edge.mesh = cap
        edge.position.y = dimensions.y*0.5+0.045
        var edge_material := StandardMaterial3D.new()
        edge_material.albedo_color = Color("#a4a59b")
        edge.material_override = edge_material
        body.add_child(edge)
        var collision := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = dimensions
        collision.shape = box
        body.add_child(collision)
