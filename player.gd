extends CharacterBody3D
var hero_class := "Warrior"\nvar hero_gender := "male"
var hp := 100
var speed := 7.0
var gravity := 20.0
var camera_pivot: Node3D

func _ready() -> void:
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.45
    shape.height = 1.8
    collision.shape = shape
    add_child(collision)
    # Use the same class/gender model builder as character selection so the chosen hero appears in-world.
    var character_builder_script = preload("res://scripts/CharacterBuilder.gd")
    var character_builder = character_builder_script.new()
    var character_model: Node3D = character_builder.build_character(hero_class, hero_gender)
    character_model.name = "VisibleHeroModel"
    add_child(character_model)
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0,1.3,0)
    add_child(camera_pivot)
    var camera := Camera3D.new()
    camera.position = Vector3(0,4.2,7.5)
    camera.rotation_degrees = Vector3(-22,0,0)
    camera.current = true
    camera_pivot.add_child(camera)
    _make_touch_controls()

func _physics_process(delta: float) -> void:
    var v := Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), Input.get_action_strength("move_back") - Input.get_action_strength("move_forward"))
    if v.length() > 1.0:
        v = v.normalized()
    var dir := Vector3(v.x,0,v.y)
    if dir.length() > 0.05:
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        look_at(global_position + dir, Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x,0,speed*5*delta)
        velocity.z = move_toward(velocity.z,0,speed*5*delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    move_and_slide()

func _make_touch_controls() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    _touch_button(layer,"◀",Vector2(24,590),"move_left")
    _touch_button(layer,"▶",Vector2(188,590),"move_right")
    _touch_button(layer,"▲",Vector2(106,510),"move_forward")
    _touch_button(layer,"▼",Vector2(106,630),"move_back")

func _touch_button(layer: CanvasLayer, label: String, pos: Vector2, action: String) -> void:
    var b := Button.new()
    b.text = label
    b.position = pos
    b.size = Vector2(78,70)
    b.button_down.connect(func(): Input.action_press(action))
    b.button_up.connect(func(): Input.action_release(action))
    layer.add_child(b)
