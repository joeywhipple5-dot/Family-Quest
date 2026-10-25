extends CharacterBody3D

var enemy_name: String = "Forest Slime"
var is_boss: bool = false
var hp: int = 40
var max_hp: int = 40
var player: CharacterBody3D
var speed: float = 2.0
var attack_timer: float = 0.0
var dead: bool = false

func _ready() -> void:
    if is_boss:
        max_hp = 600
        speed = 1.5
    elif enemy_name == "Woodland Goblin":
        max_hp = 75
        speed = 2.5
    elif enemy_name == "Thornwolf":
        max_hp = 120
        speed = 3.5
    else:
        max_hp = 40
        speed = 2.0

    hp = max_hp
    _create_enemy_model()
    _create_collision()

func _create_enemy_model() -> void:
    var mesh_instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()

    if is_boss:
        mesh.radius = 1.5
        mesh.height = 3.0
    elif enemy_name == "Thornwolf":
        mesh.radius = 0.9
        mesh.height = 1.8
    elif enemy_name == "Woodland Goblin":
        mesh.radius = 0.65
        mesh.height = 1.3
    else:
        mesh.radius = 0.8
        mesh.height = 1.6

    mesh_instance.mesh = mesh

    var material := StandardMaterial3D.new()

    if is_boss:
        material.albedo_color = Color(0.25, 0.35, 0.18)
    elif enemy_name == "Woodland Goblin":
        material.albedo_color = Color(0.55, 0.35, 0.18)
    elif enemy_name == "Thornwolf":
        material.albedo_color = Color(0.35, 0.25, 0.20)
    else:
        material.albedo_color = Color(0.22, 0.65, 0.28)

    mesh_instance.material_override = material
    add_child(mesh_instance)

func _create_collision() -> void:
    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()

    if is_boss:
        shape.radius = 1.5
    elif enemy_name == "Thornwolf":
        shape.radius = 0.9
    elif enemy_name == "Woodland Goblin":
        shape.radius = 0.65
    else:
        shape.radius = 0.8

    collision.shape = shape
    add_child(collision)

func _physics_process(delta: float) -> void:
    if dead:
        return

    if not is_instance_valid(player):
        velocity.x = 0.0
        velocity.z = 0.0
        return

    attack_timer = maxf(0.0, attack_timer - delta)

    var difference: Vector3 = player.global_position - global_position
    var distance: float = difference.length()
    var attack_range: float = 2.5 if is_boss else 1.8

    if distance > attack_range and distance < 10.0:
        var direction: Vector3 = difference.normalized()

        velocity.x = direction.x * speed
        velocity.z = direction.z * speed

        move_and_slide()
    else:
        velocity.x = 0.0
        velocity.z = 0.0

        if distance <= attack_range and attack_timer <= 0.0:
            _attack_player()

func _attack_player() -> void:
    if dead or not is_instance_valid(player):
        return

    if not player.has_method("take_damage"):
        if not "hp" in player:
            return

    var damage: int = 12 if is_boss else 5

    if player.has_method("take_damage"):
        player.take_damage(damage)
    elif "hp" in player:
        player.hp = maxi(0, player.hp - damage)

        if player.hp <= 0 and "dead" in player:
            player.dead = true

    attack_timer = 2.0

    var main := get_tree().current_scene

    if is_instance_valid(main):
        if main.has_method("_refresh"):
            main._refresh()

        if main.has_method("_message"):
            main._message(
                "%s attacks! Hero HP: %d"
                % [enemy_name, player.get("hp")]
            )

func take_hit(damage: int) -> void:
    if dead or damage <= 0:
        return

    hp = maxi(0, hp - damage)

    var main := get_tree().current_scene

    if is_instance_valid(main) and main.has_method("_message"):
        main._message(
            "%s takes %d damage! (%d/%d HP)"
            % [enemy_name, damage, hp, max_hp]
        )

    if hp <= 0:
        _die()

func _die() -> void:
    if dead:
        return

    dead = true
    hp = 0
    velocity = Vector3.ZERO

    var main := get_tree().current_scene

    if is_instance_valid(main) and main.has_method("enemy_defeated"):
        main.enemy_defeated(self)

    queue_free()
