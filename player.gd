
extends CharacterBody3D

signal died
signal respawned

class VirtualJoystick extends Control:
    signal value_changed(value: Vector2)

    var input_vector := Vector2.ZERO
    var knob_position := Vector2.ZERO
    var tracking := false

    const RADIUS := 65.0
    const KNOB_RADIUS := 25.0
    const DEADZONE := 0.12

    func _ready() -> void:
        custom_minimum_size = Vector2(160, 160)
        size = Vector2(160, 160)
        mouse_filter = Control.MOUSE_FILTER_STOP
        queue_redraw()

    func _gui_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
            if event.pressed:
                tracking = true
                _update_stick(event.position)
            else:
                _reset_stick()
            accept_event()

        elif event is InputEventScreenDrag and tracking:
            _update_stick(event.position)
            accept_event()

        elif event is InputEventMouseButton:
            if event.button_index == MOUSE_BUTTON_LEFT:
                tracking = event.pressed
                if tracking:
                    _update_stick(event.position)
                else:
                    _reset_stick()
                accept_event()

        elif event is InputEventMouseMotion and tracking:
            _update_stick(event.position)
            accept_event()

    func _update_stick(pos: Vector2) -> void:
        var offset := pos - size / 2.0

        if offset.length() > RADIUS:
            offset = offset.normalized() * RADIUS

        knob_position = offset
        input_vector = offset / RADIUS

        if input_vector.length() < DEADZONE:
            input_vector = Vector2.ZERO

        value_changed.emit(input_vector)
        queue_redraw()

    func _reset_stick() -> void:
        tracking = false
        input_vector = Vector2.ZERO
        knob_position = Vector2.ZERO
        value_changed.emit(input_vector)
        queue_redraw()

    func _draw() -> void:
        var center := size / 2.0

        draw_circle(
            center, RADIUS,
            Color(0.08, 0.10, 0.13, 0.7)
        )

        draw_arc(
            center, RADIUS, 0, TAU, 48,
            Color(0.8, 0.85, 0.9), 3.0
        )

        draw_circle(
            center + knob_position, KNOB_RADIUS,
            Color(0.25, 0.55, 0.9, 0.95)
        )


class CameraSwipeArea extends Control:
    var player: CharacterBody3D
    var tracking := false
    var last_position := Vector2.ZERO

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_STOP

    func _gui_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
            if event.pressed:
                tracking = true
                last_position = event.position
            else:
                tracking = false

            accept_event()

        elif event is InputEventScreenDrag and tracking:
            var movement := event.position - last_position
            last_position = event.position

            if is_instance_valid(player):
                player.rotate_camera(movement)

            accept_event()

        elif event is InputEventMouseButton:
            if event.button_index == MOUSE_BUTTON_LEFT:
                tracking = event.pressed
                last_position = event.position
                accept_event()

        elif event is InputEventMouseMotion and tracking:
            var movement := event.position - last_position
            last_position = event.position

            if is_instance_valid(player):
                player.rotate_camera(movement)

            accept_event()


var hero_class := "Warrior"
var hero_gender := "male"

var hp := 100
var max_hp := 100
var dead := false
var invulnerable := false

@export var speed := 7.0
@export var acceleration := 18.0
@export var braking := 24.0
@export var turn_speed := 8.0

@export var camera_distance := 6.0
@export var camera_pitch := 18.0
@export var camera_look_height := 1.2
@export var camera_follow_speed := 6.0
@export var camera_swipe_sensitivity := 0.006
@export var respawn_delay := 2.0

var gravity := 20.0

var camera: Camera3D
var camera_rig: Node3D

var camera_yaw := 0.0
var camera_yaw_target := 0.0
var camera_pitch_current := 18.0
var camera_pitch_target := 18.0

var joystick_input := Vector2.ZERO
var spawn_position := Vector3(0, 1, 4)


func _ready() -> void:
    hp = max_hp

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.45
    shape.height = 1.8
    collision.shape = shape
    add_child(collision)

    # Keep the existing character builder.
    var builder_script = preload(
        "res://scripts/CharacterBuilder.gd"
    )
    var builder = builder_script.new()

    var character_model: Node3D = builder.build_character(
        hero_class, hero_gender
    )
    character_model.name = "VisibleHeroModel"
    add_child(character_model)

    # Create an independent camera rig.
    camera_rig = Node3D.new()
    camera_rig.name = "CameraRig"
    get_tree().root.add_child(camera_rig)

    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.current = true
    camera_rig.add_child(camera)

    # Start behind the hero without camera dragging.
    camera_yaw = rotation.y
    camera_yaw_target = rotation.y
    camera_pitch_current = camera_pitch
    camera_pitch_target = camera_pitch

    camera_rig.global_position = global_position
    _update_camera_position()

    _make_touch_controls()


func _physics_process(delta: float) -> void:
    if dead:
        velocity = Vector3.ZERO
        return

    # Read keyboard/gamepad actions and the touch joystick.
    var input_dir := Vector2(
        Input.get_action_strength("move_right")
        - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back")
        - Input.get_action_strength("move_forward")
    )

    input_dir += joystick_input

    if input_dir.length_squared() > 1.0:
        input_dir = input_dir.normalized()

    # Move relative to the camera's horizontal direction.
    var yaw_basis := Basis(Vector3.UP, camera_yaw)
    var camera_forward := -yaw_basis.z
    var camera_right := yaw_basis.x

    var direction := (
        camera_right * input_dir.x
        + camera_forward * -input_dir.y
    )

    if direction.length_squared() > 1.0:
        direction = direction.normalized()

    # Smooth acceleration and stopping.
    var horizontal_velocity := Vector2(
        velocity.x, velocity.z
    )

    var target_velocity := Vector2(
        direction.x * speed,
        direction.z * speed
    )

    var movement_rate := braking

    if direction.length_squared() > 0.001:
        movement_rate = acceleration

        # Smoothly face the direction of movement.
        var target_yaw := atan2(
            -direction.x, -direction.z
        )

        rotation.y = lerp_angle(
            rotation.y,
            target_yaw,
            minf(turn_speed * delta, 1.0)
        )

    horizontal_velocity = horizontal_velocity.move_toward(
        target_velocity, movement_rate * delta
    )

    velocity.x = horizontal_velocity.x
    velocity.z = horizontal_velocity.y

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    move_and_slide()


func _process(delta: float) -> void:
    if not is_instance_valid(camera_rig):
        return

    # Smooth camera orbit independently of hero turning.
    var weight := 1.0 - exp(-6.0 * delta)

    camera_yaw = lerp_angle(
        camera_yaw, camera_yaw_target, weight
    )

    camera_pitch_current = lerpf(
        camera_pitch_current,
        camera_pitch_target,
        weight
    )

    # Smoothly follow the hero's position.
    camera_rig.global_position = (
        camera_rig.global_position.lerp(
            global_position,
            1.0 - exp(-camera_follow_speed * delta)
        )
    )

    _update_camera_position()


func _update_camera_position() -> void:
    if not is_instance_valid(camera):
        return

    var pitch_radians := deg_to_rad(camera_pitch_current)

    var horizontal_distance := (
        camera_distance * cos(pitch_radians)
    )

    var vertical_distance := (
        camera_distance * sin(pitch_radians)
    )

    # Positive Z is behind the hero at zero camera yaw.
    var offset := Vector3(
        sin(camera_yaw) * horizontal_distance,
        vertical_distance,
        cos(camera_yaw) * horizontal_distance
    )

    camera.global_position = (
        camera_rig.global_position
        + offset
        + Vector3.UP * camera_look_height
    )

    var look_target := camera_rig.global_position
    look_target.y += camera_look_height

    camera.look_at(look_target, Vector3.UP)


func rotate_camera(movement: Vector2) -> void:
    # Horizontal swipe rotates the view around the hero.
    camera_yaw_target -= (
        movement.x * camera_swipe_sensitivity
    )

    # Vertical swipe adjusts the viewing angle.
    camera_pitch_target = clampf(
        camera_pitch_target
        + movement.y * camera_swipe_sensitivity * 50.0,
        5.0,
        45.0
    )


func take_damage(amount: int) -> void:
    if dead or invulnerable or amount <= 0:
        return

    hp = maxi(hp - amount, 0)

    if hp == 0:
        _die()


func heal(amount: int) -> void:
    if dead or amount <= 0:
        return

    hp = mini(hp + amount, max_hp)


func _die() -> void:
    if dead:
        return

    dead = true
    hp = 0
    velocity = Vector3.ZERO
    died.emit()

    await get_tree().create_timer(respawn_delay).timeout

    if not is_inside_tree():
        return

    respawn()


func respawn() -> void:
    global_position = spawn_position
    velocity = Vector3.ZERO
    hp = max_hp
    dead = false
    invulnerable = true

    respawned.emit()

    await get_tree().create_timer(2.0).timeout

    if is_inside_tree():
        invulnerable = false


func _make_touch_controls() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 5
    add_child(layer)

    # Left half: movement joystick.
    var joystick := VirtualJoystick.new()
    joystick.name = "MovementJoystick"
    joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    joystick.position = Vector2(25, -185)
    joystick.size = Vector2(160, 160)

    joystick.value_changed.connect(
        func(value: Vector2):
            joystick_input = value
    )

    layer.add_child(joystick)

    # Right half: optional swipe-to-rotate camera.
    var swipe_area := CameraSwipeArea.new()
    swipe_area.name = "CameraSwipeArea"
    swipe_area.player = self

    swipe_area.anchor_left = 0.5
    swipe_area.anchor_right = 1.0
    swipe_area.anchor_top = 0.0
    swipe_area.anchor_bottom = 1.0

    swipe_area.offset_left = 0.0
    swipe_area.offset_right = 0.0
    swipe_area.offset_top = 0.0
    swipe_area.offset_bottom = 0.0

    layer.add_child(swipe_area)
