
extends CharacterBody3D

# --------------------------------------------------
# FAMILY QUEST - ENEMY
# Godot 4.3
# Enemy AI, combat, and floating health bar
# --------------------------------------------------

@export var enemy_name: String = "Forest Slime"
@export var is_boss: bool = false

@export_group("Combat")
@export var max_hp: int = 40
@export var speed: float = 2.0
@export var attack_damage: int = 5
@export var attack_range: float = 1.8
@export var detection_range: float = 10.0
@export var attack_interval: float = 2.0

var hp: int = 40
var player: CharacterBody3D
var attack_timer: float = 0.0
var dead: bool = false

var health_bar_root: Node3D
var health_bar_fill: MeshInstance3D
var health_bar_background: MeshInstance3D
var health_bar_label: Label3D


func _ready() -> void:
    add_to_group("enemies")

    _configure_enemy()
    hp = max_hp

    _create_enemy_model()
    _create_collision()
    _create_health_bar()

    _find_player()
    _update_health_bar()


# --------------------------------------------------
# ENEMY TYPES
# --------------------------------------------------

func _configure_enemy() -> void:
    if is_boss:
        max_hp = 600
        speed = 1.5
        attack_damage = 12
        attack_range = 2.5
        detection_range = 14.0
        attack_interval = 2.0
    elif enemy_name == "Woodland Goblin":
        max_hp = 75
        speed = 2.5
        attack_damage = 7
        attack_range = 1.8
        detection_range = 10.0
        attack_interval = 1.8
    elif enemy_name == "Thornwolf":
        max_hp = 120
        speed = 3.5
        attack_damage = 9
        attack_range = 1.8
        detection_range = 12.0
        attack_interval = 1.6
    else:
        max_hp = 40
        speed = 2.0
        attack_damage = 5
        attack_range = 1.8
        detection_range = 10.0
        attack_interval = 2.0

    max_hp = maxi(1, max_hp)


func _find_player() -> void:
    var found_player := get_tree().get_first_node_in_group("player")

    if found_player is CharacterBody3D:
        player = found_player as CharacterBody3D


# --------------------------------------------------
# MODEL
# --------------------------------------------------

func _create_enemy_model() -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "EnemyModel"

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
    mesh_instance.position.y = mesh.height * 0.5

    var material := StandardMaterial3D.new()

    if is_boss:
        material.albedo_color = Color(0.25, 0.35, 0.18)
    elif enemy_name == "Woodland Goblin":
        material.albedo_color = Color(0.55, 0.35, 0.18)
    elif enemy_name == "Thornwolf":
        material.albedo_color = Color(0.35, 0.25, 0.20)
    else:
        material.albedo_color = Color(0.22, 0.65, 0.28)

    material.roughness = 0.8
    mesh_instance.material_override = material

    add_child(mesh_instance)


func _create_collision() -> void:
    var collision := CollisionShape3D.new()
    collision.name = "EnemyCollision"

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
    collision.position.y = shape.radius

    add_child(collision)


# --------------------------------------------------
# FLOATING HEALTH BAR
# --------------------------------------------------

func _create_health_bar() -> void:
    health_bar_root = Node3D.new()
    health_bar_root.name = "FloatingHealthBar"

    var enemy_height := 2.0

    if is_boss:
        enemy_height = 4.0
    elif enemy_name == "Thornwolf":
        enemy_height = 2.5
    elif enemy_name == "Woodland Goblin":
        enemy_height = 2.0

    health_bar_root.position = Vector3(0.0, enemy_height, 0.0)
    add_child(health_bar_root)

    var bar_width := 1.4
    var bar_height := 0.14

    if is_boss:
        bar_width = 2.4
        bar_height = 0.22

    health_bar_background = MeshInstance3D.new()
    health_bar_background.name = "HealthBarBackground"

    var background_mesh := QuadMesh.new()
    background_mesh.size = Vector2(bar_width, bar_height)
    health_bar_background.mesh = background_mesh

    var background_material := StandardMaterial3D.new()
    background_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    background_material.albedo_color = Color(0.12, 0.08, 0.08, 0.95)
    background_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    health_bar_background.material_override = background_material

    health_bar_root.add_child(health_bar_background)

    health_bar_fill = MeshInstance3D.new()
    health_bar_fill.name = "HealthBarFill"

    var fill_mesh := QuadMesh.new()
    fill_mesh.size = Vector2(bar_width, bar_height)
    health_bar_fill.mesh = fill_mesh

    var fill_material := StandardMaterial3D.new()
    fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    fill_material.albedo_color = Color(0.15, 0.85, 0.25)
    health_bar_fill.material_override = fill_material

    health_bar_fill.position.z = -0.01
    health_bar_root.add_child(health_bar_fill)

    health_bar_label = Label3D.new()
    health_bar_label.name = "EnemyHealthText"
    health_bar_label.text = enemy_name
    health_bar_label.font_size = 32
    health_bar_label.pixel_size = 0.004
    health_bar_label.position.y = 0.24
    health_bar_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    health_bar_label.no_depth_test = true

    health_bar_root.add_child(health_bar_label)


func _update_health_bar() -> void:
    if not is_instance_valid(health_bar_fill):
        return

    var fraction := 0.0

    if max_hp > 0:
        fraction = clampf(float(hp) / float(max_hp), 0.0, 1.0)

    var bar_width := 1.4

    if is_boss:
        bar_width = 2.4

    var fill_mesh := health_bar_fill.mesh as QuadMesh

    if is_instance_valid(fill_mesh):
        fill_mesh.size.x = maxf(0.01, bar_width * fraction)

    health_bar_fill.position.x = -bar_width * (1.0 - fraction) * 0.5

    var material := health_bar_fill.material_override as StandardMaterial3D

    if is_instance_valid(material):
        if fraction > 0.5:
            material.albedo_color = Color(0.15, 0.85, 0.25)
        elif fraction > 0.25:
            material.albedo_color = Color(0.95, 0.7, 0.12)
        else:
            material.albedo_color = Color(0.95, 0.15, 0.12)

    if is_instance_valid(health_bar_label):
        health_bar_label.text = "%s  %d/%d" % [
            enemy_name,
            hp,
            max_hp
        ]


# --------------------------------------------------
# ENEMY AI
# --------------------------------------------------

func _physics_process(delta: float) -> void:
    if dead:
        return

    attack_timer = maxf(0.0, attack_timer - delta)

    if not is_instance_valid(player):
        _find_player()

        if not is_instance_valid(player):
            velocity.x = move_toward(velocity.x, 0.0, speed * delta)
            velocity.z = move_toward(velocity.z, 0.0, speed * delta)
            _apply_gravity(delta)
            move_and_slide()
            return

    if not is_instance_valid(player) or player.get("dead") == true:
        velocity.x = move_toward(velocity.x, 0.0, speed * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    var difference: Vector3 = player.global_position - global_position
    difference.y = 0.0

    var distance := difference.length()

    if distance > attack_range and distance < detection_range:
        var direction := difference.normalized()

        velocity.x = direction.x * speed
        velocity.z = direction.z * speed

        if direction.length_squared() > 0.01:
            rotation.y = atan2(-direction.x, -direction.z)
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * 4.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 4.0 * delta)

        if distance <= attack_range and attack_timer <= 0.0:
            _attack_player()

    _apply_gravity(delta)
    move_and_slide()


func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 20.0 * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0


func _attack_player() -> void:
    if dead or not is_instance_valid(player):
        return

    if player.has_method("take_damage"):
        player.call("take_damage", attack_damage)

    attack_timer = attack_interval

    var main := get_tree().current_scene

    if is_instance_valid(main) and main.has_method("_message"):
        main.call(
            "_message",
            "%s attacks for %d damage!" % [
                enemy_name,
                attack_damage
            ]
        )


# --------------------------------------------------
# DAMAGE AND DEATH
# --------------------------------------------------

func take_hit(damage: int) -> void:
    if dead or damage <= 0:
        return

    hp = maxi(0, hp - damage)
    _update_health_bar()

    var main := get_tree().current_scene

    if is_instance_valid(main) and main.has_method("_message"):
        main.call(
            "_message",
            "%s takes %d damage! (%d/%d HP)" % [
                enemy_name,
                damage,
                hp,
                max_hp
            ]
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
        main.call("enemy_defeated", self)

    queue_free()
