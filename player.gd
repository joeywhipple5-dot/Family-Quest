
extends CharacterBody3D

# =========================================================
# FAMILY QUEST - PLAYER CONTROLLER
# Godot 4.3 - Android
# =========================================================

var hp: int = 100
var max_hp: int = 100

var hero_class: String = "Warrior"
var hero_gender: String = "male"

@export var move_speed: float = 7.0
@export var run_speed: float = 10.0
@export var gravity: float = 22.0
@export var camera_sensitivity: float = 0.008
@export var camera_distance: float = 6.0
@export var camera_height: float = 2.8

# Change this if your GLB filename changes.
@export var hero_model_path: String = "res://artwork/FamilyQuest_Warrior_Hero_Rigged-2.glb"

# Adjust these if the imported model is too large or too small.
@export var hero_model_scale: float = 1.0
@export var hero_model_offset: Vector3 = Vector3.ZERO

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

var hero_visual: Node3D
var animation_player: AnimationPlayer

var is_attacking: bool = false
var is_dead: bool = false

var idle_animation: StringName = &""
var walk_animation: StringName = &""
var run_animation: StringName = &""
var attack_animation: StringName = &""
var death_animation: StringName = &""

var attack_timer: float = 0.0
var attack_duration: float = 0.65


func _ready() -> void:
	hp = max_hp

	_load_hero_model()
	_create_collision()
	_create_camera()
	_create_touch_controls()

	_update_camera()

	if idle_animation != &"":
		_play_animation(idle_animation)


# =========================================================
# LOAD HERO MODEL
# =========================================================

func _load_hero_model() -> void:
	if not ResourceLoader.exists(hero_model_path):
		push_warning("Hero model not found: " + hero_model_path)
		_create_fallback_visual()
		return

	var resource: Resource = load(hero_model_path)

	if resource == null or not resource is PackedScene:
		push_warning("Hero model could not be loaded as a PackedScene.")
		_create_fallback_visual()
		return

	var packed_model: PackedScene = resource as PackedScene
	var instance: Node = packed_model.instantiate()

	if not instance is Node3D:
		push_warning("Hero model root is not a Node3D.")
		instance.queue_free()
		_create_fallback_visual()
		return

	hero_visual = instance as Node3D
	hero_visual.name = "HeroVisual"
	add_child(hero_visual)

	hero_visual.position = hero_model_offset
	hero_visual.scale = Vector3.ONE * hero_model_scale

	_find_hero_animations()

	print("Family Quest hero model loaded: ", hero_model_path)

	if animation_player == null:
		print("No AnimationPlayer found in the hero model.")

	if idle_animation == &"":
		print("No idle animation found.")


# =========================================================
# FALLBACK VISUAL
# Used only if the model cannot be loaded.
# =========================================================

func _create_fallback_visual() -> void:
	hero_visual = Node3D.new()
	hero_visual.name = "FallbackHero"
	add_child(hero_visual)

	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.4
	body_mesh.height = 1.7

	var body := MeshInstance3D.new()
	body.name = "FallbackBody"
	body.mesh = body_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.35, 0.85)
	body.material_override = material
	body.position.y = 0.9

	hero_visual.add_child(body)

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46

	var head := MeshInstance3D.new()
	head.name = "FallbackHead"
	head.mesh = head_mesh
	head.material_override = material
	head.position.y = 1.85

	hero_visual.add_child(head)


# =========================================================
# COLLISION
# =========================================================

func _create_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "PlayerCollision"

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8

	collision.shape = capsule
	collision.position.y = 0.9

	add_child(collision)


# =========================================================
# CAMERA
# =========================================================

func _create_camera() -> void:
	game_camera = Camera3D.new()
	game_camera.name = "GameCamera"
	game_camera.current = true
	game_camera.fov = 75.0
	add_child(game_camera)


func _update_camera() -> void:
	if game_camera == null:
		return

	var target := global_position + Vector3.UP * camera_height

	var horizontal_distance := camera_distance * cos(camera_pitch)
	var vertical_distance := camera_distance * sin(camera_pitch)

	var offset := Vector3(
		sin(camera_yaw) * horizontal_distance,
		vertical_distance,
		cos(camera_yaw) * horizontal_distance
	)

	game_camera.global_position = target + offset
	game_camera.look_at(target, Vector3.UP)


# =========================================================
# MOVEMENT
# =========================================================

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0.0
		velocity.z = 0.0

		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0

		move_and_slide()
		return

	if attack_timer > 0.0:
		attack_timer -= delta

		if attack_timer <= 0.0:
			is_attacking = false
			_update_movement_animation()

	var input_direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if joystick_active:
		input_direction = joystick_vector

	var camera_forward := Vector3(
		-sin(camera_yaw),
		0.0,
		-cos(camera_yaw)
	).normalized()

	var camera_right := Vector3(
		cos(camera_yaw),
		0.0,
		-sin(camera_yaw)
	).normalized()

	var move_direction := (
		camera_right * input_direction.x
		+ camera_forward * -input_direction.y
	)

	if move_direction.length() > 1.0:
		move_direction = move_direction.normalized()

	var current_speed := move_speed

	if Input.is_action_pressed("sprint"):
		current_speed = run_speed

	if move_direction.length() > 0.05:
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed

		if hero_visual != null and not is_attacking:
			hero_visual.rotation.y = atan2(
				move_direction.x,
				move_direction.z
			)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	_update_movement_animation()


func _process(_delta: float) -> void:
	_update_camera()


# =========================================================
# ANIMATION DISCOVERY
# =========================================================

func _find_hero_animations() -> void:
	if hero_visual == null:
		return

	var players := hero_visual.find_children(
		"*",
		"AnimationPlayer",
		true,
		false
	)

	if players.size() > 0:
		animation_player = players[0] as AnimationPlayer

	if animation_player == null:
		return

	if not animation_player.animation_finished.is_connected(
		_on_animation_finished
	):
		animation_player.animation_finished.connect(
			_on_animation_finished
		)

	var animation_names := animation_player.get_animation_list()

	print("Hero animations found: ", animation_names)

	for animation_name in animation_names:
		var anim_lower := String(animation_name).to_lower()

		if idle_animation == &"":
			if anim_lower.contains("idle") \
			or anim_lower.contains("stand"):
				idle_animation = animation_name

		if walk_animation == &"":
			if anim_lower.contains("walk") \
			or anim_lower.contains("walking"):
				walk_animation = animation_name

		if run_animation == &"":
			if anim_lower.contains("run") \
			or anim_lower.contains("running") \
			or anim_lower.contains("sprint"):
				run_animation = animation_name

		if attack_animation == &"":
			if anim_lower.contains("attack") \
			or anim_lower.contains("slash") \
			or anim_lower.contains("swing"):
				attack_animation = animation_name

		if death_animation == &"":
			if anim_lower.contains("death") \
			or anim_lower.contains("die") \
			or anim_lower.contains("defeat"):
				death_animation = animation_name


func _play_animation(animation_name: StringName) -> void:
	if animation_player == null:
		return

	if animation_name == &"":
		return

	if not animation_player.has_animation(animation_name):
		return

	if animation_player.current_animation == animation_name \
	and animation_player.is_playing():
		return

	animation_player.play(animation_name)


# =========================================================
# MOVEMENT ANIMATIONS
# =========================================================

func _update_movement_animation() -> void:
	if is_dead or is_attacking:
		return

	if animation_player == null:
		return

	var horizontal_speed := Vector2(
		velocity.x,
		velocity.z
	).length()

	if horizontal_speed < 0.2:
		if idle_animation != &"":
			_play_animation(idle_animation)
	elif horizontal_speed > move_speed * 1.1:
		if run_animation != &"":
			_play_animation(run_animation)
		elif walk_animation != &"":
			_play_animation(walk_animation)
	else:
		if walk_animation != &"":
			_play_animation(walk_animation)
		elif run_animation != &"":
			_play_animation(run_animation)


# =========================================================
# ATTACK
# Call this from main.gd when the player attacks.
# =========================================================

func play_attack_animation() -> void:
	if is_dead or is_attacking:
		return

	is_attacking = true
	attack_timer = attack_duration

	if animation_player != null and attack_animation != &"":
		if animation_player.has_animation(attack_animation):
			var animation := animation_player.get_animation(
				attack_animation
			)

			if animation != null and animation.length > 0.0:
				attack_timer = animation.length

			_play_animation(attack_animation)


func _on_animation_finished(_animation_name: StringName) -> void:
	if is_dead:
		return

	if is_attacking:
		is_attacking = false
		attack_timer = 0.0
		_update_movement_animation()


# =========================================================
# DAMAGE AND DEATH
# =========================================================

func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	hp = clampi(hp - amount, 0, max_hp)

	if hp <= 0:
		play_death_animation()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	hp = clampi(hp + amount, 0, max_hp)


func play_death_animation() -> void:
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	attack_timer = 0.0

	velocity = Vector3.ZERO

	if animation_player != null and death_animation != &"":
		if animation_player.has_animation(death_animation):
			_play_animation(death_animation)

	print("Hero defeated. HP: ", hp)


# =========================================================
# ANDROID TOUCH INPUT
# =========================================================

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch

		if touch.pressed:
			if touch.position.x < get_viewport().get_visible_rect().size.x * 0.45:
				joystick_active = true
				joystick_pointer = touch.index
				joystick_origin = touch.position
				joystick_vector = Vector2.ZERO
				_update_joystick_visual()
			else:
				camera_pointer = touch.index
				camera_last_position = touch.position
		else:
			if touch.index == joystick_pointer:
				joystick_active = false
				joystick_pointer = -1
				joystick_vector = Vector2.ZERO
				_update_joystick_visual()

			if touch.index == camera_pointer:
				camera_pointer = -1

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag

		if drag.index == joystick_pointer:
			var offset := drag.position - joystick_origin
			var radius := 65.0

			joystick_vector = (offset / radius).limit_length(1.0)
			_update_joystick_visual()

		elif drag.index == camera_pointer:
			var delta_position := drag.position - camera_last_position

			camera_yaw -= delta_position.x * camera_sensitivity
			camera_pitch -= delta_position.y * camera_sensitivity

			camera_pitch = clampf(camera_pitch, -0.8, 0.25)
			camera_last_position = drag.position


# =========================================================
# ON-SCREEN JOYSTICK VISUAL
# =========================================================

func _create_touch_controls() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TouchControls"
	add_child(layer)

	var ui := Control.new()
	ui.name = "JoystickUI"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)

	joystick_base = Control.new()
	joystick_base.name = "JoystickBase"
	joystick_base.custom_minimum_size = Vector2(130, 130)
	joystick_base.position = Vector2(35, 0)
	joystick_base.anchor_top = 1.0
	joystick_base.anchor_bottom = 1.0
	joystick_base.offset_top = -165
	joystick_base.offset_bottom = -35
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(joystick_base)

	var base_circle := ColorRect.new()
	base_circle.name = "BaseCircle"
	base_circle.size = Vector2(130, 130)
	base_circle.color = Color(0.1, 0.1, 0.1, 0.35)
	base_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(base_circle)

	joystick_knob = Control.new()
	joystick_knob.name = "JoystickKnob"
	joystick_knob.position = Vector2(40, 40)
	joystick_knob.custom_minimum_size = Vector2(50, 50)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.add_child(joystick_knob)

	var knob_circle := ColorRect.new()
	knob_circle.name = "KnobCircle"
	knob_circle.size = Vector2(50, 50)
	knob_circle.color = Color(0.8, 0.8, 0.8, 0.65)
	knob_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_knob.add_child(knob_circle)


func _update_joystick_visual() -> void:
	if joystick_knob == null:
		return

	var center := Vector2(40, 40)
	var offset := joystick_vector * 35.0

	joystick_knob.position = center + offset
