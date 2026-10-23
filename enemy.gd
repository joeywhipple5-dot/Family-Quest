extends CharacterBody3D
var enemy_name := "Forest Slime"
var is_boss := false
var hp := 40
var player: CharacterBody3D
var speed := 2.0
var attack_timer := 0.0
var dead := false

func _ready() -> void:
    if is_boss:
        hp = 600
    elif enemy_name == "Woodland Goblin":
        hp = 75
    elif enemy_name == "Thornwolf":
        hp = 120
    var mi := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 1.5 if is_boss else 0.8
    mesh.height = 3.0 if is_boss else 1.6
    mi.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.25,0.35,0.18) if is_boss else Color(0.22,0.65,0.28)
    mi.material_override = mat
    add_child(mi)
    var collision := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 1.5 if is_boss else 0.8
    collision.shape = shape
    add_child(collision)

func _physics_process(delta: float) -> void:
    if dead or not is_instance_valid(player):
        return
    attack_timer -= delta
    var distance := global_position.distance_to(player.global_position)
    if distance < 10 and distance > (2.5 if is_boss else 1.8):
        var dir := (player.global_position-global_position).normalized()
        velocity.x = dir.x * speed
        velocity.z = dir.z * speed
        move_and_slide()
    elif distance <= (2.5 if is_boss else 1.8) and attack_timer <= 0:
        player.hp = max(0,player.hp-(12 if is_boss else 5))
        attack_timer = 2.0
        var main := get_tree().current_scene
        if main and main.has_method("_refresh"):
            main._refresh()
            main._message("%s attacks! Hero HP: %d" % [enemy_name,player.hp])

func take_hit(damage: int) -> void:
    if dead:
        return
    hp = max(0,hp-damage)
    if hp <= 0:
        dead = true
        var main := get_tree().current_scene
        if main and main.has_method("enemy_defeated"):
            main.enemy_defeated(self)
        queue_free()
