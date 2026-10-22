extends SceneTree
## Run: godot --headless --path . --script res://tests/dual_weapon_test.gd
const PLAYER = preload("res://scenes/player.tscn")
const GOBLIN = preload("res://scripts/goblin.gd")
const RESOLVER = preload("res://scripts/combat_resolver.gd")
var failures := 0

func check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        push_error(message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var arena := Node2D.new()
    root.add_child(arena)
    var hero := PLAYER.instantiate()
    arena.add_child(hero)
    hero.set_physics_process(false)
    hero.facing_direction = Vector2.RIGHT
    check(hero.weapon_mode == "bow", "Bow is equipped by default")
    hero.toggle_weapon()
    check(hero.weapon_mode == "sword", "Toggle equips sword")
    var front := GOBLIN.new()
    arena.add_child(front)
    front.position = Vector2(35, 0)
    front.set_physics_process(false)
    var rear := GOBLIN.new()
    arena.add_child(rear)
    rear.position = Vector2(-35, 0)
    rear.set_physics_process(false)
    var side := GOBLIN.new()
    arena.add_child(side)
    side.position = Vector2(40, 12)
    side.set_physics_process(false)
    seed(100)
    for i in range(20):
        hero._swing_sword()
    check(front.health < 10 and side.health < 10, "Sword hits multiple enemies in its arc")
    check(rear.health == 10, "Sword does not hit behind player")
    hero.toggle_weapon()
    check(hero.weapon_mode == "bow", "Second toggle restores bow")
    var resistant := RESOLVER.resolve(3, "slashing", {"slashing": 0.0})
    check(resistant.damage == 0 or resistant.result == "MISS", "Full resistance prevents damage")
    var hit := RESOLVER.resolve(3, "blunt", {"blunt": 2.0})
    check(hit.damage in [0, 6, 11], "Damage type multiplier is applied")
    arena.free()
    print("Dual Weapon V1: %d failures" % failures)
    quit(1 if failures else 0)
