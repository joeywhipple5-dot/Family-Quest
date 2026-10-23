extends Node3D

const PlayerScript = preload("res://player.gd")
const EnemyScript = preload("res://enemy.gd")

var player: CharacterBody3D
var status_label: Label
var economy_label: Label
var quest_label: Label
var message_label: Label

var hero_class := "Warrior"
var xp := 0
var silver := 0
var chore_gold := 0

var quest_stage := 0
var logs_collected := 0
var log_resources: Array[Node3D] = []
var elder: Node3D

var mob_quest_stage := 0
var mobs_defeated := 0
var quest3_stage := 0
var quest4_stage := 0
var crates_found := 0
var supply_crates: Array[Node3D] = []
var quest5_stage := 0
var path_mobs_defeated := 0

const MOBS_REQUIRED := 3
const PATH_MOBS_REQUIRED := 5


func _ready() -> void:
    _create_environment()
    _build_village()
    _build_quest_objects()

    # Read the selected class safely.
    var profile := get_node_or_null("/root/PlayerProfile")
    if profile != null:
        var selected = profile.get("selected_class")
        if selected is String:
            if selected in ["Warrior", "Mage", "Rogue", "Druid", "Ranger"]:
                hero_class = selected

    # Create the player from the actual player script.
    var new_player = PlayerScript.new()

    if not new_player is CharacterBody3D:
        _show_error("player.gd must extend CharacterBody3D.")
        return

    player = new_player as CharacterBody3D
    player.name = "Hero"
    player.set("hero_class", hero_class)
    player.position = Vector3(0, 1, 4)
    add_child(player)

    _make_hud()

    # Do not spawn enemies until the player accepts a quest.
    _message("Welcome to Hearthvale! Talk to the Village Elder.")
    _refresh()


func _show_error(message: String) -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var label := Label.new()
    label.position = Vector2(20, 30)
    label.add_theme_font_size_override("font_size", 24)
    label.text = "FAMILY QUEST ERROR\n" + message
    layer.add_child(label)

    push_error(message)


func _create_environment() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()

    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.48, 0.72, 0.9)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.8, 0.86, 1.0)
    environment.ambient_light_energy = 0.8

    env.environment = environment
    add_child(env)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -25, 0)
    add_child(light)

    _add_box(
        "Ground",
        Vector3(0, -0.3, 10),
        Vector3(60, 0.5, 70),
        Color(0.32, 0.55, 0.28),
        true
    )


func _build_village() -> void:
    # Village square and forest road.
    _add_box("Village Square", Vector3(0, -0.02, -3),
        Vector3(18, 0.12, 13), Color("#B9A27B"), false)

    _add_box("Forest Road", Vector3(0, -0.015, 18),
        Vector3(6.5, 0.1, 43), Color("#B9A27B"), false)

    # Blacksmith.
    _add_box("Blacksmith", Vector3(-8, 1.5, -7),
        Vector3(4, 3, 4), Color("#8A5435"), true)

    _add_box("Blacksmith Door", Vector3(-8, 0.95, -4.94),
        Vector3(0.9, 1.9, 0.12), Color("#4A2B1A"), false)

    _add_roof_piece("Blacksmith Roof Left",
        Vector3(-8.95, 3.15, -7),
        Vector3(2.7, 0.28, 4.8), 32, Color("#49352D"))

    _add_roof_piece("Blacksmith Roof Right",
        Vector3(-7.05, 3.15, -7),
        Vector3(2.7, 0.28, 4.8), -32, Color("#49352D"))

    # Armor shop.
    _add_box("Armor Shop", Vector3(8, 1.5, -7),
        Vector3(4, 3, 4), Color("#60788A"), true)

    _add_box("Armor Shop Door", Vector3(8, 0.95, -4.94),
        Vector3(0.9, 1.9, 0.12), Color("#352E2B"), false)

    _add_roof_piece("Armor Roof Left",
        Vector3(7.05, 3.15, -7),
        Vector3(2.7, 0.28, 4.8), 32, Color("#354657"))

    _add_roof_piece("Armor Roof Right",
        Vector3(8.95, 3.15, -7),
        Vector3(2.7, 0.28, 4.8), -32, Color("#354657"))

    # Tailor.
    _add_box("Tailor", Vector3(8, 1.5, 1),
        Vector3(3.5, 3, 3.5), Color("#93609A"), true)

    _add_box("Tailor Door", Vector3(8, 0.95, 2.79),
        Vector3(0.85, 1.9, 0.12), Color("#4A2B1A"), false)

    # Fountain.
    _add_box("Fountain Base", Vector3(0, 0.16, -5),
        Vector3(3.2, 0.3, 3.2), Color("#9A9B91"), false)

    _add_box("Fountain Water", Vector3(0, 0.55, -5),
        Vector3(2.25, 0.1, 2.25), Color("#39A9D6"), false)

    _add_box("Fountain Pillar", Vector3(0, 1.0, -5),
        Vector3(0.35, 0.7, 0.35), Color("#C3C8C5"), false)

    # Training yard.
    _add_box("Training Yard", Vector3(-8, 0.08, 2),
        Vector3(6, 0.16, 5), Color("#9C8156"), false)

    # Forest gate.
    _add_box("Woods Gate Left", Vector3(-3.8, 1.5, 12),
        Vector3(0.7, 3, 1), Color("#654329"), true)

    _add_box("Woods Gate Right", Vector3(3.8, 1.5, 12),
        Vector3(0.7, 3, 1), Color("#654329"), true)

    _add_box("Woods Gate Header", Vector3(0, 3, 12),
        Vector3(8, 0.5, 1), Color("#654329"), true)

    # Trees along the world boundaries.
    for i in range(11):
        _add_tree(Vector3(-25, 0, -10 + i * 5))
        _add_tree(Vector3(25, 0, -10 + i * 5))

    # Trees along the forest path.
    for i in range(12):
        var z := 15.0 + i * 2.7
        var spread := float(i % 3) * 1.5
        _add_tree(Vector3(-9.5 - spread, 0, z))
        _add_tree(Vector3(9.5 + spread, 0, z))

    _add_box("North Boundary", Vector3(0, 1, -16),
        Vector3(54, 2, 1), Color("#355B31"), true)

    _add_box("South Boundary", Vector3(0, 1, 47),
        Vector3(54, 2, 1), Color("#355B31"), true)


func _build_quest_objects() -> void:
    elder = Node3D.new()
    elder.name = "VillageElder"
    elder.position = Vector3(0, 0, -1)
    add_child(elder)

    var mesh_instance := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.48
    capsule.height = 1.9
    mesh_instance.mesh = capsule
    mesh_instance.position.y = 0.95

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.72, 0.62, 0.38)
    mesh_instance.material_override = material
    elder.add_child(mesh_instance)

    var elder_label := Label3D.new()
    elder_label.text = "Village Elder"
    elder_label.position.y = 2.1
    elder.add_child(elder_label)

    _add_quest_marker(elder, "!", Vector3(0, 2.8, 0),
        Color("#F4CF57"))

    var positions := [
        Vector3(-9, 0.1, 18),
        Vector3(1, 0.1, 25),
        Vector3(10, 0.1, 20)
    ]

    for i in range(positions.size()):
        var log_node := _add_box(
            "Wooden Log %d" % (i + 1),
            positions[i],
            Vector3(1.4, 0.35, 0.45),
            Color(0.38, 0.22, 0.1),
            true
        )

        log_node.set_meta("quest_log", true)
        log_resources.append(log_node)
        _add_quest_marker(log_node, "◆",
            Vector3(0, 0.8, 0), Color("#E6C16A"))


func _add_quest_marker(target: Node3D, text_value: String,
        offset: Vector3, marker_color: Color) -> void:
    var marker := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.16
    sphere.height = 0.32
    marker.mesh = sphere
    marker.position = offset

    var material := StandardMaterial3D.new()
    material.albedo_color = marker_color
    material.emission_enabled = true
    material.emission = marker_color
    marker.material_override = material
    target.add_child(marker)

    var label := Label3D.new()
    label.text = text_value
    label.position = offset + Vector3(0, 0.22, 0)
    target.add_child(label)


func _add_box(n: String, p: Vector3, s: Vector3,
        c: Color, solid: bool) -> Node3D:
    var parent: Node3D

    if solid:
        parent = StaticBody3D.new()

        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = s
        collision.shape = shape
        parent.add_child(collision)
    else:
        parent = Node3D.new()

    parent.name = n
    parent.position = p
    add_child(parent)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = s
    mesh_instance.mesh = mesh

    var material := StandardMaterial3D.new()
    material.albedo_color = c
    mesh_instance.material_override = material
    parent.add_child(mesh_instance)

    return parent


func _add_roof_piece(n: String, p: Vector3, s: Vector3,
        tilt: float, c: Color) -> void:
    var roof := _add_box(n, p, s, c, false)
    roof.rotation_degrees.z = tilt


func _add_tree(p: Vector3) -> void:
    _add_box("Tree Trunk", p + Vector3(0, 1, 0),
        Vector3(0.55, 2, 0.55), Color("#573820"), true)

    var crown := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.45
    sphere.height = 2.9
    crown.mesh = sphere
    crown.position = p + Vector3(0, 3, 0)

    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#2F7135")
    crown.material_override = material
    add_child(crown)


func _make_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "GameHUD"
    layer.layer = 10
    add_child(layer)

    var panel := PanelContainer.new()
    panel.position = Vector2(15, 15)
    panel.size = Vector2(570, 180)
    layer.add_child(panel)

    var column := VBoxContainer.new()
    panel.add_child(column)

    status_label = Label.new()
    column.add_child(status_label)

    economy_label = Label.new()
    column.add_child(economy_label)

    quest_label = Label.new()
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(quest_label)

    message_label = Label.new()
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(message_label)

    var attack := Button.new()
    attack.text = "ATTACK"
    attack.anchor_left = 1.0
    attack.anchor_right = 1.0
    attack.anchor_top = 1.0
    attack.anchor_bottom = 1.0
    attack.offset_left = -220
    attack.offset_right = -20
    attack.offset_top = -95
    attack.offset_bottom = -25
    attack.pressed.connect(_attack)
    layer.add_child(attack)

    var interact := Button.new()
    interact.text = "INTERACT"
    interact.anchor_left = 1.0
    interact.anchor_right = 1.0
    interact.anchor_top = 1.0
    interact.anchor_bottom = 1.0
    interact.offset_left = -220
    interact.offset_right = -20
    interact.offset_top = -165
    interact.offset_bottom = -105
    interact.pressed.connect(_interact)
    layer.add_child(interact)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack", false):
        _attack()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("interact", false):
        _interact()
        get_viewport().set_input_as_handled()


func _attack() -> void:
    if not is_instance_valid(player):
        return

    var nearest: Node = null
    var best_distance := 3.8

    for node in get_children():
        if node == player or not node is CharacterBody3D:
            continue

        if not node.has_method("take_hit"):
            continue

        var distance := Vector2(
            player.global_position.x - node.global_position.x,
            player.global_position.z - node.global_position.z
        ).length()

        if distance < best_distance:
            best_distance = distance
            nearest = node

    if nearest != null:
        nearest.call("take_hit", 35)
        _message("You attacked %s!" % str(nearest.get("enemy_name")))
    else:
        _message("Move closer to an enemy to attack.")


func _interact() -> void:
    if not is_instance_valid(player):
        return

    var p := player.global_position

    # Start or advance the village elder quest.
    if elder != null and _flat_distance(p, elder.global_position) < 5.5:
        if quest_stage == 0:
            quest_stage = 1
            _message("Elder: Collect 3 wooden logs from the forest.")
        elif quest_stage == 1:
            _message("Logs collected: %d/3." % logs_collected)
        elif quest_stage == 2:
            quest_stage = 3
            xp += 50
            silver += 75
            _message("Quest complete! Earned 50 XP and 75 Silver.")
        else:
            _advance_followup_quest()

        _refresh()
        return

    # Collect logs when the first quest is active.
    if quest_stage == 1:
        for log_node in log_resources:
            if not is_instance_valid(log_node):
                continue

            if _flat_distance(p, log_node.global_position) <= 3.5:
                log_resources.erase(log_node)
                log_node.queue_free()
                logs_collected += 1

                if logs_collected >= 3:
                    quest_stage = 2
                    _message("All logs collected! Return to the Elder.")
                else:
                    _message("Wood collected: %d/3." % logs_collected)

                _refresh()
                return

    if p.z > 12:
        _message("Whispering Woods: Explore the forest path.")
    elif _flat_distance(p, Vector3(0, 0, -5)) < 5:
        _message("Welcome to the Hearthvale fountain.")
    else:
        _message("Move closer to the Village Elder and interact.")


func _advance_followup_quest() -> void:
    if mob_quest_stage == 0:
        mob_quest_stage = 1
        mobs_defeated = 0
        _spawn_quest_mobs()
        _message("Quest 2: Defeat 3 monsters in Whispering Woods.")
    elif mob_quest_stage == 1:
        _message("Defeat monsters: %d/3." % mobs_defeated)
    elif mob_quest_stage == 2:
        mob_quest_stage = 3
        xp += 75
        silver += 100
        _message("Quest 2 complete!")
    elif quest3_stage == 0:
        quest3_stage = 1
        _spawn_mossjaw()
        _message("Quest 3: Defeat Mossjaw.")
    elif quest3_stage == 2:
        quest3_stage = 3
        xp += 150
        silver += 200
        _message("Mossjaw defeated! Quest complete.")
    elif quest3_stage == 3 and quest4_stage == 0:
        quest4_stage = 1
        _spawn_supply_crates()
        _message("Quest 4: Find 3 supply crates.")
    elif quest4_stage == 1:
        _message("Crates collected: %d/3." % crates_found)
    elif quest4_stage == 2:
        quest4_stage = 3
        xp += 100
        silver += 125
        _message("Quest 4 complete!")
    elif quest4_stage == 3 and quest5_stage == 0:
        quest5_stage = 1
        _spawn_path_mobs()
        _message("Quest 5: Defeat 5 monsters along the path.")
    elif quest5_stage == 1:
        _message("Monsters defeated: %d/5." % path_mobs_defeated)
    elif quest5_stage == 2:
        quest5_stage = 3
        xp += 125
        silver += 150
        _message("Quest 5 complete!")
    else:
        _message("All five demo quests are complete!")


func _spawn_quest_mobs() -> void:
    var names := ["Forest Slime", "Woodland Goblin", "Thornwolf"]
    var positions := [
        Vector3(-7, 1, 23),
        Vector3(0, 1, 27),
        Vector3(7, 1, 23)
    ]

    for i in range(3):
        var mob := CharacterBody3D.new()
        mob.name = "QuestMob%d" % i
        mob.set_script(EnemyScript)
        mob.set("enemy_name", names[i])
        mob.set("player", player)
        mob.position = positions[i]
        mob.set_meta("clear_woods_target", true)
        add_child(mob)


func _spawn_mossjaw() -> void:
    var boss := CharacterBody3D.new()
    boss.name = "Mossjaw"
    boss.set_script(EnemyScript)
    boss.set("enemy_name", "Mossjaw")
    boss.set("is_boss", true)
    boss.set("player", player)
    boss.position = Vector3(0, 1.5, 34)
    add_child(boss)


func _spawn_supply_crates() -> void:
    var positions := [
        Vector3(-7, 0.6, 15),
        Vector3(6, 0.6, 24),
        Vector3(2, 0.6, 31)
    ]

    for i in range(positions.size()):
        var crate := _add_box(
            "SupplyCrate%d" % i,
            positions[i],
            Vector3.ONE,
            Color("#8B542C"),
            true
        )
        supply_crates.append(crate)


func _spawn_path_mobs() -> void:
    var names := [
        "Path Slime 1",
        "Path Slime 2",
        "Path Goblin 1",
        "Path Goblin 2",
        "Path Thornwolf"
    ]

    var positions := [
        Vector3(-8, 1, 18),
        Vector3(8, 1, 20),
        Vector3(-5, 1, 26),
        Vector3(5, 1, 28),
        Vector3(0, 1, 32)
    ]

    for i in range(names.size()):
        var mob := CharacterBody3D.new()
        mob.name = names[i].replace(" ", "")
        mob.set_script(EnemyScript)
        mob.set("enemy_name", names[i])
        mob.set("player", player)
        mob.position = positions[i]
        mob.set_meta("path_quest_target", true)
        add_child(mob)


func enemy_defeated(enemy: Node) -> void:
    if mob_quest_stage == 1 and enemy.has_meta("clear_woods_target"):
        mobs_defeated += 1
        if mobs_defeated >= MOBS_REQUIRED:
            mob_quest_stage = 2
            _message("Woods cleared! Return to the Elder.")

    if quest3_stage == 1 and enemy.name == "Mossjaw":
        quest3_stage = 2
        _message("Mossjaw defeated! Return to the Elder.")

    if quest5_stage == 1 and enemy.has_meta("path_quest_target"):
        path_mobs_defeated += 1
        if path_mobs_defeated >= PATH_MOBS_REQUIRED:
            quest5_stage = 2
            _message("Path secured! Return to the Elder.")

    xp += 10
    silver += 15
    _refresh()


func _refresh() -> void:
    var hp_value := 100

    if is_instance_valid(player):
        var value = player.get("hp")
        if value != null:
            hp_value = int(value)

    if is_instance_valid(status_label):
        status_label.text = "HERO: %s | HP: %d/100" % [
            hero_class, hp_value
        ]

    if is_instance_valid(economy_label):
        economy_label.text = "XP: %d | Silver: %d | Chore Gold: %d" % [
            xp, silver, chore_gold
        ]

    if not is_instance_valid(quest_label):
        return

    if quest_stage == 0:
        quest_label.text = "Quest 1: Talk to the Village Elder"
    elif quest_stage == 1:
        quest_label.text = "Quest 1: Collect logs (%d/3)" % logs_collected
    elif quest_stage == 2:
        quest_label.text = "Quest 1: Return to the Elder"
    elif mob_quest_stage == 1:
        quest_label.text = "Quest 2: Defeat monsters (%d/3)" % mobs_defeated
    elif mob_quest_stage == 2:
        quest_label.text = "Quest 2: Return to the Elder"
    elif quest3_stage == 1:
        quest_label.text = "Quest 3: Defeat Mossjaw"
    elif quest3_stage == 2:
        quest_label.text = "Quest 3: Return to the Elder"
    elif quest4_stage == 1:
        quest_label.text = "Quest 4: Find crates (%d/3)" % crates_found
    elif quest5_stage == 1:
        quest_label.text = "Quest 5: Defeat monsters (%d/5)" % path_mobs_defeated
    else:
        quest_label.text = "Explore Hearthvale and continue your quests."


func _flat_distance(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _message(text_value: String) -> void:
    if is_instance_valid(message_label):
        message_label.text = text_value
    print(text_value)
