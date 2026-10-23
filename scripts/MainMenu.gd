extends Control

## Family Quest main menu for Godot 4.x.
## Set these paths in the Inspector to match the scenes in your project.
@export_file("*.tscn") var play_scene_path: String = "res://scenes/CharacterSelection.tscn"
@export_file("*.tscn") var gameplay_scene_path: String = "res://scenes/Main.tscn"

const NAVY := Color("#101827")
const PANEL := Color("#172438")
const PANEL_HOVER := Color("#28496A")
const GOLD := Color("#EAC77A")
const PALE := Color("#F2F4F8")
const MUTED := Color("#B7C4D6")

var message_dialog: AcceptDialog
var button_nodes: Array[Button] = []

func _ready() -> void:
    _build_menu()

func _build_menu() -> void:
    # Full-screen background
    var background := ColorRect.new()
    background.name = "Background"
    background.color = NAVY
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    # Decorative horizon and castle silhouettes made from UI shapes, so no external assets are required.
    var horizon := ColorRect.new()
    horizon.name = "Horizon"
    horizon.color = Color("#182D3B")
    horizon.anchor_left = 0.0
    horizon.anchor_right = 1.0
    horizon.anchor_top = 0.56
    horizon.anchor_bottom = 1.0
    horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(horizon)

    var skyline := Label.new()
    skyline.name = "CastleSilhouette"
    skyline.text = "      ♜       ♜     /\u005c_/\\       ♜       ♜"
    skyline.add_theme_font_size_override("font_size", 58)
    skyline.add_theme_color_override("font_color", Color("#263D4A"))
    skyline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    skyline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    skyline.anchor_left = 0.0
    skyline.anchor_right = 1.0
    skyline.anchor_top = 0.55
    skyline.anchor_bottom = 0.83
    skyline.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(skyline)

    var glow := ColorRect.new()
    glow.name = "MenuBackdrop"
    glow.color = Color(0.04, 0.07, 0.12, 0.88)
    glow.anchor_left = 0.5
    glow.anchor_right = 0.5
    glow.anchor_top = 0.08
    glow.anchor_bottom = 0.94
    glow.offset_left = -225
    glow.offset_right = 225
    glow.offset_top = 0
    glow.offset_bottom = 0
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(glow)

    var content := VBoxContainer.new()
    content.name = "MenuContent"
    content.anchor_left = 0.5
    content.anchor_right = 0.5
    content.anchor_top = 0.08
    content.anchor_bottom = 0.94
    content.offset_left = -190
    content.offset_right = 190
    content.offset_top = 8
    content.offset_bottom = -8
    content.add_theme_constant_override("separation", 12)
    add_child(content)

    var top_spacer := Control.new()
    top_spacer.custom_minimum_size.y = 8
    content.add_child(top_spacer)

    var emblem := Label.new()
    emblem.text = "✦"
    emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    emblem.add_theme_font_size_override("font_size", 30)
    emblem.add_theme_color_override("font_color", GOLD)
    content.add_child(emblem)

    var title_family := Label.new()
    title_family.text = "FAMILY"
    title_family.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_family.add_theme_font_size_override("font_size", 42)
    title_family.add_theme_color_override("font_color", GOLD)
    title_family.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
    title_family.add_theme_constant_override("shadow_offset_x", 2)
    title_family.add_theme_constant_override("shadow_offset_y", 3)
    content.add_child(title_family)

    var title_quest := Label.new()
    title_quest.text = "QUEST"
    title_quest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_quest.add_theme_font_size_override("font_size", 42)
    title_quest.add_theme_color_override("font_color", PALE)
    content.add_child(title_quest)

    var subtitle := Label.new()
    subtitle.text = "ONE FAMILY. ONE ADVENTURE."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", MUTED)
    content.add_child(subtitle)

    var gap := Control.new()
    gap.custom_minimum_size.y = 14
    content.add_child(gap)

    _add_menu_button(content, "▶   PLAY", _on_play_pressed, true)
    _add_menu_button(content, "♟   FAMILY PROFILES", _on_profiles_pressed)
    _add_menu_button(content, "⚙   SETTINGS", _on_settings_pressed)
    _add_menu_button(content, "✦   CREDITS", _on_credits_pressed)
    _add_menu_button(content, "↪   QUIT", _on_quit_pressed)

    var footer_spacer := Control.new()
    footer_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(footer_spacer)

    var footer := Label.new()
    footer.text = "WHIPPLE CORP.  •  PROTOTYPE 0.1"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 10)
    footer.add_theme_color_override("font_color", Color("#8798AD"))
    content.add_child(footer)

    message_dialog = AcceptDialog.new()
    message_dialog.title = "Family Quest"
    message_dialog.dialog_text = ""
    add_child(message_dialog)

func _add_menu_button(parent: VBoxContainer, label_text: String, callback: Callable, primary: bool = false) -> void:
    var button := Button.new()
    button.text = label_text
    button.custom_minimum_size = Vector2(0, 50)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.focus_mode = Control.FOCUS_ALL
    button.add_theme_font_size_override("font_size", 17)
    button.add_theme_color_override("font_color", PALE)
    button.add_theme_color_override("font_hover_color", GOLD)
    button.add_theme_color_override("font_pressed_color", GOLD)

    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#315B85") if primary else PANEL
    normal.border_color = GOLD if primary else Color("#3B4C62")
    normal.set_border_width_all(1)
    normal.set_corner_radius_all(9)
    normal.content_margin_left = 16
    normal.content_margin_right = 16
    normal.content_margin_top = 10
    normal.content_margin_bottom = 10
    button.add_theme_stylebox_override("normal", normal)

    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = PANEL_HOVER
    hover.border_color = GOLD
    button.add_theme_stylebox_override("hover", hover)

    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("#203A55")
    button.add_theme_stylebox_override("pressed", pressed)

    button.pressed.connect(callback)
    parent.add_child(button)
    button_nodes.append(button)

func _on_play_pressed() -> void:
    if play_scene_path.strip_edges() != "" and ResourceLoader.exists(play_scene_path):
        get_tree().change_scene_to_file(play_scene_path)
        return
    if gameplay_scene_path.strip_edges() != "" and ResourceLoader.exists(gameplay_scene_path):
        get_tree().change_scene_to_file(gameplay_scene_path)
        return
    _show_message(
        "The menu is ready, but the next scene has not been connected yet.\\n\\nIn the Inspector, set Play Scene Path to your character-selection scene, or Gameplay Scene Path to your gameplay scene."
    )

func _on_profiles_pressed() -> void:
    _show_message("Family Profiles\\n\\nThis menu item is reserved for the family profile and saved-character system. We will connect it when that screen is implemented.")

func _on_settings_pressed() -> void:
    _show_message("Settings\\n\\nThe settings screen will hold sound, graphics, and control options. This placeholder confirms the button works.")

func _on_credits_pressed() -> void:
    _show_message("Family Quest\\nCreated by Whipple Corp.\\n\\nA family-friendly fantasy adventure.")

func _on_quit_pressed() -> void:
    get_tree().quit()

func _show_message(message: String) -> void:
    message_dialog.dialog_text = message
    message_dialog.popup_centered()
