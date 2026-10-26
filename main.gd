
extends Node3D

const PlayerScript = preload("res://player.gd")
const EnemyScript = preload("res://enemy.gd")

const PLAYER_START := Vector3(0.0, 0.0, 10.0)
const ATTACK_RANGE := 3.5
const INTERACT_RANGE := 4.0

var player: CharacterBody3D
var camera: Camera3D
var hud_layer: CanvasLayer
var enemies: Array[Node3D] = []
var interactables: Array[Node3D] = []

var hero_class := "Warrior"
var hero_gender := "Male"

var level := 1
var xp := 0
var xp_to_next_level := 100
var silver := 0
var chore_gold := 0
var potions := 3

var quest_stage := 0
var enemies_defeated := 0
var path_enemies_defeated := 0
var herbs_collected := 0
var crates_collected := 0

var attack_cooldown := 0.0
var message_timer := 0.0
var player_dead := false

var health_label: Label
var level_label: Label
var currency_label: Label
var quest_label: Label
var message_label: Label
var class_label: Label

func _ready() -> void:
	print("Family Quest: starting gameplay")
	_create_environment()
	_create_world()
	_create_village()
	_create_player()
	_create_npcs()
	_create_objectives()
	_create_enemies()
	_create_camera()
	_create_hud()
	_refresh_hud()
	_message("Welcome to Hearthvale!")
	print("Family Quest: startup complete")

func _process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0 and is_instance_valid(message_label):
			message_label.text = ""

	_update_camera()

func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.12, 0.28, 0.48)
	sky_material.sky_horizon_color = Color(0.65, 0.75, 0.83)
	sky_material.ground_bottom_color = Color(0.12, 0.14, 0.12)
	sky_material.ground_horizon_color = Color(0.45, 0.5, 0.42)
	sky.sky_material = sky_material

	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.68, 0.75)
	environment.ambient_light_energy = 0.8
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	add_child(sun)

func _create_world() -> void:
	_make_box("GrassGround", Vector3(0, -0.5, -45),
		Vector3(100, 1, 150), Color(0.22, 0.38, 0.19), true)

	_make_box("VillageRoad", Vector3(0, 0.02, 8),
		Vector3(9, 0.08, 55), Color(0.43, 0.36, 0.26), false)

	_make_box("ForestPath", Vector3(0, 0.03, -48),
		Vector3(5, 0.1, 65), Color(0.36, 0.30, 0.20), false)

	# Village and forest boundaries.
	_make_box("WestBoundary", Vector3(-30, 2, -40),
		Vector3(1, 4, 140), Color(0.16, 0.28, 0.14), true)
	_make_box("EastBoundary", Vector3(30, 2, -40),
		Vector3(1, 4, 140), Color(0.16, 0.28, 0.14), true)
	_make_box("NorthBoundary", Vector3(0, 2, -110),
		Vector3(60, 4, 1), Color(0.16, 0.28, 0.14), true)
	_make_box("SouthBoundary", Vector3(0, 2, 30),
		Vector3(60, 4, 1), Color(0.16, 0.28, 0.14), true)

	for i in range(32):
		var z := -18.0 - float(i) * 2.7
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * (5.0 + float(i % 4) * 2.0)
		_create_tree(Vector3(x, 0, z), 1.0 + float(i % 3) * 0.15)

	for i in range(12):
		var x := -22.0 + float(i) * 4.0
		_create_tree(Vector3(x, 0, 22), 1.0)

func _create_tree(pos: Vector3, scale_value: float) -> void:
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22 * scale_value
	trunk_mesh.bottom_radius = 0.35 * scale_value
	trunk_mesh.height = 2.4 * scale_value
	trunk.mesh = trunk_mesh
	trunk.position = pos + Vector3(0, 1.2 * scale_value, 0)
	trunk.material_override = _material(Color(0.27, 0.16, 0.09))
	add_child(trunk)

	var leaves := MeshInstance3D.new()
	var leaves_mesh := SphereMesh.new()
	leaves_mesh.radius = 1.25 * scale_value
	leaves_mesh.height = 2.5 * scale_value
	leaves.mesh = leaves_mesh
	leaves.position = pos + Vector3(0, 3.0 * scale_value, 0)
	leaves.material_override = _material(Color(0.10, 0.29, 0.12))
	add_child(leaves)

func _create_village() -> void:
	_create_building("ElderHall", Vector3(-9, 0, 3),
		Vector3(7, 4, 6), Color(0.56, 0.43, 0.29))
	_create_building("Blacksmith", Vector3(9, 0, 2),
		Vector3(6, 3.5, 6), Color(0.40, 0.34, 0.30))
	_create_building("GeneralStore", Vector3(-9, 0, 14),
		Vector3(6, 3.5, 5), Color(0.54, 0.48, 0.32))
	_create_building("HouseEast", Vector3(9, 0, 14),
		Vector3(5, 3, 5), Color(0.49, 0.36, 0.25))
	_create_building("HouseWest", Vector3(-15, 0, 19),
		Vector3(5, 3, 5), Color(0.48, 0.38, 0.28))

func _create_building(building_name: String, pos: Vector3,
	size_value: Vector3, wall_color: Color) -> void:
	_make_box(building_name + "_Walls",
		pos + Vector3(0, size_value.y / 2.0, 0),
		size_value, wall_color, true)

	_make_box(building_name + "_Roof",
		pos + Vector3(0, size_value.y + 0.35, 0),
		Vector3(size_value.x + 0.8, 0.7, size_value.z + 0.8),
		Color(0.25, 0.16, 0.13), true)

func _make_box(box_name: String, pos: Vector3,
	size_value: Vector3, color_value: Color,
	add_collision: bool) -> Node3D:
	var holder: Node3D

	if add_collision:
		var body := StaticBody3D.new()
		body.name = box_name
		holder = body

		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size_value
		collision.shape = shape
		body.add_child(collision)
	else:
		var mesh_holder := Node3D.new()
		mesh_holder.name = box_name
		holder = mesh_holder

	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	visual.mesh = mesh
	visual.material_override = _material(color_value)
	holder.add_child(visual)
	holder.position = pos
	add_child(holder)
	return holder

func _material(color_value: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_value
	mat.roughness = 0.9
	return mat

func _create_player() -> void:
	var instance: Node = PlayerScript.new()
	if not instance is CharacterBody3D:
		push_error("player.gd must extend CharacterBody3D.")
		return

	player = instance as CharacterBody3D
	player.name = "Player"
	player.position = PLAYER_START
	add_child(player)

	if player.has_signal("player_died"):
		player.connect("player_died", _on_player_died)
	if player.has_signal("player_revived"):
		player.connect("player_revived", _on_player_revived)
	if player.has_signal("health_changed"):
		player.connect("health_changed", _on_player_health_changed)

	if player.has_method("set_hero_class"):
		player.call("set_hero_class", hero_class)
	if player.has_method("set_hero_gender"):
		player.call("set_hero_gender", hero_gender)

func _create_camera() -> void:
	camera = Camera3D.new()
	camera.name = "GameplayCamera"
	camera.current = true
	camera.fov = 70.0
	add_child(camera)
	_update_camera()

func _update_camera() -> void:
	if not is_instance_valid(camera) or not is_instance_valid(player):
		return

	var target := player.global_position + Vector3(0, 6.0, 9.0)
	camera.global_position = camera.global_position.lerp(target, 0.12)
	camera.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)

func _create_npcs() -> void:
	_create_npc("Elder", "Village Elder", Vector3(-5, 0, 4),
		Color(0.75, 0.65, 0.42), "elder")
	_create_npc("BlacksmithNPC", "Blacksmith", Vector3(6, 0, 5),
		Color(0.45, 0.45, 0.49), "blacksmith")
	_create_npc("Merchant", "Merchant", Vector3(-5, 0, 14),
		Color(0.28, 0.48, 0.72), "merchant")
	_create_npc("Guard", "Village Guard", Vector3(2, 0, -2),
		Color(0.32, 0.45, 0.30), "guard")

func _create_npc(npc_name: String, display_name: String,
	pos: Vector3, color_value: Color, role: String) -> void:
	var npc := Node3D.new()
	npc.name = npc_name
	npc.position = pos
	npc.set_meta("interactable", true)
	npc.set_meta("interaction_type", "npc")
	npc.set_meta("display_name", display_name)
	npc.set_meta("role", role)
	add_child(npc)

	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.42
	mesh.height = 1.8
	body.mesh = mesh
	body.position.y = 0.9
	body.material_override = _material(color_value)
	npc.add_child(body)

	var label := Label3D.new()
	label.text = display_name
	label.position.y = 2.2
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	npc.add_child(label)
	interactables.append(npc)

func _create_objectives() -> void:
	_create_objective("QuestBoard", "Quest Board",
		Vector3(0, 0, 5), Color(0.42, 0.25, 0.12), "board")

	for i in range(6):
		var x := -4.0 if i % 2 == 0 else 4.0
		var z := -15.0 - float(i) * 4.0
		_create_objective("Herb_%d" % i, "Healing Herb",
			Vector3(x, 0.25, z), Color(0.15, 0.75, 0.25), "herb")

	for i in range(5):
		var x := -4.0 if i % 2 == 0 else 4.0
		var z := -48.0 - float(i) * 7.0
		_create_objective("Crate_%d" % i, "Supply Crate",
			Vector3(x, 0.5, z), Color(0.48, 0.29, 0.13), "crate")

func _create_objective(object_name: String, display_name: String,
	pos: Vector3, color_value: Color, kind: String) -> void:
	var body := StaticBody3D.new()
	body.name = object_name
	body.position = pos
	body.set_meta("interactable", true)
	body.set_meta("interaction_type", kind)
	body.set_meta("display_name", display_name)

	var mesh_instance := MeshInstance3D.new()
	var mesh: Mesh

	if kind == "herb":
		mesh = SphereMesh.new()
	elif kind == "board":
		mesh = BoxMesh.new()
		(mesh as BoxMesh).size = Vector3(1.6, 2.0, 0.2)
	else:
		mesh = BoxMesh.new()
		(mesh as BoxMesh).size = Vector3(0.9, 0.9, 0.9)

	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color_value)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.8
	collision.shape = shape
	body.add_child(collision)

	add_child(body)
	interactables.append(body)

func _create_enemies() -> void:
	for i in range(3):
		_spawn_enemy("Forest Slime",
			Vector3(-4.0 + float(i) * 4.0, 0, -8.0 - float(i) * 3.0),
			false)

	for i in range(5):
		_spawn_enemy("Woodland Goblin",
			Vector3(-5.0 + float(i % 3) * 5.0, 0, -40.0 - float(i) * 7.0),
			false)

	for i in range(3):
		_spawn_enemy("Thornwolf",
			Vector3(-7.0 + float(i) * 7.0, 0, -65.0 - float(i) * 6.0),
			false)

	_spawn_enemy("Mossjaw", Vector3(0, 0, -100), true)

func _spawn_enemy(enemy_name: String, pos: Vector3,
	is_boss: bool) -> void:
	var instance: Node = EnemyScript.new()
	if not instance is Node3D:
		push_error("enemy.gd must extend Node3D or a derived type.")
		return

	var enemy := instance as Node3D
	enemy.name = enemy_name.replace(" ", "") + "_" + str(enemies.size())
	enemy.position = pos
	enemy.set("enemy_name", enemy_name)
	enemy.set("is_boss", is_boss)

	if enemy.has_signal("defeated"):
		enemy.connect("defeated", _on_enemy_defeated.bind(enemy))

	add_child(enemy)
	enemies.append(enemy)

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "GameHUD"
	hud_layer.layer = 10
	add_child(hud_layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	panel.custom_minimum_size = Vector2(280, 142)
	hud_layer.add_child(panel)

	var layout := VBoxContainer.new()
	panel.add_child(layout)

	health_label = _new_label("Health: --")
	level_label = _new_label("Level: 1")
	currency_label = _new_label("Gold: 0 | Silver: 0 | Potions: 3")
	class_label = _new_label("Class: Warrior")
	layout.add_child(health_label)
	layout.add_child(level_label)
	layout.add_child(currency_label)
	layout.add_child(class_label)

	quest_label = _new_label("Quest: Speak to the Elder")
	quest_label.position = Vector2(12, 164)
	quest_label.custom_minimum_size = Vector2(300, 64)
	hud_layer.add_child(quest_label)

	message_label = _new_label("")
	message_label.position = Vector2(20, 235)
	message_label.custom_minimum_size = Vector2(340, 45)
	hud_layer.add_child(message_label)

	var buttons := HBoxContainer.new()
	buttons.anchor_left = 0.0
	buttons.anchor_top = 1.0
	buttons.anchor_right = 1.0
	buttons.anchor_bottom = 1.0
	buttons.offset_left = 8
	buttons.offset_top = -64
	buttons.offset_right = -8
	buttons.offset_bottom = -8
	buttons.add_theme_constant_override("separation", 8)
	hud_layer.add_child(buttons)

	_add_button(buttons, "Attack", _attack)
	_add_button(buttons, "Interact", _interact)
	_add_button(buttons, "Potion", _use_potion)
	_add_button(buttons, "Respawn", _respawn_player)

	var class_row := HBoxContainer.new()
	class_row.position = Vector2(8, 305)
	hud_layer.add_child(class_row)
	for class_name in ["Warrior", "Mage", "Rogue", "Druid", "Ranger"]:
		_add_button(class_row, class_name,
			_select_class.bind(class_name))

func _new_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label

func _add_button(parent: Control, text_value: String,
	callback: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(74, 48)
	button.pressed.connect(callback)
	parent.add_child(button)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E:
				_interact()
			KEY_H:
				_use_potion()
			KEY_SPACE:
				_attack()
			KEY_ESCAPE:
				_message("Tap Resume in the game menu to continue.")

func _attack() -> void:
	if player_dead or attack_cooldown > 0.0:
		return
	if not is_instance_valid(player):
		return

	attack_cooldown = 0.65
	var target: Node3D
	var nearest_distance := ATTACK_RANGE

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var distance := player.global_position.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			target = enemy

	if target == null:
		_message("No enemy in range.")
		return

	var damage := 25
	match hero_class:
		"Mage":
			damage = 22
		"Rogue":
			damage = 20
		"Druid":
			damage = 18
		"Ranger":
			damage = 21

	if target.has_method("take_damage"):
		target.call("take_damage", damage)
	elif target.has_method("damage"):
		target.call("damage", damage)
	else:
		var hp_value = target.get("hp")
		if hp_value != null:
			target.set("hp", maxi(0, int(hp_value) - damage))
			if int(target.get("hp")) <= 0:
				_on_enemy_defeated(target)

	_message("%s attack: %d damage" % [hero_class, damage])

func _on_enemy_defeated(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	if enemy.has_meta("reward_claimed") and enemy.get_meta("reward_claimed"):
		return
	enemy.set_meta("reward_claimed", true)

	if enemy is Node3D:
		var enemy_node := enemy as Node3D
		if enemy_node.global_position.z < -30:
			path_enemies_defeated += 1
		else:
			enemies_defeated += 1

	xp += 25
	silver += 5
	_check_level_up()
	_refresh_hud()

	if enemy.name.to_lower().contains("mossjaw"):
		xp += 100
		silver += 50
		chore_gold += 10
		_message("Mossjaw defeated! Boss rewards earned.")
	else:
		_message("Enemy defeated! +25 XP, +5 Silver.")

	if enemy is Node3D:
		enemies.erase(enemy)
		enemy.queue_free()

	_update_quest_progress()

func _check_level_up() -> void:
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = level * 100
		if is_instance_valid(player):
			var current_health = player.get("hp")
			var maximum_health = player.get("max_hp")
			if current_health != null and maximum_health != null:
				player.set("max_hp", int(maximum_health) + 10)
				player.set("hp", int(player.get("max_hp")))
		_message("Level up! You are now level %d." % level)

func _interact() -> void:
	if player_dead or not is_instance_valid(player):
		return

	var target: Node3D
	var nearest_distance := INTERACT_RANGE

	for object in interactables:
		if not is_instance_valid(object) or object.is_queued_for_deletion():
			continue
		var distance := player.global_position.distance_to(object.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			target = object

	if target == null:
		_message("Move closer to an NPC or object.")
		return

	_interact_with_object(target)

func _interact_with_object(target: Node3D) -> void:
	if not is_instance_valid(target):
		return

	var kind := str(target.get_meta("interaction_type", ""))
	var display_name := str(target.get_meta("display_name", target.name))

	match kind:
		"npc":
			var role := str(target.get_meta("role", ""))
			match role:
				"elder":
					_talk_to_elder()
				"merchant":
					if silver >= 10:
						silver -= 10
						potions += 1
						_message("Bought a potion for 10 Silver.")
					else:
						_message("A potion costs 10 Silver.")
				"blacksmith":
					_message("The Blacksmith: Keep training, hero.")
				_:
					_message(display_name + ": Stay alert out there.")
		"herb":
			herbs_collected += 1
			xp += 5
			interactables.erase(target)
			target.queue_free()
			_message("Herb collected!")
			_check_level_up()
			_update_quest_progress()
		"crate":
			crates_collected += 1
			silver += 2
			interactables.erase(target)
			target.queue_free()
			_message("Supplies collected! +2 Silver.")
			_update_quest_progress()
		"board":
			_message(_get_quest_text())
		_:
			_message("Nothing to interact with.")

func _talk_to_elder() -> void:
	if quest_stage == 0:
		quest_stage = 1
		_message("Elder: Clear three monsters from the village.")
	elif quest_stage == 1:
		_message("Elder: Defeat %d more village monsters." %
			maxi(0, 3 - enemies_defeated))
	elif quest_stage == 2:
		_message("Elder: Gather three healing herbs in the forest.")
	elif quest_stage == 3:
		_message("Elder: Defeat five enemies along the forest path.")
	else:
		_message("Elder: Mossjaw threatens Hearthvale. Find and defeat it!")

	_refresh_hud()

func _update_quest_progress() -> void:
	if quest_stage == 1 and enemies_defeated >= 3:
		quest_stage = 2
		chore_gold += 5
		_message("Village cleared! Quest reward: 5 Gold.")
	elif quest_stage == 2 and herbs_collected >= 3:
		quest_stage = 3
		chore_gold += 5
		_message("Herbs gathered! Quest reward: 5 Gold.")
	elif quest_stage == 3 and path_enemies_defeated >= 5:
		quest_stage = 4
		chore_gold += 10
		_message("Forest path cleared! Quest reward: 10 Gold.")
	_refresh_hud()

func _get_quest_text() -> String:
	match quest_stage:
		0:
			return "Quest: Speak to the Village Elder."
		1:
			return "Quest: Defeat village monsters (%d/3)." % mini(enemies_defeated, 3)
		2:
			return "Quest: Collect herbs (%d/3)." % mini(herbs_collected, 3)
		3:
			return "Quest: Defeat forest enemies (%d/5)." % mini(path_enemies_defeated, 5)
		_:
			return "Quest: Explore the forest and challenge Mossjaw."

func _use_potion() -> void:
	if player_dead:
		_message("You cannot use a potion while defeated.")
		return
	if potions <= 0:
		_message("You have no potions.")
		return
	if not is_instance_valid(player):
		return

	var hp_value = player.get("hp")
	var max_value = player.get("max_hp")
	if hp_value == null or max_value == null:
		_message("Your player script needs hp and max_hp variables.")
		return
	if int(hp_value) >= int(max_value):
		_message("Your health is already full.")
		return

	potions -= 1
	player.set("hp", mini(int(max_value), int(hp_value) + 40))
	_on_player_health_changed()
	_message("Potion used: restored up to 40 health.")
	_refresh_hud()

func _select_class(class_name: String) -> void:
	hero_class = class_name
	if is_instance_valid(player) and player.has_method("set_hero_class"):
		player.call("set_hero_class", hero_class)
	_refresh_hud()
	_message("Hero class changed to " + hero_class + ".")

func _refresh_hud() -> void:
	if is_instance_valid(health_label):
		if is_instance_valid(player):
			var hp_value = player.get("hp")
			var max_value = player.get("max_hp")
			if hp_value != null and max_value != null:
				health_label.text = "Health: %s / %s" % [str(hp_value), str(max_value)]
			else:
				health_label.text = "Health: --"
		else:
			health_label.text = "Health: --"

	if is_instance_valid(level_label):
		level_label.text = "Level: %d | XP: %d/%d" % [level, xp, xp_to_next_level]
	if is_instance_valid(currency_label):
		currency_label.text = "Gold: %d | Silver: %d | Potions: %d" % [
			chore_gold, silver, potions
		]
	if is_instance_valid(class_label):
		class_label.text = "Class: " + hero_class
	if is_instance_valid(quest_label):
		quest_label.text = _get_quest_text()

func _message(text_value: String) -> void:
	print(text_value)
	if is_instance_valid(message_label):
		message_label.text = text_value
		message_timer = 4.0

func _on_player_health_changed(_value = null) -> void:
	_refresh_hud()

func _on_player_died() -> void:
	player_dead = true
	_message("You have been defeated. Tap Respawn.")
	_refresh_hud()

func _on_player_revived() -> void:
	player_dead = false
	_message("Back in the fight!")
	_refresh_hud()

func _respawn_player() -> void:
	if not is_instance_valid(player):
		return

	player_dead = false
	player.global_position = PLAYER_START
	player.velocity = Vector3.ZERO

	var max_value = player.get("max_hp")
	if max_value != null:
		player.set("hp", int(max_value))

	if player.has_method("revive"):
		player.call("revive")

	_refresh_hud()
	_message("You have returned to Hearthvale.")
