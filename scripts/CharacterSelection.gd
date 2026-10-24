extends Control

const CharacterBuilderScript = preload("res://scripts/CharacterBuilder.gd")
const CLASSES := ["Warrior", "Mage", "Rogue", "Druid", "Ranger"]
const DESCRIPTIONS := {"Warrior":"Tank / melee — Berserker Strike", "Mage":"Ranged magic — Arcane Blast", "Rogue":"Stealth / agility — Shadow Step", "Druid":"Nature / support — Nature's Call", "Ranger":"Precision / ranged — Arrow Volley"}
var chosen_class := "Warrior"
var chosen_gender := "male"
var preview_holder: Node3D
var details: Label
var builder: Node3D

func _ready() -> void:
    chosen_class = PlayerProfile.selected_class
    chosen_gender = PlayerProfile.selected_gender
    _build_ui()
    _refresh_preview()

func _build_ui() -> void:
    var bg := ColorRect.new(); bg.color = Color("#101827"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
    var root := VBoxContainer.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_theme_constant_override("separation", 10); root.add_theme_constant_override("margin_left", 24); root.add_theme_constant_override("margin_right", 24); root.add_theme_constant_override("margin_top", 18); root.add_theme_constant_override("margin_bottom", 18); add_child(root)
    var title := Label.new(); title.text = "CHOOSE YOUR HERO"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 30); title.add_theme_color_override("font_color", Color("#EAC77A")); root.add_child(title)
    var subtitle := Label.new(); subtitle.text = "Pick a class and appearance"; subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; root.add_child(subtitle)
    var preview_panel := PanelContainer.new(); preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(preview_panel)
    preview_holder = Node3D.new(); preview_holder.name = "PreviewHolder"
    # Keep 3D preview in a SubViewport so the character selector works as a normal Control scene.
    var viewport_container := SubViewportContainer.new(); viewport_container.custom_minimum_size = Vector2(0, 250); viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL; viewport_container.stretch = true; preview_panel.add_child(viewport_container)
    var viewport := SubViewport.new(); viewport.size = Vector2i(640, 360); viewport.own_world_3d = true; viewport_container.add_child(viewport)
    var world := Node3D.new(); viewport.add_child(world); builder = CharacterBuilderScript.new(); world.add_child(builder)
    var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color("#182438"); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.8,0.85,1); e.ambient_light_energy = 1.0; env.environment = e; world.add_child(env)
    var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-35,-25,0); world.add_child(light)
    var camera := Camera3D.new(); camera.position = Vector3(0,1.2,5.3); camera.rotation_degrees = Vector3(-5,0,0); camera.current = true; world.add_child(camera)
    var class_row := HBoxContainer.new(); class_row.add_theme_constant_override("separation", 5); root.add_child(class_row)
    for hero_class in CLASSES:
        var b := Button.new(); b.text = hero_class; b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.pressed.connect(_choose_class.bind(hero_class)); class_row.add_child(b)
    var gender_row := HBoxContainer.new(); root.add_child(gender_row)
    var male := Button.new(); male.text = "Male"; male.size_flags_horizontal = Control.SIZE_EXPAND_FILL; male.pressed.connect(_choose_gender.bind("male")); gender_row.add_child(male)
    var female := Button.new(); female.text = "Female"; female.size_flags_horizontal = Control.SIZE_EXPAND_FILL; female.pressed.connect(_choose_gender.bind("female")); gender_row.add_child(female)
    details = Label.new(); details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; root.add_child(details)
    var bottom := HBoxContainer.new(); root.add_child(bottom)
    var back := Button.new(); back.text = "BACK TO MENU"; back.size_flags_horizontal = Control.SIZE_EXPAND_FILL; back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")); bottom.add_child(back)
    var play := Button.new(); play.text = "BEGIN ADVENTURE"; play.size_flags_horizontal = Control.SIZE_EXPAND_FILL; play.pressed.connect(_begin_adventure); bottom.add_child(play)


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


func _begin_adventure() -> void:
	if not PlayerProfile.character_locked:
		PlayerProfile.set_selection(chosen_class, chosen_gender)
		PlayerProfile.lock_selection()

	get_tree().change_scene_to_file("res://scenes/Main.tscn")
