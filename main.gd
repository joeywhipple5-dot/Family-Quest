extends Node3D

# FAMILY QUEST - HEARTHVALE DEMO
# Godot 4.3
# Main world, castle, village, five quests, combat, HUD, inventory.
# Player and enemy logic remain in separate scripts.

const PlayerScript = preload("res://player.gd")
const EnemyScript = preload("res://enemy.gd")

const WORLD_WIDTH: float = 360.0
const WORLD_DEPTH: float = 400.0
const MOBS_REQUIRED: int = 3
const PATH_MOBS_REQUIRED: int = 5

var player: CharacterBody3D
var status_label: Label
var economy_label: Label
var quest_label: Label
var message_label: Label

var health_bar: ProgressBar
var mana_bar: ProgressBar
var health_text: Label
var mana_text: Label
var hud_layer: CanvasLayer

var inventory_panel: PanelContainer
var inventory_list: VBoxContainer
var inventory_is_equipment: bool = false

var hero_class: String = "Warrior"
var xp: int = 0
var silver: int = 0
var chore_gold: int = 0

# Quest 1: A New Beginning
var quest_stage: int = 0
var logs_collected: int = 0
var log_resources: Array[Node3D] = []

# Quest 2: Clear the Woods
var mob_quest_stage: int = 0
var mobs_defeated: int = 0

# Quest 3: Mossjaw's Challenge
var quest3_stage: int = 0

# Quest 4: Lost Supplies
var quest4_stage: int = 0
var crates_found: int = 0
var supply_crates: Array[Node3D] = []

# Quest 5: Keep the Path Safe
var quest5_stage: int = 0
var path_mobs_defeated: int = 0

var elder: Node3D
var npc_nodes: Array[Node3D] = []

var inventory_items: Array[Dictionary] = [
    {
        "name": "Small Health Potion",
        "type": "Consumable",
        "quantity": 2,
        "description": "A starter potion. Potion use requires player.gd support."
    },
    {
        "name": "Hearthvale Wood",
        "type": "Material",
        "quantity": 0,
        "description": "Wood collected during the first quest."
    }
]

var equipped_items: Dictionary = {
    "Weapon": "Training Sword",
    "Head": "None",
    "Chest": "Traveler Clothes",
    "Hands": "None",
    "Legs": "Traveler Trousers",
    "Feet": "Traveler Boots",
    "Accessory": "None"
}


func _ready() -> void:
    _create_environment()
    _build_castle()
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
        _show_startup_error("player.gd must extend CharacterBody3D.")
        return

    player = new_player as CharacterBody3D
    player.name = "Hero"
    add_child(player)

    if player.get("hero_class") != null:
        player.set("hero_class", hero_class)

    player.position = Vector3(0, 2, 8)

    _make_hud()
    _refresh()

    _message(
        "Welcome to Hearthvale! Talk to the Village Elder, explore the village, and follow the forest road."
    )


func _show_startup_error(error_message: String) -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var label := Label.new()
    label.position = Vector2(20, 20)
    label.text = "FAMILY QUEST STARTUP ERROR\n" + error_message
    label.add_theme_font_size_override("font_size", 24)
    layer.add_child(label)


# --------------------------------------------------
# WORLD AND ENVIRONMENT
# --------------------------------------------------

func _create_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()

    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.48, 0.72, 0.9)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.8, 0.86, 1.0)
    environment.ambient_light_energy = 0.8

    world_environment.environment = environment
    add_child(world_environment)

    var sunlight := DirectionalLight3D.new()
    sunlight.rotation_degrees = Vector3(-55, -25, 0)
    sunlight.shadow_enabled = true
    add_child(sunlight)

    _add_box(
        "Ground",
        Vector3(0, -0.3, 0),
        Vector3(WORLD_WIDTH, 0.5, WORLD_DEPTH),
        Color("#527B43"),
        true
    )

    _create_world_boundaries()


func _create_world_boundaries() -> void:
    var boundary_color := Color("#355B31")

    _add_box(
        "WestBoundary", Vector3(-180, 2, 0),
        Vector3(2, 4, 400), boundary_color, true
    )
    _add_box(
        "EastBoundary", Vector3(180, 2, 0),
        Vector3(2, 4, 400), boundary_color, true
    )
    _add_box(
        "NorthBoundary", Vector3(0, 2, -200),
        Vector3(360, 4, 2), boundary_color, true
    )
    _add_box(
        "SouthBoundary", Vector3(0, 2, 200),
        Vector3(360, 4, 2), boundary_color, true
    )


# --------------------------------------------------
# CASTLE
# --------------------------------------------------

func _build_castle() -> void:
    var stone := Color("#777D82")
    var dark_stone := Color("#4D555C")
    var roof_color := Color("#354F70")
    var wood := Color("#573820")

    _add_box(
        "Castle Courtyard",
        Vector3(0, 0.03, -62),
        Vector3(42, 0.12, 24),
        Color("#B7AA91"),
        false
    )

    # Outer walls.
    _add_box(
        "Castle Back Wall",
        Vector3(0, 4, -77),
        Vector3(44, 8, 1.8), stone, true
    )
    _add_box(
        "Castle West Wall",
        Vector3(-21, 4, -63),
        Vector3(1.8, 8, 28), stone, true
    )
    _add_box(
        "Castle East Wall",
        Vector3(21, 4, -63),
        Vector3(1.8, 8, 28), stone, true
    )
    _add_box(
        "Castle Front Wall Left",
        Vector3(-13, 4, -49),
        Vector3(18, 8, 1.8), stone, true
    )
    _add_box(
        "Castle Front Wall Right",
        Vector3(13, 4, -49),
        Vector3(18, 8, 1.8), stone, true
    )

    # Gatehouse.
    _add_box(
        "Castle Gatehouse Left",
        Vector3(-5.8, 5, -49),
        Vector3(5, 10, 4), dark_stone, true
    )
    _add_box(
        "Castle Gatehouse Right",
        Vector3(5.8, 5, -49),
        Vector3(5, 10, 4), dark_stone, true
    )
    _add_box(
        "Castle Gatehouse Header",
        Vector3(0, 9.5, -49),
        Vector3(8, 1.8, 4), dark_stone, true
    )

    _add_box(
        "Castle Gate Door",
        Vector3(0, 3.3, -46.8),
        Vector3(7, 6.6, 0.5), wood, true
    )
    _add_box(
        "Castle Gate Door Brace",
        Vector3(0, 3.5, -46.45),
        Vector3(6.4, 0.25, 0.12),
        Color("#B58A50"), false
    )

    # Central keep.
    _add_box(
        "Castle Keep",
        Vector3(0, 7, -69),
        Vector3(18, 14, 16), stone, true
    )
    _add_box(
        "Keep Roof",
        Vector3(0, 15, -69),
        Vector3(19, 2, 17), roof_color, true
    )
    _add_box(
        "Keep Door",
        Vector3(0, 2.2, -60.8),
        Vector3(2.5, 4.4, 0.25), wood, false
    )

    # Four towers.
    var tower_positions: Array[Vector3] = [
        Vector3(-20, 6, -77),
        Vector3(20, 6, -77),
        Vector3(-20, 6, -50),
        Vector3(20, 6, -50)
    ]

    for i in range(tower_positions.size()):
        var tower_position: Vector3 = tower_positions[i]

        _add_box(
            "Castle Tower %d" % (i + 1),
            tower_position,
            Vector3(6, 12, 6), dark_stone, true
        )

        _add_box(
            "Castle Tower Roof %d" % (i + 1),
            tower_position + Vector3(0, 6.8, 0),
            Vector3(7, 1.6, 7), roof_color, true
        )

        _add_box(
            "Castle Tower Battlement %d" % (i + 1),
            tower_position + Vector3(0, 7.8, 0),
            Vector3(5.5, 0.6, 5.5), stone, true
        )

    # Wall battlements.
    for x in range(-19, 20, 4):
        _add_box(
            "Back Battlement",
            Vector3(float(x), 8.6, -77),
            Vector3(1.5, 1.2, 1.8), dark_stone, true
        )

    for z in range(-74, -51, 4):
        _add_box(
            "West Battlement",
            Vector3(-21, 8.6, float(z)),
            Vector3(1.8, 1.2, 1.5), dark_stone, true
        )
        _add_box(
            "East Battlement",
            Vector3(21, 8.6, float(z)),
            Vector3(1.8, 1.2, 1.5), dark_stone, true
        )

    # Blue banners.
    _add_box(
        "Left Castle Banner Pole",
        Vector3(-8.2, 7.8, -46.7),
        Vector3(0.16, 5, 0.16), wood, false
    )
    _add_box(
        "Left Castle Banner",
        Vector3(-7.3, 7.2, -46.7),
        Vector3(1.8, 2.4, 0.15),
        Color("#315E96"), false
    )
    _add_box(
        "Right Castle Banner Pole",
        Vector3(8.2, 7.8, -46.7),
        Vector3(0.16, 5, 0.16), wood, false
    )
    _add_box(
        "Right Castle Banner",
        Vector3(7.3, 7.2, -46.7),
        Vector3(1.8, 2.4, 0.15),
        Color("#315E96"), false
    )

    var castle_label := Label3D.new()
    castle_label.text = "HEARTHVALE CASTLE"
    castle_label.position = Vector3(0, 13, -46.5)
    castle_label.pixel_size = 0.025
    add_child(castle_label)


# --------------------------------------------------
# VILLAGE, BUILDINGS AND FOREST ROAD
# --------------------------------------------------

func _build_village() -> void:
    _add_box(
        "Village Square",
        Vector3(0, -0.02, -6),
        Vector3(36, 0.12, 26),
        Color("#B9A27B"), false
    )

    _add_box(
        "Forest Road",
        Vector3(0, -0.015, 28),
        Vector3(13, 0.1, 60),
        Color("#B9A27B"), false
    )

    # Fountain.
    _add_box(
        "Fountain Base",
        Vector3(0, 0.16, -10),
        Vector3(6.4, 0.3, 6.4),
        Color("#9A9B91"), false
    )
    _add_box(
        "Fountain Basin",
        Vector3(0, 0.42, -10),
        Vector3(5.6, 0.55, 5.6),
        Color("#7E8E98"), true
    )
    _add_box(
        "Fountain Water",
        Vector3(0, 0.72, -10),
        Vector3(4.5, 0.1, 4.5),
        Color("#39A9D6"), false
    )
    _add_box(
        "Fountain Pillar",
        Vector3(0, 1.05, -10),
        Vector3(0.7, 0.7, 0.7),
        Color("#C3C8C5"), false
    )

    # Blacksmith.
    _add_building(
        "Blacksmith", Vector3(-16, 3, -14),
        Vector3(8, 6, 8), Color("#8A5435")
    )
    _add_box(
        "Blacksmith Door",
        Vector3(-16, 1.9, -9.88),
        Vector3(1.8, 3.8, 0.24),
        Color("#4A2B1A"), false
    )
    _add_box(
        "Blacksmith Sign",
        Vector3(-16, 5.1, -9.5),
        Vector3(3.6, 1.3, 0.24),
        Color("#D9B66F"), false
    )

    # Armor shop.
    _add_building(
        "Armor Shop", Vector3(16, 3, -14),
        Vector3(8, 6, 8), Color("#60788A")
    )
    _add_box(
        "Armor Shop Door",
        Vector3(16, 1.9, -9.88),
        Vector3(1.8, 3.8, 0.24),
        Color("#352E2B"), false
    )
    _add_box(
        "Armor Shop Sign",
        Vector3(16, 5.1, -9.5),
        Vector3(3.6, 1.3, 0.24),
        Color("#D9B66F"), false
    )

    # Tailor.
    _add_building(
        "Tailor", Vector3(16, 3, 2),
        Vector3(7, 6, 7), Color("#93609A")
    )
    _add_box(
        "Tailor Door",
        Vector3(16, 1.9, 5.58),
        Vector3(1.7, 3.8, 0.24),
        Color("#4A2B1A"), false
    )

    # Training yard.
    _add_box(
        "Training Yard",
        Vector3(-16, 0.08, 4),
        Vector3(12, 0.16, 10),
        Color("#9C8156"), false
    )

    for x in [-22.0, -16.0, -10.0]:
        _add_box(
            "Training Fence Post",
            Vector3(x, 1.5, 9.6),
            Vector3(0.36, 3, 0.36),
            Color("#654329"), true
        )

    _add_box(
        "Training Fence Rail",
        Vector3(-16, 1.3, 9.6),
        Vector3(12, 0.28, 0.28),
        Color("#654329"), false
    )

    # Forest entrance.
    _add_box(
        "Woods Gate Left Pillar",
        Vector3(-7.6, 3, 24),
        Vector3(1.4, 6, 2),
        Color("#654329"), true
    )
    _add_box(
        "Woods Gate Right Pillar",
        Vector3(7.6, 3, 24),
        Vector3(1.4, 6, 2),
        Color("#654329"), true
    )
    _add_box(
        "Woods Gate Header",
        Vector3(0, 6, 24),
        Vector3(16, 1, 2),
        Color("#654329"), true
    )

    # Trees framing the village.
    for i in range(11):
        _add_tree(Vector3(-50, 0, -25 + i * 8))
        _add_tree(Vector3(50, 0, -25 + i * 8))

    # Trees along the forest path.
    for i in range(18):
        var z_position: float = 30.0 + i * 2.8
        var spread: float = float(i % 3) * 2.0

        _add_tree(Vector3(-19 - spread, 0, z_position))
        _add_tree(Vector3(19 + spread, 0, z_position))

    # Rocks and ground details.
    for i in range(14):
        var z_position: float = 31.0 + i * 4.0
        var side: float = -1.0 if i % 2 == 0 else 1.0

        _add_box(
            "Forest Rock",
            Vector3(side * (11 + float(i % 3)), 0.5, z_position),
            Vector3(1.8, 1.1, 1.5),
            Color("#777B70"), false
        )

        _add_box(
            "Forest Grass Patch",
            Vector3(-side * (10 + float(i % 2)), 0.04, z_position + 2),
            Vector3(2.2, 0.08, 1.3),
            Color("#49763A"), false
        )

    for i in range(12):
        _add_box(
            "Path Marker Stone",
            Vector3(0, 0.16, 28 + i * 5),
            Vector3(0.7, 0.32, 0.7),
            Color("#D9C99D"), false
        )

    _build_npcs()


func _add_building(
    building_name: String,
    pos: Vector3,
    size: Vector3,
    building_color: Color
) -> void:
    _add_box(building_name, pos, size, building_color, true)

    _add_roof_piece(
        building_name + " Roof Left",
        pos + Vector3(-size.x * 0.25, size.y * 0.5 + 0.65, 0),
        Vector3(size.x * 0.58, 0.35, size.z + 1.0),
        -18.0, Color("#4A3027")
    )

    _add_roof_piece(
        building_name + " Roof Right",
        pos + Vector3(size.x * 0.25, size.y * 0.5 + 0.65, 0),
        Vector3(size.x * 0.58, 0.35, size.z + 1.0),
        18.0, Color("#4A3027")
    )


# --------------------------------------------------
# NPCS
# --------------------------------------------------

func _build_npcs() -> void:
    elder = _create_npc(
        "Village Elder",
        Vector3(0, 0, -2),
        Color("#B9A16A"),
        "elder"
    )

    _add_quest_marker(
        elder, "!", Vector3(0, 2.7, 0), Color("#F4CF57")
    )

    _create_npc(
        "Blacksmith",
        Vector3(-12, 0, -8),
        Color("#87563A"),
        "blacksmith"
    )

    _create_npc(
        "Armor Merchant",
        Vector3(12, 0, -8),
        Color("#60788A"),
        "merchant"
    )

    _create_npc(
        "Village Tailor",
        Vector3(12, 0, 6),
        Color("#93609A"),
        "tailor"
    )

    var guard := _create_npc(
        "Village Guard",
        Vector3(0, 0, 20),
        Color("#45658A"),
        "guard"
    )

    _add_quest_marker(
        guard, "i", Vector3(0, 2.6, 0), Color("#80D7F7")
    )


func _create_npc(
    npc_name: String,
    pos: Vector3,
    body_color: Color,
    role: String
) -> Node3D:
    var npc := Node3D.new()
    npc.name = npc_name.replace(" ", "")
    npc.position = pos
    npc.set_meta("npc_name", npc_name)
    npc.set_meta("npc_role", role)
    add_child(npc)

    # Humanoid placeholder approximately 1.8 units tall.
    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.32
    body_mesh.height = 1.45
    body.mesh = body_mesh
    body.position.y = 0.92

    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = body_color
    body.material_override = body_material
    npc.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.25
    head_mesh.height = 0.5
    head.mesh = head_mesh
    head.position = Vector3(0, 1.78, 0)

    var head_material := StandardMaterial3D.new()
    head_material.albedo_color = Color("#D4AD8D")
    head.material_override = head_material
    npc.add_child(head)

    if role == "blacksmith":
        _add_box_to_parent(
            npc, "Apron",
            Vector3(0, 0.85, -0.29),
            Vector3(0.42, 0.7, 0.08),
            Color("#3E3027")
        )
    elif role == "guard":
        _add_box_to_parent(
            npc, "Guard Chest Armor",
            Vector3(0, 1.0, -0.3),
            Vector3(0.58, 0.62, 0.12),
            Color("#A9B3BC")
        )

    var name_label := Label3D.new()
    name_label.text = npc_name
    name_label.position = Vector3(0, 2.25, 0)
    name_label.pixel_size = 0.012
    name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    npc.add_child(name_label)

    npc_nodes.append(npc)
    return npc


func _add_box_to_parent(
    parent: Node3D,
    node_name: String,
    pos: Vector3,
    size: Vector3,
    color: Color
) -> void:
    var node := Node3D.new()
    node.name = node_name
    node.position = pos
    parent.add_child(node)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh

    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh_instance.material_override = material
    node.add_child(mesh_instance)


# --------------------------------------------------
# QUEST OBJECTS AND MARKERS
# --------------------------------------------------

func _build_quest_objects() -> void:
    var log_positions: Array[Vector3] = [
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
            log_node, "◆", Vector3(0, 1.6, 0), Color("#E6C16A")
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
    marker_shape.radius = 0.22
    marker_shape.height = 0.44
    marker_mesh.mesh = marker_shape

    var marker_material := StandardMaterial3D.new()
    marker_material.albedo_color = marker_color
    marker_material.emission_enabled = true
    marker_material.emission = marker_color
    marker_material.emission_energy_multiplier = 0.7
    marker_mesh.material_override = marker_material
    marker_root.add_child(marker_mesh)

    var marker_label := Label3D.new()
    marker_label.text = marker_text
    marker_label.position = Vector3(0, 0.32, 0)
    marker_label.pixel_size = 0.024
    marker_label.modulate = marker_color
    marker_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    marker_root.add_child(marker_label)


# --------------------------------------------------
# BOXES, TREES AND ROOFS
# --------------------------------------------------

func _add_box(
    node_name: String,
    pos: Vector3,
    size: Vector3,
    color: Color,
    solid: bool
) -> Node3D:
    var parent: Node3D

    if solid:
        var body := StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
        parent = body
    else:
        parent = Node3D.new()

    parent.name = node_name
    parent.position = pos
    add_child(parent)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh

    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh_instance.material_override = material
    parent.add_child(mesh_instance)

    return parent


func _add_roof_piece(
    node_name: String,
    pos: Vector3,
    size: Vector3,
    tilt_degrees: float,
    color: Color
) -> void:
    var roof := _add_box(node_name, pos, size, color, false)
    roof.rotation_degrees.z = tilt_degrees


func _add_tree(pos: Vector3) -> void:
    var tree := _add_box(
        "Tree Trunk",
        pos + Vector3(0, 2, 0),
        Vector3(1.1, 4.0, 1.1),
        Color("#573820"),
        true
    )

    var greens: Array[Color] = [
        Color("#245C2D"),
        Color("#2F7135"),
        Color("#3A7B3D")
    ]

    var offsets: Array[Vector3] = [
        Vector3(0, 5.1, 0),
        Vector3(-1.1, 4.5, 0.3),
        Vector3(1.0, 4.7, -0.3)
    ]

    var sizes: Array[float] = [2.9, 2.0, 2.1]

    for i in range(3):
        var crown := MeshInstance3D.new()
        crown.position = offsets[i]

        var mesh := SphereMesh.new()
        mesh.radius = sizes[i]
        mesh.height = sizes[i] * 2.0
        crown.mesh = mesh

        var material := StandardMaterial3D.new()
        material.albedo_color = greens[i]
        crown.material_override = material
        tree.add_child(crown)


# --------------------------------------------------
# HUD AND MOBILE BUTTONS
# --------------------------------------------------

func _make_hud() -> void:
    hud_layer = CanvasLayer.new()
    hud_layer.name = "GameHUD"
    hud_layer.layer = 10
    add_child(hud_layer)

    var panel := PanelContainer.new()
    panel.position = Vector2(15, 15)
    panel.custom_minimum_size = Vector2(360, 180)
    hud_layer.add_child(panel)

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

    var class_row := HBoxContainer.new()
    column.add_child(class_row)

    for class_name in ["Warrior", "Mage", "Rogue", "Druid", "Ranger"]:
        var class_button := Button.new()
        class_button.text = class_name
        class_button.pressed.connect(_select_class.bind(class_name))
        class_row.add_child(class_button)

    _make_resource_bars()

    # Backpack and equipment buttons at the top right.
    var inventory_buttons := HBoxContainer.new()
    inventory_buttons.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    inventory_buttons.position = Vector2(-150, 115)
    inventory_buttons.add_theme_constant_override("separation", 8)
    hud_layer.add_child(inventory_buttons)

    var backpack_button := Button.new()
    backpack_button.text = "🎒"
    backpack_button.custom_minimum_size = Vector2(64, 56)
    backpack_button.tooltip_text = "Backpack"
    backpack_button.pressed.connect(_open_inventory.bind(false))
    inventory_buttons.add_child(backpack_button)

    var equipment_button := Button.new()
    equipment_button.text = "⚔"
    equipment_button.custom_minimum_size = Vector2(64, 56)
    equipment_button.tooltip_text = "Weapons and Equipment"
    equipment_button.pressed.connect(_open_inventory.bind(true))
    inventory_buttons.add_child(equipment_button)

    # Attack button.
    var attack_button := Button.new()
    attack_button.text = "ATTACK"
    attack_button.anchor_left = 1.0
    attack_button.anchor_right = 1.0
    attack_button.anchor_top = 1.0
    attack_button.anchor_bottom = 1.0
    attack_button.offset_left = -220
    attack_button.offset_right = -20
    attack_button.offset_top = -90
    attack_button.offset_bottom = -20
    attack_button.pressed.connect(_attack)
    hud_layer.add_child(attack_button)

    # Interaction button.
    var interact_button := Button.new()
    interact_button.text = "INTERACT"
    interact_button.anchor_left = 1.0
    interact_button.anchor_right = 1.0
    interact_button.anchor_top = 1.0
    interact_button.anchor_bottom = 1.0
    interact_button.offset_left = -220
    interact_button.offset_right = -20
    interact_button.offset_top = -160
    interact_button.offset_bottom = -100
    interact_button.pressed.connect(_interact)
    hud_layer.add_child(interact_button)


func _make_resource_bars() -> void:
    var panel := PanelContainer.new()
    panel.name = "ResourceBars"
    panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    panel.position = Vector2(-315, 15)
    panel.custom_minimum_size = Vector2(300, 85)
    panel.size = Vector2(300, 85)

    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("#17251F")
    panel_style.set_corner_radius_all(8)
    panel_style.content_margin_left = 10
    panel_style.content_margin_right = 10
    panel_style.content_margin_top = 8
    panel_style.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel", panel_style)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 3)
    panel.add_child(layout)

    health_text = Label.new()
    health_text.text = "HEALTH 100/100"
    layout.add_child(health_text)

    health_bar = ProgressBar.new()
    health_bar.min_value = 0
    health_bar.max_value = 100
    health_bar.value = 100
    health_bar.show_percentage = false
    health_bar.custom_minimum_size = Vector2(275, 14)
    health_bar.add_theme_stylebox_override(
        "fill", _make_bar_style(Color("#E53945"))
    )
    layout.add_child(health_bar)

    mana_text = Label.new()
    mana_text.text = "MANA 100/100"
    layout.add_child(mana_text)

    mana_bar = ProgressBar.new()
    mana_bar.min_value = 0
    mana_bar.max_value = 100
    mana_bar.value = 100
    mana_bar.show_percentage = false
    mana_bar.custom_minimum_size = Vector2(275, 14)
    mana_bar.add_theme_stylebox_override(
        "fill", _make_bar_style(Color("#388BFF"))
    )
    layout.add_child(mana_bar)

    hud_layer.add_child(panel)


func _make_bar_style(color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(4)
    return style


# --------------------------------------------------
# BACKPACK AND EQUIPMENT WINDOWS
# --------------------------------------------------

func _open_inventory(show_equipment: bool) -> void:
    inventory_is_equipment = show_equipment

    if is_instance_valid(inventory_panel):
        inventory_panel.queue_free()

    inventory_panel = PanelContainer.new()
    inventory_panel.name = "InventoryWindow"
    inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
    inventory_panel.position = Vector2(-210, -220)
    inventory_panel.custom_minimum_size = Vector2(420, 440)
    inventory_panel.size = Vector2(420, 440)
    hud_layer.add_child(inventory_panel)

    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 8)
    inventory_panel.add_child(outer)

    var header := HBoxContainer.new()
    outer.add_child(header)

    var title := Label.new()
    title.text = "Weapons & Equipment" if show_equipment else "Backpack"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)

    var close_button := Button.new()
    close_button.text = "X"
    close_button.pressed.connect(_close_inventory)
    header.add_child(close_button)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    outer.add_child(scroll)

    inventory_list = VBoxContainer.new()
    inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(inventory_list)

    _populate_inventory()


func _populate_inventory() -> void:
    if not is_instance_valid(inventory_list):
        return

    for child in inventory_list.get_children():
        child.queue_free()

    if inventory_is_equipment:
        for slot in equipped_items.keys():
            var row := HBoxContainer.new()

            var slot_label := Label.new()
            slot_label.text = "%s: %s" % [
                str(slot), str(equipped_items[slot])
            ]
            slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.add_child(slot_label)

            var change_button := Button.new()
            change_button.text = "Change"
            change_button.pressed.connect(
                _show_equipment_message.bind(str(slot))
            )
            row.add_child(change_button)

            inventory_list.add_child(row)

        var note := Label.new()
        note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        note.text = (
            "Equipment slots are displayed. Real equipment changes "
            + "and stat bonuses need player.gd integration."
        )
        inventory_list.add_child(note)

    else:
        if inventory_items.is_empty():
            var empty_label := Label.new()
            empty_label.text = "Your backpack is empty."
            inventory_list.add_child(empty_label)

        for item in inventory_items:
            var row := VBoxContainer.new()

            var item_label := Label.new()
            item_label.text = "%s  x%d" % [
                str(item.get("name", "Unknown Item")),
                int(item.get("quantity", 1))
            ]
            row.add_child(item_label)

            var description := Label.new()
            description.text = str(item.get("description", ""))
            description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            row.add_child(description)

            inventory_list.add_child(row)


func _show_equipment_message(slot: String) -> void:
    _message(
        "Equipment slot: %s. Equipping items requires player.gd integration."
        % slot
    )


func _close_inventory() -> void:
    if is_instance_valid(inventory_panel):
        inventory_panel.queue_free()

    inventory_panel = null


func _add_inventory_quantity(item_name: String, amount: int) -> void:
    for i in range(inventory_items.size()):
        if str(inventory_items[i].get("name", "")) == item_name:
            inventory_items[i]["quantity"] = (
                int(inventory_items[i].get("quantity", 0)) + amount
            )

            if is_instance_valid(inventory_panel):
                _populate_inventory()
            return

    inventory_items.append({
        "name": item_name,
        "type": "Material",
        "quantity": amount,
        "description": "Collected during an adventure."
    })

    if is_instance_valid(inventory_panel):
        _populate_inventory()


# --------------------------------------------------
# INPUT AND CLASS SELECTION
# --------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack", false):
        _attack()
        get_viewport().set_input_as_handled()

    elif event.is_action_pressed("interact", false):
        _interact()
        get_viewport().set_input_as_handled()


func _select_class(class_name: String) -> void:
    hero_class = class_name

    if is_instance_valid(player):
        if player.has_method("set_hero_class"):
            player.call("set_hero_class", class_name)
        else:
            player.set("hero_class", class_name)

    var abilities := {
        "Warrior": "Titan Smash",
        "Mage": "Starfall",
        "Rogue": "Phantom Flurry",
        "Druid": "Worldroot Surge",
        "Ranger": "Heavenpiercer"
    }

    _message(
        "Selected %s — signature ability: %s."
        % [class_name, abilities[class_name]]
    )

    _refresh()


# --------------------------------------------------
# COMBAT
# --------------------------------------------------

func _attack() -> void:
    if not is_instance_valid(player):
        return

    if player.get("dead") == true:
        _message("You have fallen. Wait to respawn.")
        return

    var nearest: Node = null
    var best_distance: float = 3.8

    for node in get_children():
        if (
            node is CharacterBody3D
            and node != player
            and node.has_method("take_hit")
        ):
            var distance := _flat_distance(
                player.global_position,
                node.global_position
            )

            if distance < best_distance:
                best_distance = distance
                nearest = node

    if nearest != null:
        var damage: int = 35

        if nearest.get("is_boss") == true:
            damage = 20

        nearest.call("take_hit", damage)

        _message(
            "%s attacks %s."
            % [hero_class, str(nearest.get("enemy_name"))]
        )
    else:
        _message("Move closer to an enemy to attack.")


# --------------------------------------------------
# INTERACTION AND QUEST COLLECTION
# --------------------------------------------------

func _interact() -> void:
    if not is_instance_valid(player):
        return

    var player_position: Vector3 = player.global_position

    # Quest 1: collect logs.
    if quest_stage == 1:
        var closest_log: Node3D = null
        var closest_distance: float = 7.0

        for log_node in log_resources:
            if is_instance_valid(log_node):
                var distance := _flat_distance(
                    player_position, log_node.global_position
                )

                if distance <= closest_distance:
                    closest_distance = distance
                    closest_log = log_node

        if closest_log != null:
            log_resources.erase(closest_log)
            closest_log.queue_free()

            logs_collected += 1
            _add_inventory_quantity("Hearthvale Wood", 1)

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

    # Quest 4: collect supply crates.
    if quest4_stage == 1:
        var closest_crate: Node3D = null
        var closest_crate_distance: float = 7.0

        for crate_node in supply_crates:
            if is_instance_valid(crate_node):
                var distance := _flat_distance(
                    player_position, crate_node.global_position
                )

                if distance <= closest_crate_distance:
                    closest_crate_distance = distance
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
                _message("Supplies found: %d/3." % crates_found)

            _refresh()
            return

    # Village Elder quest progression.
    if (
        is_instance_valid(elder)
        and _flat_distance(player_position, elder.global_position) <= 5.0
    ):
        if quest_stage < 3:
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
        else:
            _advance_followup_quest()

        _refresh()
        return

    # Other NPCs.
    for npc in npc_nodes:
        if (
            is_instance_valid(npc)
            and _flat_distance(player_position, npc.global_position) <= 4.0
        ):
            var npc_name := str(npc.get_meta("npc_name", "Villager"))
            var role := str(npc.get_meta("npc_role", "villager"))

            match role:
                "blacksmith":
                    _message(
                        "Blacksmith: Weapon upgrades and crafting will be available here."
                    )
                "merchant":
                    _message(
                        "Armor Merchant: I will offer armor suited to each hero class."
                    )
                "tailor":
                    _message(
                        "Village Tailor: Outfits and appearance customization are coming soon."
                    )
                "guard":
                    _message(
                        "Village Guard: The castle is to the north. Whispering Woods lies beyond the village road."
                    )
                _:
                    _message("%s: Welcome to Hearthvale." % npc_name)

            return

    # Points of interest.
    if _flat_distance(player_position, Vector3(0, 0, -10)) < 9.0:
        _message("Village fountain: Welcome to Hearthvale!")
    elif _flat_distance(player_position, Vector3(-16, 0, -14)) < 9.0:
        _message("Blacksmith: Weapon shop.")
    elif _flat_distance(player_position, Vector3(16, 0, -14)) < 9.0:
        _message("Armor shop: Class-specific gear.")
    elif _flat_distance(player_position, Vector3(16, 0, 2)) < 8.0:
        _message("Tailor: Appearance customization.")
    elif player_position.z > 24.0:
        _message(
            "Whispering Woods: Interact near a wooden log or supply crate."
        )
    elif player_position.z < -42.0:
        _message("Hearthvale Castle: The castle gate is currently scenery.")
    else:
        _message(
            "Move near an NPC, fountain, shop, or quest item, then interact."
        )


func _advance_followup_quest() -> void:
    # Quest 2: Clear the Woods.
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

    # Quest 3: Mossjaw's Challenge.
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

    # Quest 4: Lost Supplies.
    elif quest3_stage == 3 and quest4_stage == 0:
        quest4_stage = 1
        crates_found = 0
        _spawn_supply_crates()
        _message(
            "Quest 4: Lost Supplies — find 3 supply crates along the forest path."
        )

    elif quest4_stage == 1:
        _message(
            "Village Elder: Find the missing supplies (%d/3)."
            % crates_found
        )

    elif quest4_stage == 2:
        quest4_stage = 3
        xp += 100
        silver += 125
        _message(
            "Quest complete: Lost Supplies! Reward: 100 XP and 125 Silver."
        )

    # Quest 5: Keep the Path Safe.
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

    _refresh()


func _flat_distance(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


# --------------------------------------------------
# ENEMY SPAWNING
# --------------------------------------------------

func _spawn_quest_mobs() -> void:
    var enemy_types: Array[String] = [
        "Forest Slime",
        "Woodland Goblin",
        "Thornwolf"
    ]

    var positions: Array[Vector3] = [
        Vector3(-12, 1, 42),
        Vector3(0, 1, 46),
        Vector3(12, 1, 42)
    ]

    for i in range(enemy_types.size()):
        var mob = EnemyScript.new()

        if not mob is CharacterBody3D:
            push_error("enemy.gd must extend CharacterBody3D.")
            return

        mob.name = "QuestMob%d" % (i + 1)
        mob.set("enemy_name", enemy_types[i])
        mob.position = positions[i]
        mob.set("player", player)
        mob.set_meta("clear_woods_target", true)
        add_child(mob)


func _spawn_mossjaw() -> void:
    var boss = EnemyScript.new()

    if not boss is CharacterBody3D:
        push_error("enemy.gd must extend CharacterBody3D.")
        return

    boss.name = "Mossjaw"
    boss.set("enemy_name", "Mossjaw")
    boss.set("is_boss", true)
    boss.position = Vector3(0, 1.5, 60)
    boss.set("player", player)
    add_child(boss)

    _message("Mossjaw has appeared deep in Whispering Woods!")


func _spawn_supply_crates() -> void:
    var positions: Array[Vector3] = [
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
        _add_quest_marker(
            crate, "!", Vector3(0, 1.2, 0), Color("#E6C16A")
        )


func _spawn_path_mobs() -> void:
    var enemy_names: Array[String] = [
        "Path Slime 1",
        "Path Slime 2",
        "Path Goblin 1",
        "Path Goblin 2",
        "Path Thornwolf"
    ]

    var positions: Array[Vector3] = [
        Vector3(-12, 1, 35),
        Vector3(12, 1, 39),
        Vector3(-7, 1, 47),
        Vector3(7, 1, 51),
        Vector3(0, 1, 58)
    ]

    for i in range(enemy_names.size()):
        var mob = EnemyScript.new()

        if not mob is CharacterBody3D:
            push_error("enemy.gd must extend CharacterBody3D.")
            return

        mob.name = enemy_names[i].replace(" ", "")
        mob.set("enemy_name", enemy_names[i])
        mob.position = positions[i]
        mob.set("player", player)
        mob.set_meta("path_quest_target", true)
        add_child(mob)


# Called by enemy.gd when an enemy is defeated.
func enemy_defeated(enemy: Node) -> void:
    var reward_message: String = (
        "%s defeated!" % str(enemy.get("enemy_name"))
    )

    if enemy.has_meta("clear_woods_target") and mob_quest_stage == 1:
        mobs_defeated += 1

        if mobs_defeated >= MOBS_REQUIRED:
            mob_quest_stage = 2
            reward_message += " The woods are clear. Return to the Elder!"
        else:
            reward_message += " Woods cleared: %d/3." % mobs_defeated

    elif enemy.name == "Mossjaw" and quest3_stage == 1:
        quest3_stage = 2
        reward_message += " Return to the Elder!"

    elif enemy.has_meta("path_quest_target") and quest5_stage == 1:
        path_mobs_defeated += 1

        if path_mobs_defeated >= PATH_MOBS_REQUIRED:
            quest5_stage = 2
            reward_message += " The path is safe. Return to the Elder!"
        else:
            reward_message += " Path secured: %d/5." % path_mobs_defeated

    if enemy.get("is_boss") == true:
        xp += 100
        silver += 100
    else:
        xp += 10
        silver += 15

    _refresh()

    _message(
        "%s Reward: XP and Silver. Combat does not award Chore Gold."
        % reward_message
    )


# --------------------------------------------------
# QUEST HUD AND RESOURCE BAR REFRESH
# --------------------------------------------------

func _refresh() -> void:
    var hp_value: int = 100

    if is_instance_valid(player):
        var hp_read = player.get("hp")
        if hp_read != null:
            hp_value = clampi(int(hp_read), 0, 100)

    if is_instance_valid(status_label):
        status_label.text = "HERO: %s | HP: %d/100" % [
            hero_class, hp_value
        ]

    if is_instance_valid(economy_label):
        economy_label.text = "XP: %d | Silver: %d | Chore Gold: %d" % [
            xp, silver, chore_gold
        ]

    _refresh_resource_bars()

    if not is_instance_valid(quest_label):
        return

    if quest_stage == 0:
        quest_label.text = (
            "Quest: A New Beginning — Talk to the Village Elder"
        )
    elif quest_stage == 1:
        quest_label.text = (
            "Quest: A New Beginning — Collect logs (%d/3)"
            % logs_collected
        )
    elif quest_stage == 2:
        quest_label.text = (
            "Quest: A New Beginning — Return to the Elder"
        )
    elif mob_quest_stage == 0:
        quest_label.text = (
            "A New Beginning complete — Talk to the Elder"
        )
    elif mob_quest_stage == 1:
        quest_label.text = (
            "Quest 2: Clear the Woods — Defeat monsters (%d/3)"
            % mobs_defeated
        )
    elif mob_quest_stage == 2:
        quest_label.text = (
            "Quest 2: Clear the Woods — Return to the Elder"
        )
    elif quest3_stage == 1:
        quest_label.text = (
            "Quest 3: Mossjaw's Challenge — Defeat Mossjaw"
        )
    elif quest3_stage == 2:
        quest_label.text = (
            "Quest 3: Mossjaw's Challenge — Return to the Elder"
        )
    elif quest4_stage == 1:
        quest_label.text = (
            "Quest 4: Lost Supplies — Find crates (%d/3)"
            % crates_found
        )
    elif quest4_stage == 2:
        quest_label.text = (
            "Quest 4: Lost Supplies — Return to the Elder"
        )
    elif quest5_stage == 1:
        quest_label.text = (
            "Quest 5: Keep the Path Safe — Defeat monsters (%d/5)"
            % path_mobs_defeated
        )
    elif quest5_stage == 2:
        quest_label.text = (
            "Quest 5: Keep the Path Safe — Return to the Elder"
        )
    else:
        quest_label.text = "Demo complete: All 5 quests finished!"


func _refresh_resource_bars() -> void:
    if not is_instance_valid(player):
        return

    var hp_read = player.get("hp")
    var max_hp_read = player.get("max_hp")

    var hp_max: int = (
        100 if max_hp_read == null else maxi(1, int(max_hp_read))
    )
    var hp: int = (
        hp_max if hp_read == null
        else clampi(int(hp_read), 0, hp_max)
    )

    var mana_read = player.get("mana")
    var max_mana_read = player.get("max_mana")

    var mana_max: int = (
        100 if max_mana_read == null
        else maxi(1, int(max_mana_read))
    )
    var mana: int = (
        mana_max if mana_read == null
        else clampi(int(mana_read), 0, mana_max)
    )

    if is_instance_valid(health_bar):
        health_bar.max_value = hp_max
        health_bar.value = hp
        health_text.text = "HEALTH %d/%d" % [hp, hp_max]

    if is_instance_valid(mana_bar):
        mana_bar.max_value = mana_max
        mana_bar.value = mana
        mana_text.text = "MANA %d/%d" % [mana, mana_max]


func _message(text_message: String) -> void:
    if is_instance_valid(message_label):
        message_label.text = text_message

    print(text_message)
