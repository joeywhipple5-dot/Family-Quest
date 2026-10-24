
extends CharacterBody3D

# ==========================================
# FAMILY QUEST - PLAYER CONTROLLER
# Godot 4.3 | Android + Keyboard
# ==========================================

@export var hero_class: String = "Warrior"
@export var hero_gender: String = "male"

@export var max_hp: int = 100
@export var move_speed: float = 5.0
@export var run_speed: float = 8.0
@export var gravity: float = 22.0
@export var turn_speed: float = 10.0

@export var camera_distance: float = 6.0
@export var camera_height: float = 2.8
@export var camera_sensitivity: float = 0.008

@export var hero_model_path: String = \
"res://artwork/FamilyQuest_Walk_Animation_Fresh_Download.glb"

@export var hero_model_scale: float = 0.3
@export var hero_model_offset: Vector3 = Vector3.ZERO

var hp: int = 100
var is_dead: bool = false

var hero_model: Node3D
var animation_player: AnimationPlayer
var skeleton: Skeleton3D

var walk_animation: StringName = &""
var idle_animation: StringName = &""
var attack_animation: StringName = &""
var death_animation: StringName = &""

var mobile_move_input: Vector2 = Vector2.ZERO
var camera_yaw: float = 0.0
var camera_pitch: float = -0.15

var camera_pivot: Node3D
var game_camera: Camera3D

var joystick_finger: int = -1
var camera_finger: int = -1
var joystick_origin: Vector2 = Vector2.ZERO
var joystick_position: Vector2 = Vector2.ZERO

var joystick_radius: float = 90.0
var camera_drag_enabled: bool = true

var previous_movement: bool = false


func _ready() -> void:
    hp = max_hp

    _create_collision()
    _load_hero_model()
    _create_camera()
    _find_hero_animations()

    if walk_animation != &"":
        _play_idle_or_rest_pose()

    add_to_group("player")


# ==========================================
# CHARACTER MODEL
# ==========================================

func _create_collision() -> void:
    var collision := CollisionShape3D.new()
    collision.name = "PlayerCollision"

    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.8

    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)


func _load_hero_model() -> void:
    if not ResourceLoader.exists(hero_model_path):
        push_error("Family Quest: Hero GLB not found: " + hero_model_path)
        _create_fallback_model()
        return

    var packed_scene := load(hero_model_path) as PackedScene

    if packed_scene == null:
        push_error("Family Quest: Could not load hero GLB.")
        _create_fallback_model()
        return

    hero_model = packed_scene.instantiate() as Node3D

    if hero_model == null:
        push_error("Family Quest: GLB root is not a Node3D.")
        _create_fallback_model()
        return

    hero_model.name = "HeroModel"
    hero_model.position = hero_model_offset
    hero_model.scale = Vector3.ONE * hero_model_scale

    add_child(hero_model)

    skeleton = _find_skeleton(hero_model)

    print("Family Quest: Hero model loaded.")
    print("Family Quest: Skeleton found: ", skeleton != null)


func _find_skeleton(root: Node) -> Skeleton3D:
    if root is Skeleton3D:
        return root as Skeleton3D

    for child in root.get_children():
        var result := _find_skeleton(child)
        if result != null:
            return result

    return null


func _create_fallback_model() -> void:
    var mesh_instance := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()

    capsule.radius = 0.35
    capsule.height = 1.8

    mesh_instance.mesh = capsule
    mesh_instance.position.y = 0.9
    add_child(mesh_instance)


# ==========================================
# ANIMATION DISCOVERY
# ==========================================

func _find_hero_animations() -> void:
    animation_player = null
    walk_animation = &""
    idle_animation = &""
    attack_animation = &""
    death_animation = &""

    if hero_model == null:
        return

    var players := hero_model.find_children(
        "*", "AnimationPlayer", true, false
    )

    for item in players:
        var candidate := item as AnimationPlayer
        if candidate == null:
            continue

        animation_player = candidate

        for animation_name in candidate.get_animation_list():
            var lower_name := String(animation_name).to_lower()

            if lower_name.contains("walk"):
                walk_animation = StringName(animation_name)
            elif lower_name.contains("idle"):
                idle_animation = StringName(animation_name)
            elif lower_name.contains("attack"):
                attack_animation = StringName(animation_name)
            elif lower_name.contains("death"):
                death_animation = StringName(animation_name)

        if walk_animation != &"":
            break

    if animation_player == null:
        push_warning("Hero GLB has no AnimationPlayer.")
        return

    if walk_animation == &"":
        push_warning("No Walk animation found in the hero GLB.")
    else:
        print("Family Quest: Walk animation found: ", walk_animation)

    if idle_animation != &"":
        print("Family Quest: Idle animation found: ", idle_animation)

    if attack_animation != &"":
        print("Family Quest: Attack animation found: ", attack_animation)


func _play_idle_or_rest_pose() -> void:
    if animation_player == null:
        return

    if idle_animation != &"":
        animation_player.play(idle_animation)
    elif walk_animation != &"":
        # No idle clip exists in this GLB.
        # Return the Walk animation to its first frame.
        animation_player.play(walk_animation)
        animation_player.seek(0.0, true)
        animation_player.pause()


func _play_walk() -> void:
    if animation_player == null or walk_animation == &"":
        return

    if not animation_player.is_playing() \
    or animation_player.current_animation != walk_animation:
        animation_player.play(walk_animation)

    animation_player.speed_scale = 1.0


func _stop_walking() -> void:
    if animation_player == null:
        return

    if idle_animation != &"":
        animation_player.play(idle_animation)
    elif walk_animation != &"":
        animation_player.play(walk_animation)
        animation_player.seek(0.0, true)
        animation_player.pause()


func play_attack_animation() -> void:
    if is_dead or animation_player == null:
        return

    if attack_animation != &"":
        animation_player.play(attack_animation)


func play_death_animation() -> void:
    if animation_player == null:
        return

    if death_animation != &"":
        animation_player.play(death_animation)


# ==========================================
# CAMERA
# ==========================================

func _create_camera() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0.0, camera_height, 0.0)
    add_child(camera_pivot)

    game_camera = Camera3D.new()
    game_camera.name = "PlayerCamera"
    game_camera.position = Vector3(0.0, 0.0, camera_distance)
    game_camera.current = true
    camera_pivot.add_child(game_camera)

    camera_yaw = rotation.y
    _update_camera_rotation()


func _update_camera_rotation() -> void:
    if camera_pivot == null:
        return

    camera_pitch = clampf(camera_pitch, -0.65, 0.25)

    camera_pivot.rotation = Vector3(
        camera_pitch,
        camera_yaw,
        0.0
    )


# ==========================================
# MOVEMENT
# ==========================================

func _physics_process(delta: float) -> void:
    if is_dead:
        velocity.x = 0.0
        velocity.z = 0.0

        if not is_on_floor():
            velocity.y -= gravity * delta

        move_and_slide()
        return

    var move_input := _get_movement_input()
    var moving := move_input.length() > 0.12

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    if moving:
        var forward := -global_basis.z
        var right := global_basis.x

        # Camera-relative movement.
        if camera_pivot != null:
            forward = -camera_pivot.global_basis.z
            right = camera_pivot.global_basis.x

        forward.y = 0.0
        right.y = 0.0

        forward = forward.normalized()
        right = right.normalized()

        var direction := (
            right * move_input.x
            + forward * -move_input.y
        ).normalized()

        var current_speed := move_speed

        if Input.is_key_pressed(KEY_SHIFT):
            current_speed = run_speed

        velocity.x = direction.x * current_speed
        velocity.z = direction.z * current_speed

        # Face the direction of movement.
        var target_yaw := atan2(-direction.x, -direction.z)

        rotation.y = lerp_angle(
            rotation.y,
            target_yaw,
            minf(turn_speed * delta, 1.0)
        )

        _play_walk()
    else:
        velocity.x = move_toward(
            velocity.x, 0.0, move_speed * 8.0 * delta
        )
        velocity.z = move_toward(
            velocity.z, 0.0, move_speed * 8.0 * delta
        )

        if previous_movement:
            _stop_walking()

    previous_movement = moving
    move_and_slide()


func _get_movement_input() -> Vector2:
    var keyboard_input := Input.get_vector(
        "move_left",
        "move_right",
        "move_forward",
        "move_back"
    )

    if keyboard_input.length() > 0.1:
        return keyboard_input

    if mobile_move_input.length() > 0.1:
        return mobile_move_input

    return Vector2.ZERO


# ==========================================
# ANDROID TOUCH CONTROLS
# ==========================================

func set_virtual_joystick_input(direction: Vector2) -> void:
    mobile_move_input = direction.limit_length(1.0)


func set_camera_touch_delta(delta: Vector2) -> void:
    camera_yaw -= delta.x * camera_sensitivity
    camera_pitch -= delta.y * camera_sensitivity
    _update_camera_rotation()


func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        var screen_size := get_viewport().get_visible_rect().size

        if touch.pressed:
            if joystick_finger == -1 \
            and touch.position.x < screen_size.x * 0.35 \
            and touch.position.y > screen_size.y * 0.55:
                joystick_finger = touch.index
                joystick_origin = touch.position
                joystick_position = touch.position
                mobile_move_input = Vector2.ZERO

            elif camera_finger == -1 \
            and touch.position.x > screen_size.x * 0.35:
                camera_finger = touch.index

        else:
            if touch.index == joystick_finger:
                joystick_finger = -1
                mobile_move_input = Vector2.ZERO

            if touch.index == camera_finger:
                camera_finger = -1

    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag

        if drag.index == joystick_finger:
            var offset := drag.position - joystick_origin
            var limited := offset.limit_length(joystick_radius)

            joystick_position = joystick_origin + limited

            mobile_move_input = Vector2(
                limited.x / joystick_radius,
                limited.y / joystick_radius
            ).limit_length(1.0)

        elif drag.index == camera_finger and camera_drag_enabled:
            set_camera_touch_delta(drag.relative)


# ==========================================
# HEALTH / DAMAGE / DEATH
# ==========================================

func take_damage(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    hp = maxi(hp - amount, 0)

    if hp <= 0:
        hp = 0
        is_dead = true
        velocity = Vector3.ZERO
        mobile_move_input = Vector2.ZERO
        play_death_animation()
        print("Family Quest: Hero defeated.")
    elif animation_player != null:
        if animation_player.has_animation("Hit_Reaction"):
            animation_player.play("Hit_Reaction")

    _print_health()


func heal(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    hp = mini(hp + amount, max_hp)
    _print_health()


func revive() -> void:
    hp = max_hp
    is_dead = false
    velocity = Vector3.ZERO
    mobile_move_input = Vector2.ZERO
    previous_movement = false
    _play_idle_or_rest_pose()
    print("Family Quest: Hero revived.")


func _print_health() -> void:
    print("Hero HP: ", hp, "/", max_hp)
