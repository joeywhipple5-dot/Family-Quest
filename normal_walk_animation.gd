extends Node
## Family Quest — Natural humanoid walk clip
## Godot 4.3
## Attach this script to the character model root.

@export var skeleton_path: NodePath = NodePath("Skeleton3D")
@export var animation_player_path: NodePath = NodePath("AnimationPlayer")

@export_range(0.5, 2.0, 0.1) var walk_duration: float = 1.0
@export_range(5.0, 35.0, 1.0) var leg_swing_degrees: float = 25.0
@export_range(5.0, 30.0, 1.0) var arm_swing_degrees: float = 18.0

const CLIP_NAME: StringName = &"FamilyQuest_Normal_Walk"

var skeleton: Skeleton3D
var animation_player: AnimationPlayer


func _ready() -> void:
	skeleton = get_node_or_null(skeleton_path) as Skeleton3D
	animation_player = get_node_or_null(
		animation_player_path
	) as AnimationPlayer

	# Find the actual rig if the imported GLB has nested nodes.
	if skeleton == null:
		skeleton = find_child("*", "Skeleton3D", true, false) as Skeleton3D

	if animation_player == null:
		animation_player = find_child(
			"*", "AnimationPlayer", true, false
		) as AnimationPlayer

	if skeleton == null or animation_player == null:
		push_error(
			"Walk clip: Skeleton3D or AnimationPlayer was not found. "
			+ "Set the exported paths to the Warrior's actual nodes."
		)
		return

	create_walk_clip()


func create_walk_clip() -> void:
	var library := animation_player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		var err := animation_player.add_animation_library("", library)
		if err != OK:
			push_error("Could not create animation library.")
			return

	if library.has_animation(CLIP_NAME):
		library.remove_animation(CLIP_NAME)

	var clip := Animation.new()
	clip.resource_name = "FamilyQuest_Normal_Walk"
	clip.length = walk_duration
	clip.loop_mode = Animation.LOOP_LINEAR

	# Angles are pose rotations relative to the skeleton's rest pose.
	var leg := deg_to_rad(leg_swing_degrees)
	var arm := deg_to_rad(arm_swing_degrees)

	_add_bone_track(clip, ["thigh_l", "upperleg_l", "LeftUpLeg"],
		[
			[0.0, -leg], [0.25, 0.0], [0.5, leg],
			[0.75, 0.0], [1.0, -leg]
		])

	_add_bone_track(clip, ["thigh_r", "upperleg_r", "RightUpLeg"],
		[
			[0.0, leg], [0.25, 0.0], [0.5, -leg],
			[0.75, 0.0], [1.0, leg]
		])

	# Knees flex during the backward part of each stride.
	_add_bone_track(clip, ["calf_l", "lowerleg_l", "LeftLeg"],
		[
			[0.0, 0.0], [0.25, -0.10], [0.5, -0.30],
			[0.75, -0.10], [1.0, 0.0]
		])

	_add_bone_track(clip, ["calf_r", "lowerleg_r", "RightLeg"],
		[
			[0.0, -0.30], [0.25, -0.10], [0.5, 0.0],
			[0.75, -0.10], [1.0, -0.30]
		])

	# Opposite arm swing: right arm forward as left leg advances.
	_add_bone_track(clip, ["upperarm_l", "LeftArm", "upper_arm.L"],
		[
			[0.0, arm], [0.25, 0.0], [0.5, -arm],
			[0.75, 0.0], [1.0, arm]
		])

	_add_bone_track(clip, ["upperarm_r", "RightArm", "upper_arm.R"],
		[
			[0.0, -arm], [0.25, 0.0], [0.5, arm],
			[0.75, 0.0], [1.0, -arm]
		])

	# Small torso counter-rotation keeps the movement natural.
	_add_bone_track(clip, ["pelvis", "hips", "Hips"],
		[
			[0.0, -0.035], [0.25, 0.0], [0.5, 0.035],
			[0.75, 0.0], [1.0, -0.035]
		], Vector3.UP)

	_add_bone_track(clip, ["spine_01", "spine", "Spine"],
		[
			[0.0, 0.025], [0.25, 0.0], [0.5, -0.025],
			[0.75, 0.0], [1.0, 0.025]
		], Vector3.UP)

	var result := library.add_animation(CLIP_NAME, clip)
	if result != OK:
		push_error("Could not register the normal walking animation.")
		return

	print("Created animation clip: ", CLIP_NAME)


func _add_bone_track(
	clip: Animation,
	candidates: Array,
	keys: Array,
	axis: Vector3 = Vector3.RIGHT
) -> void:
	var bone_index := _find_bone(candidates)
	if bone_index < 0:
		return

	var relative_skeleton_path := str(
		animation_player.get_path_to(skeleton)
	)
	var track_path := NodePath(
		relative_skeleton_path
		+ ":bone_pose/"
		+ str(bone_index)
		+ "/rotation"
	)

	var track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, track_path)
	clip.track_set_interpolation_type(
		track, Animation.INTERPOLATION_CUBIC
	)

	for key_data in keys:
		var time := float(key_data[0]) * walk_duration
		var angle := float(key_data[1])
		var rotation := Quaternion(axis.normalized(), angle)
		clip.track_insert_key(track, time, rotation)


func _find_bone(candidates: Array) -> int:
	for candidate in candidates:
		var index := skeleton.find_bone(str(candidate))
		if index >= 0:
			return index

	return -1
