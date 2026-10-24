
extends Node3D

const PlayerScript = preload("res://player.gd")
const EnemyScript = preload("res://enemy.gd")

const MOBS_REQUIRED := 3
const PATH_MOBS_REQUIRED := 5

var player: CharacterBody3D
var elder: Node3D
var status_label: Label
var economy_label: Label
var quest_label: Label
var message_label: Label

var hero_class := "Warrior"
var hero_gender := "male"
var xp := 0
var silver := 0
var chore_gold := 0

# Quest 1
var quest_stage := 0
var logs_collected := 0
var log_resources: Array[Node3D] = []

# Quest 2
var mob_quest_stage := 0
var mobs_defeated := 0

# Quest 3
var quest3_stage := 0

# Quest 4
var quest4_stage := 0
var crates_found := 0
var supply_crates: Array[Node3D] = []

# Quest 5
var quest5_stage := 0
var path_mobs_defeated := 0


func _ready() -> void:
    if get_node_or_null("/root/PlayerProfile") != null:
        var profile = get_node("/root/PlayerProfile")
        hero_class = str(profile.get("selected_class"))
        hero_gender = str(profile.get("selected_gender"))

    _create_environment()
    _build_village()
    _build_hearthvale_expansion()
    _build_quest_objects()

    player = CharacterBody3D.new()
    player.name = "Hero"
    player.set_script(PlayerScript)
    player.set("hero_class", hero_class)
    player.set("hero_gender", hero_gender)
    player.position = Vector3(0, 1, 4)
    add_child(player)

    _make_hud()
    _message("Welcome to Hearthvale! Find the Village Elder to begin.")
    _refresh()


# --------------------------------------------------
# WORLD AND LIGHTING
# --------------------------------------------------

func _create_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.48, 0.72, 0.9)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.8, 0.86, 1.0)
    env.ambient_light_energy = 0.8
    world.environment = env
    add_child(world)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -25, 0)
    light.shadow_enabled = true
    add_child(light)

    _add_box(
        "MainGround",
        Vector3(0, -0.3, 10),
        Vector3(70, 0.5, 100),
        Color(0.32, 0.55, 0.28),
        true
    )


func _build_village() -> void:
    _add_box(
        "VillageSquare",
        Vector3(0, -0.02, -3),
        Vector3(20, 0.12, 15),
        Color("#B9A27B"),
        false
    )

    _add_box(
        "ForestRoad",
        Vector3(0, -0.015, 18),
        Vector3(7, 0.1, 43),
        Color("#B9A27B"),
        false
    )

    # Village fountain
    _add_box(
        "FountainBase",
        Vector3(0, 0.16, -5),
        Vector3(3.2, 0.3, 3.2),
        Color("#9A9B91"),
        false
    )

    _add_box(
        "FountainBasin",
        Vector3(0, 0.42, -5),
        Vector3(2.8, 0.55, 2.8),
        Color("#7E8E98"),
        false
    )

    _add_box(
        "FountainWater",
        Vector3(0, 0.72, -5),
        Vector3(2.25, 0.1, 2.25),
        Color("#39A9D6"),
        false
    )

    _add_box(
        "FountainPillar",
        Vector3(0, 1.05, -5),
        Vector3(0.35, 0.7, 0.35),
        Color("#C3C8C5"),
        false
    )

    # Original village shops
    _build_house(Vector3(-8, 0, -7), Color("#8A5435"), "Blacksmith")
    _build_house(Vector3(8, 0, -7), Color("#60788A"), "ArmorShop")
    _build_house(Vector3(8, 0, 1), Color("#93609A"), "Tailor")

    # Training yard
    _add_box(
        "TrainingYard",
        Vector3(-8, 0.08, 2),
        Vector3(6, 0.16, 5),
        Color("#9C8156"),
        false
    )

    for x in [-11.0, -8.0, -5.0]:
        _add_box(
            "TrainingFence",
            Vector3(x, 0.75, 4.8),
            Vector3(0.18, 1.5, 0.18),
            Color("#654329"),
            true
        )

    _add_box(
        "TrainingRail",
        Vector3(-8, 1.0, 4.8),
        Vector3(6, 0.14, 0.14),
        Color("#654329"),
        false
    )

    # Woods gate
    _add_box(
        "WoodsGateLeft",
        Vector3(-3.8, 1.5, 12),
        Vector3(0.7, 3, 1),
        Color("#654329"),
        true
    )

    _add_box(
        "WoodsGateRight",
        Vector3(3.8, 1.5, 12),
        Vector3(0.7, 3, 1),
        Color("#654329"),
        true
    )

    _add_box(
        "WoodsGateHeader",
        Vector3(0, 3, 12),
        Vector3(8, 0.5, 1),
        Color("#654329"),
        false
    )

    # Trees along the edges
    for i in range(12):
        var z := 15.0 + i * 2.7
        _build_tree(Vector3(-10, 0, z))
        _build_tree(Vector3(10, 0, z))

    for i in range(10):
        var z := -10.0 + i * 5.0
        _build_tree(Vector3(-27, 0, z))
        _build_tree(Vector3(27, 0, z))

    _add_box(
        "SouthBoundary",
        Vector3(0, 1, 58),
        Vector3(60, 2, 1),
        Color("#355B31"),
        true
    )


# --------------------------------------------------
# EXPANDED HEARTHVALE TOWN AND CASTLE
# --------------------------------------------------

func _build_hearthvale_expansion() -> void:
    _add_box(
        "CastleDistrictGround",
        Vector3(0, -0.32, -37),
        Vector3(70, 0.45, 100),
        Color("#477C40"),
        true
    )

    _add_box(
        "CastleApproachRoad",
        Vector3(0, -0.02, -34),
        Vector3(12, 0.12, 68),
        Color("#B9A27B"),
        false
    )

    _add_box(
        "MarketSquare",
        Vector3(0, 0.02, -22),
        Vector3(34, 0.15, 18),
        Color("#C8B58E"),
        false
    )

    # Market district buildings
    _build_house(Vector3(-15, 0, -20), Color("#9A6546"), "Baker")
    _build_house(Vector3(15, 0, -20), Color("#526E8A"), "GeneralStore")
    _build_house(Vector3(-17, 0, -33), Color("#A18454"), "Inn")
    _build_house(Vector3(17, 0, -33), Color("#76518A"), "Apothecary")
    _build_house(Vector3(-13, 0, -44), Color("#8A5541"), "TownHouse")
    _build_house(Vector3(13, 0, -44), Color("#54765A"), "TownHouse")

    # Market stalls
    _add_box(
        "MarketStallRed",
        Vector3(-6, 1.2, -23),
        Vector3(4, 2.4, 3),
        Color("#9B4D36"),
        false
    )

    _add_box(
        "MarketStallBlue",
        Vector3(6, 1.2, -23),
        Vector3(4, 2.4, 3),
        Color("#426A99"),
        false
    )

    _add_box(
        "MarketStallRoofRed",
        Vector3(-6, 2.5, -23),
        Vector3(4.6, 0.25, 3.6),
        Color("#D4B36D"),
        false
    )

    _add_box(
        "MarketStallRoofBlue",
        Vector3(6, 2.5, -23),
        Vector3(4.6, 0.25, 3.6),
        Color("#7194BA"),
        false
    )

    # Castle courtyard
    _add_box(
        "CastleCourtyard",
        Vector3(0, 0.02, -62),
        Vector3(42, 0.15, 24),
        Color("#8B8C89"),
        false
    )

    var stone := Color("#777D87")
    var dark_stone := Color("#555B66")

    _add_box(
        "CastleBackWall",
        Vector3(0, 4, -77),
        Vector3(42, 8, 2),
        stone,
        true
    )

    _add_box(
        "CastleLeftWall",
        Vector3(-20, 4, -64),
        Vector3(2, 8, 26),
        stone,
        true
    )

    _add_box(
        "CastleRightWall",
        Vector3(20, 4, -64),
        Vector3(2, 8, 26),
        stone,
        true
    )

    _add_box(
        "CastleFrontLeft",
        Vector3(-13, 4, -51),
        Vector3(16, 8, 2),
        stone,
        true
    )

    _add_box(
        "CastleFrontRight",
        Vector3(13, 4, -51),
        Vector3(16, 8, 2),
        stone,
        true
    )

    _add_box(
        "CastleGatehouse",
        Vector3(0, 6, -51),
        Vector3(9, 12, 4),
        dark_stone,
        false
    )

    _add_box(
        "CastleGate",
        Vector3(0, 3, -48.7),
        Vector3(5, 6, 0.35),
        Color("#402719"),
        false
    )

    _add_box(
        "CastleKeep",
        Vector3(0, 7, -69),
        Vector3(18, 14, 16),
        Color("#626975"),
        true
    )

    _build_tower(Vector3(-16, 0, -73), 15)
    _build_tower(Vector3(16, 0, -73), 15)
    _build_tower(Vector3(-16, 0, -53), 12)
    _build_tower(Vector3(16, 0, -53), 12)

    _add_box(
        "KeepRoof",
        Vector3(0, 14.5, -69),
        Vector3(19, 1, 17),
        Color("#343E50"),
        false
    )

    _add_box(
        "CastleBannerLeft",
        Vector3(-8, 9, -60),
        Vector3(1.3, 4, 0.15),
        Color("#315EA0"),
        false
    )

    _add_box(
        "CastleBannerRight",
        Vector3(8, 9, -60),
        Vector3(1.3, 4, 0.15),
        Color("#315EA0"),
        false
    )

    # Trees around the outskirts
    for i in range(12):
        var x := -31.0 + float(i) * 5.5
        _build_tree(Vector3(x, 0, -13))
        _build_tree(Vector3(x, 0, -47))

    for i in range(8):
        var z := -18.0 - float(i) * 7.0
        _build_tree(Vector3(-29, 0, z))
        _build_tree(Vector3(29, 0, z))


# --------------------------------------------------
# HOUSE BUILDING
# --------------------------------------------------

func _build_house(p: Vector3, house_color: Color, house_name: String) -> void:
    # Floor inside the house
    _add_box(
        house_name + "InteriorFloor",
        p + Vector3(0, 0.08, 0),
        Vector3(5.8, 0.16, 5.8),
        Color("#9B8060"),
        true
    )

    # Left wall
    _add_box(
        house_name + "LeftWall",
        p + Vector3(-2.9, 2.2, 0),
        Vector3(0.2, 4.4, 6.0),
        house_color,
        true
    )

    # Right wall
    _add_box(
        house_name + "RightWall",
        p + Vector3(2.9, 2.2, 0),
        Vector3(0.2, 4.4, 6.0),
        house_color,
        true
    )

    # Back wall
    _add_box(
        house_name + "BackWall",
        p + Vector3(0, 2.2, -2.9),
        Vector3(6.0, 4.4, 0.2),
        house_color,
        true
    )

    # Front wall left of the entrance
    _add_box(
        house_name + "FrontLeftWall",
        p + Vector3(-2.0, 2.2, 2.9),
        Vector3(2.0, 4.4, 0.2),
        house_color,
        true
    )

    # Front wall right of the entrance
    _add_box(
        house_name + "FrontRightWall",
        p + Vector3(2.0, 2.2, 2.9),
        Vector3(2.0, 4.4, 0.2),
        house_color,
        true
    )

    # Wall above the doorway
    _add_box(
        house_name + "DoorHeader",
        p + Vector3(0, 3.35, 2.9),
        Vector3(2.0, 2.1, 0.2),
        house_color,
        true
    )

    # Roof is visual only
    _add_box(
        house_name + "Roof",
        p + Vector3(0, 4.65, 0),
        Vector3(6.8, 0.6, 6.8),
        Color("#49352D"),
        false
    )

    # Door placed at the side of the entrance
    _add_box(
        house_name + "Door",
        p + Vector3(0.65, 1.05, 2.78),
        Vector3(0.65, 2.1, 0.12),
        Color("#4A2B1A"),
        false
    )

    # Front windows
    _add_box(
        house_name + "WindowLeft",
        p + Vector3(-2.0, 2.3, 3.02),
        Vector3(0.75, 0.9, 0.1),
        Color("#9ED5E0"),
        false
    )

    _add_box(
        house_name + "WindowRight",
        p + Vector3(2.0, 2.3, 3.02),
        Vector3(0.75, 0.9, 0.1),
        Color("#9ED5E0"),
        false
    )

    # Interior counter
    _add_box(
        house_name + "InteriorCounter",
        p + Vector3(0, 0.65, -1.25),
        Vector3(2.0, 0.9, 0.7),
        Color("#654329"),
        true
    )


func _build_tower(p: Vector3, tower_height: float) -> void:
    _add_box(
        "CastleTower",
        p + Vector3(0, tower_height / 2.0, 0),
        Vector3(5, tower_height, 5),
        Color("#747B87"),
        true
    )

    _add_box(
        "CastleTowerTop",
        p + Vector3(0, tower_height + 0.4, 0),
        Vector3(6, 0.8, 6),
        Color("#414956"),
        false
    )


func _build_tree(p: Vector3) -> void:
    var trunk := _add_box(
        "TreeTrunk",
        p + Vector3(0, 1, 0),
        Vector3(0.55, 2, 0.55),
        Color("#573820"),
        true
    )

    var greens := [
        Color("#245C2D"),
        Color("#2F7135"),
        Color("#3A7B3D")
    ]

    var offsets := [
        Vector3(0, 2.55, 0),
        Vector3(-0.55, 2.25, 0.15),
        Vector3(0.5, 2.35, -0.15)
    ]

    for i in range(3):
        var crown := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 1.4 if i == 0 else 1.0
        mesh.height = mesh.radius * 2.0
        crown.mesh = mesh
        crown.position = offsets[i]

        var mat := StandardMaterial3D.new()
        mat.albedo_color = greens[i]
        crown.material_override = mat
        trunk.add_child(crown)


# --------------------------------------------------
# QUEST OBJECTS
# --------------------------------------------------

func _build_quest_objects() -> void:
    elder = Node3D.new()
    elder.name = "VillageElder"
    elder.position = Vector3(0, 0, -1)
    add_child(elder)

    var elder_mesh := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.48
    capsule.height = 1.9
    elder_mesh.mesh = capsule
    elder_mesh.position.y = 0.95

    var elder_mat := StandardMaterial3D.new()
    elder_mat.albedo_color = Color("#B8A16A")
    elder_mesh.material_override = elder_mat
    elder.add_child(elder_mesh)

    var elder_label := Label3D.new()
    elder_label.text = "Village Elder"
    elder_label.position = Vector3(0, 2.1, 0)
    elder_label.pixel_size = 0.01
    elder.add_child(elder_label)

    _add_quest_marker(
        elder,
        "!",
        Vector3(0, 2.8, 0),
        Color("#F4CF57")
    )

    var log_positions := [
        Vector3(-9, 0.1, 18),
        Vector3(1, 0.1, 25),
        Vector3(10, 0.1, 20)
    ]

    for i in range(log_positions.size()):
        var log_node := _add_box(
            "WoodenLog%d" % i,
            log_positions[i],
            Vector3(1.4, 0.35, 0.45),
            Color("#613A20"),
            true
        )

        log_node.set_meta("quest_log", true)
        log_resources.append(log_node)

        _add_quest_marker(
            log_node,
            "◆",
            Vector3(0, 0.8, 0),
            Color("#E6C16A")
        )


func _add_quest_marker(
    target: Node3D,
    marker_text: String,
    offset: Vector3,
    marker_color: Color
) -> void:
    var marker := Node3D.new()
    marker.position = offset
    target.add_child(marker)

    var mesh_instance := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.16
    sphere.height = 0.32
    mesh_instance.mesh = sphere

    var mat := StandardMaterial3D.new()
    mat.albedo_color = marker_color
    mat.emission_enabled = true
    mat.emission = marker_color
    mesh_instance.material_override = mat
    marker.add_child(mesh_instance)

    var label := Label3D.new()
    label.text = marker_text
    label.position.y = 0.22
    label.pixel_size = 0.012
    label.modulate = marker_color
    marker.add_child(label)


func _add_box(
    object_name: String,
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

    parent.name = object_name
    parent.position = p
    add_child(parent)

    var mesh_instance := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = s
    mesh_instance.mesh = box

    var material := StandardMaterial3D.new()
    material.albedo_color = c
    mesh_instance.material_override = material
    parent.add_child(mesh_instance)

    return parent


# --------------------------------------------------
# HUD AND CONTROLS
# --------------------------------------------------

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "GameHUD"
    add_child(layer)

    var panel := PanelContainer.new()
    panel.position = Vector2(15, 15)
    panel.size = Vector2(570, 175)
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

    var interact_button := Button.new()
    interact_button.text = "INTERACT"
    interact_button.anchor_left = 1.0
    interact_button.anchor_right = 1.0
    interact_button.anchor_top = 1.0
    interact_button.anchor_bottom = 1.0
    interact_button.offset_left = -220
    interact_button.offset_right = -20
    interact_button.offset_top = -165
    interact_button.offset_bottom = -95
    interact_button.pressed.connect(_interact)
    layer.add_child(interact_button)

    var attack_button := Button.new()
    attack_button.text = "ATTACK"
    attack_button.anchor_left = 1.0
    attack_button.anchor_right = 1.0
    attack_button.anchor_top = 1.0
    attack_button.anchor_bottom = 1.0
    attack_button.offset_left = -220
    attack_button.offset_right = -20
    attack_button.offset_top = -85
    attack_button.offset_bottom = -15
    attack_button.pressed.connect(_attack)
    layer.add_child(attack_button)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack", false):
        _attack()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("interact", false):
        _interact()
        get_viewport().set_input_as_handled()


# --------------------------------------------------
# COMBAT
# --------------------------------------------------

func _attack() -> void:
    if not is_instance_valid(player):
        return

    var nearest: Node = null
    var best_distance := 3.8

    for node in get_children():
        if node is CharacterBody3D and node != player and node.has_method("take_hit"):
            var distance := _flat_distance(
                player.global_position,
                node.global_position
            )

            if distance < best_distance:
                best_distance = distance
                nearest = node

    if nearest != null:
        var damage := 35

        if nearest.get("is_boss"):
            damage = 20

        nearest.call("take_hit", damage)
        _message(
            "%s attacks %s." % [
                hero_class,
                str(nearest.get("enemy_name"))
            ]
        )
    else:
        _message("Move closer to an enemy to attack.")


func enemy_defeated(e: Node) -> void:
    if mob_quest_stage == 1 and e.has_meta("clear_woods_target") and not e.get("is_boss"):
        mobs_defeated += 1

        if mobs_defeated >= MOBS_REQUIRED:
            mob_quest_stage = 2
            _message("All 3 monsters defeated! Return to the Village Elder.")
        else:
            _message("Clear the Woods: %d/3 defeated." % mobs_defeated)

    if quest3_stage == 1 and e.name == "Mossjaw":
        quest3_stage = 2
        _message("Mossjaw defeated! Return to the Village Elder.")

    if quest5_stage == 1 and e.has_meta("path_quest_target") and not e.get("is_boss"):
        path_mobs_defeated += 1

        if path_mobs_defeated >= PATH_MOBS_REQUIRED:
            quest5_stage = 2
            _message("The path is clear! Return to the Village Elder.")
        else:
            _message(
                "Keep the Path Safe: %d/5 defeated." %
                path_mobs_defeated
            )

    xp += 30 if e.get("is_boss") else 10
    silver += 100 if e.get("is_boss") else 15

    _refresh()

    _message(
        "%s defeated! Earned XP and Silver. Combat does not award Chore Gold."
        % str(e.get("enemy_name"))
    )


func _spawn_quest_mobs() -> void:
    var names := [
        "Forest Slime",
        "Woodland Goblin",
        "Thornwolf"
    ]

    var positions := [
        Vector3(-7, 1, 23),
        Vector3(0, 1, 27),
        Vector3(7, 1, 23)
    ]

    for i in range(MOBS_REQUIRED):
        var mob := CharacterBody3D.new()
        mob.name = "QuestMob%d" % (i + 1)
        mob.set_script(EnemyScript)
        mob.set("enemy_name", names[i])
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
    boss.position = Vector3(0, 1.5, 34)
    boss.set("player", player)
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
            Vector3(1, 1, 1),
            Color("#8B5229"),
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
        mob.position = positions[i]
        mob.set("player", player)
        mob.set_meta("path_quest_target", true)
        add_child(mob)


# --------------------------------------------------
# INTERACTIONS AND QUEST PROGRESSION
# --------------------------------------------------

func _interact() -> void:
    if not is_instance_valid(player):
        return

    var p: Vector3 = player.global_position

    # Collect logs for Quest 1
    if quest_stage == 1:
        var closest_log: Node3D = null
        var closest_distance := 3.5

        for item in log_resources:
            if is_instance_valid(item):
                var d := _flat_distance(p, item.global_position)

                if d <= closest_distance:
                    closest_distance = d
                    closest_log = item

        if closest_log != null:
            log_resources.erase(closest_log)
            closest_log.queue_free()
            logs_collected += 1

            if logs_collected >= 3:
                quest_stage = 2
                _message("You collected all 3 logs. Return to the Village Elder.")
            else:
                _message("Wood collected: %d/3." % logs_collected)

            _refresh()
            return

    # Collect supply crates for Quest 4
    if quest4_stage == 1:
        var closest_crate: Node3D = null
        var closest_distance := 3.5

        for item in supply_crates:
            if is_instance_valid(item):
                var d := _flat_distance(p, item.global_position)

                if d <= closest_distance:
                    closest_distance = d
                    closest_crate = item

        if closest_crate != null:
            supply_crates.erase(closest_crate)
            closest_crate.queue_free()
            crates_found += 1

            if crates_found >= 3:
                quest4_stage = 2
                _message("All 3 crates found! Return to the Village Elder.")
            else:
                _message("Supplies found: %d/3." % crates_found)

            _refresh()
            return

    # Talk to the Village Elder
    if is_instance_valid(elder) and _flat_distance(p, elder.global_position) <= 5.5:
        if quest_stage == 0:
            quest_stage = 1
            _message("Village Elder: Gather 3 wooden logs for Hearthvale.")

        elif quest_stage == 1:
            _message(
                "Village Elder: Bring me 3 logs. Collected: %d/3."
                % logs_collected
            )

        elif quest_stage == 2:
            quest_stage = 3
            xp += 50
            silver += 75
            _message("Quest complete: A New Beginning! +50 XP, +75 Silver.")

        elif mob_quest_stage == 0:
            mob_quest_stage = 1
            mobs_defeated = 0
            _spawn_quest_mobs()
            _message("Quest 2: Defeat 3 monsters in Whispering Woods.")

        elif mob_quest_stage == 1:
            _message("Defeat the monsters: %d/3." % mobs_defeated)

        elif mob_quest_stage == 2:
            mob_quest_stage = 3
            xp += 75
            silver += 100
            _message("Quest complete: Clear the Woods! +75 XP, +100 Silver.")

        elif quest3_stage == 0:
            quest3_stage = 1
            _spawn_mossjaw()
            _message("Quest 3: Defeat Mossjaw, then return to the Elder.")

        elif quest3_stage == 1:
            _message("Mossjaw is still in the woods. Defeat him!")

        elif quest3_stage == 2:
            quest3_stage = 3
            xp += 150
            silver += 200
            _message("Quest complete: Mossjaw's Challenge! +150 XP, +200 Silver.")

        elif quest4_stage == 0:
            quest4_stage = 1
            crates_found = 0
            _spawn_supply_crates()
            _message("Quest 4: Find the 3 missing supply crates.")

        elif quest4_stage == 1:
            _message("Find the missing crates: %d/3." % crates_found)

        elif quest4_stage == 2:
            quest4_stage = 3
            xp += 100
            silver += 125
            _message("Quest complete: Lost Supplies! +100 XP, +125 Silver.")

        elif quest5_stage == 0:
            quest5_stage = 1
            path_mobs_defeated = 0
            _spawn_path_mobs()
            _message("Quest 5: Defeat 5 monsters along the path.")

        elif quest5_stage == 1:
            _message(
                "Secure the path: %d/5 monsters defeated."
                % path_mobs_defeated
            )

        elif quest5_stage == 2:
            quest5_stage = 3
            xp += 125
            silver += 150
            _message("Quest complete: Keep the Path Safe! +125 XP, +150 Silver.")

        else:
            _message("Hearthvale is safer because of you, hero!")

        _refresh()
        return

    # Town interactions
    if _flat_distance(p, Vector3(0, 0, -5)) < 5:
        _message("Village fountain: Welcome to Hearthvale!")

    elif _flat_distance(p, Vector3(-8, 0, -7)) < 5:
        _message("Blacksmith: Weapon shop coming soon.")

    elif _flat_distance(p, Vector3(8, 0, -7)) < 5:
        _message("Armor shop: Class-specific gear coming soon.")

    elif _flat_distance(p, Vector3(8, 0, 1)) < 4.5:
        _message("Tailor: Appearance customization coming soon.")

    elif p.z < -48:
        _message("Castle district: The castle will host future quests.")

    elif p.z > 12:
        _message("Whispering Woods: Explore the path and gather resources.")

    else:
        _message("Explore Hearthvale and interact with people and objects.")


func _flat_distance(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


# --------------------------------------------------
# HUD REFRESH
# --------------------------------------------------

func _refresh() -> void:
    var hp_value := 100

    if is_instance_valid(player):
        hp_value = int(player.get("hp"))

    if is_instance_valid(status_label):
        status_label.text = "HERO: %s  |  HP: %d/100" % [
            hero_class,
            hp_value
        ]

    if is_instance_valid(economy_label):
        economy_label.text = "XP: %d  |  Silver: %d  |  Chore Gold: %d" % [
            xp,
            silver,
            chore_gold
        ]

    if not is_instance_valid(quest_label):
        return

    if quest_stage == 0:
        quest_label.text = "Quest 1: Talk to the Village Elder"

    elif quest_stage == 1:
        quest_label.text = "Quest 1: Collect wooden logs (%d/3)" % logs_collected

    elif quest_stage == 2:
        quest_label.text = "Quest 1: Return to the Village Elder"

    elif mob_quest_stage == 0:
        quest_label.text = "Quest 1 complete: Talk to the Elder for Quest 2"

    elif mob_quest_stage == 1:
        quest_label.text = "Quest 2: Defeat monsters (%d/3)" % mobs_defeated

    elif mob_quest_stage == 2:
        quest_label.text = "Quest 2: Return to the Village Elder"

    elif quest3_stage == 0:
        quest_label.text = "Quest 2 complete: Talk to the Elder for Quest 3"

    elif quest3_stage == 1:
        quest_label.text = "Quest 3: Defeat Mossjaw"

    elif quest3_stage == 2:
        quest_label.text = "Quest 3: Return to the Village Elder"

    elif quest4_stage == 0:
        quest_label.text = "Quest 3 complete: Talk to the Elder for Quest 4"

    elif quest4_stage == 1:
        quest_label.text = "Quest 4: Find supply crates (%d/3)" % crates_found

    elif quest4_stage == 2:
        quest_label.text = "Quest 4: Return to the Village Elder"

    elif quest5_stage == 0:
        quest_label.text = "Quest 4 complete: Talk to the Elder for Quest 5"

    elif quest5_stage == 1:
        quest_label.text = "Quest 5: Defeat path monsters (%d/5)" % path_mobs_defeated

    elif quest5_stage == 2:
        quest_label.text = "Quest 5: Return to the Village Elder"

    else:
        quest_label.text = "Demo complete: All 5 quests finished!"


func _message(t: String) -> void:
    if is_instance_valid(message_label):
        message_label.text = t

    print(t)
