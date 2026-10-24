func _find_animations() -> void:
	_walk_animation_name = &""
	_idle_animation_name = &""
	_death_animation_name = &""

	if _animation_player == null:
		push_error("Family Quest: No AnimationPlayer found.")
		return

	if _model_instance != null:
		_animation_player.root_node = _animation_player.get_path_to(
			_model_instance
		)

	var animations: PackedStringArray = (
		_animation_player.get_animation_list()
	)

	for animation_name in animations:
		var anim_text := String(animation_name).to_lower()

		if anim_text.contains("walk"):
			_walk_animation_name = StringName(animation_name)
		elif anim_text.contains("idle") or anim_text.contains("stand"):
			_idle_animation_name = StringName(animation_name)
		elif anim_text.contains("death") or anim_text.contains("die"):
			_death_animation_name = StringName(animation_name)

	print("=== FAMILY QUEST ANIMATION CHECK ===")
	print("Model: ", _model_instance)
	print("Animation player: ", _animation_player.get_path())
	print("Animation root: ", _animation_player.root_node)
	print("Available animations: ", animations)

	if _walk_animation_name == &"":
		push_error("Family Quest: No walk animation found.")
		return

	var walk: Animation = _animation_player.get_animation(
		_walk_animation_name
	)

	print("Walk animation: ", _walk_animation_name)
	print("Walk track count: ", walk.get_track_count())

	for i in range(walk.get_track_count()):
		var track_path: NodePath = walk.track_get_path(i)
		print("Animation track ", i, ": ", track_path)

	_animation_player.play(_walk_animation_name)
	_animation_player.seek(0.0, true)

	if _idle_animation_name == &"":
		_animation_player.pause()


func _update_character_animation(moving: bool) -> void:
	if _animation_player == null:
		return

	if _walk_animation_name == &"":
		return

	if moving:
		if (
			_animation_player.current_animation
			!= String(_walk_animation_name)
			or not _animation_player.is_playing()
		):
			_animation_player.play(_walk_animation_name)

	elif _idle_animation_name != &"":
		if (
			_animation_player.current_animation
			!= String(_idle_animation_name)
			or not _animation_player.is_playing()
		):
			_animation_player.play(_idle_animation_name)

	else:
		if _animation_player.is_playing():
			_animation_player.pause()
