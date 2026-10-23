extends Control

class FantasyBackdrop extends Control:
    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        queue_redraw()

    func _notification(what: int) -> void:
        if what == NOTIFICATION_RESIZED:
            queue_redraw()

    func _draw() -> void:
        var w := size.x
        var h := size.y

        # Deep magical night sky
        draw_rect(
            Rect2(Vector2.ZERO, size),
            Color("#0A1222")
        )

        # Distant blue atmospheric glow
        draw_circle(
            Vector2(w * 0.5, h * 0.46),
            h * 0.60,
            Color("#14263B")
        )

        # Stars
        for i in range(100):
            var sx := fposmod(float(i * 137 + 53), 997.0) / 997.0 * w
            var sy := fposmod(float(i * 79 + 31), 613.0) / 613.0 * h * 0.70
            var radius := 1.0 + float(i % 3) * 0.5

            draw_circle(
                Vector2(sx, sy),
                radius,
                Color(0.85, 0.88, 1.0, 0.65)
            )

        # Moon and soft halo
        var moon := Vector2(w * 0.83, h * 0.19)
        draw_circle(moon, h * 0.10, Color(0.82, 0.72, 0.48, 0.06))
        draw_circle(moon, h * 0.065, Color("#D9D6C4"))
        draw_circle(
            moon + Vector2(h * 0.025, -h * 0.012),
            h * 0.055,
            Color("#A9B6C8")
        )
        draw_circle(
            moon + Vector2(-h * 0.012, h * 0.012),
            h * 0.045,
            Color("#D9D6C4")
        )

        # Distant mountain range
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(0, h * 0.56),
                Vector2(w * 0.14, h * 0.39),
                Vector2(w * 0.25, h * 0.55),
                Vector2(w * 0.43, h * 0.35),
                Vector2(w * 0.61, h * 0.56),
                Vector2(w * 0.79, h * 0.40),
                Vector2(w, h * 0.54),
                Vector2(w, h),
                Vector2(0, h)
            ]),
            Color("#1B3044")
        )

        # Dark foreground hills
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(0, h * 0.72),
                Vector2(w * 0.22, h * 0.62),
                Vector2(w * 0.40, h * 0.74),
                Vector2(w * 0.67, h * 0.62),
                Vector2(w, h * 0.70),
                Vector2(w, h),
                Vector2(0, h)
            ]),
            Color("#102633")
        )

        # Castle silhouette on the horizon
        var cx := w * 0.50
        var ground := h * 0.70
        var stone := Color("#0A1928")
        var roof := Color("#0B1726")

        draw_rect(
            Rect2(Vector2(cx - 66, ground - 92), Vector2(132, 100)),
            stone
        )
        draw_rect(
            Rect2(Vector2(cx - 88, ground - 116), Vector2(35, 124)),
            stone
        )
        draw_rect(
            Rect2(Vector2(cx + 53, ground - 116), Vector2(35, 124)),
            stone
        )

        draw_colored_polygon(
            PackedVector2Array([
                Vector2(cx - 94, ground - 116),
                Vector2(cx - 71, ground - 143),
                Vector2(cx - 47, ground - 116)
            ]),
            roof
        )
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(cx + 47, ground - 116),
                Vector2(cx + 71, ground - 143),
                Vector2(cx + 94, ground - 116)
            ]),
            roof
        )

        # Castle windows
        for x_offset in [-71.0, 71.0, -28.0, 0.0, 28.0]:
            draw_rect(
                Rect2(
                    Vector2(cx + x_offset - 3, ground - 82),
                    Vector2(6, 12)
                ),
                Color("#D9AD62")
            )

        # Golden path leading toward the castle
        draw_colored_polygon(
            PackedVector2Array([
                Vector2(w * 0.47, h),
                Vector2(w * 0.53, h),
                Vector2(w * 0.515, ground),
                Vector2(w * 0.485, ground)
            ]),
            Color(0.68, 0.48, 0.23, 0.16)
        )

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
    # Full-screen fantasy background
    var background := ColorRect.new()
    background.name = "Background"
    background.color = Color("#0A1222")
    background.set_anchors_and_offsets_preset(
        Control.PRESET_FULL_RECT
    )
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    # Distant landscape
    var horizon := ColorRect.new()
    horizon.name = "FantasyHorizon"
    horizon.color = Color("#182D3B")
    horizon.anchor_left = 0.0
    horizon.anchor_right = 1.0
    horizon.anchor_top = 0.56
    horizon.anchor_bottom = 1.0
    horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(horizon)

    # Atmospheric moon and stars
    var sky_art := Label.new()
    sky_art.name = "FantasySky"
    sky_art.text = "✦     ·       ✧      ·      ☾      ·       ✦"
    sky_art.add_theme_font_size_override("font_size", 30)
    sky_art.add_theme_color_override(
        "font_color", Color("#D9C18A")
    )
    sky_art.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sky_art.anchor_left = 0.0
    sky_art.anchor_right = 1.0
    sky_art.anchor_top = 0.10
    sky_art.anchor_bottom = 0.22
    sky_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(sky_art)

    # Castle silhouette
    var castle := Label.new()
    castle.name = "CastleSilhouette"
    castle.text = "♜       ♜       ♜"
    castle.add_theme_font_size_override("font_size", 64)
    castle.add_theme_color_override(
        "font_color", Color("#263D4A")
    )
    castle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    castle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    castle.anchor_left = 0.0
    castle.anchor_right = 1.0
    castle.anchor_top = 0.52
    castle.anchor_bottom = 0.78
    castle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(castle)

    # Gold-framed menu panel
    var glow := Panel.new()
    glow.name = "MenuBackdrop"
    glow.anchor_left = 0.5
    glow.anchor_right = 0.5
    glow.anchor_top = 0.08
    glow.anchor_bottom = 0.94
    glow.offset_left = -225
    glow.offset_right = 225
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("#091322")
    panel_style.bg_color.a = 0.97
    panel_style.border_color = Color("#B69A61")
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(14)
    panel_style.shadow_color = Color(0, 0, 0, 0.45)
    panel_style.shadow_size = 12
    glow.add_theme_stylebox_override("panel", panel_style)
    add_child(glow)

    # Existing menu content and navigation remain below

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
