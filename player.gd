
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

@export var camera_follow_speed := 5.0
@export var camera_distance := 6.0
@export var camera_height := 3.0
@export var camera_look_height := 1.2
@export var respawn_delay := 2.0

var gravity := 20.0
var camera: Camera3D
var joystick_input := Vector2.ZERO
var spawn_position := Vector3(0, 1, 4)
var camera_offset := Vector3.ZERO


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

    # Camera is independent of player rotation.
    # This prevents sudden camera spins when the hero turns.
    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.position = Vector3.ZERO
    camera.current = true
    get_tree().root.add_child.call_deferred(camera)

    camera_offset = Vector3(0, camera_height, camera_distance)

    _make_touch_controls()


func _process(delta: float) -> void:
    if not is_instance_valid(camera):
        return

    # Follow behind the direction the hero faces.
    var behind := global_transform.basis.z.normalized()
    var target_position := global_position
    target_position += Vector3.UP * camera_height
    target_position += behind * camera_distance

    var follow_weight := 1.0 - exp(
        -camera_follow_speed * delta
    )

    camera.global_position = camera.global_position.lerp(
        target_position, follow_weight
    )

    var look_target := global_position
    look_target.y += camera_look_height

    camera.look_at(look_target, Vector3.UP)


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

    # Movement is relative to the hero's facing direction.
    var forward := -global_transform.basis.z
    var right := global_transform.basis.x

    forward.y = 0.0
    right.y = 0.0
    forward = forward.normalized()
    right = right.normalized()

    var direction := (
        right * input_dir.x
        + forward * -input_dir.y
    )

    if direction.length_squared() > 1.0:
        direction = direction.normalized()

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

        # Turn smoothly toward the movement direction.
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
