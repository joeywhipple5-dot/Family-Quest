
extends CharacterBody3D

# =========================================================
# FAMILY QUEST - ANDROID PLAYER CONTROLLER
# Godot 4.3
# Left joystick = movement
# Right side = camera control
# =========================================================

@export_category("Hero")
@export var hero_class: String = "Warrior"
@export var hero_gender: String = "male"
@export var hero_model_path: String = "res://artwork/FamilyQuest_Walk_Animation_Fresh_Download.glb"
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
@export var camera_min_pitch: float = -0.55
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

# Joystick UI
var joystick_layer: CanvasLayer
var joystick_base: Panel
var joystick_knob: Panel
var joystick_center: Vector2
var joystick_radius: float = 55.0
var joystick_finger: int = -1
var camera_finger: int = -1

# Animation fallback
var animation_time: float = 0.0
var moving: bool = false
var procedural_bones: Dictionary = {}
var saved_bone_rotations: Dictionary = {}


func _ready() -> void:
    hp = max_hp
    _create_collision()
    _load_hero_model()
    _create_camera()
    _find_animations()
    _create_mobile_joystick()
    add_to_group("player")


# =========================================================
# COLLISION
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


# =========================================================
# LOAD CHARACTER
# =========================================================

func _load_hero_model() -> void:
    if not ResourceLoader.exists(hero_model_path):
        push_error("Hero model not found: " + hero_model_path)
        _create_fallback_model()
        return

    var packed := load(hero_model_path) as PackedScene

    if packed == null:
        push_error("Could not load hero GLB as PackedScene.")
        _create_fallback_model()
        return

    hero_model = packed.instantiate() as Node3D

    if hero_model == null:
        push_error("Hero GLB root is not Node3D.")
        _create_fallback_model()
        return

    hero_model.name = "HeroModel"
    hero_model.position = hero_model_offset
    hero_model.scale = Vector3.ONE * hero_model_scale
    add_child(hero_model)

    skeleton = _find_skeleton(hero_model)

    if skeleton != null:
        _prepare_procedural_bones()

    print("Hero model loaded: ", hero_model_path)
    print("Skeleton found: ", skeleton != null)


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
    capsule.radius = 0.32
    capsule.height = 1.7

    mesh_instance.mesh = capsule
    mesh_instance.position.y = 0.85
    add_child(mesh_instance)


# =========================================================
# ANIMATION DISCOVERY
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
        print("Walk clip found: ", walk_animation)
    else:
        push_warning("No Walk clip found. Trying procedural bone animation.")

    if idle_animation != &"":
        print("Idle clip found: ", idle_animation)


func _play_walk() -> void:
    if animation_player != null and walk_animation != &"":
        if animation_player.current_animation != walk_animation:
            animation_player.play(walk_animation)

        animation_player.speed_scale = 1.0


func _play_idle() -> void:
    if animation_player != null:
        if idle_animation != &"":
            if animation_player.current_animation != idle_animation:
                animation_player.play(idle_animation)
        elif walk_animation != &"":
            # A real idle clip is unavailable.
            # Pause at the first Walk frame instead of looping in place.
            animation_player.play(walk_animation)
            animation_player.seek(0.0, true)
            animation_player.pause()


func play_attack_animation() -> void:
    if is_dead:
        return

    if animation_player != null and attack_animation != &"":
        animation_player.play(attack_animation)


func play_death_animation() -> void:
    if animation_player != null and death_animation != &"":
        animation_player.play(death_animation)


# =========================================================
# PROCEDURAL WALK FALLBACK
# Used only if there is no Walk clip.
# =========================================================

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


func _apply_procedural_walk(delta: float) -> void:
    if skeleton == null or procedural_bones.is_empty():
        return

    # Never layer procedural rotations on top of a real Walk clip.
    if animation_player != null and walk_animation != &"":
        return

    if not moving:
        _reset_procedural_bones()
        return

    animation_time += delta * 8.0
    var swing := sin(animation_time) * 0.48

    for bone_index in procedural_bones:
        var bone_name := String(
            skeleton.get_bone_name(int(bone_index))
        ).to_lower()

        var category: String = procedural_bones[bone_index]
        var base_rotation: Quaternion = saved_bone_rotations[bone_index]
        var angle := 0.0

        var is_left := (
            bone_name.contains("left")
            or bone_name.begins_with("l_")
            or bone_name.begins_with("l ")
        )

        match category:
            "leg":
                angle = swing if is_left else -swing
            "lower_leg":
                angle = maxf(0.0, -swing) * 0.7 if is_left else maxf(0.0, swing) * 0.7
            "arm":
                angle = -swing * 0.65 if is_left else swing * 0.65
            "lower_arm":
                angle = 0.12

        var offset_rotation := Quaternion(Vector3.RIGHT, angle)

        skeleton.set_bone_pose_rotation(
            int(bone_index),
            base_rotation * offset_rotation
        )


func _reset_procedural_bones() -> void:
    if skeleton == null:
        return

    for bone_index in saved_bone_rotations:
        skeleton.set_bone_pose_rotation(
            int(bone_index),
            saved_bone_rotations[bone_index]
        )


# =========================================================
# CAMERA
# =========================================================

func _create_camera() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.name = "CameraPivot"
    add_child(camera_pivot)

    # Prevent the camera pivot inheriting the player's rotation.
    camera_pivot.top_level = true

    game_camera = Camera3D.new()
    game_camera.name = "PlayerCamera"
    game_camera.position = Vector3(0.0, 0.0, camera_distance)
    game_camera.current = true
    camera_pivot.add_child(game_camera)

    camera_yaw = rotation.y
    _update_camera()
    _follow_camera()


func _follow_camera() -> void:
    if camera_pivot == null:
        return

    camera_pivot.global_position = global_position + Vector3(
        0.0, camera_height, 0.0
    )


func _update_camera() -> void:
    if camera_pivot == null:
        return

    camera_pitch = clampf(
        camera_pitch, camera_min_pitch, camera_max_pitch
    )

    camera_pivot.global_rotation = Vector3(
        camera_pitch, camera_yaw, 0.0
    )


# =========================================================
# VISIBLE ANDROID JOYSTICK
# =========================================================

func _create_mobile_joystick() -> void:
    joystick_layer = CanvasLayer.new()
    joystick_layer.name = "MobileJoystickLayer"
    joystick_layer.layer = 10
    add_child(joystick_layer)

    joystick_base = Panel.new()
    joystick_base.name = "JoystickBase"
    joystick_base.size = Vector2(150.0, 150.0)
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var base_style := StyleBoxFlat.new()
    base_style.bg_color = Color(0.08, 0.10, 0.12, 0.55)
    base_style.border_color = Color(0.85, 0.88, 0.90, 0.8)
    base_style.set_border_width_all(3)
    base_style.set_corner_radius_all(75)
    joystick_base.add_theme_stylebox_override("panel", base_style)
    joystick_layer.add_child(joystick_base)

    joystick_knob = Panel.new()
    joystick_knob.name = "JoystickKnob"
    joystick_knob.size = Vector2(64.0, 64.0)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var knob_style := StyleBoxFlat.new()
    knob_style.bg_color = Color(0.8, 0.84, 0.88, 0.85)
    knob_style.border_color = Color.WHITE
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

    joystick_knob.position = (
        joystick_center + offset - Vector2(32.0, 32.0)
    )


# =========================================================
# TOUCH INPUT
# LEFT SIDE: MOVEMENT ONLY
# RIGHT SIDE: CAMERA ONLY
# =========================================================

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        var screen_size := get_viewport().get_visible_rect().size

        if touch.pressed:
            # Left side starts movement control only.
            if joystick_finger == -1 and _touch_is_on_left_side(touch.position):
                joystick_finger = touch.index
                _process_joystick_touch(touch.position)
                get_viewport().set_input_as_handled()

            # Right side starts camera control only.
            elif camera_finger == -1 and touch.position.x >= screen_size.x * 0.5:
                camera_finger = touch.index

        else:
            if touch.index == joystick_finger:
                joystick_finger = -1
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


func _touch_is_on_left_side(position: Vector2) -> bool:
    var screen_size := get_viewport().get_visible_rect().size

    return (
        position.x < screen_size.x * 0.45
        and position.y > screen_size.y * 0.48
    )


func _process_joystick_touch(position: Vector2) -> void:
    # Joystick touches never change camera_yaw or camera_pitch.
    var offset := position - joystick_center
    mobile_move_input = (offset / joystick_radius).limit_length(1.0)
    _update_joystick_visual(mobile_move_input)


func set_virtual_joystick_input(direction: Vector2) -> void:
    mobile_move_input = direction.limit_length(1.0)


func set_camera_touch_delta(delta: Vector2) -> void:
    camera_yaw -= delta.x * camera_sensitivity
    camera_pitch -= delta.y * camera_sensitivity
    _update_camera()


# =========================================================
# PLAYER MOVEMENT
# =========================================================

func _physics_process(delta: float) -> void:
    if is_dead:
        velocity.x = 0.0
        velocity.z = 0.0

        if not is_on_floor():
            velocity.y -= gravity * delta

        move_and_slide()
        _follow_camera()
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
            rotation.y,
            target_yaw,
            minf(turn_speed * delta, 1.0)
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
    _follow_camera()


func _get_movement_input() -> Vector2:
    var keyboard_input := Input.get_vector(
        "move_left",
        "move_right",
        "move_forward",
        "move_back"
    )

    if keyboard_input.length() > 0.1:
        return keyboard_input

    return mobile_move_input


# =========================================================
# HEALTH / DAMAGE / DEATH / REVIVE
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
