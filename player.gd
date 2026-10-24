
extends CharacterBody3D
## Family Quest player controller — Godot 4.3
## Android movement, camera, health, death, and character animation.

signal health_changed(current_health: int, maximum_health: int)
signal player_died
signal player_revived

@export_group("Character")
@export_file("*.glb", "*.tscn") var character_scene_path: String = "res://artwork/FamilyQuest_RSDW_Male_Walk_Animated.glb"
@export var character_scale: float = 1.0
@export_range(-180.0, 180.0, 1.0) var model_forward_offset_degrees: float = 180.0
@export var model_local_position: Vector3 = Vector3.ZERO

@export_group("Movement")
@export var move_speed: float = 5.0
@export var acceleration: float = 18.0
@export var deceleration: float = 22.0
@export var rotation_speed: float = 12.0
@export var gravity_strength: float = 22.0
@export var jump_velocity: float = 5.0

@export_group("Camera")
@export var camera_distance: float = 4.0
@export var camera_height: float = 1.7
@export var camera_sensitivity: float = 0.006
@export_range(-70.0, -5.0, 1.0) var camera_min_pitch_degrees: float = -55.0
@export_range(5.0, 70.0, 1.0) var camera_max_pitch_degrees: float = 25.0

@export_group("Health")
@export var max_health: int = 100
@export var respawn_health: int = 100

@export_group("Procedural Walk Fallback")
@export var use_procedural_walk_fallback: bool = true
@export var fallback_walk_frequency: float = 8.0
@export var fallback_leg_swing_degrees: float = 28.0
@export var fallback_arm_swing_degrees: float = 22.0

var current_health: int = 100
var hero_class: String = "Warrior"
var hero_gender: String = "Male"
var is_dead: bool = false

var _move_input: Vector2 = Vector2.ZERO
var _camera_yaw: float = 0.0
var _camera_pitch: float = deg_to_rad(-12.0)
var _camera_touch_id: int = -1
var _joystick_touch_id: int = -1
var _joystick_center: Vector2 = Vector2.ZERO
var _joystick_radius: float = 72.0
var _walk_phase: float = 0.0

var _model_root: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _walk_animation_name: StringName = &""
var _idle_animation_name: StringName = &""
var _attack_animation_name: StringName = &""
var _death_animation_name: StringName = &""
var _using_real_walk_animation: bool = false
var _bone_indices: Dictionary = {}
var _bone_rest_rotations: Dictionary = {}

var _camera_pivot: Node3D
var _camera: Camera3D
var _hud_layer: CanvasLayer
var _joystick_base: Control
var _joystick_knob: Control
var _health_label: Label
var _joystick_active: bool = false


func _ready() -> void:
	max_health = maxi(1, max_health)
	current_health = clampi(current_health if current_health > 0 else max_health, 1, max_health)

	_create_collision()
	_load_character()
	_create_camera()
	_create_mobile_controls()
	_cache_humanoid_bones()
	_find_animations()

	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

		if not is_on_floor():
			velocity.y -= gravity_strength * delta
		else:
			velocity.y = 0.0

		move_and_slide()
		_update_camera()
		return

	var input_dir := _move_input.limit_length(1.0)
	var camera_basis := Basis(Vector3.UP, _camera_yaw)
	var world_move := camera_basis * Vector3(input_dir.x, 0.0, input_dir.y)
	world_move.y = 0.0

	if world_move.length_squared() > 1.0:
		world_move = world_move.normalized()

	var desired_x := world_move.x * move_speed
	var desired_z := world_move.z * move_speed
	var rate := acceleration if world_move.length_squared() > 0.001 else deceleration

	velocity.x = move_toward(velocity.x, desired_x, rate * delta)
	velocity.z = move_toward(velocity.z, desired_z, rate * delta)

	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	if world_move.length_squared() > 0.001:
		var target_yaw := atan2(-world_move.x, -world_move.z) + deg_to_rad(model_forward_offset_degrees)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(rotation_speed * delta, 0.0, 1.0))

	move_and_slide()

	var moving := Vector2(velocity.x, velocity.z).length() > 0.1
	_update_character_animation(delta, moving)
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch

		if touch.pressed:
			var screen_size := get_viewport().get_visible_rect().size

			if touch.position.x < screen_size.x * 0.48 and _joystick_touch_id == -1:
				_joystick_touch_id = touch.index
				_joystick_active = true
				_joystick_center = touch.position
				_update_joystick_visual(touch.position)
				_update_joystick_from_position(touch.position)

			elif touch.position.x >= screen_size.x * 0.48 and _camera_touch_id == -1:
				_camera_touch_id = touch.index
		else:
			if touch.index == _joystick_touch_id:
				_joystick_touch_id = -1
				_joystick_active = false
				_move_input = Vector2.ZERO
				_reset_joystick_visual()

			if touch.index == _camera_touch_id:
				_camera_touch_id = -1

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag

		if drag.index == _joystick_touch_id:
			_update_joystick_from_position(drag.position)
			_update_joystick_visual(drag.position)

		elif drag.index == _camera_touch_id:
			set_camera_touch_delta(drag.relative)

	elif event is InputEventKey and (event as InputEventKey).pressed:
		var key := event as InputEventKey
		if key.keycode == KEY_SPACE and is_on_floor() and not is_dead:
			velocity.y = jump_velocity


func set_virtual_joystick_input(direction: Vector2) -> void:
	_move_input = direction.limit_length(1.0)


func set_camera_touch_delta(delta: Vector2) -> void:
	_camera_yaw -= delta.x * camera_sensitivity
	_camera_pitch = clampf(
		_camera_pitch - delta.y * camera_sensitivity,
		deg_to_rad(camera_min_pitch_degrees),
		deg_to_rad(camera_max_pitch_degrees)
	)
	_apply_camera_rotation()


func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	_update_health_label()

	if current_health == 0:
		_die()


func damage(amount: int) -> void:
	take_damage(amount)


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	_update_health_label()


func revive(at_position: Vector3 = Vector3.INF) -> void:
	is_dead = false
	current_health = clampi(respawn_health, 1, max_health)
	velocity = Vector3.ZERO

	if at_position != Vector3.INF:
		global_position = at_position

	health_changed.emit(current_health, max_health)
	_update_health_label()

	if _animation_player:
		if _idle_animation_name != &"":
			_animation_player.play(_idle_animation_name)
		elif _walk_animation_name != &"":
			_animation_player.play(_walk_animation_name)
			_animation_player.seek(0.0, true)
			_animation_player.pause()

	player_revived.emit()


func set_hero_class(value: String) -> void:
	hero_class = value


func set_hero_gender(value: String) -> void:
	hero_gender = value


func _create_collision() -> void:
	var capsule := CollisionShape3D.new()
	capsule.name = "PlayerCollision"

	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.8

	capsule.shape = shape
	capsule.position.y = 0.9
	add_child(capsule)


func _load_character() -> void:
	if character_scene_path.is_empty() or not ResourceLoader.exists(character_scene_path):
		push_warning("Player character file not found: " + character_scene_path)
		return

	var packed := load(character_scene_path) as PackedScene
	if packed == null:
		push_warning("Player character file could not be loaded as a scene: " + character_scene_path)
		return

	_model_root = Node3D.new()
	_model_root.name = "CharacterVisual"
	add_child(_model_root)

	var instance := packed.instantiate()
	_model_root.add_child(instance)

	if instance is Node3D:
		var visual := instance as Node3D
		visual.position = model_local_position
		visual.scale = Vector3.ONE * character_scale

	_find_nodes(_model_root)


func _find_nodes(root: Node) -> void:
	if root is Skeleton3D and _skeleton == null:
		_skeleton = root as Skeleton3D

	if root is AnimationPlayer and _animation_player == null:
		_animation_player = root as AnimationPlayer

	for child in root.get_children():
		_find_nodes(child)


func _cache_humanoid_bones() -> void:
	_bone_indices.clear()
	_bone_rest_rotations.clear()

	if _skeleton == null:
		return

	for i in range(_skeleton.get_bone_count()):
		var bone_name := _skeleton.get_bone_name(i).to_lower()
		_bone_rest_rotations[i] = _skeleton.get_bone_rest(i).basis.get_rotation_quaternion()
		_register_bone_alias(i, bone_name)


func _register_bone_alias(index: int, bone_name: String) -> void:
	var aliases := {
		"thigh_l": ["thigh_l", "upperleg_l", "upper_leg_l", "upleg_l", "leftupleg", "left_thigh", "thighleft"],
		"thigh_r": ["thigh_r", "upperleg_r", "upper_leg_r", "upleg_r", "rightupleg", "right_thigh", "thighright"],
		"calf_l": ["calf_l", "lowerleg_l", "lower_leg_l", "shin_l", "leftleg", "left_calf"],
		"calf_r": ["calf_r", "lowerleg_r", "lower_leg_r", "shin_r", "rightleg", "right_calf"],
		"upperarm_l": ["upperarm_l", "upper_arm_l", "leftupperarm", "upperarmleft", "arm_l"],
		"upperarm_r": ["upperarm_r", "upper_arm_r", "rightupperarm", "upperarmright", "arm_r"],
		"lowerarm_l": ["lowerarm_l", "lower_arm_l", "forearm_l", "leftlowerarm"],
		"lowerarm_r": ["lowerarm_r", "lower_arm_r", "forearm_r", "rightlowerarm"],
		"pelvis": ["pelvis", "hips", "hip"],
		"spine": ["spine_01", "spine1", "spine", "spine_02"]
	}

	for category in aliases.keys():
		if _bone_indices.has(category):
			continue

		for alias in aliases[category]:
			if bone_name == alias or bone_name.ends_with("/" + alias) or bone_name.ends_with(alias):
				_bone_indices[category] = index
				break


func _find_animations() -> void:
	_walk_animation_name = &""
	_idle_animation_name = &""
	_attack_animation_name = &""
	_death_animation_name = &""
	_using_real_walk_animation = false

	if _animation_player == null:
		push_warning("No AnimationPlayer found inside the character GLB.")
		return

	var names := _animation_player.get_animation_list()

	# Prefer the actual full-body Walk clip in the supplied animated GLB.
	for anim_name in names:
		var lower_name := String(anim_name).to_lower()
		if lower_name == "walk" or lower_name.contains("walk_fwd") or lower_name.contains("walk_forward"):
			_walk_animation_name = StringName(anim_name)
			_using_real_walk_animation = true
			break

	# Fallback to any animation whose name contains walk or run.
	if _walk_animation_name == &"":
		for anim_name in names:
			var lower_name := String(anim_name).to_lower()
			if lower_name.contains("walk") or lower_name.contains("run"):
				_walk_animation_name = StringName(anim_name)
				_using_real_walk_animation = true
				break

	for anim_name in names:
		var lower_name := String(anim_name).to_lower()

		if _idle_animation_name == &"" and (lower_name.contains("idle") or lower_name.contains("stand")):
			_idle_animation_name = StringName(anim_name)

		if _attack_animation_name == &"" and (lower_name.contains("attack") or lower_name.contains("slash")):
			_attack_animation_name = StringName(anim_name)

		if _death_animation_name == &"" and (lower_name.contains("death") or lower_name.contains("die")):
			_death_animation_name = StringName(anim_name)

	if _walk_animation_name == &"":
		push_warning("No walk animation found. Available animations: " + str(names))
	else:
		print("Using full-body walk animation: ", _walk_animation_name)

		if _idle_animation_name != &"":
			_animation_player.play(_idle_animation_name)
		else:
			_animation_player.play(_walk_animation_name)
			_animation_player.seek(0.0, true)
			_animation_player.pause()


func _update_character_animation(delta: float, moving: bool) -> void:
	if _animation_player and _using_real_walk_animation and _walk_animation_name != &"":
		if moving:
			if _animation_player.current_animation != String(_walk_animation_name) or not _animation_player.is_playing():
				_animation_player.play(_walk_animation_name)
		elif _idle_animation_name != &"":
			if _animation_player.current_animation != String(_idle_animation_name):
				_animation_player.play(_idle_animation_name)
		else:
			# The supplied model has a Walk clip but may not have an Idle clip.
			# Pause at the first frame when standing still.
			if _animation_player.current_animation != String(_walk_animation_name):
				_animation_player.play(_walk_animation_name)

			_animation_player.seek(0.0, true)
			_animation_player.pause()

		return

	if use_procedural_walk_fallback and _skeleton:
		if moving:
			_walk_phase += delta * fallback_walk_frequency
		_apply_procedural_pose(_walk_phase if moving else 0.0)


func _apply_procedural_pose(phase: float) -> void:
	if _skeleton == null:
		return

	var swing := sin(phase) * deg_to_rad(fallback_leg_swing_degrees)
	var arm_swing := -sin(phase) * deg_to_rad(fallback_arm_swing_degrees)

	_apply_bone_swing("thigh_l", swing)
	_apply_bone_swing("thigh_r", -swing)
	_apply_bone_swing("calf_l", maxf(0.0, -sin(phase)) * deg_to_rad(22.0))
	_apply_bone_swing("calf_r", maxf(0.0, sin(phase)) * deg_to_rad(22.0))
	_apply_bone_swing("upperarm_l", arm_swing)
	_apply_bone_swing("upperarm_r", -arm_swing)


func _apply_bone_swing(category: String, angle: float) -> void:
	if _skeleton == null or not _bone_indices.has(category):
		return

	var bone_index: int = _bone_indices[category]
	var rest_rotation: Quaternion = _bone_rest_rotations.get(bone_index, Quaternion.IDENTITY)
	_skeleton.set_bone_pose_rotation(
		bone_index,
		rest_rotation * Quaternion(Vector3.RIGHT, angle)
	)


func _create_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	add_child(_camera_pivot)
	_camera_pivot.top_level = true
	_camera_pivot.global_position = global_position + Vector3(0.0, camera_height, 0.0)

	_camera = Camera3D.new()
	_camera.name = "PlayerCamera"
	_camera.position = Vector3(0.0, 0.0, camera_distance)
	_camera.current = true
	_camera_pivot.add_child(_camera)

	_apply_camera_rotation()


func _apply_camera_rotation() -> void:
	if _camera_pivot:
		_camera_pivot.rotation = Vector3(_camera_pitch, _camera_yaw, 0.0)


func _update_camera() -> void:
	if _camera_pivot:
		_camera_pivot.global_position = global_position + Vector3(0.0, camera_height, 0.0)
		_apply_camera_rotation()


func _create_mobile_controls() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "PlayerMobileHUD"
	add_child(_hud_layer)

	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(root)

	_joystick_base = Panel.new()
	_joystick_base.name = "JoystickBase"
	_joystick_base.custom_minimum_size = Vector2(150, 150)
	_joystick_base.size = Vector2(150, 150)
	_joystick_base.position = Vector2(28, -178)
	_joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_joystick_base.modulate = Color(0.8, 0.85, 0.95, 0.38)
	_joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_joystick_base)

	_joystick_knob = Panel.new()
	_joystick_knob.name = "JoystickKnob"
	_joystick_knob.custom_minimum_size = Vector2(58, 58)
	_joystick_knob.size = Vector2(58, 58)
	_joystick_knob.position = Vector2(46, 46)
	_joystick_knob.modulate = Color(0.95, 0.97, 1.0, 0.8)
	_joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joystick_base.add_child(_joystick_knob)

	_health_label = Label.new()
	_health_label.name = "HealthLabel"
	_health_label.position = Vector2(22, 18)
	_health_label.add_theme_font_size_override("font_size", 24)
	_health_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(_health_label)

	_update_health_label()


func _update_joystick_from_position(position_on_screen: Vector2) -> void:
	var offset := position_on_screen - _joystick_center

	if offset.length() > _joystick_radius:
		offset = offset.normalized() * _joystick_radius

	_move_input = Vector2(
		offset.x / _joystick_radius,
		offset.y / _joystick_radius
	).limit_length(1.0)


func _update_joystick_visual(position_on_screen: Vector2) -> void:
	if _joystick_base == null or _joystick_knob == null:
		return

	var screen_size := get_viewport().get_visible_rect().size
	var base_center := Vector2(103.0, screen_size.y - 103.0)
	var offset := position_on_screen - base_center

	if offset.length() > _joystick_radius:
		offset = offset.normalized() * _joystick_radius

	_joystick_knob.position = Vector2(46, 46) + offset


func _reset_joystick_visual() -> void:
	if _joystick_knob:
		_joystick_knob.position = Vector2(46, 46)


func _update_health_label() -> void:
	if _health_label:
		_health_label.text = "HP  %d / %d" % [current_health, max_health]


func _die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector3.ZERO

	if _animation_player and _death_animation_name != &"":
		_animation_player.play(_death_animation_name)

	player_died.emit()
