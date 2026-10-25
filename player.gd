
extends CharacterBody3D

signal health_changed(current_hp: int, maximum_hp: int)
signal player_died
signal player_revived

# --------------------------------------------------
# FAMILY QUEST - PLAYER
# Godot 4.3
# Fixed bottom-left mobile joystick
# --------------------------------------------------

@export_group("Movement")
@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var gravity: float = 20.0
@export var joystick_radius: float = 65.0

@export_group("Health")
@export var max_health: int = 100
@export var starting_health: int = 100

@export_group("Combat")
@export var attack_damage: int = 20
@export var attack_cooldown: float = 0.5

var current_health: int = 100
var dead: bool = false
var hero_class: String = "Warrior"
var hero_gender: String = "Male"

var attack_timer: float = 0.0
var movement_input: Vector2 = Vector2.ZERO

# Joystick state
var joystick_active: bool = false
var joystick_touch_index: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_vector: Vector2 = Vector2.ZERO

# Nodes
var player_model: MeshInstance3D
var collision_shape: CollisionShape3D

var joystick_base: Panel
var joystick_knob: Panel
var joystick_layer: CanvasLayer


func _ready() -> void:
    add_to_group("player")

    max_health = maxi(1, max_health)
    current_health = clampi(starting_health, 0, max_health)

    _create_player_model()
    _create_collision()
    _create_joystick()

    health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
    if dead:
        velocity = Vector3.ZERO
        return

    attack_timer = maxf(0.0, attack_timer - delta)

    _update_movement(delta)

    move_and_slide()


# --------------------------------------------------
# PLAYER MODEL
# --------------------------------------------------

func _create_player_model() -> void:
    if is_instance_valid(player_model):
        player_model.queue_free()

    player_model = MeshInstance3D.new()
    player_model.name = "PlayerModel"

    var capsule := CapsuleMesh.new()
    capsule.radius = 0.4
    capsule.height = 1.8

    player_model.mesh = capsule
    player_model.position = Vector3(0.0, 0.9, 0.0)

    var material := StandardMaterial3D.new()
    material.albedo_color = _get_class_color()
    material.roughness = 0.8

    player_model.material_override = material
    add_child(player_model)


func _get_class_color() -> Color:
    match hero_class:
        "Warrior":
            return Color(0.65, 0.20, 0.16)
        "Mage":
            return Color(0.30, 0.25, 0.75)
        "Rogue":
            return Color(0.20, 0.22, 0.25)
        "Druid":
            return Color(0.20, 0.55, 0.25)
        "Ranger":
            return Color(0.65, 0.48, 0.20)
        _:
            return Color(0.65, 0.20, 0.16)


func set_hero_class(new_class: String) -> void:
    var valid_classes := [
        "Warrior",
        "Mage",
        "Rogue",
        "Druid",
        "Ranger"
    ]

    if new_class not in valid_classes:
        return

    hero_class = new_class

    if is_instance_valid(player_model):
        var material := StandardMaterial3D.new()
        material.albedo_color = _get_class_color()
        material.roughness = 0.8
        player_model.material_override = material


func set_hero_gender(new_gender: String) -> void:
    if new_gender == "Male" or new_gender == "Female":
        hero_gender = new_gender


# --------------------------------------------------
# COLLISION
# --------------------------------------------------

func _create_collision() -> void:
    collision_shape = CollisionShape3D.new()
    collision_shape.name = "PlayerCollision"

    var shape := CapsuleShape3D.new()
    shape.radius = 0.4
    shape.height = 1.8

    collision_shape.shape = shape
    collision_shape.position = Vector3(0.0, 0.9, 0.0)

    add_child(collision_shape)


# --------------------------------------------------
# FIXED MOBILE JOYSTICK
# Always visible at bottom-left.
# The base stays still; only the knob moves.
# --------------------------------------------------

func _create_joystick() -> void:
    joystick_layer = CanvasLayer.new()
    joystick_layer.name = "PlayerJoystickLayer"
    add_child(joystick_layer)

    joystick_base = Panel.new()
    joystick_base.name = "JoystickBase"
    joystick_base.size = Vector2(140.0, 140.0)
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(0.08, 0.10, 0.12, 0.62)
    base_style.border_color = Color(0.75, 0.72, 0.58, 0.9)
    base_style.set_border_width_all(3)
    base_style.set_corner_radius_all(70)

    joystick_base.add_theme_stylebox_override(
        "panel",
        base_style
    )

    joystick_layer.add_child(joystick_base)

    joystick_knob = Panel.new()
    joystick_knob.name = "JoystickKnob"
    joystick_knob.size = Vector2(64.0, 64.0)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var knob_style := StyleBoxFlat.new()
    knob_style.bg_color = Color(0.72, 0.68, 0.52, 0.92)
    knob_style.border_color = Color(0.95, 0.88, 0.67, 1.0)
    knob_style.set_border_width_all(2)
    knob_style.set_corner_radius_all(32)

    joystick_knob.add_theme_stylebox_override(
        "panel",
        knob_style
    )

    joystick_layer.add_child(joystick_knob)

    _position_joystick()


func _position_joystick() -> void:
    if not is_instance_valid(joystick_base):
        return

    var screen_size := get_viewport().get_visible_rect().size

    # Fixed bottom-left placement.
    joystick_base.position = Vector2(
        28.0,
        screen_size.y - 168.0
    )

    if not joystick_active:
        _center_joystick_knob()


func _center_joystick_knob() -> void:
    if not is_instance_valid(joystick_base):
        return

    if not is_instance_valid(joystick_knob):
        return

    joystick_knob.position = (
        joystick_base.position
        + (joystick_base.size - joystick_knob.size) * 0.5
    )


func _input(event: InputEvent) -> void:
    if dead:
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            _try_start_joystick(event.position, event.index)
        elif event.index == joystick_touch_index:
            _stop_joystick()

    elif event is InputEventScreenDrag:
        if joystick_active and event.index == joystick_touch_index:
            _update_joystick(event.position)

    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SPACE:
            perform_attack()
        elif event.keycode == KEY_SHIFT:
            dodge()


func _try_start_joystick(
    touch_position: Vector2,
    touch_index: int
) -> void:
    if joystick_active:
        return

    if not is_instance_valid(joystick_base):
        return

    var base_rect := Rect2(
        joystick_base.position,
        joystick_base.size
    )

    # Only touches beginning on the joystick activate it.
    if not base_rect.has_point(touch_position):
        return

    joystick_active = true
    joystick_touch_index = touch_index
    joystick_origin = joystick_base.position + joystick_base.size * 0.5

    _update_joystick(touch_position)


func _update_joystick(touch_position: Vector2) -> void:
    if not joystick_active:
        return

    var offset := touch_position - joystick_origin

    if offset.length() > joystick_radius:
        offset = offset.normalized() * joystick_radius

    joystick_vector = offset / joystick_radius

    if is_instance_valid(joystick_knob):
        joystick_knob.position = (
            joystick_origin
            + offset
            - joystick_knob.size * 0.5
        )


func _stop_joystick() -> void:
    joystick_active = false
    joystick_touch_index = -1
    joystick_vector = Vector2.ZERO

    _center_joystick_knob()


# --------------------------------------------------
# MOVEMENT
# Joystick and keyboard both work.
# Movement is relative to the game world's axes.
# --------------------------------------------------

func _update_movement(delta: float) -> void:
    var input_vector := joystick_vector

    # Keyboard fallback for testing in the editor.
    if not joystick_active:
        input_vector = Input.get_vector(
            "ui_left",
            "ui_right",
            "ui_up",
            "ui_down"
        )

    movement_input = input_vector

    var direction := Vector3(
        input_vector.x,
        0.0,
        input_vector.y
    )

    if direction.length_squared() > 1.0:
        direction = direction.normalized()

    var target_x := direction.x * move_speed
    var target_z := direction.z * move_speed

    velocity.x = move_toward(
        velocity.x,
        target_x,
        acceleration * delta
    )

    velocity.z = move_toward(
        velocity.z,
        target_z,
        acceleration * delta
    )

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    # Face the direction of travel.
    if direction.length_squared() > 0.01:
        rotation.y = atan2(-direction.x, -direction.z)


# --------------------------------------------------
# HEALTH
# --------------------------------------------------

func take_damage(amount: int) -> void:
    if dead or amount <= 0:
        return

    current_health = maxi(0, current_health - amount)
    health_changed.emit(current_health, max_health)

    if current_health <= 0:
        _die()


func heal(amount: int) -> void:
    if dead or amount <= 0:
        return

    current_health = mini(
        max_health,
        current_health + amount
    )

    health_changed.emit(current_health, max_health)


func set_max_health(new_maximum: int) -> void:
    max_health = maxi(1, new_maximum)
    current_health = clampi(current_health, 0, max_health)

    health_changed.emit(current_health, max_health)


func _die() -> void:
    if dead:
        return

    dead = true
    current_health = 0
    velocity = Vector3.ZERO

    _stop_joystick()
    player_died.emit()


func revive(spawn_position: Vector3 = Vector3.ZERO) -> void:
    global_position = spawn_position
    velocity = Vector3.ZERO
    current_health = max_health
    dead = false

    health_changed.emit(current_health, max_health)
    player_revived.emit()


# Compatibility alias for scripts using respawn().
func respawn(spawn_position: Vector3 = Vector3.ZERO) -> void:
    revive(spawn_position)


# --------------------------------------------------
# ATTACK
# Main.gd will handle selecting and damaging enemies.
# --------------------------------------------------

func perform_attack() -> void:
    if dead or attack_timer > 0.0:
        return

    attack_timer = attack_cooldown

    var main := get_tree().current_scene

    if is_instance_valid(main) and main.has_method("_attack"):
        main.call("_attack")


func use_ability() -> void:
    if dead:
        return

    # Ability behavior will be connected to the class
    # system when the combat scripts are matched.


func dodge() -> void:
    if dead:
        return

    var dodge_direction := Vector3(
        movement_input.x,
        0.0,
        movement_input.y
    )

    if dodge_direction.length_squared() < 0.01:
        dodge_direction = Vector3(
            -sin(rotation.y),
            0.0,
            -cos(rotation.y)
        )

    dodge_direction = dodge_direction.normalized()

    velocity.x = dodge_direction.x * move_speed * 2.0
    velocity.z = dodge_direction.z * move_speed * 2.0


# --------------------------------------------------
# RESIZE SUPPORT
# --------------------------------------------------

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        if is_instance_valid(joystick_base):
            _position_joystick()
