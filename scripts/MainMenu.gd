
extends Control

## Family Quest - Main Menu
## Godot 4.x / Android landscape

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
    # --------------------------------------------------
    # BACKGROUND FALLBACK
    # --------------------------------------------------
    var fallback := ColorRect.new()
    fallback.name = "BackgroundFallback"
    fallback.color = NAVY
    fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fallback)

    # --------------------------------------------------
    # FANTASY VILLAGE BACKGROUND IMAGE
    # --------------------------------------------------
    var scenery := load("res://artwork/menu_background.png") as Texture2D

    if scenery != null:
        var background := TextureRect.new()
        background.name = "FantasyBackground"
        background.texture = scenery
        background.set_anchors_and_offsets_preset(
            Control.PRESET_FULL_RECT
        )
        background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        background.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(background)
    else:
        push_warning(
            "Family Quest: menu_background.png could not be loaded."
        )

    # --------------------------------------------------
    # GOLD-FRAMED MENU PANEL
    # --------------------------------------------------
    var panel := Panel.new()
    panel.name = "MenuBackdrop"
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.06
    panel.anchor_bottom = 0.94
    panel.offset_left = -225
    panel.offset_right = 225
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("#091322")
    panel_style.bg_color.a = 0.84
    panel_style.border_color = Color("#B69A61")
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(14)
    panel_style.shadow_color = Color(0, 0, 0, 0.55)
    panel_style.shadow_size = 12
    panel.add_theme_stylebox_override("panel", panel_style)
    add_child(panel)

    # --------------------------------------------------
    # MENU CONTENT
    # --------------------------------------------------
    var content := VBoxContainer.new()
    content.name = "MenuContent"
    content.anchor_left = 0.5
    content.anchor_right = 0.5
    content.anchor_top = 0.06
    content.anchor_bottom = 0.94
    content.offset_left = -190
    content.offset_right = 190
    content.offset_top = 8
    content.offset_bottom = -8
    content.add_theme_constant_override("separation", 12)
    add_child(content)

    
    # Family Quest crest
    var crest_texture := load(
        "res://artwork/family_quest_crest.png"
    ) as Texture2D

    if crest_texture != null:
        var crest := TextureRect.new()
        crest.name = "FamilyQuestCrest"
        crest.texture = crest_texture
        crest.custom_minimum_size = Vector2(0, 190)
        crest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
        crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.add_child(crest)
    else:
        push_warning("Family Quest crest failed to load.")


    var subtitle := Label.new()
    subtitle.text = "ONE FAMILY. ONE ADVENTURE."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", MUTED)
    content.add_child(subtitle)

    var gap := Control.new()
    gap.custom_minimum_size.y = 12
    content.add_child(gap)

    # --------------------------------------------------
    # MENU BUTTONS
    # --------------------------------------------------
    _add_menu_button(
        content, "▶   PLAY", _on_play_pressed, true
    )
    _add_menu_button(
        content, "♟   FAMILY PROFILES", _on_profiles_pressed
    )
    _add_menu_button(
        content, "⚙   SETTINGS", _on_settings_pressed
    )
    _add_menu_button(
        content, "✦   CREDITS", _on_credits_pressed
    )
    _add_menu_button(
        content, "↪   QUIT", _on_quit_pressed
    )

    # Footer stays at the bottom of the panel
    var footer_spacer := Control.new()
    footer_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(footer_spacer)

    var footer := Label.new()
    footer.text = "WHIPPLE CORP.  •  PROTOTYPE 0.1"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 10)
    footer.add_theme_color_override(
        "font_color",
        Color("#B7C4D6")
    )
    content.add_child(footer)

    # Dialog used by the placeholder menu options
    message_dialog = AcceptDialog.new()
    message_dialog.title = "Family Quest"
    message_dialog.dialog_text = ""
    add_child(message_dialog)


func _add_menu_button(
    parent: VBoxContainer,
    label_text: String,
    callback: Callable,
    primary: bool = false
) -> void:
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


# ------------------------------------------------------
# BUTTON ACTIONS
# ------------------------------------------------------

func _on_play_pressed() -> void:
    if (
        play_scene_path.strip_edges() != ""
        and ResourceLoader.exists(play_scene_path)
    ):
        get_tree().change_scene_to_file(play_scene_path)
        return

    if (
        gameplay_scene_path.strip_edges() != ""
        and ResourceLoader.exists(gameplay_scene_path)
    ):
        get_tree().change_scene_to_file(gameplay_scene_path)
        return

    _show_message(
        "The menu is ready, but the next scene is not connected yet.\n\n"
        + "Check Play Scene Path in the Inspector."
    )


func _on_profiles_pressed() -> void:
    _show_message(
        "Family Profiles\n\n"
        + "The family profile and saved-character system "
        + "will be connected when that screen is implemented."
    )


func _on_settings_pressed() -> void:
    _show_message(
        "Settings\n\n"
        + "Sound, graphics, and control options will be added here."
    )


func _on_credits_pressed() -> void:
    _show_message(
        "Family Quest\n"
        + "Created by Whipple Corp.\n\n"
        + "A family-friendly fantasy adventure."
    )


func _on_quit_pressed() -> void:
    get_tree().quit()


func _show_message(message: String) -> void:
    message_dialog.dialog_text = message
    message_dialog.popup_centered()
