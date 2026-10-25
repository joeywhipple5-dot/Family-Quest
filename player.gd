
extends CharacterBody3D

# ============================================================
# FAMILY QUEST - PLAYER
# Godot 4.3 | Android | Landscape
# ============================================================

signal health_changed(current_hp: int, maximum_hp: int)
signal player_died
signal player_respawned
signal attack_requested
signal ability_requested(ability_name: String)

@export_group("Movement")
@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var deceleration: float = 22.0
@export var rotation_speed: float = 12.0
@export var gravity: float = 18.0
@export var camera_relative_movement: bool = true

@export_group("Health")
@export var max_health: int = 100
@export var starting_health: int = 100
@export var respawn_delay: float = 3.0

@export_group("Touch Controls")
@export var joystick_radius: float = 65.0
@export var joystick_deadzone: float = 0.12
@export var show_touch_controls: bool = true

@export_group("Combat")
@export var attack_cooldown: float = 0.5
@export var ability_cooldown: float = 3.0

var current_health: int = 100
var is_dead: bool = false
var is_attacking: bool = false

var _move_input: Vector2 = Vector2.ZERO
var _attack_timer: float = 0.0
var _ability_timer: float = 0.0

var _joystick_touch_id: int = -1
var _joystick_origin: Vector2 = Vector2.ZERO
var _joystick_vector: Vector2 = Vector2.ZERO

var _joystick_base: Control
var _joystick_knob: Control
var _health_bar: ProgressBar
var _health_text: Label
var _attack_button: Button
var _heal_button: Button
var _ability_button: Button
var _dodge_button: Button
var _hud_layer: CanvasLayer

var _respawn_position: Vector3
var _respawn_rotation: Vector3

func _ready() -> void:
    max_health = maxi(1, max_health)
    current_health = clampi(starting_health, 0, max_health)

    _respawn_position = global_position
    _respawn_rotation = rotation

    add_to_group("player")

    if show_touch_controls:
        _create_mobile_hud()

    _update_health_display()
    health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
    if is_dead:
        velocity = Vector3.ZERO
        return

    _attack_timer = maxf(0.0, _attack_timer - delta)
    _ability_timer = maxf(0.0, _ability_timer - delta)

    _read_movement_input()
    _move_player(delta)
    _update_joystick_visual()


# ============================================================
# MOVEMENT
# ============================================================

func _read_movement_input() -> void:
    var keyboard_input := Vector2.ZERO

    keyboard_input.x = (
        Input.get_action_strength("move_right")
        - Input.get_action_strength("move_left")
    )
    keyboard_input.y = (
        Input.get_action_strength("move_down")
        - Input.get_action_strength("move_up")
    )

    if keyboard_input.length() > 1.0:
        keyboard_input = keyboard_input.normalized()

    if _joystick_vector.length() > joystick_deadzone:
        _move_input = _joystick_vector
    else:
        _move_input = keyboard_input


func _move_player(delta: float) -> void:
    var direction := Vector3.ZERO

    if _move_input.length() > joystick_deadzone:
        direction = Vector3(
            _move_input.x,
            0.0,
            _move_input.y
        )

        if camera_relative_movement:
            var camera := get_viewport().get_camera_3d()

            if camera != null:
                var forward := -camera.global_basis.z
                var right := camera.global_basis.x

                forward.y = 0.0
                right.y = 0.0

                forward = forward.normalized()
                right = right.normalized()

                direction = right * _move_input.x
                direction += forward * -_move_input.y
        else:
            direction = Vector3(
                _move_input.x,
                0.0,
                _move_input.y
            )

        direction.y = 0.0
        direction = direction.normalized()

    var target_velocity := direction * move_speed
    var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)

    var rate := acceleration
    if direction == Vector3.ZERO:
        rate = deceleration

    horizontal_velocity = horizontal_velocity.move_toward(
        target_velocity,
        rate * delta
    )

    velocity.x = horizontal_velocity.x
    velocity.z = horizontal_velocity.z

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    if direction.length_squared() > 0.001:
        var target_angle := atan2(direction.x, direction.z)

        rotation.y = lerp_angle(
            rotation.y,
            target_angle,
            minf(rotation_speed * delta, 1.0)
        )

    move_and_slide()


# ============================================================
# HEALTH AND DAMAGE
# ============================================================

func take_damage(amount: int, _attacker: Node = null) -> void:
    if is_dead or amount <= 0:
        return

    current_health = maxi(0, current_health - amount)
    _update_health_display()
    health_changed.emit(current_health, max_health)

    if current_health <= 0:
        _die()


func heal(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    var previous_health := current_health
    current_health = mini(max_health, current_health + amount)

    if current_health != previous_health:
        _update_health_display()
        health_changed.emit(current_health, max_health)


func set_max_health(new_maximum: int, refill: bool = false) -> void:
    max_health = maxi(1, new_maximum)

    if refill:
        current_health = max_health
    else:
        current_health = mini(current_health, max_health)

    _update_health_display()
    health_changed.emit(current_health, max_health)


func _die() -> void:
    if is_dead:
        return

    is_dead = true
    velocity = Vector3.ZERO
    _move_input = Vector2.ZERO
    _joystick_vector = Vector2.ZERO

    player_died.emit()

    # Respawn timer is handled without blocking the game.
    await get_tree().create_timer(respawn_delay).timeout

    if not is_inside_tree():
        return

    respawn()


func respawn() -> void:
    global_position = _respawn_position
    rotation = _respawn_rotation
    velocity = Vector3.ZERO

    current_health = max_health
    is_dead = false

    _move_input = Vector2.ZERO
    _joystick_vector = Vector2.ZERO
    _joystick_touch_id = -1

    _update_health_display()
    health_changed.emit(current_health, max_health)
    player_respawned.emit()


func set_respawn_point(new_position: Vector3) -> void:
    _respawn_position = new_position


# ============================================================
# ATTACK AND ABILITIES
# These emit signals for the combat system to connect.
# ============================================================

func perform_attack() -> void:
    if is_dead or _attack_timer > 0.0:
        return

    _attack_timer = attack_cooldown
    is_attacking = true

    attack_requested.emit()

    # The combat system can reset this when its animation ends.
    await get_tree().create_timer(0.25).timeout

    if is_inside_tree():
        is_attacking = false


func use_ability(ability_name: String) -> void:
    if is_dead or _ability_timer > 0.0:
        return

    _ability_timer = ability_cooldown
    ability_requested.emit(ability_name)


func dodge() -> void:
    if is_dead:
        return

    var dodge_direction := Vector3(velocity.x, 0.0, velocity.z)

    if dodge_direction.length_squared() < 0.01:
        dodge_direction = -global_basis.z
        dodge_direction.y = 0.0

    dodge_direction = dodge_direction.normalized()

    velocity.x = dodge_direction.x * move_speed * 2.0
    velocity.z = dodge_direction.z * move_speed * 2.0


# ============================================================
# MOBILE HUD
# ============================================================

func _create_mobile_hud() -> void:
    _hud_layer = CanvasLayer.new()
    _hud_layer.name = "MobileHUD"
    add_child(_hud_layer)

    var root := Control.new()
    root.name = "HUDRoot"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    _hud_layer.add_child(root)

    _create_health_bar(root)
    _create_joystick(root)
    _create_action_buttons(root)


func _create_health_bar(root: Control) -> void:
    var panel := PanelContainer.new()
    panel.name = "PlayerHealthPanel"
    panel.position = Vector2(20, 20)
    panel.custom_minimum_size = Vector2(240, 58)
    root.add_child(panel)

    var layout := VBoxContainer.new()
    panel.add_child(layout)

    _health_text = Label.new()
    _health_text.text = "Lv. 1  HP: %d/%d" % [
        current_health, max_health
    ]
    layout.add_child(_health_text)

    _health_bar = ProgressBar.new()
    _health_bar.custom_minimum_size = Vector2(220, 18)
    _health_bar.min_value = 0
    _health_bar.max_value = max_health
    _health_bar.value = current_health
    _health_bar.show_percentage = false
    layout.add_child(_health_bar)


func _create_joystick(root: Control) -> void:
    _joystick_base = Control.new()
    _joystick_base.name = "FixedJoystick"
    _joystick_base.custom_minimum_size = Vector2(150, 150)
    _joystick_base.position = Vector2(35, -185)
    _joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    _joystick_base.mouse_filter = Control.MOUSE_FILTER_STOP
    root.add_child(_joystick_base)

    var base_visual := Panel.new()
    base_visual.name = "JoystickRing"
    base_visual.position = Vector2(0, 0)
    base_visual.size = Vector2(130, 130)
    base_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _joystick_base.add_child(base_visual)

    _joystick_knob = Panel.new()
    _joystick_knob.name = "JoystickKnob"
    _joystick_knob.position = Vector2(43, 43)
    _joystick_knob.size = Vector2(44, 44)
    _joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _joystick_base.add_child(_joystick_knob)


func _create_action_buttons(root: Control) -> void:
    _attack_button = _make_button(
        root, "⚔", Vector2(-145, -150), Vector2(95, 95)
    )
    _attack_button.name = "AttackButton"
    _attack_button.pressed.connect(perform_attack)

    _heal_button = _make_button(
        root, "♥", Vector2(-255, -105), Vector2(62, 62)
    )
    _heal_button.name = "HealButton"
    _heal_button.pressed.connect(_on_heal_pressed)

    _ability_button = _make_button(
        root, "✦", Vector2(-205, -225), Vector2(62, 62)
    )
    _ability_button.name = "AbilityButton"
    _ability_button.pressed.connect(
        func(): use_ability("special")
    )

    _dodge_button = _make_button(
        root, "➤", Vector2(-270, -180), Vector2(62, 62)
    )
    _dodge_button.name = "DodgeButton"
    _dodge_button.pressed.connect(dodge)


func _make_button(
    root: Control,
    button_text: String,
    bottom_right_offset: Vector2,
    button_size: Vector2
) -> Button:
    var button := Button.new()
    button.text = button_text
    button.custom_minimum_size = button_size
    button.size = button_size
    button.position = bottom_right_offset
    button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    button.focus_mode = Control.FOCUS_NONE
    root.add_child(button)
    return button


func _on_heal_pressed() -> void:
    # Placeholder healing amount. Connect to the real item or
    # ability system before shipping the game.
    heal(25)


func _update_health_display() -> void:
    if not is_instance_valid(_health_bar):
        return

    _health_bar.max_value = max_health
    _health_bar.value = current_health

    if is_instance_valid(_health_text):
        _health_text.text = "Lv. 1  HP: %d/%d" % [
            current_health, max_health
        ]


# ============================================================
# TOUCH JOYSTICK
# ============================================================

func _input(event: InputEvent) -> void:
    if is_dead or not show_touch_controls:
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            _try_start_joystick(event)
        elif event.index == _joystick_touch_id:
            _joystick_touch_id = -1
            _joystick_vector = Vector2.ZERO
            _move_input = Vector2.ZERO
            _update_joystick_visual()

    elif event is InputEventScreenDrag:
        if event.index == _joystick_touch_id:
            _update_joystick_from_screen(event.position)


func _try_start_joystick(event: InputEventScreenTouch) -> void:
    if _joystick_touch_id != -1:
        return

    if not is_instance_valid(_joystick_base):
        return

    var base_rect := Rect2(
        _joystick_base.global_position,
        _joystick_base.size
    )

    if base_rect.has_point(event.position):
        _joystick_touch_id = event.index
        _joystick_origin = (
            _joystick_base.global_position
            + Vector2(65, 65)
        )
        _update_joystick_from_screen(event.position)


func _update_joystick_from_screen(screen_position: Vector2) -> void:
    var offset := screen_position - _joystick_origin
    var max_radius := joystick_radius

    if offset.length() > max_radius:
        offset = offset.normalized() * max_radius

    _joystick_vector = Vector2(
        offset.x / max_radius,
        offset.y / max_radius
    )

    if _joystick_vector.length() < joystick_deadzone:
        _joystick_vector = Vector2.ZERO


func _update_joystick_visual() -> void:
    if not is_instance_valid(_joystick_knob):
        return

    var center := Vector2(43, 43)
    var offset := _joystick_vector * joystick_radius

    _joystick_knob.position = center + offset


# ============================================================
# OPTIONAL INTEGRATION HELPERS
# ============================================================

func get_current_health() -> int:
    return current_health


func get_max_health() -> int:
    return max_health


func is_player_alive() -> bool:
    return not is_dead


func set_movement_enabled(enabled: bool) -> void:
    if not enabled:
        _move_input = Vector2.ZERO
        _joystick_vector = Vector2.ZERO
        velocity.x = 0.0
        velocity.z = 0.0
