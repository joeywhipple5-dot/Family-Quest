
extends Node3D

var debug_layer: CanvasLayer
var debug_background: ColorRect
var debug_label: Label


func _ready() -> void:
	_show_test_screen()


func _show_test_screen() -> void:
	# Create a screen overlay that stays visible above the 3D world.
	debug_layer = CanvasLayer.new()
	debug_layer.name = "StartupDiagnostic"
	debug_layer.layer = 100
	add_child(debug_layer)

	# Bright green background makes the test unmistakable.
	debug_background = ColorRect.new()
	debug_background.name = "TestBackground"
	debug_background.color = Color(0.0, 0.6, 0.2, 1.0)
	debug_background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	debug_layer.add_child(debug_background)

	# Display a message in the center of the screen.
	debug_label = Label.new()
	debug_label.name = "TestLabel"
	debug_label.text = "MAIN.GD IS RUNNING"
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	debug_label.add_theme_font_size_override("font_size", 30)
	debug_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)
	debug_label.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	debug_layer.add_child(debug_label)

	print("DIAGNOSTIC: main.gd _ready() executed successfully.")


func _process(_delta: float) -> void:
	# Keep the test screen visible during the diagnostic.
	if not is_instance_valid(debug_layer):
		return

	if not is_instance_valid(debug_background):
		return

	if not is_instance_valid(debug_label):
		return
