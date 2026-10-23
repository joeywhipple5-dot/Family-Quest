extends CharacterBody3D

var hp: int = 100
var max_hp: int = 100
var hero_class: String = "Warrior"
var hero_gender: String = "male"

var speed: float = 7.0
var gravity: float = 20.0

var game_camera: Camera3D


func _ready() -> void:
    # Make the player visible without CharacterBuilder.
    var body_mesh := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.45
    capsule_mesh.height = 1.8
    body_mesh.mesh = capsule_mesh
    body_mesh.position.y = 0.9

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.2, 0.45, 0.9)
    body_mesh.material_override = material
    add_child(body_mesh)

    # Add player collision.
    var collision := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.45
    capsule_shape.height = 1.8
    collision.shape = capsule_shape
    collision.position.y = 0.9
    add_child(collision)

    # Create a camera independent of the player rotation.
    game_camera = Camera3D.new()
    game_camera.name = "GameCamera"
    get_tree().root.add_child.call_deferred(game_camera)

    _position_camera()


func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector(
        "move_left",
        "move_right",
        "move_forward",
        "move_back"
    )

    var direction := Vector3(input_dir.x, 0, input_dir.y)

    if direction.length_squared() > 1.0:
        direction = direction.normalized()

    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    move_and_slide()


func _process(_delta: float) -> void:
    _position_camera()


func _position_camera() -> void:
    if not is_instance_valid(game_camera):
        return

    game_camera.global_position = (
        global_position + Vector3(0, 3.5, 7.0)
    )

    game_camera.look_at(
        global_position + Vector3(0, 1.0, 0),
        Vector3.UP
    )

    game_camera.current = true
