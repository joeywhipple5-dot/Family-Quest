
extends CharacterBody3D

signal health_changed(current_health: int, maximum_health: int)
signal player_died
signal player_revived

@export_group("Character")
@export_file("*.glb", "*.tscn")
var character_scene_path: String = "res://artwork/FamilyQuest_Warrior_Hero_Rigged-2.glb"
@export var character_scale: float = 1.0
@export_range(-180.0, 180.0, 1.0)
var model_forward_offset_degrees: float = 180.0
@export var model_local_position: Vector3 = Vector3.ZERO

@export_group("Movement")
@export var move_speed: float = 4.5
@export var acceleration: float = 14.0
@export var deceleration: float = 18.0
@export var rotation_speed: float = 10.0
@export var gravity_strength: float = 22.0
@export var jump_velocity: float = 5.0
@export_range(0.0, 0.3, 0.01)
var joystick_deadzone: float = 0.12

@export_group("Camera")
@export var camera_distance: float = 5.0
@export var camera_height: float = 1.7
@export var camera_sensitivity: float = 0.006
@export_range(-70.0, -5.0, 1.0)
var camera_min_pitch_degrees: float = -55.0
@export_range(5.0, 70.0, 1.0)
var camera_max_pitch_degrees: float = 25.0

@export_group("Health")
@export var max_health: int = 100
@export var respawn_health: int = 100

var current_health: int = 100
var hero_class: String = "Warrior"
var hero_gender: String = "Male"
var is_dead: bool = false

var _move_input: Vector2 = Vector2.ZERO
var _joystick_input: Vector2 = Vector2.ZERO
var _keyboard_input: Vector2 = Vector2.ZERO

var _camera_yaw: float = 0.0
# Positive pitch means the camera looks down toward the player.
var _camera_pitch: float = deg_to_rad(12.0)

var _camera_touch_id: int = -1
var _joystick_touch_id: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_radius: float = 65.0

var _model_root: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _walk_controller: Node
var _walk_animation_name: StringName = &""
var _idle_animation_name: StringName = &""
var _death_animation_name: StringName = &""

var _camera_pivot: Node3D
var _camera: Camera3D
var _hud_layer: CanvasLayer
var _joystick_base: Panel
var _joystick_knob: Panel
var _health_label: Label


func _ready() -> void:
    max_health = maxi(max_health, 1)
    current_health = max_health

    _create_collision()
    _create_camera()
    _create_mobile_controls()
    _load_character()
    _find_animations()
    _update_camera()

    health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
    _update_keyboard_input()

    if _joystick_touch_id != -1:
        _move_input = _joystick_input
    else:
        _move_input = _keyboard_input

    if is_dead:
        _move_input = Vector2.ZERO
        _joystick_input = Vector2.ZERO

        var dead_horizontal := Vector3(velocity.x, 0.0, velocity.z)
        dead_horizontal = dead_horizontal.move_toward(
            Vector3.ZERO,
            deceleration * delta
        )
        velocity.x = dead_horizontal.x
        velocity.z = dead_horizontal.z

        if not is_on_floor():
            velocity.y -= gravity_strength * delta
        else:
            velocity.y = 0.0

        move_and_slide()
        _update_camera()
        return

    # Remove tiny accidental joystick inputs and preserve analog strength.
    var input_dir: Vector2 = _move_input.limit_length(1.0)
    var input_strength: float = input_dir.length()

    if input_strength < joystick_deadzone:
        input_dir = Vector2.ZERO
        input_strength = 0.0

    # Convert joystick directions into camera-relative world movement.
    # At zero camera yaw, pushing up moves toward -Z.
    var camera_basis := Basis(Vector3.UP, _camera_yaw)
    var world_move: Vector3 = camera_basis * Vector3(
        input_dir.x,
        0.0,
        input_dir.y
    )
    world_move.y = 0.0

    if world_move.length_squared() > 0.0001:
        world_move = world_move.normalized() * input_strength
    else:
        world_move = Vector3.ZERO

    # Smooth acceleration and reliable stopping without excessive sliding.
    var target_horizontal_velocity: Vector3 = world_move * move_speed
    var current_horizontal_velocity := Vector3(
        velocity.x,
        0.0,
        velocity.z
    )

    var movement_rate: float = acceleration
    if input_strength <= 0.0:
        movement_rate = deceleration

    current_horizontal_velocity = current_horizontal_velocity.move_toward(
        target_horizontal_velocity,
        movement_rate * delta
    )

    velocity.x = current_horizontal_velocity.x
    velocity.z = current_horizontal_velocity.z

    # Gravity and ground handling.
    if not is_on_floor():
        velocity.y -= gravity_strength * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    # Turn the hero smoothly toward the direction of travel.
    if world_move.length_squared() > 0.01:
        var target_yaw: float = atan2(
            -world_move.x,
            -world_move.z
        )
        target_yaw += deg_to_rad(model_forward_offset_degrees)

        rotation.y = lerp_angle(
            rotation.y,
            target_yaw,
            1.0 - exp(-rotation_speed * delta)
        )

    move_and_slide()

    _update_character_animation(input_strength > 0.1)
    _update_camera()


func _update_keyboard_input() -> void:
    var direction := Vector2.ZERO

    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        direction.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        direction.y += 1.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        direction.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        direction.x += 1.0

    _keyboard_input = direction.limit_length(1.0)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch

        if touch.pressed:
            var screen_size: Vector2 = get_viewport().get_visible_rect().size

            # Left side: fixed joystick. Right side: camera control.
            if (
                touch.position.x < screen_size.x * 0.48
                and _joystick_touch_id == -1
            ):
                _joystick_touch_id = touch.index
                _joystick_center = _get_joystick_screen_center()
                _update_joystick_from_position(touch.position)
                _update_joystick_visual(touch.position)

            elif (
                touch.position.x >= screen_size.x * 0.48
                and _camera_touch_id == -1
            ):
                _camera_touch_id = touch.index
        else:
            if touch.index == _joystick_touch_id:
                _joystick_touch_id = -1
                _joystick_input = Vector2.ZERO
                _move_input = _keyboard_input
                _reset_joystick_visual()

            if touch.index == _camera_touch_id:
                _camera_touch_id = -1

    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag

        if drag.index == _joystick_touch_id:
            _update_joystick_from_position(drag.position)
            _update_joystick_visual(drag.position)

        elif drag.index == _camera_touch_id:
            set_camera_touch_delta(drag.relative)

    elif event is InputEventKey:
        var key := event as InputEventKey

        if (
            key.pressed
            and not key.echo
            and key.keycode == KEY_SPACE
            and is_on_floor()
            and not is_dead
        ):
            velocity.y = jump_velocity


func set_virtual_joystick_input(direction: Vector2) -> void:
    _joystick_input = direction.limit_length(1.0)
    if _joystick_touch_id == -1:
        _move_input = _joystick_input


func set_camera_touch_delta(delta: Vector2) -> void:
    _camera_yaw -= delta.x * camera_sensitivity

    _camera_pitch = clampf(
        _camera_pitch + delta.y * camera_sensitivity,
        deg_to_rad(camera_min_pitch_degrees),
        deg_to_rad(camera_max_pitch_degrees)
    )

    _apply_camera_rotation()


func set_hero_class(value: String) -> void:
    hero_class = value


func set_hero_gender(value: String) -> void:
    hero_gender = value


func take_damage(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    current_health = maxi(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    _update_health_label()

    if current_health == 0:
        _die()


func damage(amount: int) -> void:
    take_damage(amount)


func heal(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    current_health = mini(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)
    _update_health_label()


func revive(at_position: Vector3 = Vector3.INF) -> void:
    is_dead = false
    current_health = clampi(respawn_health, 1, max_health)
    velocity = Vector3.ZERO
    _move_input = Vector2.ZERO
    _joystick_input = Vector2.ZERO

    if at_position != Vector3.INF:
        global_position = at_position

    health_changed.emit(current_health, max_health)
    _update_health_label()

    if _animation_player != null:
        if _idle_animation_name != &"":
            _animation_player.play(_idle_animation_name)
        elif _walk_animation_name != &"":
            _animation_player.play(_walk_animation_name)
            _animation_player.pause()

    player_revived.emit()


func _create_collision() -> void:
    var capsule := CollisionShape3D.new()
    capsule.name = "PlayerCollision"

    var shape := CapsuleShape3D.new()
    shape.radius = 0.34
    shape.height = 1.8

    capsule.shape = shape
    capsule.position.y = 0.9
    add_child(capsule)


func _load_character() -> void:
    if (
        character_scene_path.is_empty()
        or not ResourceLoader.exists(character_scene_path)
    ):
        push_warning(
            "Player model not found: "
            + character_scene_path
            + ". Player collision and controls will still work."
        )
        return

    var resource: Resource = load(character_scene_path)
    var packed := resource as PackedScene

    if packed == null:
        push_warning(
            "Player model could not be loaded as a PackedScene: "
            + character_scene_path
        )
        return

    _model_root = Node3D.new()
    _model_root.name = "CharacterVisual"
    add_child(_model_root)

    var instance: Node = packed.instantiate()
    _model_root.add_child(instance)

    if instance is Node3D:
        var visual := instance as Node3D
        visual.position = model_local_position
        visual.scale = Vector3.ONE * character_scale

    var walk_script_resource: Resource = (
        load("res://scripts/normal_walk_animation.gd")
        if ResourceLoader.exists("res://scripts/normal_walk_animation.gd")
        else null
    )
    var walk_script := walk_script_resource as Script

    if walk_script != null:
        _walk_controller = Node.new()
        _walk_controller.name = "NormalWalkAnimation"
        _walk_controller.set_script(walk_script)
        instance.add_child(_walk_controller)
    else:
        push_warning(
            "Optional walk animation script not found: "
            + "res://scripts/normal_walk_animation.gd"
        )

    _find_character_nodes(_model_root)


func _find_character_nodes(node: Node) -> void:
    if node is Skeleton3D and _skeleton == null:
        _skeleton = node as Skeleton3D

    if node is AnimationPlayer and _animation_player == null:
        _animation_player = node as AnimationPlayer

    for child in node.get_children():
        _find_character_nodes(child)


func _find_animations() -> void:
    if _animation_player == null:
        return

    var animations: PackedStringArray = _animation_player.get_animation_list()

    for animation_name in animations:
        var lower_name: String = String(animation_name).to_lower()

        if _walk_animation_name == &"" and (
            lower_name == "walk"
            or lower_name.contains("walk_fwd")
            or lower_name.contains("walk_forward")
            or lower_name.contains("normal_walk")
        ):
            _walk_animation_name = StringName(animation_name)

        if _idle_animation_name == &"" and (
            lower_name.contains("idle")
            or lower_name.contains("stand")
        ):
            _idle_animation_name = StringName(animation_name)

        if _death_animation_name == &"" and (
            lower_name.contains("death")
            or lower_name.contains("die")
        ):
            _death_animation_name = StringName(animation_name)

    if _walk_animation_name == &"":
        for animation_name in animations:
            var lower_name: String = String(animation_name).to_lower()
            if lower_name.contains("walk") or lower_name.contains("run"):
                _walk_animation_name = StringName(animation_name)
                break

    if _idle_animation_name != &"":
        _animation_player.play(_idle_animation_name)
    elif _walk_animation_name != &"":
        _animation_player.play(_walk_animation_name)
        _animation_player.seek(0.0, true)
        _animation_player.pause()


func _update_character_animation(moving: bool) -> void:
    if _animation_player == null:
        return

    var generated_walk := StringName("FamilyQuest_Normal_Walk")
    if _animation_player.has_animation(generated_walk):
        _walk_animation_name = generated_walk

    if _walk_animation_name == &"":
        return

    if moving:
        if (
            _animation_player.current_animation != String(_walk_animation_name)
            or not _animation_player.is_playing()
        ):
            _animation_player.play(_walk_animation_name)

    elif _idle_animation_name != &"":
        if _animation_player.current_animation != String(_idle_animation_name):
            _animation_player.play(_idle_animation_name)

    elif (
        _animation_player.current_animation != String(_walk_animation_name)
        or _animation_player.is_playing()
    ):
        _animation_player.play(_walk_animation_name)
        _animation_player.seek(0.0, true)
        _animation_player.pause()


func _create_camera() -> void:
    # The pivot follows the hero, but its local yaw is compensated
    # so the camera can orbit independently of hero rotation.
    _camera_pivot = Node3D.new()
    _camera_pivot.name = "CameraPivot"
    _camera_pivot.position = Vector3(0.0, camera_height, 0.0)
    add_child(_camera_pivot)

    _camera = Camera3D.new()
    _camera.name = "PlayerCamera"
    _camera.position = Vector3(0.0, 0.0, maxf(camera_distance, 1.0))
    _camera.fov = 70.0
    _camera.near = 0.1
    _camera.far = 1000.0
    _camera.current = true
    _camera_pivot.add_child(_camera)

    _apply_camera_rotation()
    _camera.make_current()


func _apply_camera_rotation() -> void:
    if _camera_pivot == null:
        return

    _camera_pivot.rotation = Vector3(
        -_camera_pitch,
        _camera_yaw - rotation.y,
        0.0
    )


func _update_camera() -> void:
    if (
        not is_instance_valid(_camera_pivot)
        or not is_instance_valid(_camera)
    ):
        return

    _camera_pivot.position = Vector3(0.0, camera_height, 0.0)
    _apply_camera_rotation()

    if not _camera.current:
        _camera.make_current()


func _create_mobile_controls() -> void:
    _hud_layer = CanvasLayer.new()
    _hud_layer.name = "PlayerMobileHUD"
    add_child(_hud_layer)

    var root := Control.new()
    root.name = "HUDRoot"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _hud_layer.add_child(root)

    _joystick_base = Panel.new()
    _joystick_base.name = "JoystickBase"
    _joystick_base.size = Vector2(150.0, 150.0)
    _joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    _joystick_base.position = Vector2(28.0, -178.0)
    _joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(0.12, 0.18, 0.22, 0.58)
    base_style.corner_radius_top_left = 75
    base_style.corner_radius_top_right = 75
    base_style.corner_radius_bottom_left = 75
    base_style.corner_radius_bottom_right = 75
    base_style.set_border_width_all(3)
    base_style.border_color = Color(0.85, 0.92, 1.0, 0.8)
    _joystick_base.add_theme_stylebox_override("panel", base_style)
    root.add_child(_joystick_base)

    _joystick_knob = Panel.new()
    _joystick_knob.name = "JoystickKnob"
    _joystick_knob.size = Vector2(58.0, 58.0)
    _joystick_knob.position = Vector2(46.0, 46.0)
    _joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var knob_style := StyleBoxFlat.new()
    knob_style.bg_color = Color(0.30, 0.62, 0.82, 0.95)
    knob_style.corner_radius_top_left = 29
    knob_style.corner_radius_top_right = 29
    knob_style.corner_radius_bottom_left = 29
    knob_style.corner_radius_bottom_right = 29
    knob_style.set_border_width_all(2)
    knob_style.border_color = Color.WHITE
    _joystick_knob.add_theme_stylebox_override("panel", knob_style)
    _joystick_base.add_child(_joystick_knob)

    _health_label = Label.new()
    _health_label.name = "HealthLabel"
    _health_label.position = Vector2(22.0, 18.0)
    _health_label.add_theme_font_size_override("font_size", 24)
    _health_label.add_theme_color_override("font_color", Color.WHITE)
    root.add_child(_health_label)

    _update_health_label()


func _get_joystick_screen_center() -> Vector2:
    var screen_size: Vector2 = get_viewport().get_visible_rect().size
    return Vector2(103.0, screen_size.y - 103.0)


func _update_joystick_from_position(screen_position: Vector2) -> void:
    var offset: Vector2 = (
        screen_position - _joystick_center
    ).limit_length(_joystick_radius)

    var raw_input := Vector2(
        offset.x / _joystick_radius,
        offset.y / _joystick_radius
    ).limit_length(1.0)

    var strength: float = raw_input.length()

    if strength <= joystick_deadzone:
        _joystick_input = Vector2.ZERO
        return

    # Remap the dead zone so movement begins smoothly rather than jumping.
    var adjusted_strength: float = (
        (strength - joystick_deadzone)
        / (1.0 - joystick_deadzone)
    )
    _joystick_input = (
        raw_input.normalized() * adjusted_strength
    ).limit_length(1.0)


func _update_joystick_visual(screen_position: Vector2) -> void:
    if _joystick_knob == null:
        return

    var offset: Vector2 = (
        screen_position - _get_joystick_screen_center()
    ).limit_length(_joystick_radius)

    _joystick_knob.position = Vector2(46.0, 46.0) + offset


func _reset_joystick_visual() -> void:
    if _joystick_knob != null:
        _joystick_knob.position = Vector2(46.0, 46.0)


func _update_health_label() -> void:
    if _health_label != null:
        _health_label.text = "HP  %d / %d" % [
            current_health,
            max_health
        ]


func _die() -> void:
    if is_dead:
        return

    is_dead = true
    velocity = Vector3.ZERO
    _move_input = Vector2.ZERO
    _joystick_input = Vector2.ZERO

    if _animation_player != null and _death_animation_name != &"":
        _animation_player.play(_death_animation_name)

    player_died.emit()
