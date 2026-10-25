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
const MOBS_REQUIRED := 3

var quest3_stage := 0
var quest4_stage := 0
var crates_found := 0
var supply_crates: Array[Node3D] = []

var quest5_stage := 0
var path_mobs_defeated := 0
const PATH_MOBS_REQUIRED := 5


func _ready() -> void:
    _create_environment()
    _build_village()
    _build_quest_objects()

    var profile := get_node_or_null("/root/PlayerProfile")
    if profile != null:
        var saved_class = profile.get("selected_class")
        if saved_class is String and saved_class in [
            "Warrior", "Mage", "Rogue", "Druid", "Ranger"
        ]:
            hero_class = saved_class

    var new_player = PlayerScript.new()

    if not new_player is CharacterBody3D:
        push_error("player.gd must extend CharacterBody3D.")
        _show_startup_error(
            "Player script is not a CharacterBody3D."
        )
        return

    player = new_player as CharacterBody3D
    player.name = "Hero"
    add_child(player)
    player.set("hero_class", hero_class)
    player.position = Vector3(0, 2, 8)

    _make_hud()

    _message(
        "Welcome to Hearthvale! Use the joystick to move, " +
        "ATTACK to fight, and INTERACT to talk."
    )
    _refresh()


func _show_startup_error(message: String) -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var label := Label.new()
    label.position = Vector2(20, 20)
    label.add_theme_font_size_override("font_size", 24)
    label.text = "FAMILY QUEST STARTUP ERROR\n" + message
    layer.add_child(label)


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

    # Four-times the original ground area.
    _add_box(
        "Ground",
        Vector3(0, -0.3, 0),
        Vector3(120, 0.5, 140),
        Color(0.32, 0.55, 0.28),
        true
    )

    _create_world_boundaries()


func _create_world_boundaries() -> void:
    var boundary_color := Color("#355B31")

    _add_box(
        "WestBoundary",
        Vector3(-60, 2, 0),
        Vector3(2, 4, 140),
        boundary_color,
        true
    )

    _add_box(
        "EastBoundary",
        Vector3(60, 2, 0),
        Vector3(2, 4, 140),
        boundary_color,
        true
    )

    _add_box(
        "NorthBoundary",
        Vector3(0, 2, -70),
        Vector3(120, 4, 2),
        boundary_color,
        true
    )

    _add_box(
        "SouthBoundary",
        Vector3(0, 2, 70),
        Vector3(120, 4, 2),
        boundary_color,
        true
    )


func _build_village() -> void:
    # Village square and broad road into the forest.
    _add_box(
        "Village Square",
        Vector3(0, -0.02, -6),
        Vector3(36, 0.12, 26),
        Color("#B9A27B"),
        false
    )

    _add_box(
        "Forest Road",
        Vector3(0, -0.015, 28),
        Vector3(13, 0.1, 60),
        Color("#B9A27B"),
        false
    )

    # Fountain.
    _add_box(
        "Fountain Base",
        Vector3(0, 0.16, -10),
        Vector3(6.4, 0.3, 6.4),
        Color("#9A9B91"),
        false
    )

    _add_box(
        "Fountain Basin",
        Vector3(0, 0.42, -10),
        Vector3(5.6, 0.55, 5.6),
        Color("#7E8E98"),
        true
    )

    _add_box(
        "Fountain Water",
        Vector3(0, 0.72, -10),
        Vector3(4.5, 0.1, 4.5),
        Color("#39A9D6"),
        false
    )

    _add_box(
        "Fountain Pillar",
        Vector3(0, 1.05, -10),
        Vector3(0.7, 0.7, 0.7),
        Color("#C3C8C5"),
        false
    )

    # Blacksmith.
    _add_box(
        "Blacksmith",
        Vector3(-16, 3, -14),
        Vector3(8, 6, 8),
        Color("#8A5435"),
        true
    )

    _add_box(
        "Blacksmith Door",
        Vector3(-16, 1.9, -9.88),
        Vector3(1.8, 3.8, 0.24),
        Color("#4A2B1A"),
        false
    )

    _add_box(
        "Blacksmith Sign",
        Vector3(-16, 5.1, -9.5),
        Vector3(3.6, 1.3, 0.24),
        Color("#D9B66F"),
        false
    )

    # Armor shop.
    _add_box(
        "Armor Shop",
        Vector3(16, 3, -14),
        Vector3(8, 6, 8),
        Color("#60788A"),
        true
    )

    _add_box(
        "Armor Shop Door",
        Vector3(16, 1.9, -9.88),
        Vector3(1.8, 3.8, 0.24),
        Color("#352E2B"),
        false
    )

    _add_box(
        "Armor Shop Sign",
        Vector3(16, 5.1, -9.5),
        Vector3(3.6, 1.3, 0.24),
        Color("#D9B66F"),
        false
    )

    # Tailor.
    _add_box(
        "Tailor",
        Vector3(16, 3, 2),
        Vector3(7, 6, 7),
        Color("#93609A"),
        true
    )

    _add_box(
        "Tailor Door",
        Vector3(16, 1.9, 5.58),
        Vector3(1.7, 3.8, 0.24),
        Color("#4A2B1A"),
        false
    )

    # Training yard.
    _add_box(
        "Training Yard",
        Vector3(-16, 0.08, 4),
        Vector3(12, 0.16, 10),
        Color("#9C8156"),
        false
    )

    for x in [-22.0, -16.0, -10.0]:
        _add_box(
            "Training Fence Post",
            Vector3(x, 1.5, 9.6),
            Vector3(0.36, 3, 0.36),
            Color("#654329"),
            true
        )

    _add_box(
        "Training Fence Rail",
        Vector3(-16, 1.3, 9.6),
        Vector3(12, 0.28, 0.28),
        Color("#654329"),
        false
    )

    # Forest entrance gate.
    _add_box(
        "Woods Gate Left Pillar",
        Vector3(-7.6, 3, 24),
        Vector3(1.4, 6, 2),
        Color("#654329"),
        true
    )

    _add_box(
        "Woods Gate Right Pillar",
        Vector3(7.6, 3, 24),
        Vector3(1.4, 6, 2),
        Color("#654329"),
        true
    )

    _add_box(
        "Woods Gate Header",
        Vector3(0, 6, 24),
        Vector3(16, 1, 2),
        Color("#654329"),
        true
    )

    # Trees frame the village and the forest path.
    for i in range(11):
        _add_tree(Vector3(-50, 0, -25 + i * 8))
        _add_tree(Vector3(50, 0, -25 + i * 8))

    for i in range(18):
        var z := 30.0 + i * 2.8
        var spread := float(i % 3) * 2.0
        _add_tree(Vector3(-19 - spread, 0, z))
        _add_tree(Vector3(19 + spread, 0, z))

    for i in range(14):
        var z := 31.0 + i * 4.0
        var side := -1.0 if i % 2 == 0 else 1.0

        _add_box(
            "Forest Rock",
            Vector3(side * (11 + float(i % 3)), 0.5, z),
            Vector3(1.8, 1.1, 1.5),
            Color("#777B70"),
            false
        )

        _add_box(
            "Forest Grass Patch",
            Vector3(-side * (10 + float(i % 2)), 0.04, z + 2),
            Vector3(2.2, 0.08, 1.3),
            Color("#49763A"),
            false
        )

    for i in range(12):
        _add_box(
            "Path Marker Stone",
            Vector3(0, 0.16, 28 + i * 5),
            Vector3(0.7, 0.32, 0.7),
            Color("#D9C99D"),
            false
        )


func _build_quest_objects() -> void:
    # Village Elder.
    elder = Node3D.new()
    elder.name = "VillageElder"
    elder.position = Vector3(0, 0, -2)
    add_child(elder)

    var elder_mesh := MeshInstance3D.new()
    var elder_capsule := CapsuleMesh.new()
    elder_capsule.radius = 0.96
    elder_capsule.height = 3.8
    elder_mesh.mesh = elder_capsule
    elder_mesh.position.y = 1.9

    var elder_mat := StandardMaterial3D.new()
    elder_mat.albedo_color = Color(0.72, 0.62, 0.38)
    elder_mesh.material_override = elder_mat
    elder.add_child(elder_mesh)

    var elder_label := Label3D.new()
    elder_label.text = "Village Elder"
    elder_label.position = Vector3(0, 4.2, 0)
    elder_label.pixel_size = 0.02
    elder.add_child(elder_label)

    _add_quest_marker(
        elder,
        "!",
        Vector3(0, 5.6, 0),
        Color("#F4CF57")
    )

    # Three logs along the forest trail.
    var log_positions := [
        Vector3(-18, 0.2, 36),
        Vector3(2, 0.2, 50),
        Vector3(20, 0.2, 40)
    ]

    for i in range(log_positions.size()):
        var log_node := _add_box(
            "Wooden Log %d" % (i + 1),
            log_positions[i],
            Vector3(2.8, 0.7, 0.9),
            Color(0.38, 0.22, 0.1),
            true
        )

        log_node.set_meta("quest_log", true)
        log_resources.append(log_node)

        _add_quest_marker(
            log_node,
            "◆",
            Vector3(0, 1.6, 0),
            Color("#E6C16A")
        )


func _add_quest_marker(
    target: Node3D,
    marker_text: String,
    offset: Vector3,
    marker_color: Color
) -> void:
    var marker_root := Node3D.new()
    marker_root.name = "QuestMarker_" + marker_text
    marker_root.position = offset
    target.add_child(marker_root)

    var marker_mesh := MeshInstance3D.new()
    var marker_shape := SphereMesh.new()
    marker_shape.radius = 0.32
    marker_shape.height = 0.64
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
    label.position = Vector3(0, 0.44, 0)
    label.pixel_size = 0.024
    label.modulate = marker_color
    marker_root.add_child(label)
func _add_box(
    n: String,
    p: Vector3,
    s: Vector3,
    c: Color,
    solid: bool
) -> Node3D:
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


func _add_roof_piece(
    n: String,
    p: Vector3,
    s: Vector3,
    tilt_degrees: float,
    c: Color
) -> void:
    var roof := _add_box(n, p, s, c, false)
    roof.rotation_degrees.z = tilt_degrees


func _add_tree(p: Vector3) -> void:
    var tree := _add_box(
        "Tree Trunk",
        p + Vector3(0, 2, 0),
        Vector3(1.1, 4.0, 1.1),
        Color("#573820"),
        true
    )

    var greens := [
        Color("#245C2D"),
        Color("#2F7135"),
        Color("#3A7B3D")
    ]

    var offsets := [
        Vector3(0, 5.1, 0),
        Vector3(-1.1, 4.5, 0.3),
        Vector3(1.0, 4.7, -0.3)
    ]

    var sizes := [2.9, 2.0, 2.1]

    for i in range(3):
        var crown := MeshInstance3D.new()
        crown.position = offsets[i]

        var mesh := SphereMesh.new()
        mesh.radius = sizes[i]
        mesh.height = sizes[i] * 2.0
        crown.mesh = mesh

        var mat := StandardMaterial3D.new()
        mat.albedo_color = greens[i]
        crown.material_override = mat

        tree.add_child(crown)


func _make_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "GameHUD"
    layer.layer = 10
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
    attack.text = "ATTACK"
    attack.anchor_left = 1.0
    attack.anchor_right = 1.0
    attack.anchor_top = 1.0
    attack.anchor_bottom = 1.0
    attack.offset_left = -220
    attack.offset_right = -20
    attack.offset_top = -90
    attack.offset_bottom = -20
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
    interact.offset_top = -160
    interact.offset_bottom = -100
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
        player.set("hero_class", c)

        if player.has_method("set_hero_class"):
            player.call("set_hero_class", c)

    var abilities := {
        "Warrior": "Titan Smash",
        "Mage": "Starfall",
        "Rogue": "Phantom Flurry",
        "Druid": "Worldroot Surge",
        "Ranger": "Heavenpiercer"
    }

    _message(
        "Selected %s — signature ability: %s."
        % [c, abilities[c]]
    )
    _refresh()


func _attack() -> void:
    if not is_instance_valid(player):
        return

    if player.get("dead") == true:
        _message("You have fallen. Wait to respawn.")
        return

    var nearest: Node = null
    var best := 3.8

    for node in get_children():
        if (
            node is CharacterBody3D
            and node != player
            and node.has_method("take_hit")
        ):
            var d := _flat_distance(
                player.global_position,
                node.global_position
            )

            if d < best:
                best = d
                nearest = node

    if nearest != null:
        var damage := 35
        if nearest.get("is_boss") == true:
            damage = 20

        nearest.call("take_hit", damage)

        _message(
            "%s attacks %s."
            % [hero_class, str(nearest.get("enemy_name"))]
        )
    else:
        _message("Move closer to an enemy to attack.")


func _interact() -> void:
    if not is_instance_valid(player):
        return

    var p: Vector3 = player.global_position

    # Collect quest logs.
    if quest_stage == 1:
        var closest_log: Node3D = null
        var closest_distance := 7.0

        for log_node in log_resources:
            if is_instance_valid(log_node):
                var log_distance := _flat_distance(
                    p,
                    log_node.global_position
                )

                if log_distance <= closest_distance:
                    closest_distance = log_distance
                    closest_log = log_node

        if closest_log != null:
            log_resources.erase(closest_log)
            closest_log.queue_free()
            logs_collected += 1

            if logs_collected >= 3:
                quest_stage = 2
                _message(
                    "You collected all 3 logs. Return to the Village Elder."
                )
            else:
                _message(
                    "Wood collected: %d/3. Find the remaining logs."
                    % logs_collected
                )

            _refresh()
            return

    # Collect supply crates.
    if quest4_stage == 1:
        var closest_crate: Node3D = null
        var crate_distance := 7.0

        for crate_node in supply_crates:
            if is_instance_valid(crate_node):
                var d := _flat_distance(
                    p,
                    crate_node.global_position
                )

                if d <= crate_distance:
                    crate_distance = d
                    closest_crate = crate_node

        if closest_crate != null:
            supply_crates.erase(closest_crate)
            closest_crate.queue_free()
            crates_found += 1

            if crates_found >= 3:
                quest4_stage = 2
                _message(
                    "All 3 supply crates found! Return to the Village Elder."
                )
            else:
                _message(
                    "Supplies found: %d/3." % crates_found
                )

            _refresh()
            return

    # Talk to the Village Elder.
    if (
        is_instance_valid(elder)
        and _flat_distance(p, elder.global_position) <= 9.0
    ):
        match quest_stage:
            0:
                quest_stage = 1
                _message(
                    "Village Elder: Please gather 3 wooden logs for Hearthvale."
                )
            1:
                _message(
                    "Village Elder: Bring me 3 wooden logs. Collected: %d/3."
                    % logs_collected
                )
            2:
                quest_stage = 3
                xp += 50
                silver += 75
                _message(
                    "Quest complete: A New Beginning! Reward: 50 XP and 75 Silver."
                )
            3:
                _advance_followup_quest()

        _refresh()
        return

    # Nearby points of interest.
    if _flat_distance(p, Vector3(0, 0, -10)) < 9:
        _message("Village fountain: Welcome to Hearthvale!")
    elif _flat_distance(p, Vector3(-16, 0, -14)) < 9:
        _message("Blacksmith: Weapon shop placeholder.")
    elif _flat_distance(p, Vector3(16, 0, -14)) < 9:
        _message("Armor shop: Class-specific gear is planned.")
    elif _flat_distance(p, Vector3(16, 0, 2)) < 8:
        _message("Tailor: Appearance customization is planned.")
    elif p.z > 24:
        _message(
            "Whispering Woods: Interact near a wooden log or supply crate."
        )
    else:
        _message(
            "Move near the Village Elder, fountain, or a shop, then interact."
        )


func _advance_followup_quest() -> void:
    if mob_quest_stage == 0:
        mob_quest_stage = 1
        mobs_defeated = 0
        _spawn_quest_mobs()
        _message(
            "Village Elder: Clear 3 small monsters from Whispering Woods."
        )

    elif mob_quest_stage == 1:
        _message(
            "Village Elder: Defeat the small monsters (%d/3)."
            % mobs_defeated
        )

    elif mob_quest_stage == 2:
        mob_quest_stage = 3
        xp += 75
        silver += 100
        _message(
            "Quest complete: Clear the Woods! Reward: 75 XP and 100 Silver."
        )

    elif mob_quest_stage == 3 and quest3_stage == 0:
        quest3_stage = 1
        _spawn_mossjaw()
        _message(
            "Quest 3: Mossjaw's Challenge — defeat Mossjaw, then return here!"
        )

    elif quest3_stage == 1:
        _message("Village Elder: Mossjaw still threatens the woods. Defeat him!")

    elif quest3_stage == 2:
        quest3_stage = 3
        xp += 150
        silver += 200
        _message(
            "Quest complete: Mossjaw's Challenge! Reward: 150 XP and 200 Silver."
        )

    elif quest3_stage == 3 and quest4_stage == 0:
        quest4_stage = 1
        crates_found = 0
        _spawn_supply_crates()
        _message(
            "Quest 4: Lost Supplies — find 3 supply crates along the forest path."
        )

    elif quest4_stage == 1:
        _message(
            "Village Elder: Find the missing supplies (%d/3)." % crates_found
        )

    elif quest4_stage == 2:
        quest4_stage = 3
        xp += 100
        silver += 125
        _message(
            "Quest complete: Lost Supplies! Reward: 100 XP and 125 Silver."
        )

    elif quest4_stage == 3 and quest5_stage == 0:
        quest5_stage = 1
        path_mobs_defeated = 0
        _spawn_path_mobs()
        _message(
            "Quest 5: Keep the Path Safe — defeat 5 small monsters."
        )

    elif quest5_stage == 1:
        _message(
            "Village Elder: Secure the path (%d/5 monsters defeated)."
            % path_mobs_defeated
        )

    elif quest5_stage == 2:
        quest5_stage = 3
        xp += 125
        silver += 150
        _message(
            "Quest complete: Keep the Path Safe! Reward: 125 XP and 150 Silver."
        )

    else:
        _message(
            "Village Elder: Hearthvale is safer because of you. Well done, hero!"
        )
func _flat_distance(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _spawn_quest_mobs() -> void:
    var types := [
        "Forest Slime",
        "Woodland Goblin",
        "Thornwolf"
    ]

    var positions := [
        Vector3(-12, 1, 42),
        Vector3(0, 1, 46),
        Vector3(12, 1, 42)
    ]

    for i in range(types.size()):
        var mob := CharacterBody3D.new()
        mob.name = "QuestMob%d" % (i + 1)
        mob.set_script(EnemyScript)
        mob.set("enemy_name", types[i])
        mob.position = positions[i]
        mob.set("player", player)
        mob.set_meta("clear_woods_target", true)
        add_child(mob)


func _spawn_mossjaw() -> void:
    var boss := CharacterBody3D.new()
    boss.name = "Mossjaw"
    boss.set_script(EnemyScript)
    boss.set("enemy_name", "Mossjaw")
    boss.set("is_boss", true)
    boss.position = Vector3(0, 1.5, 60)
    boss.set("player", player)
    add_child(boss)

    _message("Mossjaw has appeared deep in Whispering Woods!")


func _spawn_supply_crates() -> void:
    var positions := [
        Vector3(-9, 0.6, 36),
        Vector3(9, 0.6, 46),
        Vector3(0, 0.6, 56)
    ]

    for i in range(positions.size()):
        var crate := _add_box(
            "SupplyCrate%d" % (i + 1),
            positions[i],
            Vector3(1.3, 1.2, 1.3),
            Color("#80502D"),
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
        Vector3(-12, 1, 35),
        Vector3(12, 1, 39),
        Vector3(-7, 1, 47),
        Vector3(7, 1, 51),
        Vector3(0, 1, 58)
    ]

    for i in range(names.size()):
        var mob := CharacterBody3D.new()
        mob.name = names[i].replace(" ", "")
        mob.set_script(EnemyScript)
        mob.set("enemy_name", names[i])
        mob.position = positions[i]
        mob.set("player", player)
        mob.set_meta("path_quest_target", true)
        add_child(mob)


func enemy_defeated(e: Node) -> void:
    var reward_message := "%s defeated!" % str(e.get("enemy_name"))

    if e.has_meta("clear_woods_target") and mob_quest_stage == 1:
        mobs_defeated += 1

        if mobs_defeated >= MOBS_REQUIRED:
            mob_quest_stage = 2
            reward_message += " The woods are clear. Return to the Elder!"
        else:
            reward_message += " Woods cleared: %d/3." % mobs_defeated

    elif e.name == "Mossjaw" and quest3_stage == 1:
        quest3_stage = 2
        reward_message += " Return to the Elder!"

    elif e.has_meta("path_quest_target") and quest5_stage == 1:
        path_mobs_defeated += 1

        if path_mobs_defeated >= PATH_MOBS_REQUIRED:
            quest5_stage = 2
            reward_message += " The path is safe. Return to the Elder!"
        else:
            reward_message += " Path secured: %d/5." % path_mobs_defeated

    xp += 100 if e.get("is_boss") == true else 10
    silver += 100 if e.get("is_boss") == true else 15

    _refresh()
    _message(
        "%s Reward: XP and Silver. Combat does not award Chore Gold."
        % reward_message
    )


func _refresh() -> void:
    var hp_value := 100

    if is_instance_valid(player):
        var hp_read = player.get("hp")
        if hp_read != null:
            hp_value = int(hp_read)

    if is_instance_valid(status_label):
        status_label.text = "HERO: %s | HP: %d/100" % [
            hero_class,
            hp_value
        ]

    if is_instance_valid(economy_label):
        economy_label.text = "XP: %d | Silver: %d | Chore Gold: %d" % [
            xp,
            silver,
            chore_gold
        ]

    if not is_instance_valid(quest_label):
        return

    if quest_stage == 0:
        quest_label.text = "Quest: A New Beginning — Talk to the Village Elder"

    elif quest_stage == 1:
        quest_label.text = "Quest: A New Beginning — Collect logs (%d/3)" % logs_collected

    elif quest_stage == 2:
        quest_label.text = "Quest: A New Beginning — Return to the Elder"

    elif mob_quest_stage == 0:
        quest_label.text = "A New Beginning complete — Talk to the Elder"

    elif mob_quest_stage == 1:
        quest_label.text = "Quest 2: Clear the Woods — Defeat monsters (%d/3)" % mobs_defeated

    elif mob_quest_stage == 2:
        quest_label.text = "Quest 2: Clear the Woods — Return to the Elder"

    elif quest3_stage == 1:
        quest_label.text = "Quest 3: Mossjaw's Challenge — Defeat Mossjaw"

    elif quest3_stage == 2:
        quest_label.text = "Quest 3: Mossjaw's Challenge — Return to the Elder"

    elif quest4_stage == 1:
        quest_label.text = "Quest 4: Lost Supplies — Find crates (%d/3)" % crates_found

    elif quest4_stage == 2:
        quest_label.text = "Quest 4: Lost Supplies — Return to the Elder"

    elif quest5_stage == 1:
        quest_label.text = "Quest 5: Keep the Path Safe — Defeat monsters (%d/5)" % path_mobs_defeated

    elif quest5_stage == 2:
        quest_label.text = "Quest 5: Keep the Path Safe — Return to the Elder"

    else:
        quest_label.text = "Demo complete: All 5 quests finished!"


func _message(t: String) -> void:
    if is_instance_valid(message_label):
        message_label.text = t

    print(t)
