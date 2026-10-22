extends CanvasLayer
## Camera tuning and runtime diagnostics for the isolated 2.5D experiment.
var camera: Camera3D
var hero: CharacterBody3D
var experiment: Node3D
var stats: Label
var panel: PanelContainer
var readouts: Dictionary = {}

func configure(active_camera: Camera3D, active_hero: CharacterBody3D, owner_scene: Node3D) -> void:
    camera = active_camera
    hero = active_hero
    experiment = owner_scene

func _ready() -> void:
    panel = PanelContainer.new()
    panel.position = Vector2(12,12)
    add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var title := Label.new()
    title.text = "GAUNTLANDS | CAMERA LAB"
    column.add_child(title)
    stats = Label.new()
    column.add_child(stats)
    _add_control(column,"Zoom (orthographic size)","size",6.0,40.0,0.5)
    _add_control(column,"Elevation (degrees)","camera_elevation",15.0,85.0,1.0)
    _add_control(column,"Rotation (degrees)","camera_yaw",-180.0,180.0,5.0)
    _add_control(column,"Follow distance","camera_distance",8.0,50.0,1.0)
    _add_control(column,"Vertical framing","camera_framing",-4.0,6.0,0.25)
    var reset := Button.new()
    reset.text = "Reset camera"
    reset.pressed.connect(_reset)
    column.add_child(reset)
    var hint := Label.new()
    hint.text = "F3: hide/show  |  +/-: zoom\nSend screenshot with settings visible"
    column.add_child(hint)
    _refresh()

func _add_control(column: VBoxContainer, caption: String, property: String, minimum: float, maximum: float, step: float) -> void:
    var label := Label.new()
    column.add_child(label)
    readouts[property] = label
    var slider := HSlider.new()
    slider.custom_minimum_size = Vector2(240,0)
    slider.min_value = minimum
    slider.max_value = maximum
    slider.step = step
    slider.value = _get_value(property)
    slider.value_changed.connect(func(value: float) -> void:
        _set_value(property,value)
        _refresh()
    )
    column.add_child(slider)
    readouts[property + "_slider"] = slider

func _get_value(property: String) -> float:
    if property == "size":
        return camera.size
    return float(experiment.get(property))

func _set_value(property: String, value: float) -> void:
    if property == "size":
        camera.size = value
    else:
        experiment.set(property,value)
        experiment.call("_update_camera_transform",true)

func _reset() -> void:
    _set_value("size",13.0)
    _set_value("camera_elevation",45.0)
    _set_value("camera_yaw",45.0)
    _set_value("camera_distance",24.0)
    _set_value("camera_framing",0.7)
    for property in ["size","camera_elevation","camera_yaw","camera_distance","camera_framing"]:
        var slider: HSlider = readouts[property + "_slider"]
        slider.set_value_no_signal(_get_value(property))
    _refresh()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_F3:
        panel.visible = not panel.visible
        get_viewport().set_input_as_handled()
    elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
        _set_value("size",maxf(6.0,camera.size-1.0))
        _sync_zoom()
    elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
        _set_value("size",minf(40.0,camera.size+1.0))
        _sync_zoom()

func _sync_zoom() -> void:
    var slider: HSlider = readouts["size_slider"]
    slider.set_value_no_signal(camera.size)
    _refresh()

func _process(_delta: float) -> void:
    if panel.visible:
        _refresh()

func _refresh() -> void:
    if stats == null or camera == null or hero == null:
        return
    var p := hero.global_position
    stats.text = "FPS: %d | Position: %.1f, %.1f, %.1f\nSpeed: %.2f m/s" % [Engine.get_frames_per_second(),p.x,p.y,p.z,hero.velocity.length()]
    var captions := {"size":"Zoom","camera_elevation":"Elevation","camera_yaw":"Rotation","camera_distance":"Distance","camera_framing":"Framing"}
    for property in captions:
        var label: Label = readouts[property]
        label.text = "%s: %.2f" % [captions[property],_get_value(property)]
