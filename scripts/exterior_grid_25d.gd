extends MeshInstance3D
## Visual-only exterior ground and background fill under concealed floor tiles.
var exterior_cells: Dictionary = {}
var concealed_background: Dictionary = {}

func build(occupied: Dictionary, origin: Vector3, cell_size: float) -> void:
    name = "ExteriorGroundGrid"
    cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var min_cell := Vector2i.ZERO
    var max_cell := Vector2i.ZERO
    for cell in occupied:
        min_cell = min_cell.min(cell)
        max_cell = max_cell.max(cell)
    var vertices := PackedVector3Array()
    # Extend beyond any view in this lab, while anchoring the grid to the world.
    for x in range(min_cell.x - 32, max_cell.x + 33):
        for z in range(min_cell.y - 32, max_cell.y + 33):
            var cell := Vector2i(x,z)
            if occupied.has(cell):
                continue
            exterior_cells[cell] = true
            var center := origin + Vector3(x * cell_size,-0.2,z * cell_size)
            var half := cell_size * 0.5
            var a := center + Vector3(-half,0,-half)
            var b := center + Vector3(half,0,-half)
            var c := center + Vector3(half,0,half)
            var d := center + Vector3(-half,0,half)
            vertices.append_array(PackedVector3Array([a,c,b,a,d,c]))
    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    var ground := ArrayMesh.new()
    ground.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh = ground
    var shader := Shader.new()
    shader.code = """shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float cell_size = 2.0;
uniform vec2 grid_origin = vec2(0.0);
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    vec2 p = (world_position.xz - grid_origin) / cell_size;
    vec2 edge = abs(fract(p + 0.5) - 0.5);
    vec2 aa = max(fwidth(p), vec2(0.0001));
    vec2 line = 1.0 - smoothstep(vec2(0.008), vec2(0.008) + aa, edge);
    ALBEDO = mix(vec3(0.11765,0.14902,0.18824), vec3(0.145,0.177,0.215), max(line.x,line.y));
}
"""
    var material := ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("cell_size",cell_size)
    material.set_shader_parameter("grid_origin",Vector2(origin.x,origin.z)-Vector2.ONE*cell_size*0.5)
    material_override = material
    # Hidden floors must not leave holes that advertise the dungeon footprint.
    # These visual background patches withdraw before their floor is rendered.
    var tile := PlaneMesh.new()
    tile.size = Vector2.ONE * cell_size
    for cell in occupied:
        var background := MeshInstance3D.new()
        background.mesh = tile
        background.material_override = material
        background.position = origin + Vector3(cell.x * cell_size,-0.2,cell.y * cell_size)
        background.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(background)
        concealed_background[cell] = background

func sync_background(floors: Dictionary) -> void:
    for cell in concealed_background:
        concealed_background[cell].visible = not floors[cell].visible
