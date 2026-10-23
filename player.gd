
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


class CameraDragArea extends Control:
    var player: CharacterBody3D
    var dragging := false
    var last_position := Vector2.ZERO

    const SENSITIVITY := 0.008

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_STOP

    func _gui_input(event: InputEvent) -> void:
        if event is InputEventScreenTouch:
            if event.pressed:
                dragging = true
                last_position = event.position
            else:
                dragging = false
            accept_event()

        elif event is InputEventScreenDrag and dragging:
            _rotate_camera(event.position)
            accept_event()

        elif event is InputEventMouseButton:
            if event.button_index == MOUSE_BUTTON_LEFT:
                dragging = event.pressed
                last_position = event.position
                accept_event()

        elif event is InputEventMouseMotion and dragging:
            _rotate_camera(event.position)
            accept_event()

    func _rotate_camera(pos: Vector2) -> void:
        if player == null or player.dead:
            return

        var movement := pos - last_position
        last_position = pos
        player.rotate_camera(movement.x)


var hero_class := "Warrior"
var hero_gender := "male"

var hp := 100
var max_hp := 100
var dead := false
var invulnerable := false

@export var speed := 7.0
@export var acceleration := 18.0
@export var braking := 24.0
@export var turn_speed := 10.0

@export var camera_sensitivity := 0.008
@export var respawn_delay := 2.0

var gravity := 20.0
var camera_pivot: Node3D
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

    var builder_script = preload(
        "res://scripts/CharacterBuilder.gd"
    )
    var builder = builder_script.new()
    var character_model: Node3D = builder.build_character(
        hero_class, hero_gender
    )
    character_model.name = "VisibleHeroModel"
    add_child(character_model)

    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 1.3, 0)
    add_child(camera_pivot)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 4.2, 7.5)
    camera.rotation_degrees = Vector3(-22, 0, 0)
    camera.current = true
    camera_pivot.add_child(camera)

    _make_touch_controls()


func _physics_process(delta: float) -> void:
    if dead:
        velocity = Vector3.ZERO
        return

    var input_dir := Vector2(
        Input.get_action_strength("move_right")
        - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back")
        - Input.get_action_strength("move_forward")
    )

    input_dir += joystick_input

    if input_dir.length_squared() > 1.0:
        input_dir = input_dir.normalized()

    # Convert movement into camera-relative directions.
    var camera_basis := camera_pivot.global_transform.basis
    var camera_forward := -camera_basis.z
    var camera_right := camera_basis.x

    camera_forward.y = 0.0
    camera_right.y = 0.0
    camera_forward = camera_forward.normalized()
    camera_right = camera_right.normalized()

    var direction := (
        camera_right * input_dir.x
        + camera_forward * -input_dir.y
    ).normalized()

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

    horizontal_velocity = horizontal_velocity.move_toward(
        target_velocity, movement_rate * delta
    )

    velocity.x = horizontal_velocity.x
    velocity.z = horizontal_velocity.y

    if direction.length_squared() > 0.001:
        var target_yaw := atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(
            rotation.y,
            target_yaw,
            minf(turn_speed * delta, 1.0)
        )

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    move_and_slide()


func rotate_camera(horizontal_drag: float) -> void:
    if camera_pivot == null:
        return

    camera_pivot.rotation.y -= (
        horizontal_drag * camera_sensitivity
    )


func take_damage(amount: int) -> void:
    if dead or invulnerable or amount <= 0:
        return

    hp = maxi(hp - amount, 0)

    if hp <= 0:
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

    # Right half of the screen rotates the camera.
    var camera_drag := CameraDragArea.new()
    camera_drag.name = "CameraDragArea"
    camera_drag.player = self
    camera_drag.set_anchors_preset(Control.PRESET_FULL_RECT)
    camera_drag.anchor_left = 0.5
    camera_drag.anchor_right = 1.0
    camera_drag.anchor_top = 0.0
    camera_drag.anchor_bottom = 1.0
    camera_drag.offset_left = 0.0
    camera_drag.offset_right = 0.0
    camera_drag.offset_top = 0.0
    camera_drag.offset_bottom = 0.0
    layer.add_child(camera_drag)

    # Left joystick stays above the camera drag area.
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
