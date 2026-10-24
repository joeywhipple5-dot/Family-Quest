
extends CharacterBody3D

signal health_changed(current_health: int, maximum_health: int)
signal player_died
signal player_revived

@export_group("Character")
@export_file("*.glb", "*.tscn")
var character_scene_path: String = "res://artwork/FamilyQuest_Walk_Animation_Fresh_Download.glb"
@export var character_scale: float = 1.0
@export_range(-180.0, 180.0, 1.0)
var model_forward_offset_degrees: float = 180.0
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
@export_range(-70.0, -5.0, 1.0)
var camera_min_pitch_degrees: float = -55.0
@export_range(5.0, 70.0, 1.0)
var camera_max_pitch_degrees: float = 25.0

@export_group("Health")
@export var max_health: int = 100
@export var respawn_health: int = 100

var current_health: int = 100
var hero_class: String = "Warrior"
var hero_gender: String = "Male"
var is_dead: bool = false

var _move_input := Vector2.ZERO
var _camera_yaw := 0.0
var _camera_pitch := deg_to_rad(-12.0)
var _camera_touch_id := -1
var _joystick_touch_id := -1
var _joystick_center := Vector2.ZERO
var _joystick_radius := 65.0

var _model_root: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer

var _walk_animation_name: StringName = &""
var _idle_animation_name: StringName = &""
var _death_animation_name: StringName = &""

var _camera_pivot: Node3D
var _camera: Camera3D
var _hud_layer: CanvasLayer
var _joystick_base: Panel
var _joystick_knob: Panel
var _health_label: Label


func _ready() -> void:
	max_health = maxi(1, max_health)
	respawn_health = clampi(respawn_health, 1, max_health)
	current_health = max_health

	_create_collision()
	_load_character()
	_create_camera()
	_create_mobile_controls()
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
	world_move = world_move.limit_length(1.0)

	var rate := acceleration
	if world_move.length_squared() <= 0.001:
		rate = deceleration

	velocity.x = move_toward(velocity.x, world_move.x * move_speed, rate * delta)
	velocity.z = move_toward(velocity.z, world_move.z * move_speed, rate * delta)

	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	if world_move.length_squared() > 0.001:
		var target_yaw := atan2(-world_move.x, -world_move.z)
		target_yaw += deg_to_rad(model_forward_offset_degrees)

		rotation.y = lerp_angle(
			rotation.y,
			target_yaw,
			clampf(rotation_speed * delta, 0.0, 1.0)
		)

	move_and_slide()

	_update_character_animation(world_move.length() > 0.1)
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch

		if touch.pressed:
			var screen_size := get_viewport().get_visible_rect().size

			if touch.position.x < screen_size.x * 0.48:
				if _joystick_touch_id == -1:
					_joystick_touch_id = touch.index
					_joystick_center = _get_joystick_screen_center()
					_update_joystick_from_position(touch.position)
					_update_joystick_visual(touch.position)
			elif _camera_touch_id == -1:
				_camera_touch_id = touch.index
		else:
			if touch.index == _joystick_touch_id:
				_joystick_touch_id = -1
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

	elif event is InputEventKey:
		var key := event as InputEventKey

		if key.pressed and not key.echo:
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

	if _animation_player != null:
		if _idle_animation_name != &"":
			_animation_player.play(_idle_animation_name)
		elif _walk_animation_name != &"":
			_animation_player.play(_walk_animation_name)
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
	if not ResourceLoader.exists(character_scene_path):
		push_warning("Player model not found: " + character_scene_path)
		return

	var resource := load(character_scene_path)
	var packed := resource as PackedScene

	if packed == null:
		push_warning("Could not load character as a PackedScene: " + character_scene_path)
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

	_find_character_nodes(_model_root)


func _find_character_nodes(node: Node) -> void:
	# Find an AnimationPlayer first. The skeleton is searched separately
	# so we can report what the imported model actually contains.
	if node is AnimationPlayer and _animation_player == null:
		_animation_player = node as AnimationPlayer

	if node is Skeleton3D and _skeleton == null:
		_skeleton = node as Skeleton3D

	for child in node.get_children():
		_find_character_nodes(child)


func _find_animations() -> void:
	_walk_animation_name = &""
	_idle_animation_name = &""
	_death_animation_name = &""

	if _animation_player == null:
		push_warning("No AnimationPlayer found in character model.")
		return

	var animations := _animation_player.get_animation_list()

	for animation_name in animations:
		var animation_text := String(animation_name).to_lower()

		if _walk_animation_name == &"" and animation_text.contains("walk"):
			_walk_animation_name = StringName(animation_name)

		if _idle_animation_name == &"" and (
			animation_text.contains("idle")
			or animation_text.contains("stand")
		):
			_idle_animation_name = StringName(animation_name)

		if _death_animation_name == &"" and (
			animation_text.contains("death")
			or animation_text.contains("die")
		):
			_death_animation_name = StringName(animation_name)

	print("=== CHARACTER ANIMATION DIAGNOSTICS ===")
	print("Model: ", _model_root.get_path() if _model_root else "MISSING")
	print("Skeleton: ", _skeleton.get_path() if _skeleton else "MISSING")
	print("AnimationPlayer: ", _animation_player.get_path())
	print("Animation root: ", _animation_player.root_node)
	print("Available animations: ", animations)

	if _walk_animation_name != &"":
		var walk := _animation_player.get_animation(_walk_animation_name)
		print("Walk animation: ", _walk_animation_name)
		print("Walk length: ", walk.length)
		print("Walk track count: ", walk.get_track_count())

		var leg_tracks := 0

		for i in range(walk.get_track_count()):
			var track_path := walk.track_get_path(i)
			print("Track ", i, ": ", track_path)

			var path_text := String(track_path).to_lower()
			if path_text.contains("calf") or path_text.contains("thigh"):
				leg_tracks += 1

		print("Thigh/calf track count: ", leg_tracks)

		if walk.length > 0.0:
			_animation_player.play(_walk_animation_name)
			_animation_player.seek(0.0, true)

			if _idle_animation_name == &"":
				_animation_player.pause()
	else:
		push_warning("No walk animation found. Available animations: " + str(animations))

	if _skeleton == null:
		push_warning("No Skeleton3D found in the imported character.")


func _update_character_animation(moving: bool) -> void:
	if _animation_player == null:
		return

	if moving:
		if _walk_animation_name == &"":
			return

		if (
			_animation_player.current_animation != String(_walk_animation_name)
			or not _animation_player.is_playing()
		):
			_animation_player.play(_walk_animation_name)

	elif _idle_animation_name != &"":
		if _animation_player.current_animation != String(_idle_animation_name):
			_animation_player.play(_idle_animation_name)

	elif _walk_animation_name != &"":
		if (
			_animation_player.current_animation != String(_walk_animation_name)
			or _animation_player.is_playing()
		):
			_animation_player.play(_walk_animation_name)
			_animation_player.seek(0.0, true)
			_animation_player.pause()


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
	if _camera_pivot != null:
		_camera_pivot.rotation = Vector3(_camera_pitch, _camera_yaw, 0.0)


func _update_camera() -> void:
	if _camera_pivot != null:
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
	_joystick_base.size = Vector2(150, 150)
	_joystick_base.position = Vector2(28, -178)
	_joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.12, 0.18, 0.22, 0.58)
	base_style.corner_radius_top_left = 75
	base_style.corner_radius_top_right = 75
	base_style.corner_radius_bottom_left = 75
	base_style.corner_radius_bottom_right = 75
	base_style.border_width_left = 3
	base_style.border_width_top = 3
	base_style.border_width_right = 3
	base_style.border_width_bottom = 3
	base_style.border_color = Color(0.85, 0.92, 1.0, 0.8)

	_joystick_base.add_theme_stylebox_override("panel", base_style)
	root.add_child(_joystick_base)

	_joystick_knob = Panel.new()
	_joystick_knob.name = "JoystickKnob"
	_joystick_knob.size = Vector2(58, 58)
	_joystick_knob.position = Vector2(46, 46)
	_joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.30, 0.62, 0.82, 0.95)
	knob_style.corner_radius_top_left = 29
	knob_style.corner_radius_top_right = 29
	knob_style.corner_radius_bottom_left = 29
	knob_style.corner_radius_bottom_right = 29
	knob_style.border_width_left = 2
	knob_style.border_width_top = 2
	knob_style.border_width_right = 2
	knob_style.border_width_bottom = 2
	knob_style.border_color = Color.WHITE

	_joystick_knob.add_theme_stylebox_override("panel", knob_style)
	_joystick_base.add_child(_joystick_knob)

	_health_label = Label.new()
	_health_label.name = "HealthLabel"
	_health_label.position = Vector2(22, 18)
	_health_label.add_theme_font_size_override("font_size", 24)
	_health_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(_health_label)

	_update_health_label()


func _get_joystick_screen_center() -> Vector2:
	var screen_size := get_viewport().get_visible_rect().size
	return Vector2(103.0, screen_size.y - 103.0)


func _update_joystick_from_position(screen_position: Vector2) -> void:
	var offset := screen_position - _joystick_center
	offset = offset.limit_length(_joystick_radius)

	_move_input = Vector2(
		offset.x / _joystick_radius,
		offset.y / _joystick_radius
	).limit_length(1.0)


func _update_joystick_visual(screen_position: Vector2) -> void:
	if _joystick_knob == null:
		return

	var offset := screen_position - _get_joystick_screen_center()
	offset = offset.limit_length(_joystick_radius)
	_joystick_knob.position = Vector2(46.0, 46.0) + offset


func _reset_joystick_visual() -> void:
	if _joystick_knob != null:
		_joystick_knob.position = Vector2(46.0, 46.0)


func _update_health_label() -> void:
	if _health_label != null:
		_health_label.text = "HP  %d / %d" % [current_health, max_health]


func _die() -> void:
	if is_dead:
		return

	is_dead = true
	current_health = 0
	velocity = Vector3.ZERO

	if _animation_player != null:
		if _death_animation_name != &"":
			_animation_player.play(_death_animation_name)
		elif _idle_animation_name != &"":
			_animation_player.play(_idle_animation_name)
		elif _walk_animation_name != &"":
			_animation_player.pause()

	player_died.emit()
