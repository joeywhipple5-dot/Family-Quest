
extends CharacterBody3D

var hero_class := "Warrior"
var hero_gender := "male"
var hp := 100

# Movement tuning
@export var speed := 7.0
@export var acceleration := 18.0
@export var braking := 24.0
@export var turn_speed := 10.0

var gravity := 20.0
var camera_pivot: Node3D


func _ready() -> void:
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.45
    shape.height = 1.8
    collision.shape = shape
    add_child(collision)

    # Build the selected hero.
    var builder_script = preload("res://scripts/CharacterBuilder.gd")
    var builder = builder_script.new()
    var character_model: Node3D = builder.build_character(
        hero_class, hero_gender
    )
    character_model.name = "VisibleHeroModel"
    add_child(character_model)

    # Third-person camera.
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
    # Read the existing touchscreen and keyboard actions.
    var input_dir := Vector2(
        Input.get_action_strength("move_right")
        - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_back")
        - Input.get_action_strength("move_forward")
    )

    # Prevent diagonal movement from being faster.
    if input_dir.length_squared() > 1.0:
        input_dir = input_dir.normalized()

    var direction := Vector3(input_dir.x, 0, input_dir.y)

    # Smoothly accelerate and brake.
    var horizontal_velocity := Vector2(velocity.x, velocity.z)
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

    # Turn gradually toward the movement direction.
    if direction.length_squared() > 0.001:
        var target_yaw := atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(
            rotation.y,
            target_yaw,
            minf(turn_speed * delta, 1.0)
        )

    # Gravity and ground handling.
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    move_and_slide()


func _make_touch_controls() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    _touch_button(layer, "◀", Vector2(24, 590), "move_left")
    _touch_button(layer, "▶", Vector2(188, 590), "move_right")
    _touch_button(layer, "▲", Vector2(106, 510), "move_forward")
    _touch_button(layer, "▼", Vector2(106, 630), "move_back")


func _touch_button(
    layer: CanvasLayer,
    label: String,
    pos: Vector2,
    action: String
) -> void:
    var button := Button.new()
    button.text = label
    button.position = pos
    button.size = Vector2(78, 70)

    button.button_down.connect(
        func(): Input.action_press(action)
    )
    button.button_up.connect(
        func(): Input.action_release(action)
    )

    layer.add_child(button)
