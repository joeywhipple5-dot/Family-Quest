
extends Control

const CharacterBuilderScript = preload("res://scripts/CharacterBuilder.gd")

const CLASSES := ["Warrior", "Mage", "Rogue", "Druid", "Ranger"]

const DESCRIPTIONS := {
	"Warrior": "Tank / melee — Berserker Strike",
	"Mage": "Ranged magic — Arcane Blast",
	"Rogue": "Stealth / agility — Shadow Step",
	"Druid": "Nature / support — Nature's Call",
	"Ranger": "Precision / ranged — Arrow Volley"
}

var chosen_class := "Warrior"
var chosen_gender := "male"

var details: Label
var builder: Node3D
var hero_preview: Node3D
var class_buttons: Array[Button] = []
var gender_buttons: Array[Button] = []
var play_button: Button


func _ready() -> void:
	chosen_class = PlayerProfile.selected_class
	chosen_gender = PlayerProfile.selected_gender
	_build_ui()
	_refresh_preview()
	_update_lock_state()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#101827")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24
	root.offset_right = -24
	root.offset_top = 18
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title := Label.new()
	title.text = "CHOOSE YOUR HERO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#EAC77A"))
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Pick a class and appearance"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(subtitle)

	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(preview_panel)

	var viewport_container := SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(0, 220)
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_container.stretch = true
	preview_panel.add_child(viewport_container)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)

	var world := Node3D.new()
	world.name = "PreviewWorld"
	viewport.add_child(world)

	builder = CharacterBuilderScript.new()
	builder.name = "CharacterBuilder"
	world.add_child(builder)

	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#182438")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.8, 0.85, 1.0)
	environment.ambient_light_energy = 1.0
	environment_node.environment = environment
	world.add_child(environment_node)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	world.add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.2, 5.3)
	camera.rotation_degrees = Vector3(-5, 0, 0)
	camera.current = true
	world.add_child(camera)

	var class_row := HBoxContainer.new()
	class_row.add_theme_constant_override("separation", 4)
	root.add_child(class_row)

	for hero_class in CLASSES:
		var button := Button.new()
		button.text = hero_class
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 42
		button.pressed.connect(_choose_class.bind(hero_class))
		class_row.add_child(button)
		class_buttons.append(button)

	var gender_row := HBoxContainer.new()
	root.add_child(gender_row)

	var male_button := Button.new()
	male_button.text = "Male"
	male_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	male_button.pressed.connect(_choose_gender.bind("male"))
	gender_row.add_child(male_button)
	gender_buttons.append(male_button)

	var female_button := Button.new()
	female_button.text = "Female"
	female_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	female_button.pressed.connect(_choose_gender.bind("female"))
	gender_row.add_child(female_button)
	gender_buttons.append(female_button)

	details = Label.new()
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(details)

	var bottom := HBoxContainer.new()
	root.add_child(bottom)

	var back_button := Button.new()
	back_button.text = "BACK TO MENU"
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(_back_to_menu)
	bottom.add_child(back_button)

	play_button = Button.new()
	play_button.text = "BEGIN ADVENTURE"
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_button.pressed.connect(_begin_adventure)
	bottom.add_child(play_button)


func _refresh_preview() -> void:
	if builder == null or not is_instance_valid(builder):
		return

	if hero_preview != null and is_instance_valid(hero_preview):
		hero_preview.queue_free()
		hero_preview = null

	hero_preview = builder.build_character(chosen_class, chosen_gender)
	builder.add_child(hero_preview)

	details.text = "%s (%s)\n%s" % [
		chosen_class,
		chosen_gender.capitalize(),
		DESCRIPTIONS.get(chosen_class, "")
	]

	if PlayerProfile.character_locked:
		details.text += "\nYour hero is locked."


func _choose_class(value: String) -> void:
	if PlayerProfile.character_locked:
		return

	chosen_class = value
	_refresh_preview()


func _choose_gender(value: String) -> void:
	if PlayerProfile.character_locked:
		return

	chosen_gender = value
	_refresh_preview()


func _update_lock_state() -> void:
	var locked: bool = PlayerProfile.character_locked

	for button in class_buttons:
		button.disabled = locked

	for button in gender_buttons:
		button.disabled = locked

	if locked:
		play_button.text = "CONTINUE ADVENTURE"
	else:
		play_button.text = "BEGIN ADVENTURE"


func _begin_adventure() -> void:
	if not PlayerProfile.character_locked:
		PlayerProfile.set_selection(chosen_class, chosen_gender)
		PlayerProfile.lock_selection()

	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
