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

# A New Beginning: speak to the elder, collect three logs, then return.
# 0 = not started, 1 = gathering, 2 = return to elder, 3 = complete.
var quest_stage := 0
var logs_collected := 0
var log_resources: Array[Node3D] = []
var elder: Node3D

# Second quest: Clear the Woods
# 0 = locked, 1 = defeat three small mobs, 2 = return to elder, 3 = complete
var mob_quest_stage := 0
var mobs_defeated := 0
const MOBS_REQUIRED := 3

# Quests 3-5, unlocked in order after Clear the Woods.
var quest3_stage := 0 # 0 locked, 1 defeat Mossjaw, 2 return, 3 complete
var quest4_stage := 0 # 0 locked, 1 find crates, 2 return, 3 complete
var crates_found := 0
var supply_crates: Array[Node3D] = []
var quest5_stage := 0 # 0 locked, 1 defeat five mobs, 2 return, 3 complete
var path_mobs_defeated := 0
const PATH_MOBS_REQUIRED := 5

func _ready() -> void:
    hero_class = PlayerProfile.selected_class
    _create_environment()
    _build_village()
    _build_quest_objects()

    player = CharacterBody3D.new()
    player.name = "Hero"
    player.set_script(PlayerScript)
    player.hero_class = hero_class
    player.position = Vector3(0, 1, 4)
    add_child(player)

    var names := ["Forest Slime", "Woodland Goblin", "Thornwolf"]
    for i in range(names.size()):
        var enemy := CharacterBody3D.new()
        enemy.name = names[i].replace(" ", "")
        enemy.set_script(EnemyScript)
        enemy.enemy_name = names[i]
        enemy.position = Vector3(-5 + i * 5, 1, 20 + (i % 2) * 3)
        enemy.player = player
        add_child(enemy)

    _make_hud()
    _message("Welcome to Hearthvale! WASD to move, Space to attack, E to interact.")
    _refresh()

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
    light.shadow_enabled = true
    add_child(light)

    _add_box("Ground", Vector3(0, -0.3, 10), Vector3(60, 0.5, 70), Color(0.32, 0.55, 0.28), true)

func _build_village() -> void:
    # A readable tan stone-and-dirt road leads from the village square through the gate.
    _add_box("Village Square", Vector3(0, -0.02, -3), Vector3(18, 0.12, 13), Color("#B9A27B"), false)
    _add_box("Forest Road", Vector3(0, -0.015, 18), Vector3(6.5, 0.1, 43), Color("#B9A27B"), false)
    # Pale road edging makes the route easy to read on a phone screen.
    for z in range(-2, 39, 4):
        _add_box("Road Edge Left", Vector3(-3.45, 0.03, z), Vector3(0.18, 0.12, 2.8), Color("#D9C99D"), false)
        _add_box("Road Edge Right", Vector3(3.45, 0.03, z), Vector3(0.18, 0.12, 2.8), Color("#D9C99D"), false)

    # Central village landmarks.
    _add_box("Fountain Basin", Vector3(0, 0.35, -5), Vector3(2.8, 0.7, 2.8), Color("#7E8E98"), true)
    _add_box("Fountain Water", Vector3(0, 0.76, -5), Vector3(2.25, 0.12, 2.25), Color("#39A9D6"), false)
    _add_box("Blacksmith", Vector3(-8, 1.5, -7), Vector3(4, 3, 4), Color("#8A5435"), true)
    _add_box("Blacksmith Roof", Vector3(-8, 3.25, -7), Vector3(4.7, 0.5, 4.7), Color("#49352D"), true)
    _add_box("Blacksmith Door", Vector3(-8, 0.95, -4.94), Vector3(0.9, 1.9, 0.12), Color("#4A2B1A"), false)
    _add_box("Blacksmith Sign", Vector3(-8, 2.55, -4.75), Vector3(1.8, 0.65, 0.12), Color("#D9B66F"), false)
    _add_box("Armor Shop", Vector3(8, 1.5, -7), Vector3(4, 3, 4), Color("#60788A"), true)
    _add_box("Armor Shop Roof", Vector3(8, 3.25, -7), Vector3(4.7, 0.5, 4.7), Color("#354657"), true)
    _add_box("Armor Shop Door", Vector3(8, 0.95, -4.94), Vector3(0.9, 1.9, 0.12), Color("#352E2B"), false)
    _add_box("Armor Shop Sign", Vector3(8, 2.55, -4.75), Vector3(1.8, 0.65, 0.12), Color("#D9B66F"), false)
    _add_box("Tailor", Vector3(8, 1.5, 1), Vector3(3.5, 3, 3.5), Color("#93609A"), true)
    _add_box("Tailor Roof", Vector3(8, 3.25, 1), Vector3(4.1, 0.45, 4.1), Color("#56365E"), true)
    _add_box("Tailor Door", Vector3(8, 0.95, 2.79), Vector3(0.85, 1.9, 0.12), Color("#4A2B1A"), false)
    _add_box("Training Yard", Vector3(-8, 0.5, 2), Vector3(6, 1, 5), Color("#8B7048"), true)
    # Training-yard fence rails and posts.
    for x in [-11.0, -8.0, -5.0]:
        _add_box("Training Fence Post", Vector3(x, 0.75, 4.8), Vector3(0.18, 1.5, 0.18), Color("#654329"), true)
    _add_box("Training Fence Rail", Vector3(-8, 1.1, 4.8), Vector3(6, 0.16, 0.16), Color("#654329"), true)

    # Woods gate is an open arch; the path remains unobstructed.
    _add_box("Woods Gate Left Pillar", Vector3(-3.8, 1.5, 12), Vector3(0.7, 3, 1), Color("#654329"), true)
    _add_box("Woods Gate Right Pillar", Vector3(3.8, 1.5, 12), Vector3(0.7, 3, 1), Color("#654329"), true)
    _add_box("Woods Gate Header", Vector3(0, 3.0, 12), Vector3(8, 0.5, 1), Color("#654329"), true)
    _add_box("Gate Sign", Vector3(0, 2.55, 11.35), Vector3(2.8, 0.55, 0.14), Color("#D9B66F"), false)

    # Clear world boundaries: solid tree lines and boundary stones keep players on the playable map.
    for i in range(11):
        _add_tree(Vector3(-25, 0, -10 + i * 5))
        _add_tree(Vector3(25, 0, -10 + i * 5))
    _add_box("North Boundary", Vector3(0, 1.0, -16), Vector3(54, 2, 1), Color("#355B31"), true)
    _add_box("South Boundary", Vector3(0, 1.0, 47), Vector3(54, 2, 1), Color("#355B31"), true)

    # Tree clusters frame the route without blocking the road.
    for i in range(10):
        var z := 17.0 + i * 2.6
        _add_tree(Vector3(-10.0 - (i % 3) * 2.0, 0, z))
        _add_tree(Vector3(10.0 + (i % 3) * 2.0, 0, z))
    # Small path stones guide the eye toward the first forest encounter.
    for i in range(6):
        _add_box("Path Marker Stone", Vector3(0, 0.08, 16 + i * 4), Vector3(0.35, 0.16, 0.35), Color("#D9C99D"), false)

func _build_quest_objects() -> void:
    elder = Node3D.new()
    elder.name = "VillageElder"
    elder.position = Vector3(0, 0, -1)
    add_child(elder)

    var elder_mesh := MeshInstance3D.new()
    var elder_capsule := CapsuleMesh.new()
    elder_capsule.radius = 0.48
    elder_capsule.height = 1.9
    elder_mesh.mesh = elder_capsule
    elder_mesh.position.y = 0.95
    var elder_mat := StandardMaterial3D.new()
    elder_mat.albedo_color = Color(0.72, 0.62, 0.38)
    elder_mesh.material_override = elder_mat
    elder.add_child(elder_mesh)

    var elder_label := Label3D.new()
    elder_label.text = "Village Elder"
    elder_label.position = Vector3(0, 2.1, 0)
    elder_label.pixel_size = 0.01
    elder.add_child(elder_label)
    _add_quest_marker(elder, "!", Vector3(0, 2.8, 0), Color("#F4CF57"))

    var log_positions := [
        Vector3(-9, 0.1, 18),
        Vector3(1, 0.1, 25),
        Vector3(10, 0.1, 20)
    ]
    for i in range(log_positions.size()):
        var log_node := _add_box(
            "Wooden Log %d" % (i + 1),
            log_positions[i],
            Vector3(1.4, 0.35, 0.45),
            Color(0.38, 0.22, 0.1),
            true
        )
        log_node.set_meta("quest_log", true)
        log_resources.append(log_node)
        _add_quest_marker(log_node, "◆", Vector3(0, 0.8, 0), Color("#E6C16A"))

func _add_quest_marker(target: Node3D, marker_text: String, offset: Vector3, marker_color: Color) -> void:
    var marker_root := Node3D.new()
    marker_root.name = "QuestMarker_" + marker_text
    marker_root.position = offset
    target.add_child(marker_root)
    var marker_mesh := MeshInstance3D.new()
    var marker_shape := SphereMesh.new()
    marker_shape.radius = 0.16
    marker_shape.height = 0.32
    marker_mesh.mesh = marker_shape
    var marker_material := StandardMaterial3D.new()
    marker_material.albedo_color = marker_color
    marker_material.emission_enabled = true
    marker_material.emission = marker_color
    marker_material.emission_energy_multiplier = 0.7
    marker_mesh.material_override = marker_material
    marker_root.add_child(marker_mesh)
    var label := Label3D.new()
    label.text = marker_text
    label.position = Vector3(0, 0.22, 0)
    label.pixel_size = 0.012
    label.modulate = marker_color
    marker_root.add_child(label)

func _add_box(n: String, p: Vector3, s: Vector3, c: Color, solid: bool) -> Node3D:
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

    var mi := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = s
    mi.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = c
    mi.material_override = mat
    parent.add_child(mi)
    return parent

func _add_tree(p: Vector3) -> void:
    var tree := _add_box("Tree Trunk", p + Vector3(0, 1, 0), Vector3(0.7, 2, 0.7), Color(0.3, 0.18, 0.08), true)
    var crown := MeshInstance3D.new()
    crown.position = Vector3(0, 2.6, 0)
    var mesh := SphereMesh.new()
    mesh.radius = 1.6
    mesh.height = 3.2
    crown.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.16, 0.42, 0.19)
    crown.material_override = mat
    tree.add_child(crown)

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "GameHUD"
    add_child(layer)

    var panel := PanelContainer.new()
    panel.position = Vector2(15, 15)
    panel.size = Vector2(570, 190)
    layer.add_child(panel)

    var col := VBoxContainer.new()
    panel.add_child(col)

    status_label = Label.new()
    col.add_child(status_label)

    economy_label = Label.new()
    col.add_child(economy_label)

    quest_label = Label.new()
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    col.add_child(quest_label)

    message_label = Label.new()
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    col.add_child(message_label)

    var row := HBoxContainer.new()
    col.add_child(row)
    for c in ["Warrior", "Mage", "Rogue", "Druid", "Ranger"]:
        var b := Button.new()
        b.text = c
        b.pressed.connect(_select_class.bind(c))
        row.add_child(b)

    var attack := Button.new()
    attack.text = "ATTACK (Space)"
    attack.position = Vector2(1030, 610)
    attack.size = Vector2(210, 65)
    attack.pressed.connect(_attack)
    layer.add_child(attack)

    var interact := Button.new()
    interact.text = "INTERACT (E)"
    interact.position = Vector2(1030, 535)
    interact.size = Vector2(210, 60)
    interact.pressed.connect(_interact)
    layer.add_child(interact)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack", false):
        _attack()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("interact", false):
        _interact()
        get_viewport().set_input_as_handled()

func _select_class(c: String) -> void:
    hero_class = c
    if is_instance_valid(player):
        player.hero_class = c
    var abilities := {
        "Warrior": "Titan Smash",
        "Mage": "Starfall",
        "Rogue": "Phantom Flurry",
        "Druid": "Worldroot Surge",
        "Ranger": "Heavenpiercer"
    }
    _message("Selected %s — signature ability: %s (ability system is a prototype placeholder)." % [c, abilities[c]])
    _refresh()

func _attack() -> void:
    if not is_instance_valid(player):
        return
    var nearest: Node = null
    var best := 3.8
    for node in get_children():
        if node is CharacterBody3D and node != player and node.has_method("take_hit"):
            var d := _flat_distance(player.global_position, node.global_position)
            if d < best:
                best = d
                nearest = node
    if nearest:
        nearest.take_hit(20 if nearest.is_boss else 35)
        _message("%s attacks %s." % [hero_class, nearest.enemy_name])
    else:
        _message("Move closer to an enemy to attack.")

func _interact() -> void:
    if not is_instance_valid(player):
        return
    var p: Vector3 = player.global_position

    # Collect the closest quest log when the quest is in its gathering stage.
    if quest_stage == 1:
        var closest_log: Node3D = null
        var closest_distance := 3.5
        for log_node in log_resources:
            if is_instance_valid(log_node):
                var log_distance := _flat_distance(p, log_node.global_position)
                if log_distance <= closest_distance:
                    closest_distance = log_distance
                    closest_log = log_node
        if closest_log:
            log_resources.erase(closest_log)
            closest_log.queue_free()
            logs_collected += 1
            if logs_collected >= 3:
                quest_stage = 2
                _message("You collected all 3 logs. Return to the Village Elder.")
            else:
                _message("Wood collected: %d/3. Find the remaining logs." % logs_collected)
            _refresh()
            return

    # Quest 4: collect the closest supply crate.
    if quest4_stage == 1:
        var closest_crate: Node3D = null
        var crate_distance := 3.5
        for crate_node in supply_crates:
            if is_instance_valid(crate_node):
                var d := _flat_distance(p, crate_node.global_position)
                if d <= crate_distance:
                    crate_distance = d
                    closest_crate = crate_node
        if closest_crate:
            supply_crates.erase(closest_crate)
            closest_crate.queue_free()
            crates_found += 1
            if crates_found >= 3:
                quest4_stage = 2
                _message("All 3 supply crates found! Return to the Village Elder.")
            else:
                _message("Supplies found: %d/3." % crates_found)
            _refresh()
            return

    if is_instance_valid(elder) and _flat_distance(p, elder.global_position) <= 5.5:
        match quest_stage:
            0:
                quest_stage = 1
                _message("Village Elder: Please gather 3 wooden logs for Hearthvale.")
            1:
                _message("Village Elder: Please bring me 3 wooden logs. Collected: %d/3." % logs_collected)
            2:
                quest_stage = 3
                xp += 50
                silver += 75
                _message("Quest complete: A New Beginning! Reward: 50 XP and 75 Silver.")
            3:
                if mob_quest_stage == 0:
                    mob_quest_stage = 1
                    mobs_defeated = 0
                    _spawn_quest_mobs()
                    _message("Village Elder: Clear 3 small monsters from Whispering Woods.")
                elif mob_quest_stage == 1:
                    _message("Village Elder: Defeat the small monsters (%d/3)." % mobs_defeated)
                elif mob_quest_stage == 2:
                    mob_quest_stage = 3
                    xp += 75
                    silver += 100
                    _message("Quest complete: Clear the Woods! Reward: 75 XP and 100 Silver.")
                elif mob_quest_stage == 3:
                    if quest3_stage == 0:
                        quest3_stage = 1
                        _spawn_mossjaw()
                        _message("Quest 3: Mossjaw's Challenge — defeat Mossjaw, then return here!")
                    elif quest3_stage == 1:
                        _message("Village Elder: Mossjaw still threatens the woods. Defeat him!")
                    elif quest3_stage == 2:
                        quest3_stage = 3
                        xp += 150
                        silver += 200
                        _message("Quest complete: Mossjaw's Challenge! Reward: 150 XP and 200 Silver.")
                    elif quest3_stage == 3 and quest4_stage == 0:
                        quest4_stage = 1
                        crates_found = 0
                        _spawn_supply_crates()
                        _message("Quest 4: Lost Supplies — find 3 supply crates along the forest path.")
                    elif quest4_stage == 1:
                        _message("Village Elder: Find the missing supplies (%d/3)." % crates_found)
                    elif quest4_stage == 2:
                        quest4_stage = 3
                        xp += 100
                        silver += 125
                        _message("Quest complete: Lost Supplies! Reward: 100 XP and 125 Silver.")
                    elif quest4_stage == 3 and quest5_stage == 0:
                        quest5_stage = 1
                        path_mobs_defeated = 0
                        _spawn_path_mobs()
                        _message("Quest 5: Keep the Path Safe — defeat 5 small monsters.")
                    elif quest5_stage == 1:
                        _message("Village Elder: Secure the path (%d/5 monsters defeated)." % path_mobs_defeated)
                    elif quest5_stage == 2:
                        quest5_stage = 3
                        xp += 125
                        silver += 150
                        _message("Quest complete: Keep the Path Safe! Reward: 125 XP and 150 Silver.")
                    else:
                        _message("Village Elder: Hearthvale is safer because of you. Well done, hero!")
        _refresh()
        return

    if _flat_distance(p, Vector3(0, 0, -5)) < 5:
        _message("Village fountain: Welcome to Hearthvale!")
    elif _flat_distance(p, Vector3(-8, 0, -7)) < 5:
        _message("Blacksmith: weapon shop placeholder.")
    elif _flat_distance(p, Vector3(8, 0, -7)) < 5:
        _message("Armor shop placeholder: class-specific gear is planned.")
    elif _flat_distance(p, Vector3(8, 0, 1)) < 4.5:
        _message("Tailor: appearance customization is planned.")
    elif p.z > 12:
        _message("Whispering Woods: interact near a wooden log to gather it.")
    else:
        _message("Move near the Village Elder, fountain, or a shop, then interact.")

func _flat_distance(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _spawn_quest_mobs() -> void:
    var types := ["Forest Slime", "Woodland Goblin", "Thornwolf"]
    var positions := [Vector3(-7, 1, 23), Vector3(0, 1, 27), Vector3(7, 1, 23)]
    for i in range(MOBS_REQUIRED):
        var mob := CharacterBody3D.new()
        mob.name = "QuestMob%d" % (i + 1)
        mob.set_script(EnemyScript)
        mob.enemy_name = types[i]
        mob.position = positions[i]
        mob.player = player
        mob.set_meta("clear_woods_target", true)
        add_child(mob)

func enemy_defeated(e: Node) -> void:
    if mob_quest_stage == 1 and e.has_meta("clear_woods_target") and not e.is_boss:
        mobs_defeated += 1
        if mobs_defeated >= MOBS_REQUIRED:
            mob_quest_stage = 2
            _message("All 3 small monsters defeated! Return to the Village Elder.")
        else:
            _message("Clear the Woods: %d/3 monsters defeated." % mobs_defeated)
    if quest3_stage == 1 and e.name == "Mossjaw":
        quest3_stage = 2
        _message("Mossjaw defeated! Return to the Village Elder.")
    if quest5_stage == 1 and e.has_meta("path_quest_target") and not e.is_boss:
        path_mobs_defeated += 1
        if path_mobs_defeated >= PATH_MOBS_REQUIRED:
            quest5_stage = 2
            _message("The path is clear! Return to the Village Elder.")
        else:
            _message("Keep the Path Safe: %d/5 monsters defeated." % path_mobs_defeated)
    xp += 30 if e.is_boss else 10
    silver += 100 if e.is_boss else 15
    _refresh()
    _message("%s defeated! Earned XP and Silver. Combat never awards Chore Gold." % e.enemy_name)

func _spawn_mossjaw() -> void:
    var boss := CharacterBody3D.new()
    boss.name = "Mossjaw"
    boss.set_script(EnemyScript)
    boss.enemy_name = "Mossjaw"
    boss.is_boss = true
    boss.position = Vector3(0, 1.5, 34)
    boss.player = player
    add_child(boss)

func _spawn_supply_crates() -> void:
    var positions := [Vector3(-7, 0.6, 15), Vector3(6, 0.6, 24), Vector3(2, 0.6, 31)]
    for i in range(positions.size()):
        var crate := _add_box("SupplyCrate%d" % i, positions[i], Vector3(1.0, 1.0, 1.0), Color(0.55, 0.32, 0.14), true)
        supply_crates.append(crate)

func _spawn_path_mobs() -> void:
    var names := ["Path Slime 1", "Path Slime 2", "Path Goblin 1", "Path Goblin 2", "Path Thornwolf"]
    var positions := [Vector3(-8, 1, 18), Vector3(8, 1, 20), Vector3(-5, 1, 26), Vector3(5, 1, 28), Vector3(0, 1, 32)]
    for i in range(names.size()):
        var mob := CharacterBody3D.new()
        mob.name = names[i].replace(" ", "")
        mob.set_script(EnemyScript)
        mob.enemy_name = names[i]
        mob.position = positions[i]
        mob.player = player
        mob.set_meta("path_quest_target", true)
        add_child(mob)

func _refresh() -> void:
    var hp_value := 100
    if is_instance_valid(player):
        hp_value = player.hp
    if is_instance_valid(status_label):
        status_label.text = "HERO: %s  |  HP: %d/100" % [hero_class, hp_value]
    if is_instance_valid(economy_label):
        economy_label.text = "XP: %d  |  Silver: %d  |  Chore Gold: %d" % [xp, silver, chore_gold]
    if is_instance_valid(quest_label):
        match quest_stage:
            0:
                quest_label.text = "Quest: A New Beginning — Talk to the Village Elder"
            1:
                quest_label.text = "Quest: A New Beginning — Collect wooden logs (%d/3)" % logs_collected
            2:
                quest_label.text = "Quest: A New Beginning — Return to the Village Elder"
            3:
                match mob_quest_stage:
                    0:
                        quest_label.text = "Quest complete: A New Beginning — Talk to the Elder for your next quest"
                    1:
                        quest_label.text = "Quest: Clear the Woods — Defeat small mobs (%d/3)" % mobs_defeated
                    2:
                        quest_label.text = "Quest: Clear the Woods — Return to the Village Elder"
                    3:
                        if quest3_stage == 0:
                            quest_label.text = "Quest complete: Clear the Woods — Talk to the Elder"
                        elif quest3_stage == 1:
                            quest_label.text = "Quest 3: Mossjaw's Challenge — Defeat Mossjaw"
                        elif quest3_stage == 2:
                            quest_label.text = "Quest 3: Mossjaw's Challenge — Return to the Elder"
                        elif quest3_stage == 3 and quest4_stage == 0:
                            quest_label.text = "Quest complete: Mossjaw's Challenge — Talk to the Elder"
                        elif quest4_stage == 1:
                            quest_label.text = "Quest 4: Lost Supplies — Find crates (%d/3)" % crates_found
                        elif quest4_stage == 2:
                            quest_label.text = "Quest 4: Lost Supplies — Return to the Elder"
                        elif quest4_stage == 3 and quest5_stage == 0:
                            quest_label.text = "Quest complete: Lost Supplies — Talk to the Elder"
                        elif quest5_stage == 1:
                            quest_label.text = "Quest 5: Keep the Path Safe — Defeat mobs (%d/5)" % path_mobs_defeated
                        elif quest5_stage == 2:
                            quest_label.text = "Quest 5: Keep the Path Safe — Return to the Elder"
                        else:
                            quest_label.text = "Demo complete: All 5 quests finished!"

func _message(t: String) -> void:
    if is_instance_valid(message_label):
        message_label.text = t
    print(t)
