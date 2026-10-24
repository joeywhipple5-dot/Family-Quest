
extends CharacterBody3D

# =========================================================
# FAMILY QUEST - PLAYER CONTROLLER
# Godot 4.3 | Android | Third-person RPG
# =========================================================

@export_category("Hero")
@export var hero_class: String = "Warrior"
@export var hero_gender: String = "male"
@export var hero_model_path: String = "res://artwork/FamilyQuest_Walk_Animation_Fresh_Download.glb"

# GLB scale: adjust if the imported character is still too small/large.
@export var hero_model_scale: float = 1.0
@export var hero_model_offset: Vector3 = Vector3.ZERO

@export_category("Movement")
@export var move_speed: float = 4.5
@export var run_speed: float = 7.0
@export var gravity: float = 22.0
@export var turn_speed: float = 9.0

@export_category("Camera")
@export var camera_distance: float = 4.0
@export var camera_height: float = 1.8
@export var camera_sensitivity: float = 0.008
@export var camera_min_pitch: float = -0.65
@export var camera_max_pitch: float = 0.25

@export_category("Health")
@export var max_hp: int = 100

var hp: int = 100
var is_dead: bool = false

var hero_model: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer

var walk_animation: StringName = &""
var idle_animation: StringName = &""
var attack_animation: StringName = &""
var death_animation: StringName = &""

var camera_pivot: Node3D
var game_camera: Camera3D

var mobile_move_input: Vector2 = Vector2.ZERO
var camera_yaw: float = 0.0
var camera_pitch: float = -0.12

var joystick_layer: CanvasLayer
var joystick_base: Panel
var joystick_knob: Panel
var joystick_center: Vector2
var joystick_active: bool = false
var joystick_finger: int = -1
var camera_finger: int = -1
var joystick_radius: float = 65.0

var moving: bool = false
var animation_time: float = 0.0
var saved_bone_rotations: Dictionary = {}
var procedural_bones: Dictionary = {}


func _ready() -> void:
    hp = max_hp
    _create_collision()
    _load_hero_model()
    _create_camera()
    _find_animations()
    _create_mobile_joystick()
    add_to_group("player")


# =========================================================
# MODEL LOADING
# =========================================================

func _create_collision() -> void:
    var collision := CollisionShape3D.new()
    collision.name = "PlayerCollision"

    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.32
    capsule.height = 1.7

    collision.shape = capsule
    collision.position.y = 0.85
    add_child(collision)


func _load_hero_model() -> void:
    if not ResourceLoader.exists(hero_model_path):
        push_error("Family Quest: Model not found: " + hero_model_path)
        _create_fallback_model()
        return

    var packed := load(hero_model_path) as PackedScene
    if packed == null:
        push_error("Family Quest: GLB could not be loaded.")
        _create_fallback_model()
        return

    hero_model = packed.instantiate() as Node3D
    if hero_model == null:
        push_error("Family Quest: GLB root is not Node3D.")
        _create_fallback_model()
        return

    hero_model.name = "HeroModel"
    hero_model.position = hero_model_offset
    hero_model.scale = Vector3.ONE * hero_model_scale
    add_child(hero_model)

    skeleton = _find_skeleton(hero_model)

    if skeleton != null:
        _prepare_procedural_bones()

    print("Family Quest: Hero model loaded.")
    print("Family Quest: Skeleton found: ", skeleton != null)


func _find_skeleton(root: Node) -> Skeleton3D:
    if root is Skeleton3D:
        return root as Skeleton3D

    for child in root.get_children():
        var found := _find_skeleton(child)
        if found != null:
            return found

    return null


func _create_fallback_model() -> void:
    var mesh_instance := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.32
    capsule.height = 1.7
    mesh_instance.mesh = capsule
    mesh_instance.position.y = 0.85
    add_child(mesh_instance)


# =========================================================
# ANIMATIONS
# =========================================================

func _find_animations() -> void:
    if hero_model == null:
        return

    var players := hero_model.find_children(
        "*", "AnimationPlayer", true, false
    )

    for node in players:
        var candidate := node as AnimationPlayer
        if candidate == null:
            continue

        animation_player = candidate

        for clip in candidate.get_animation_list():
            var clip_name := String(clip).to_lower()

            if clip_name.contains("walk"):
                walk_animation = StringName(clip)
            elif clip_name.contains("idle"):
                idle_animation = StringName(clip)
            elif clip_name.contains("attack"):
                attack_animation = StringName(clip)
            elif clip_name.contains("death"):
                death_animation = StringName(clip)

        if walk_animation != &"":
            break

    if walk_animation != &"":
        print("Family Quest: Walk clip: ", walk_animation)
    else:
        push_warning(
            "No Walk animation clip found. Procedural movement will be attempted."
        )

    if idle_animation != &"":
        animation_player.play(idle_animation)


func _prepare_procedural_bones() -> void:
    if skeleton == null:
        return

    for i in range(skeleton.get_bone_count()):
        var bone_name := skeleton.get_bone_name(i).to_lower()

        var category := ""

        if bone_name.contains("thigh") or bone_name.contains("upperleg"):
            category = "leg"
        elif bone_name.contains("calf") or bone_name.contains("lowerleg"):
            category = "lower_leg"
        elif bone_name.contains("upperarm"):
            category = "arm"
        elif bone_name.contains("lowerarm") or bone_name.contains("forearm"):
            category = "lower_arm"

        if category != "":
            procedural_bones[i] = category
            saved_bone_rotations[i] = skeleton.get_bone_pose_rotation(i)


func _play_walk() -> void:
    if animation_player != null and walk_animation != &"":
        if animation_player.current_animation != walk_animation:
            animation_player.play(walk_animation)

        animation_player.speed_scale = 1.0


func _play_idle() -> void:
    if animation_player != null and idle_animation != &"":
        animation_player.play(idle_animation)


func play_attack_animation() -> void:
    if is_dead:
        return

    if animation_player != null and attack_animation != &"":
        animation_player.play(attack_animation)


func play_death_animation() -> void:
    if animation_player != null and death_animation != &"":
        animation_player.play(death_animation)


func _apply_procedural_walk(delta: float) -> void:
    if skeleton == null or procedural_bones.is_empty():
        return

    animation_time += delta * (8.0 if moving else 0.0)
    var swing := sin(animation_time) * 0.48

    for bone_index in procedural_bones:
        var category: String = procedural_bones[bone_index]
        var base_rotation: Quaternion = saved_bone_rotations[bone_index]
        var angle := 0.0

        match category:
            "leg":
                angle = swing if String(skeleton.get_bone_name(bone_index)).to_lower().contains("left") else -swing
            "lower_leg":
                angle = maxf(0.0, -swing) * 0.7 if String(skeleton.get_bone_name(bone_index)).to_lower().contains("left") else maxf(0.0, swing) * 0.7
            "arm":
                angle = -swing * 0.65 if String(skeleton.get_bone_name(bone_index)).to_lower().contains("left") else swing * 0.65
            "lower_arm":
                angle = 0.12

        var walk_rotation := Quaternion(Vector3.RIGHT, angle)
        skeleton.set_bone_pose_rotation(
            bone_index, base_rotation * walk_rotation
        )


func _reset_procedural_bones() -> void:
    if skeleton == null:
        return

    for bone_index in saved_bone_rotations:
        skeleton.set_bone_pose_rotation(
            int(bone_index), saved_bone_rotations[bone_index]
        )


# =========================================================
# THIRD-PERSON CAMERA
# =========================================================

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
    _update_camera()


func _update_camera() -> void:
    if camera_pivot == null:
        return

    camera_pitch = clampf(
        camera_pitch, camera_min_pitch, camera_max_pitch
    )

    camera_pivot.rotation = Vector3(
        camera_pitch, camera_yaw, 0.0
    )


# =========================================================
# VISIBLE AND FUNCTIONAL ANDROID JOYSTICK
# =========================================================

func _create_mobile_joystick() -> void:
    joystick_layer = CanvasLayer.new()
    joystick_layer.name = "MobileJoystickLayer"
    joystick_layer.layer = 10
    add_child(joystick_layer)

    joystick_base = Panel.new()
    joystick_base.name = "JoystickBase"
    joystick_base.custom_minimum_size = Vector2(150, 150)
    joystick_base.size = Vector2(150, 150)
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(0.08, 0.10, 0.12, 0.52)
    base_style.border_color = Color(0.85, 0.88, 0.90, 0.75)
    base_style.set_border_width_all(3)
    base_style.set_corner_radius_all(75)
    joystick_base.add_theme_stylebox_override("panel", base_style)
    joystick_layer.add_child(joystick_base)

    joystick_knob = Panel.new()
    joystick_knob.name = "JoystickKnob"
    joystick_knob.custom_minimum_size = Vector2(64, 64)
    joystick_knob.size = Vector2(64, 64)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var knob_style := StyleBoxFlat.new()
    knob_style.bg_color = Color(0.80, 0.84, 0.88, 0.80)
    knob_style.border_color = Color(1.0, 1.0, 1.0, 0.95)
    knob_style.set_border_width_all(2)
    knob_style.set_corner_radius_all(32)
    joystick_knob.add_theme_stylebox_override("panel", knob_style)
    joystick_layer.add_child(joystick_knob)

    _position_joystick()

    get_viewport().size_changed.connect(_position_joystick)


func _position_joystick() -> void:
    if joystick_base == null or joystick_knob == null:
        return

    var screen_size := get_viewport().get_visible_rect().size

    joystick_base.position = Vector2(
        28.0, screen_size.y - 178.0
    )

    joystick_center = joystick_base.position + Vector2(75.0, 75.0)

    joystick_knob.position = joystick_center - Vector2(32.0, 32.0)


func _update_joystick_visual(direction: Vector2) -> void:
    if joystick_knob == null:
        return

    var offset := direction.limit_length(1.0) * joystick_radius
    joystick_knob.position = joystick_center + offset - Vector2(32.0, 32.0)


# =========================================================
# INPUT
# =========================================================

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch

        if touch.pressed:
            if joystick_finger == -1 and _touch_is_on_joystick_area(touch.position):
                joystick_finger = touch.index
                joystick_active = true
                _process_joystick_touch(touch.position)
                get_viewport().set_input_as_handled()

            elif camera_finger == -1 and touch.position.x > get_viewport().get_visible_rect().size.x * 0.42:
                camera_finger = touch.index

        else:
            if touch.index == joystick_finger:
                joystick_finger = -1
                joystick_active = false
                mobile_move_input = Vector2.ZERO
                _update_joystick_visual(Vector2.ZERO)
                get_viewport().set_input_as_handled()

            if touch.index == camera_finger:
                camera_finger = -1

    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag

        if drag.index == joystick_finger:
            _process_joystick_touch(drag.position)
            get_viewport().set_input_as_handled()

        elif drag.index == camera_finger:
            camera_yaw -= drag.relative.x * camera_sensitivity
            camera_pitch -= drag.relative.y * camera_sensitivity
            _update_camera()


func _touch_is_on_joystick_area(position: Vector2) -> bool:
    var screen_size := get_viewport().get_visible_rect().size

    return (
        position.x < screen_size.x * 0.40
        and position.y > screen_size.y * 0.52
    )


func _process_joystick_touch(position: Vector2) -> void:
    var offset := position - joystick_center
    var direction := offset / joystick_radius

    mobile_move_input = direction.limit_length(1.0)
    _update_joystick_visual(mobile_move_input)


func set_virtual_joystick_input(direction: Vector2) -> void:
    mobile_move_input = direction.limit_length(1.0)


func set_camera_touch_delta(delta: Vector2) -> void:
    camera_yaw -= delta.x * camera_sensitivity
    camera_pitch -= delta.y * camera_sensitivity
    _update_camera()


# =========================================================
# MOVEMENT
# =========================================================

func _physics_process(delta: float) -> void:
    if is_dead:
        velocity.x = 0.0
        velocity.z = 0.0

        if not is_on_floor():
            velocity.y -= gravity * delta

        move_and_slide()
        return

    var input_direction := _get_movement_input()
    moving = input_direction.length() > 0.12

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif velocity.y < 0.0:
        velocity.y = 0.0

    if moving:
        var forward := -camera_pivot.global_basis.z
        var right := camera_pivot.global_basis.x

        forward.y = 0.0
        right.y = 0.0
        forward = forward.normalized()
        right = right.normalized()

        var direction := (
            right * input_direction.x
            + forward * -input_direction.y
        ).normalized()

        var speed := move_speed
        if Input.is_key_pressed(KEY_SHIFT):
            speed = run_speed

        velocity.x = direction.x * speed
        velocity.z = direction.z * speed

        var target_yaw := atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(
            rotation.y, target_yaw, minf(turn_speed * delta, 1.0)
        )

        _play_walk()
        _apply_procedural_walk(delta)

    else:
        velocity.x = move_toward(
            velocity.x, 0.0, move_speed * 8.0 * delta
        )
        velocity.z = move_toward(
            velocity.z, 0.0, move_speed * 8.0 * delta
        )

        _play_idle()
        _reset_procedural_bones()

    move_and_slide()


func _get_movement_input() -> Vector2:
    var keyboard := Input.get_vector(
        "move_left", "move_right", "move_forward", "move_back"
    )

    if keyboard.length() > 0.1:
        return keyboard

    return mobile_move_input


# =========================================================
# HEALTH, DAMAGE, DEATH, REVIVE
# =========================================================

func take_damage(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    hp = maxi(0, hp - amount)

    if hp == 0:
        is_dead = true
        velocity = Vector3.ZERO
        mobile_move_input = Vector2.ZERO
        play_death_animation()
        print("Family Quest: Hero defeated.")

    elif animation_player != null:
        for clip in animation_player.get_animation_list():
            if String(clip).to_lower().contains("hit"):
                animation_player.play(clip)
                break

    print("Hero HP: ", hp, "/", max_hp)


func heal(amount: int) -> void:
    if is_dead or amount <= 0:
        return

    hp = mini(max_hp, hp + amount)
    print("Hero HP: ", hp, "/", max_hp)


func revive() -> void:
    hp = max_hp
    is_dead = false
    velocity = Vector3.ZERO
    mobile_move_input = Vector2.ZERO
    moving = false
    _reset_procedural_bones()
    _play_idle()
    print("Family Quest: Hero revived.")
