extends Node3D
## Isolated 3D architecture test. Existing 2D scenes and combat remain untouched.
const SPEED := 5.0
const GOBLIN_SPEED := 3.5
const GOBLIN_DETECTION := 12.0
const GOBLIN_STOP := 1.65
const GOBLIN_ATTACK_COOLDOWN := 1.45
const GOBLIN_WINDUP := 0.48
const LOOT_CHEST = preload("res://scripts/loot_chest_25d.gd")
const COMBAT_LOG_UI = preload("res://scripts/combat_log_25d.gd")
const SPIKE_TRAP = preload("res://scripts/spike_trap_25d.gd")
const CHARACTER_ANIMATION = preload("res://scripts/character_animation_25d.gd")
const DEBUG_OVERLAY = preload("res://scripts/debug_overlay_25d.gd")
const DUNGEON_DOOR = preload("res://scripts/dungeon_door_25d.gd")
const START_ROOM = preload("res://scenes/rooms/starting_chamber.tscn")
const CORRIDOR_ROOM = preload("res://scenes/rooms/connecting_corridor.tscn")
const ENCOUNTER_ROOM = preload("res://scenes/rooms/encounter_chamber.tscn")
const WALL_HEIGHT := 3.1
const WINDOW_FADE_SPEED := 5.0
const ATTACK_INTERVAL := 0.55
const ATTACK_RANGE := 11.0
var hero: CharacterBody3D
var camera: Camera3D
var goblins: Array[CharacterBody3D] = []
var wall_occluders: Array[StaticBody3D] = []
var wall_windows: Dictionary = {}
var window_strengths: Dictionary = {}
var doors: Array[Node3D] = []
var corridor_revealed := false
var chamber_revealed := false
var corridor_root: Node3D
var chamber_root: Node3D
var target: CharacterBody3D
var target_marker: MeshInstance3D
var attack_held := false
var attack_timer := 0.0
var combat_log := "Ready":
    set(value):
        combat_log = value
        if is_instance_valid(combat_log_ui):
            combat_log_ui.call("add_message", value)
var combat_log_ui: CanvasLayer
var goblin_health: Dictionary = {}
var goblin_home: Dictionary = {}
var goblin_ai: Dictionary = {}
var hero_health := 100
var gold := 0
var reward_chest: Node3D
var hero_dead := false
var goblin_state := "Idle"
var goblin_distance := 0.0
var light_enabled := true
var camera_yaw := 45.0
var camera_elevation := 24.0
var camera_distance := 24.0
var camera_framing := 0.7

func _ready() -> void:
    # Each room owns its own geometry; adjoining sockets align exactly.
    var start_room := START_ROOM.instantiate()
    start_room.name = "StartingRoom"
    add_child(start_room)
    corridor_root = CORRIDOR_ROOM.instantiate()
    corridor_root.name = "CorridorRoom"
    corridor_root.position.x = 16.0
    add_child(corridor_root)
    chamber_root = ENCOUNTER_ROOM.instantiate()
    chamber_root.name = "EncounterRoom"
    chamber_root.position.x = 24.5
    add_child(chamber_root)
    for room in [start_room, corridor_root, chamber_root]:
        for wall in room.get("occluding_walls"):
            wall_occluders.append(wall)
    _place_door("MainDoor", Vector3(13,0,0), 1.5, false)
    _place_door("HallDoubleDoor", Vector3(19,0,0), 3.0, true)
    doors[1].reparent(corridor_root, true)
    _make_box("Pillar", Vector3(-3,1.15,-3), Vector3(1.1,2.3,1.1), Color("#666d6c"))
    _decorate_start_room()
    _decorate_chamber()
    hero = _make_actor("Hero", Vector3(-5,0,1), Color("#587b9c"))
    _decorate_actor(hero, true)

    for position in [Vector3(1,0,-2),Vector3(3,0,2),Vector3(24,0,0)]:
        var goblin := _make_actor("Goblin",position,Color("#769557"))
        goblins.append(goblin)
        _decorate_actor(goblin, false)
        goblin_health[goblin] = 35
        goblin_home[goblin] = goblin.global_position
        goblin_ai[goblin] = {"state":"Idle", "cooldown":0.5, "windup":-1.0, "last_seen":-100.0}
    goblins[2].reparent(chamber_root, true)
    _place_spike_trap(Vector3(5.5, 0, 1.0))
    reward_chest = Node3D.new()
    reward_chest.name = "GuardroomChest"
    reward_chest.set_script(LOOT_CHEST)
    reward_chest.position = Vector3(0.8, 0, -0.8)
    chamber_root.add_child(reward_chest)
    _make_target_marker()
    camera = Camera3D.new()
    camera.name = "IsometricCamera"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 13.0
    camera.current = true
    add_child(camera)
    _update_camera_transform(true)
    var overlay := CanvasLayer.new()
    overlay.name = "DeveloperOverlay"
    overlay.set_script(DEBUG_OVERLAY)
    overlay.call("configure", camera, hero, self)
    add_child(overlay)
    combat_log_ui = CanvasLayer.new()
    combat_log_ui.name = "CombatHistory"
    combat_log_ui.set_script(COMBAT_LOG_UI)
    add_child(combat_log_ui)
    combat_log_ui.call("add_message", "Entered the dungeon. L: combat history")
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55,-35,0)
    sun.light_energy = 0.5
    add_child(sun)
    var ambient := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("#151b23")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("#717d87")
    environment.ambient_light_energy = 0.45
    ambient.environment = environment
    add_child(ambient)
    var torch := OmniLight3D.new()
    torch.name = "Torch"
    torch.position = Vector3(-5,2.8,-5.9)
    torch.light_color = Color("#ffb35f")
    torch.light_energy = 2.2
    torch.omni_range = 8.0
    add_child(torch)

func _place_spike_trap(location: Vector3) -> void:
    var trap := Node3D.new()
    trap.name = "SpikeTrap"
    trap.set_script(SPIKE_TRAP)
    trap.position = location
    var victims: Array[CharacterBody3D] = [hero]
    victims.append_array(goblins)
    trap.call("configure", victims)
    trap.connect("triggered", Callable(self, "_on_trap_triggered"))
    add_child(trap)

func _floating_combat_text(world_position: Vector3, message: String, tint: Color) -> void:
    var label := Label3D.new()
    label.name = "CombatText"
    label.text = message
    label.font_size = 48
    label.pixel_size = 0.006
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.outline_size = 8
    label.modulate = tint
    label.position = world_position + Vector3(randf_range(-0.22, 0.22), 2.05, 0)
    add_child(label)
    var drift := create_tween()
    drift.set_parallel(true)
    drift.tween_property(label, "position", label.position + Vector3(0, 1.1, 0), 0.9)
    drift.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.25)
    drift.chain().tween_callback(label.queue_free)

func _on_trap_triggered(victim: CharacterBody3D, amount: int) -> void:
    if victim == hero:
        _take_hero_damage(amount)
        return
    if not goblin_health.has(victim):
        return
    goblin_health[victim] = int(goblin_health[victim]) - amount
    if goblin_ai.has(victim):
        goblin_ai[victim]["windup"] = -1.0
    combat_log = "Spike trap hit goblin! -%d HP" % amount
    _floating_combat_text(victim.global_position, str(amount), Color("#ff9359"))
    victim.get_node("Animator").call("play_hit")
    if int(goblin_health[victim]) <= 0:
        goblins.erase(victim)
        goblin_health.erase(victim)
        goblin_home.erase(victim)
        goblin_ai.erase(victim)
        if target == victim:
            target = null
            attack_timer = INF
        victim.queue_free()
        combat_log = "Goblin killed by spike trap"

func _take_hero_damage(amount: int) -> void:
    if hero_dead:
        return
    hero_health = maxi(0, hero_health - amount)
    _floating_combat_text(hero.global_position, "-%d" % amount, Color("#ff6565"))
    combat_log = "Spike trap! -%d HP" % amount
    hero.get_node("Animator").call("play_hit")
    if hero_health <= 0:
        hero_dead = true
        combat_log = "Hero defeated"
        hero.velocity = Vector3.ZERO

func _decorate_start_room() -> void:
    # Low-profile stone courses give the room a first masonry treatment.
    for x in range(-11, 12, 3):
        _make_box("NorthStoneCourse", Vector3(float(x), 0.5, -9.22), Vector3(2.75, 0.045, 0.07), Color("#969588"), false)
        _make_box("SouthStoneCourse", Vector3(float(x), 0.5, 9.22), Vector3(2.75, 0.045, 0.07), Color("#969588"), false)
    for x in range(-11, 12, 3):
        for z in range(-7, 8, 3):
            _make_box("FloorJoint", Vector3(float(x), 0.005, float(z)), Vector3(2.85, 0.012, 0.035), Color("#22282d"), false)
    # A small stone plinth and an iron brazier beside the first doorway.
    _make_box("BrazierPlinth", Vector3(10.6,0.24,-3.0), Vector3(0.9,0.48,0.9), Color("#66675f"))
    _make_box("BrazierBowl", Vector3(10.6,0.58,-3.0), Vector3(0.7,0.2,0.7), Color("#292a29"), false)

func _decorate_chamber() -> void:
    # Decorations belong to the room, so discovery hides them as a unit.
    for x in [21.0, 25.0, 28.0]:
        for z in [-4.0, 0.0, 4.0]:
            var joint_name := "ChamberJoint_%d_%d" % [int(x), int(z)]
            _make_box(joint_name, Vector3(x, 0.005, z), Vector3(2.7, 0.012, 0.045), Color("#23282b"), false)
            get_node(joint_name).reparent(chamber_root, true)
    _make_box("ChamberAltar", Vector3(27,0.42,-3.4), Vector3(1.5,0.84,1.0), Color("#62655e"))
    get_node("ChamberAltar").reparent(chamber_root, true)
    _make_box("AltarTop", Vector3(27,0.88,-3.4), Vector3(1.65,0.13,1.15), Color("#989588"), false)
    get_node("AltarTop").reparent(chamber_root, true)

func _decorate_actor(actor: CharacterBody3D, is_hero: bool) -> void:
    # Low-poly silhouettes: distinct head, torso, limbs, and equipment.
    var visual := actor.get_node_or_null("Visual") as MeshInstance3D
    if visual != null:
        visual.visible = false
    var torso := MeshInstance3D.new()
    torso.name = "Torso"
    var torso_mesh := BoxMesh.new()
    torso_mesh.size = Vector3(0.62, 0.77, 0.42)
    torso.mesh = torso_mesh
    torso.position.y = 1.04
    var torso_mat := StandardMaterial3D.new()
    torso_mat.albedo_color = Color("#506c82") if is_hero else Color("#646b39")
    torso.material_override = torso_mat
    actor.add_child(torso)
    var head := MeshInstance3D.new()
    head.name = "Head"
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.28 if is_hero else 0.31
    head_mesh.height = 0.56 if is_hero else 0.62
    head.mesh = head_mesh
    head.position.y = 1.63
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color("#c29a76") if is_hero else Color("#73864c")
    head.material_override = skin
    actor.add_child(head)
    for side in [-1.0, 1.0]:
        var leg := MeshInstance3D.new()
        var leg_mesh := BoxMesh.new()
        leg_mesh.size = Vector3(0.23, 0.62, 0.29)
        leg.mesh = leg_mesh
        leg.name = "LeftLeg" if side < 0.0 else "RightLeg"
        leg.position = Vector3(side * 0.18, 0.34, 0)
        var cloth := StandardMaterial3D.new()
        cloth.albedo_color = Color("#343b40") if is_hero else Color("#554634")
        leg.material_override = cloth
        actor.add_child(leg)
        var arm := MeshInstance3D.new()
        var arm_mesh := BoxMesh.new()
        arm_mesh.size = Vector3(0.2, 0.65, 0.24)
        arm.mesh = arm_mesh
        arm.name = "LeftArm" if side < 0.0 else "RightArm"
        arm.position = Vector3(side * 0.42, 1.04, 0)
        arm.material_override = torso_mat
        actor.add_child(arm)
        if not is_hero:
            var ear := MeshInstance3D.new()
            var ear_mesh := SphereMesh.new()
            ear_mesh.radius = 0.16
            ear_mesh.height = 0.19
            ear.mesh = ear_mesh
            ear.position = Vector3(side * 0.36, 1.65, 0)
            ear.material_override = skin
            actor.add_child(ear)
    if is_hero:
        var pack := MeshInstance3D.new()
        var pack_mesh := BoxMesh.new()
        pack_mesh.size = Vector3(0.48, 0.62, 0.24)
        pack.mesh = pack_mesh
        pack.position = Vector3(0, 1.05, 0.34)
        var leather := StandardMaterial3D.new()
        leather.albedo_color = Color("#6b4b31")
        pack.material_override = leather
        actor.add_child(pack)
    var animator := Node3D.new()
    animator.name = "Animator"
    animator.set_script(CHARACTER_ANIMATION)
    animator.set("is_hero", is_hero)
    actor.add_child(animator)

func _physics_process(delta: float) -> void:
    if hero_dead:
        if Input.is_key_pressed(KEY_R):
            get_tree().reload_current_scene()
        return
    var direction := Input.get_vector("move_left","move_right","move_up","move_down")
    # Screen-relative movement: derive the ground-plane axes from the camera.
    var right: Vector3 = camera.global_basis.x
    var up: Vector3 = -camera.global_basis.z
    right.y = 0.0
    up.y = 0.0
    right = right.normalized()
    up = up.normalized()
    var motion: Vector3 = (right * direction.x - up * direction.y).normalized()
    if motion.length_squared() > 0.001 and not attack_held:
        _turn_actor(hero, motion, delta)
    hero.velocity = motion * SPEED
    hero.move_and_slide()
    _update_combat(delta)
    _update_camera_transform(false, delta)
    _update_goblin(delta)
    _update_room_reveal()
    _update_wall_visibility()
    _animate_wall_windows(delta)

func _update_room_reveal() -> void:
    if not corridor_revealed and bool(doors[0].get("opened")):
        corridor_revealed = true
        corridor_root.call("reveal")
    if not chamber_revealed and corridor_revealed and bool(doors[1].get("opened")):
        chamber_revealed = true
        chamber_root.call("reveal")

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
        _cycle_target()
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
        if is_instance_valid(reward_chest) and reward_chest.is_visible_in_tree() and hero.global_position.distance_to(reward_chest.global_position) <= 2.0:
            if reward_chest.call("interact", hero):
                gold += 25
                combat_log = "Found 25 gold! Total: %d" % gold
                _floating_combat_text(reward_chest.global_position, "+25 GOLD", Color("#ffd36b"))
                return
        var closest: Node3D = null
        var closest_distance := 2.5
        for candidate in doors:
            if not candidate.is_visible_in_tree():
                continue
            var distance := hero.global_position.distance_to(candidate.global_position)
            if distance < closest_distance:
                closest_distance = distance
                closest = candidate
        if closest != null:
            closest.call("interact", hero)

func _place_door(label: String, location: Vector3, width: float, paired: bool) -> void:
    var instance := Node3D.new()
    instance.name = label
    instance.set_script(DUNGEON_DOOR)
    instance.set("opening_width", width)
    instance.set("double_door", paired)
    instance.position = location
    instance.rotation.y = PI * 0.5
    add_child(instance)
    doors.append(instance)

func _make_target_marker() -> void:
    target_marker = MeshInstance3D.new()
    target_marker.name = "TargetIndicator"
    var ring := CylinderMesh.new()
    ring.top_radius = 0.51
    ring.bottom_radius = 0.51
    ring.height = 0.045
    target_marker.mesh = ring
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#e0bd55")
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    target_marker.material_override = mat
    target_marker.visible = false
    add_child(target_marker)

func _eligible_targets() -> Array[CharacterBody3D]:
    var candidates: Array[CharacterBody3D] = []
    var space := get_world_3d().direct_space_state
    for enemy in goblins:
        if not is_instance_valid(enemy) or not enemy.is_visible_in_tree():
            continue
        if int(goblin_health.get(enemy, 0)) <= 0:
            continue
        if hero.global_position.distance_to(enemy.global_position) > ATTACK_RANGE:
            continue
        var query := PhysicsRayQueryParameters3D.create(hero.global_position + Vector3.UP, enemy.global_position + Vector3.UP)
        query.collision_mask = 1
        if not space.intersect_ray(query).is_empty():
            continue
        candidates.append(enemy)
    candidates.sort_custom(func(a: CharacterBody3D, b: CharacterBody3D) -> bool:
        return hero.global_position.distance_squared_to(a.global_position) < hero.global_position.distance_squared_to(b.global_position))
    return candidates

func _cycle_target() -> void:
    var candidates := _eligible_targets()
    if candidates.is_empty():
        target = null
        return
    var index := candidates.find(target)
    target = candidates[(index + 1) % candidates.size()]

func _update_combat(delta: float) -> void:
    var candidates := _eligible_targets()
    if target == null or not candidates.has(target):
        target = candidates[0] if not candidates.is_empty() else null
    target_marker.visible = target != null
    if target != null:
        target_marker.global_position = target.global_position + Vector3(0, 0.05, 0)
    var attacking := Input.is_key_pressed(KEY_SPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_A)
    if not attacking:
        attack_held = false
        attack_timer = 0.0
        return
    if not attack_held:
        attack_held = true
        attack_timer = 0.0
    if target == null:
        return
    var direction := target.global_position - hero.global_position
    direction.y = 0.0
    if direction.length_squared() > 0.001:
        _turn_actor(hero, direction, delta)
    attack_timer -= delta
    if attack_timer > 0.0:
        return
    attack_timer = ATTACK_INTERVAL
    hero.get_node("Animator").call("play_attack")
    _spawn_arrow(target.global_position + Vector3(0, 1.05, 0))
    var roll := randf()
    if roll < 0.15:
        combat_log = "Miss!"
        _floating_combat_text(target.global_position, "MISS", Color("#bfc6c9"))
        return
    var critical := roll > 0.92
    var damage := 15 if critical else 8
    goblin_health[target] = int(goblin_health[target]) - damage
    target.get_node("Animator").call("play_hit")
    combat_log = ("Critical! " if critical else "Hit! ") + str(damage)
    _floating_combat_text(target.global_position, ("CRIT %d!" % damage) if critical else str(damage), Color("#ffca52") if critical else Color("#f5f1dc"))
    if int(goblin_health[target]) <= 0:
        var fallen := target
        goblins.erase(fallen)
        goblin_health.erase(fallen)
        goblin_home.erase(fallen)
        goblin_ai.erase(fallen)
        fallen.queue_free()
        target = null
        target_marker.visible = false
        combat_log = "Goblin defeated"
        # Require button release before firing at a different target.
        attack_timer = INF

func _spawn_arrow(destination: Vector3) -> void:
    # The arrow's local -Z axis is its forward direction.
    var origin := hero.global_position + Vector3(0, 1.25, 0)
    var flight_direction := destination - origin
    if flight_direction.length_squared() < 0.001:
        return
    var arrow := Node3D.new()
    arrow.name = "Arrow"
    add_child(arrow)
    arrow.global_position = origin
    arrow.look_at(destination, Vector3.UP)
    var wood := StandardMaterial3D.new()
    wood.albedo_color = Color("#aa7c45")
    var steel := StandardMaterial3D.new()
    steel.albedo_color = Color("#c0c5c8")
    steel.metallic = 0.55
    var feather := StandardMaterial3D.new()
    feather.albedo_color = Color("#d6d0bb")
    var shaft := MeshInstance3D.new()
    shaft.name = "Shaft"
    var shaft_mesh := CylinderMesh.new()
    shaft_mesh.top_radius = 0.022
    shaft_mesh.bottom_radius = 0.022
    shaft_mesh.height = 0.76
    shaft.mesh = shaft_mesh
    shaft.rotation.x = PI * 0.5
    shaft.material_override = wood
    arrow.add_child(shaft)
    var tip := MeshInstance3D.new()
    tip.name = "Arrowhead"
    var tip_mesh := CylinderMesh.new()
    tip_mesh.top_radius = 0.0
    tip_mesh.bottom_radius = 0.085
    tip_mesh.height = 0.2
    tip.mesh = tip_mesh
    tip.rotation.x = -PI * 0.5
    tip.position.z = -0.47
    tip.material_override = steel
    arrow.add_child(tip)
    for side in [-1.0, 1.0]:
        var vane := MeshInstance3D.new()
        var vane_mesh := BoxMesh.new()
        vane_mesh.size = Vector3(0.12, 0.012, 0.18)
        vane.mesh = vane_mesh
        vane.position = Vector3(side * 0.065, 0, 0.29)
        vane.material_override = feather
        arrow.add_child(vane)
    var flight := create_tween()
    flight.tween_property(arrow, "global_position", destination, 0.19)
    flight.tween_callback(arrow.queue_free)

func _turn_actor(actor: CharacterBody3D, facing: Vector3, delta: float) -> void:
    if facing.length_squared() < 0.0001:
        return
    var desired := atan2(-facing.x, -facing.z)
    actor.rotation.y = rotate_toward(actor.rotation.y, desired, delta * 8.0)

func _goblin_sees_hero(goblin: CharacterBody3D) -> bool:
    if not goblin.is_visible_in_tree() or hero_dead:
        return false
    if goblin.global_position.distance_to(hero.global_position) > GOBLIN_DETECTION:
        return false
    var from := goblin.global_position + Vector3.UP
    var to := hero.global_position + Vector3.UP
    var ray := PhysicsRayQueryParameters3D.create(from, to)
    ray.collision_mask = 1
    return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _update_goblin(delta: float) -> void:
    goblin_state = "Idle"
    goblin_distance = 0.0
    for goblin in goblins:
        if not is_instance_valid(goblin) or not goblin.is_visible_in_tree():
            continue
        var ai: Dictionary = goblin_ai[goblin]
        var displacement := hero.global_position - goblin.global_position
        displacement.y = 0.0
        var distance := displacement.length()
        var home: Vector3 = goblin_home[goblin]
        var sees := _goblin_sees_hero(goblin)
        ai["cooldown"] = maxf(0.0, float(ai["cooldown"]) - delta)
        var health := int(goblin_health.get(goblin, 0))
        var retreating := health <= 10
        var state := "Idle"
        var velocity := Vector3.ZERO
        if float(ai["windup"]) >= 0.0:
            ai["windup"] = float(ai["windup"]) - delta
            state = "Attacking"
            if float(ai["windup"]) < 0.0 and sees and distance <= GOBLIN_STOP + 0.35 and not hero_dead:
                var roll := randf()
                if roll < 0.18:
                    combat_log = "Goblin misses!"
                    _floating_combat_text(hero.global_position, "MISS", Color("#bfc6c9"))
                else:
                    var critical := roll > 0.94
                    var damage := 16 if critical else 9
                    _take_hero_damage(damage)
                    combat_log = ("Goblin critical! " if critical else "Goblin hit! ") + str(damage)
        elif retreating:
            state = "Retreating"
            var away := goblin.global_position - hero.global_position
            away.y = 0.0
            if sees and away.length_squared() > 0.01:
                velocity = away.normalized() * GOBLIN_SPEED
            elif goblin.global_position.distance_to(home) > 0.6:
                velocity = (home - goblin.global_position).normalized() * GOBLIN_SPEED
            else:
                state = "Guarding"
        elif sees:
            ai["last_seen"] = Time.get_ticks_msec() / 1000.0
            if distance > GOBLIN_STOP:
                state = "Chasing"
                velocity = displacement.normalized() * GOBLIN_SPEED
            elif float(ai["cooldown"]) <= 0.0:
                state = "Attacking"
                ai["windup"] = GOBLIN_WINDUP
                ai["cooldown"] = GOBLIN_ATTACK_COOLDOWN
                goblin.get_node("Animator").call("play_attack")
            else:
                state = "In range"
        elif goblin.global_position.distance_to(home) > 0.6:
            state = "Returning"
            velocity = (home - goblin.global_position).normalized() * GOBLIN_SPEED
        goblin.velocity = velocity
        goblin.move_and_slide()
        if velocity.length_squared() > 0.001:
            _turn_actor(goblin, velocity, delta)
        elif state == "Attacking" and displacement.length_squared() > 0.001:
            _turn_actor(goblin, displacement, delta)
        ai["state"] = state
        if goblin == goblins[0]:
            goblin_state = state
            goblin_distance = distance

func _update_wall_visibility() -> void:
    # Fade foreground walls for the hero and for enemies with a clear
    # ground-level line of sight to the hero. Do not reveal enemies
    # concealed by actual dungeon walls.
    var space := get_world_3d().direct_space_state
    var newly_faded: Dictionary = {}
    _collect_camera_occluders(space, hero.global_position + Vector3(0,0.9,0), newly_faded)
    for goblin in goblins:
        if not is_instance_valid(goblin) or not goblin.is_visible_in_tree():
            continue
        var from := hero.global_position + Vector3(0,0.9,0)
        var to := goblin.global_position + Vector3(0,0.9,0)
        var sight := PhysicsRayQueryParameters3D.create(from,to)
        sight.collision_mask = 1
        if space.intersect_ray(sight).is_empty():
            _collect_camera_occluders(space,to,newly_faded)
    wall_windows = newly_faded

func _animate_wall_windows(delta: float) -> void:
    for wall in wall_occluders:
        var visual := wall.get_node_or_null("Visual") as MeshInstance3D
        if visual == null:
            continue
        var shader_material := visual.material_override as ShaderMaterial
        var positions: Array = wall_windows.get(wall, [])
        var strength: float = window_strengths.get(wall, 0.0)
        strength = move_toward(strength, 1.0 if not positions.is_empty() else 0.0, delta * WINDOW_FADE_SPEED)
        window_strengths[wall] = strength
        shader_material.set_shader_parameter("fade_strength", strength)
        if not positions.is_empty():
            var holes := PackedVector4Array()
            for i in range(4):
                holes.append(positions[i] if i < positions.size() else Vector4(-10.0, -10.0, 0.0, 0.0))
            shader_material.set_shader_parameter("holes", holes)
            shader_material.set_shader_parameter("hole_count", mini(positions.size(), 4))
        elif strength <= 0.001:
            shader_material.set_shader_parameter("hole_count", 0)

func _collect_camera_occluders(space: PhysicsDirectSpaceState3D, target: Vector3, result: Dictionary) -> void:
    var origin := camera.global_position
    var excluded: Array[RID] = []
    for i in range(12):
        var query := PhysicsRayQueryParameters3D.create(origin,target)
        query.collision_mask = 1
        query.exclude = excluded
        var hit := space.intersect_ray(query)
        if hit.is_empty():
            break
        var wall := hit["collider"] as StaticBody3D
        if wall == null or not wall_occluders.has(wall):
            break
        if not result.has(wall):
            result[wall] = []
        var uv := camera.unproject_position(target) / get_viewport().get_visible_rect().size
        var positions: Array = result[wall]
        if positions.size() < 4:
            positions.append(Vector4(uv.x, uv.y, 1.35 / camera.size, 0.0))
        excluded.append(wall.get_rid())

func _update_camera_transform(immediate: bool, delta: float = 0.0) -> void:
    var yaw := deg_to_rad(camera_yaw)
    var elevation := deg_to_rad(camera_elevation)
    var horizontal := cos(elevation) * camera_distance
    var offset := Vector3(sin(yaw) * horizontal, sin(elevation) * camera_distance, cos(yaw) * horizontal)
    var focus := hero.global_position + Vector3(0,camera_framing,0)
    var desired := focus + offset
    camera.global_position = desired if immediate else camera.global_position.lerp(desired, minf(1.0, delta * 7.0))
    camera.look_at(camera.global_position - offset, Vector3.UP)

func _make_box(label: String, location: Vector3, size: Vector3, tint: Color, solid: bool = true) -> void:
    var body := StaticBody3D.new()
    body.name = label
    body.position = location
    add_child(body)
    var mesh := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    mesh.mesh = shape
    if solid:
        var shader := Shader.new()
        shader.code = """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
uniform vec4 stone_color : source_color = vec4(0.47, 0.48, 0.44, 1.0);
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
        float distance_to_target = length(delta);
        reveal = max(reveal, 1.0 - smoothstep(holes[i].z * 0.55, holes[i].z, distance_to_target));
    }
    ALPHA = 1.0 - 0.94 * reveal * fade_strength;
}
"""
        var wall_material := ShaderMaterial.new()
        wall_material.shader = shader
        wall_material.set_shader_parameter("stone_color", tint)
        wall_material.set_shader_parameter("aspect_ratio", get_viewport().get_visible_rect().size.aspect())
        mesh.material_override = wall_material
    else:
        var material := StandardMaterial3D.new()
        material.albedo_color = tint
        material.roughness = 1.0
        mesh.material_override = material
    mesh.name = "Visual"
    body.add_child(mesh)
    if solid:
        wall_occluders.append(body)
        var edge := MeshInstance3D.new()
        edge.name = "StoneEdge"
        var cap := BoxMesh.new()
        cap.size = Vector3(size.x + 0.06, 0.09, size.z + 0.06)
        edge.mesh = cap
        edge.position.y = size.y * 0.5 + 0.045
        var edge_material := StandardMaterial3D.new()
        edge_material.albedo_color = Color("#a4a59b")
        edge_material.roughness = 1.0
        edge.material_override = edge_material
        body.add_child(edge)
        var collider := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        collider.shape = box
        body.add_child(collider)

func _make_actor(label: String, location: Vector3, tint: Color) -> CharacterBody3D:
    var actor := CharacterBody3D.new()
    actor.name = label
    actor.position = location
    actor.collision_layer = 2
    actor.collision_mask = 3
    add_child(actor)
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    collider.shape = capsule
    collider.position.y = 0.9
    actor.add_child(collider)
    var body := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.35
    capsule_mesh.height = 1.8
    body.mesh = capsule_mesh
    body.position.y = 0.9
    body.name = "Visual"
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    body.material_override = material
    actor.add_child(body)
    return actor
