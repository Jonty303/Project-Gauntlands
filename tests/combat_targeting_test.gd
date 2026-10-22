extends SceneTree
## Run: godot --headless --path . --script res://tests/combat_targeting_test.gd

const PLAYER = preload("res://scenes/player.tscn")
const GOBLIN = preload("res://scripts/goblin.gd")
const RESOLVER = preload("res://scripts/combat_resolver.gd")
var arena: Node2D
var player: CharacterBody2D
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(condition: bool, description: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error(description)

func enemy(at: Vector2) -> Node2D:
    var goblin := GOBLIN.new()
    arena.add_child(goblin)
    goblin.position = at
    goblin.set_physics_process(false)
    return goblin

func tick() -> void:
    player._physics_process(1.0 / 60.0)

func arrows() -> Array[Node]:
    return arena.get_children().filter(func(node: Node) -> bool:
        return node.get_script() == preload("res://scripts/arrow.gd"))

func _run() -> void:
    arena = Node2D.new()
    root.add_child(arena)
    player = PLAYER.instantiate()
    arena.add_child(player)
    player.set_physics_process(false)
    player.facing_direction = Vector2.RIGHT
    var front := enemy(Vector2(200, 0))
    var behind := enemy(Vector2(-50, 0))
    var flank := enemy(Vector2(0, 100))
    tick()
    check(player.soft_target == front, "Forward arc wins over nearer enemy behind")
    player.soft_target = null
    front.position = Vector2(451, 0)
    tick()
    check(player.soft_target == behind, "Nearest elsewhere is selected, including behind")
    behind.position = Vector2(-451, 0)
    tick()
    check(player.soft_target == flank, "Out-of-range next selection is replaced")
    front.position = Vector2(200, 0)
    tick()
    check(player.soft_target == flank, "Valid selection persists when another enemy enters forward arc")

    player.soft_target = front
    player.touch_attack = true
    tick()
    check(player.target == front and player.attacking, "Press commits to next enemy")
    check(arrows().size() == 1, "Initial press fires an arrow")
    player._cycle_target(1)
    check(player.soft_target == flank and player.target == front, "Cycle during hold changes only next")
    player.fire_cooldown = 0.0
    tick()
    check(player.soft_target == flank and player.target == front, "Manual selection persists during hold")
    check(arrows()[-1].direction.is_equal_approx(Vector2.RIGHT), "Held fire still aims at original enemy")
    player._cycle_target(-1)
    check(player.soft_target == front and player.target == front, "Previous cycle returns to original without changing active")
    player._cycle_target(-1)
    check(player.soft_target == flank, "Previous cycle wraps around")
    front.position = Vector2(500, 0)
    tick()
    check(player.attacking and player.target == front, "Active enemy leaving range does not cancel commitment")
    front.alive = false
    front.remove_from_group("enemies")
    var before_death := arrows().size()
    tick()
    check(not player.attacking and player.attack_exhausted and player.target == null, "Active death exhausts hold")
    check(player.soft_target == flank, "Active death preserves different manual next selection")
    for i in range(40):
        tick()
    check(arrows().size() == before_death, "Held input never transfers fire after death")
    front.alive = true
    front.add_to_group("enemies")
    tick()
    check(not player.attacking, "Respawn cannot restart an exhausted hold")
    player.touch_attack = false
    tick()
    player.touch_attack = true
    tick()
    check(player.target == flank and player.attacking, "Release/repress attacks selected next enemy")

    behind.position = Vector2(-100, 0)
    player.soft_target = behind
    behind.remove_from_group("enemies")
    tick()
    check(player.soft_target == flank and player.target == flank, "Next death replaces selection without changing active")
    flank.remove_from_group("enemies")
    front.position = Vector2(-200, 0)
    tick()
    check(player.soft_target == front and player.attack_exhausted, "Shared active/next death selects enemy behind without firing")
    player.touch_attack = false
    tick()
    player.touch_attack = true
    tick()
    check(player.target == front, "Repress commits to replacement behind")
    front.free()
    tick()
    check(player.target == null and player.soft_target == null and player.attack_exhausted, "Freed enemy is handled safely")

    player.touch_attack = false
    tick()
    player.touch_attack = true
    tick()
    check(player.attacking and player.target == null, "No-target press preserves directional firing")
    var newcomer := enemy(Vector2(100, 0))
    tick()
    check(player.soft_target == newcomer and player.target == null, "Enemy entering range becomes next without transferring free fire")
    player.touch_attack = false
    tick()
    player.touch_attack = true
    tick()
    check(player.target == newcomer, "Repress after free fire uses new next target")
    newcomer.position = Vector2(450, 0)
    check(player._is_enemy_available(newcomer), "Range includes exactly 450 units")
    newcomer.position.x = 450.01
    tick()
    check(player.soft_target == null and player.target == newcomer, "Next range is strict while active remains committed")
    newcomer.position = Vector2.ZERO
    tick()
    check(player.soft_target == newcomer, "Overlapping living enemy remains selectable")

    player.touch_attack = false
    player.set_touch_direction(Vector2.LEFT)
    var old_position := player.position
    var old_gait: float = player.gait_phase
    tick()
    check(player.position.x < old_position.x and player.gait_phase > old_gait, "Movement and gait animation continue")
    player.set_touch_direction(Vector2.ZERO)
    newcomer.queue_free()
    tick()
    check(player.soft_target == null, "Queued deletion cannot remain next target")
    await process_frame

    # Real projectile contact still invokes RPG resolution (including misses).
    var victim := enemy(Vector2(100, 0))
    var outcomes := {}
    var valid_damage := true
    seed(12345)
    for i in range(1000):
        var result: Dictionary = RESOLVER.resolve()
        outcomes[result.result] = true
        valid_damage = valid_damage and result.damage in [0, 2, 4]
    check(valid_damage, "All 1000 RPG rolls retain miss/hit/crit damage")
    check(outcomes.has("MISS") and outcomes.has("HIT") and outcomes.has("CRIT!"), "RPG resolver retains all three outcomes")
    var projectile := Node2D.new()
    projectile.set_script(preload("res://scripts/arrow.gd"))
    arena.add_child(projectile)
    projectile.position = Vector2(70, 0)
    projectile.direction = Vector2.RIGHT
    projectile._physics_process(0.1)
    check(projectile.is_queued_for_deletion() and victim.combat_text != "", "Swept projectile contact invokes goblin hit resolution")

    arena.free()
    var main := preload("res://scenes/main.tscn").instantiate()
    root.add_child(main)
    check(get_nodes_in_group("enemies").size() == 4, "Main scene provides four living test goblins")
    check(InputMap.action_get_events("target_previous")[1].button_index == JOY_BUTTON_LEFT_SHOULDER, "Left shoulder binding retained")
    check(InputMap.action_get_events("target_next")[1].button_index == JOY_BUTTON_RIGHT_SHOULDER, "Right shoulder binding retained")
    main.free()
    print("Combat Targeting V2: %d checks, %d failures" % [checks, failures])
    quit(1 if failures else 0)
