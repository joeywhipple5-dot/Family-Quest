
extends CharacterBody3D

var hp: int = 100
var max_hp: int = 100
var hero_class: String = "Warrior"
var hero_gender: String = "male"

@export var move_speed: float = 7.0
@export var gravity: float = 22.0
@export var camera_sensitivity: float = 0.008
@export var camera_distance: float = 6.0
@export var camera_height: float = 2.8

var game_camera: Camera3D
var camera_yaw: float = 0.0
var camera_pitch: float = -0.12

var joystick_active: bool = false
var joystick_pointer: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_vector: Vector2 = Vector2.ZERO

var camera_pointer: int = -1
var camera_last_position: Vector2 = Vector2.ZERO

var joystick_base: Control
var joystick_knob: Control


func _ready() -> void:
    # Temporary visible hero.
    var body_mesh := MeshInstance3D.new()
    body_mesh.name = "TemporaryHeroVisual"

    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.45
    capsule_mesh.height = 1.8
    body_mesh.mesh = capsule_mesh
    body_mesh.position.y = 0.9

    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = Color(0.12, 0.36, 0.95)
    body_mesh.material_override = body_material
    add_child(body_mesh)

    # Hero collision.
    var collision := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.45
    capsule_shape.height = 1.8
    collision.shape = capsule_shape
    collision.position.y = 0.9
    add_child(collision)

    # Camera is a child of the hero, but its orbit
    # position is calculated in world coordinates.
    game_camera = Camera3D.new()
    game_camera.name = "GameCamera"
    add_child(game_camera)

    _create_touch_controls()
    _update_camera()


func _physics_process(delta: float) -> void:
    var input_vector := Input.get_vector(
        "move_left",
        "move_right",
        "move_forward",
        "move_back"
    )

    if joystick_active:
        input_vector = joystick_vector

    # Use camera direction, ignoring its vertical angle.
    var forward := -game_camera.global_basis.z
    var right := game_camera.global_basis.x

    forward.y = 0.0
    right.y = 0.0
    forward = forward.normalized()
    right = right.normalized()

    var move_direction := right * input_vector.x
    move_direction += forward * -input_vector.y

    if move_direction.length_squared() > 1.0:
        move_direction = move_direction.normalized()

    velocity.x = move_direction.x * move_speed
    velocity.z = move_direction.z * move_speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    move_and_slide()


func _process(_delta: float) -> void:
    # Keep the camera orbit centered on the moving hero.
    _update_camera()


func _create_touch_controls() -> void:
    var layer := CanvasLayer.new()
    layer.name = "PlayerTouchControls"
    add_child(layer)

    joystick_base = Control.new()
    joystick_base.name = "JoystickBase"
    joystick_base.anchor_left = 0.0
    joystick_base.anchor_top = 1.0
    joystick_base.anchor_right = 0.0
    joystick_base.anchor_bottom = 1.0
    joystick_base.offset_left = 35
    joystick_base.offset_top = -190
    joystick_base.offset_right = 165
    joystick_base.offset_bottom = -60
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(joystick_base)

    var base_panel := Panel.new()
    base_panel.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    base_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(0.12, 0.16, 0.19, 0.48)
    base_style.set_corner_radius_all(65)
    base_panel.add_theme_stylebox_override("panel", base_style)
    joystick_base.add_child(base_panel)

    joystick_knob = Control.new()
    joystick_knob.name = "JoystickKnob"
    joystick_knob.position = Vector2(40, 40)
    joystick_knob.size = Vector2(50, 50)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_base.add_child(joystick_knob)

    var knob_panel := Panel.new()
    knob_panel.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    knob_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var knob_style := StyleBoxFlat.new()
    knob_style.bg_color = Color(0.78, 0.83, 0.88, 0.85)
    knob_style.set_corner_radius_all(25)
    knob_panel.add_theme_stylebox_override("panel", knob_style)
    joystick_knob.add_child(knob_panel)


func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _handle_touch_start(event.index, event.position)
        else:
            _handle_touch_end(event.index)

    elif event is InputEventScreenDrag:
        _handle_touch_drag(event.index, event.position)

    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _handle_touch_start(-2, event.position)
            else:
                _handle_touch_end(-2)

    elif event is InputEventMouseMotion:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            _handle_touch_drag(-2, event.position)


func _handle_touch_start(
    pointer_id: int,
    position: Vector2
) -> void:
    var screen_size := get_viewport().get_visible_rect().size

    # Left side: joystick.
    if position.x < screen_size.x * 0.42:
        if not joystick_active and joystick_pointer == -1:
            var center := (
                joystick_base.global_position
                + joystick_base.size * 0.5
            )

            if position.distance_to(center) < 115.0:
                joystick_active = true
                joystick_pointer = pointer_id
                joystick_origin = center
                _update_joystick(position)
                return

    # Right side: camera orbit.
    elif camera_pointer == -1:
        camera_pointer = pointer_id
        camera_last_position = position


func _handle_touch_drag(
    pointer_id: int,
    position: Vector2
) -> void:
    if pointer_id == joystick_pointer and joystick_active:
        _update_joystick(position)

    elif pointer_id == camera_pointer:
        var drag_delta := position - camera_last_position
        camera_last_position = position

        camera_yaw -= drag_delta.x * camera_sensitivity

        camera_pitch = clampf(
            camera_pitch - drag_delta.y * camera_sensitivity,
            -0.45,
            0.35
        )

        _update_camera()


func _handle_touch_end(pointer_id: int) -> void:
    if pointer_id == joystick_pointer:
        joystick_active = false
        joystick_pointer = -1
        joystick_vector = Vector2.ZERO
        joystick_knob.position = Vector2(40, 40)

    if pointer_id == camera_pointer:
        camera_pointer = -1


func _update_joystick(touch_position: Vector2) -> void:
    var difference := touch_position - joystick_origin
    var radius := 42.0

    if difference.length() > radius:
        difference = difference.normalized() * radius

    joystick_vector = difference / radius
    joystick_knob.position = Vector2(40, 40) + difference


func _update_camera() -> void:
    if not is_instance_valid(game_camera):
        return

    if not game_camera.is_inside_tree():
        return

    # Aim at the hero's upper body.
    var target := global_position + Vector3(
        0.0,
        camera_height - 1.6,
        0.0
    )

    var horizontal_distance := (
        camera_distance * cos(camera_pitch)
    )
    var vertical_distance := (
        camera_distance * sin(camera_pitch)
    )

    var offset := Vector3(
        sin(camera_yaw) * horizontal_distance,
        vertical_distance,
        cos(camera_yaw) * horizontal_distance
    )

    # Position camera behind the hero at a fixed distance.
    game_camera.global_position = target + offset
    game_camera.look_at(target, Vector3.UP)
    game_camera.current = true
