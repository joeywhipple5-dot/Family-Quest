
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
    # Visible temporary hero. CharacterBuilder can be restored later.
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

    # Collision shape for the hero.
    var collision := CollisionShape3D.new()
    collision.name = "PlayerCollision"

    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.45
    capsule_shape.height = 1.8
    collision.shape = capsule_shape
    collision.position.y = 0.9
    add_child(collision)

    # Create a camera attached to the player.
    var camera_pivot := Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0, camera_height, 0)
    add_child(camera_pivot)

    game_camera = Camera3D.new()
    game_camera.name = "GameCamera"
    game_camera.position = Vector3(0, 0, camera_distance)
    game_camera.current = true
    camera_pivot.add_child(game_camera)

    _update_camera()
    _create_touch_controls()


func _physics_process(delta: float) -> void:
    # Keyboard controls also work when available.
    var keyboard_input := Input.get_vector(
        "move_left",
        "move_right",
        "move_forward",
        "move_back"
    )

    var input_vector := keyboard_input

    # Mobile joystick overrides keyboard only when being used.
    if joystick_active:
        input_vector = joystick_vector

    # Movement follows the direction the camera is facing.
    var forward := -global_basis.z
    var right := global_basis.x

    # Remove vertical components so slopes do not change the direction.
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

    # Gravity and ground movement.
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    move_and_slide()


func _create_touch_controls() -> void:
    var layer := CanvasLayer.new()
    layer.name = "PlayerTouchControls"
    add_child(layer)

    # Left-side joystick base.
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
    base_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    base_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(0.12, 0.16, 0.19, 0.48)
    base_style.set_corner_radius_all(65)
    base_panel.add_theme_stylebox_override("panel", base_style)
    joystick_base.add_child(base_panel)

    # Joystick knob.
    joystick_knob = Control.new()
    joystick_knob.name = "JoystickKnob"
    joystick_knob.position = Vector2(40, 40)
    joystick_knob.size = Vector2(50, 50)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_base.add_child(joystick_knob)

    var knob_panel := Panel.new()
    knob_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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

    # Optional mouse support for desktop testing.
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _handle_touch_start(-2, event.position)
            else:
                _handle_touch_end(-2)

    elif event is InputEventMouseMotion:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            _handle_touch_drag(-2, event.position)


func _handle_touch_start(pointer_id: int, position: Vector2) -> void:
    var screen_size := get_viewport().get_visible_rect().size

    # Start joystick when touching the lower-left control area.
    if pointer_id != camera_pointer and position.x < screen_size.x * 0.42:
        if not joystick_active and joystick_pointer == -1:
            var base_center := joystick_base.global_position + joystick_base.size * 0.5
            var touch_distance := position.distance_to(base_center)

            if touch_distance < 115.0:
                joystick_active = true
                joystick_pointer = pointer_id
                joystick_origin = base_center
                _update_joystick(position)
                return

    # Right half of the screen controls camera rotation.
    if position.x >= screen_size.x * 0.42 and camera_pointer == -1:
        camera_pointer = pointer_id
        camera_last_position = position


func _handle_touch_drag(pointer_id: int, position: Vector2) -> void:
    if pointer_id == joystick_pointer and joystick_active:
        _update_joystick(position)

    elif pointer_id == camera_pointer:
        var drag_delta := position - camera_last_position
        camera_last_position = position

        camera_yaw -= drag_delta.x * camera_sensitivity
        camera_pitch -= drag_delta.y * camera_sensitivity
        camera_pitch = clampf(camera_pitch, -0.65, 0.35)

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

    var pivot := game_camera.get_parent() as Node3D
    if pivot == null:
        return

    pivot.rotation.y = camera_yaw
    pivot.rotation.x = camera_pitch

    # Keep camera behind the player, looking toward the upper body.
    game_camera.position = Vector3(0, 0, camera_distance)
    game_camera.look_at_from_position(
        game_camera.position,
        Vector3.ZERO,
        Vector3.UP
    )
