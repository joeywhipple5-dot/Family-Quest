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
    # Load the saved hero selection.
    if get_node_or_null("/root/PlayerProfile") != null:
        var profile = get_node("/root/PlayerProfile")
        hero_class = str(profile.get("selected_class"))
        hero_gender = str(profile.get("selected_gender"))

    _create_environment()
    _build_village()
    _build_hearthvale_expansion()
    _build_village_details()
    _build_quest_objects()
    _build_town_npcs()

    # Create the player using the selected hero.
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

    # Main ground.
    _add_box(
        "MainGround",
        Vector3(0, -0.3, 10),
        Vector3(70, 0.5, 100),
        Color(0.32, 0.55, 0.28),
        true
    )


func _build_village() -> void:
    # Village square and main road.
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

    # Fountain.
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

    # Existing shops.
    _build_house(Vector3(-8, 0, -7), Color("#8A5435"), "Blacksmith")
    _build_house(Vector3(8, 0, -7), Color("#60788A"), "ArmorShop")
    _build_house(Vector3(8, 0, 1), Color("#93609A"), "Tailor")

    # Training yard.
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

    # Open woods gate.
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

    # Trees along the edges.
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
    # Extended ground to support the castle district.
    _add_box(
        "CastleDistrictGround",
        Vector3(0, -0.32, -37),
        Vector3(70, 0.45, 100),
        Color("#477C40"),
        true
    )

    # Main road from the original village to the castle.
    _add_box(
        "CastleApproachRoad",
        Vector3(0, -0.02, -34),
        Vector3(12, 0.12, 68),
        Color("#B9A27B"),
        false
    )

    # Expanded market square.
    _add_box(
        "MarketSquare",
        Vector3(0, 0.02, -22),
        Vector3(34, 0.15, 18),
        Color("#C8B58E"),
        false
    )

    # Extra houses and shops.
    _build_house(Vector3(-15, 0, -20), Color("#9A6546"), "Baker")
    _build_house(Vector3(15, 0, -20), Color("#526E8A"), "GeneralStore")
    _build_house(Vector3(-17, 0, -33), Color("#A18454"), "Inn")
    _build_house(Vector3(17, 0, -33), Color("#76518A"), "Apothecary")
    _build_house(Vector3(-13, 0, -44), Color("#8A5541"), "TownHouse")
    _build_house(Vector3(13, 0, -44), Color("#54765A"), "TownHouse")

    # Market stalls.
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

    # Castle courtyard.
    _add_box(
        "CastleCourtyard",
        Vector3(0, 0.02, -62),
        Vector3(42, 0.15, 24),
        Color("#8B8C89"),
        false
    )

    var stone := Color("#777D87")
    var dark_stone := Color("#555B66")

    # Castle outer walls.
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

    # Front wall sections leave an opening for the gate.
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

    # Central gatehouse.
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

    # Main keep behind the courtyard.
    _add_box(
        "CastleKeep",
        Vector3(0, 7, -69),
        Vector3(18, 14, 16),
        Color("#626975"),
        true
    )

    # Four tall towers.
    _build_tower(Vector3(-16, 0, -73), 15)
    _build_tower(Vector3(16, 0, -73), 15)
    _build_tower(Vector3(-16, 0, -53), 12)
    _build_tower(Vector3(16, 0, -53), 12)

    # Castle roof accents and banners.
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

    # More trees along the outskirts.
    for i in range(12):
        var x := -31.0 + float(i) * 5.5
        _build_tree(Vector3(x, 0, -13))
        _build_tree(Vector3(x, 0, -47))

    for i in range(8):
        var z := -18.0 - float(i) * 7.0
        _build_tree(Vector3(-29, 0, z))
        _build_tree(Vector3(29, 0, z))


func _build_house(p: Vector3, house_color: Color, house_name: String) -> void:
    _add_box(
        house_name,
        p + Vector3(0, 2.2, 0),
        Vector3(6, 4.4, 6),
        house_color,
        true
    )

    _add_box(
        house_name + "Roof",
        p + Vector3(0, 4.65, 0),
        Vector3(6.8, 0.6, 6.8),
        Color("#49352D"),
        false
    )

    _add_box(
        house_name + "Door",
        p + Vector3(0, 1.1, 3.05),
        Vector3(1.3, 2.2, 0.15),
        Color("#4A2B1A"),
        false
    )

    _add_box(
        house_name + "WindowLeft",
        p + Vector3(-1.8, 2.3, 3.06),
        Vector3(0.9, 0.9, 0.12),
        Color("#9ED5E0"),
        false
    )

    _add_box(
        house_name + "WindowRight",
        p + Vector3(1.8, 2.3, 3.06),
        Vector3(0.9, 0.9, 0.12),
        Color("#9ED5E0"),
        false
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
# VILLAGE OVERHAUL DETAILS
# --------------------------------------------------

func _build_village_details() -> void:
    # More readable paving stones along the main routes.
    for i in range(9):
        var z := -15.0 + float(i) * 4.0
        _add_box(
            "RoadStone_%02d" % i,
            Vector3(0, 0.055, z),
            Vector3(2.4, 0.06, 0.65),
            Color("#D4C5A4"),
            false
        )

    # Warm lantern posts around the market and village square.
    var lamp_positions := [
        Vector3(-10, 0, -12), Vector3(10, 0, -12),
        Vector3(-12, 0, -23), Vector3(12, 0, -23),
        Vector3(-4, 0, -34), Vector3(4, 0, -34),
        Vector3(-5, 0, 5), Vector3(5, 0, 5)
    ]
    for i in range(lamp_positions.size()):
        _build_lamp(lamp_positions[i], i)

    # Seating and small village props.
    _build_bench(Vector3(-4.5, 0, -8), 0.0)
    _build_bench(Vector3(4.5, 0, -8), 180.0)
    _build_bench(Vector3(-11.5, 0, -18), 90.0)
    _build_bench(Vector3(11.5, 0, -18), -90.0)

    var barrel_positions := [
        Vector3(-11, 0, -4), Vector3(-5, 0, -3),
        Vector3(10, 0, -5), Vector3(12, 0, -21),
        Vector3(-12, 0, -25), Vector3(-15, 0, -31),
        Vector3(18, 0, -35), Vector3(-18, 0, -35)
    ]
    for i in range(barrel_positions.size()):
        _build_barrel(barrel_positions[i], i)

    # Planters and flower patches add color without expensive assets.
    var flower_positions := [
        Vector3(-5.5, 0, -11), Vector3(5.5, 0, -11),
        Vector3(-11, 0, -10), Vector3(11, 0, -10),
        Vector3(-12, 0, -29), Vector3(12, 0, -29),
        Vector3(-18, 0, -19), Vector3(18, 0, -19)
    ]
    for i in range(flower_positions.size()):
        _build_flower_patch(flower_positions[i], i)

    # Signs make the main village locations easier to identify.
    _build_sign(Vector3(-8, 0, -1.8), "BLACKSMITH", Color("#B97B42"))
    _build_sign(Vector3(8, 0, -1.8), "ARMOR", Color("#6688A6"))
    _build_sign(Vector3(0, 0, 8.2), "WHISPERING WOODS", Color("#8D6A3D"))
    _build_sign(Vector3(0, 0, -40), "CASTLE DISTRICT", Color("#7D8797"))


func _build_lamp(p: Vector3, index: int) -> void:
    _add_box("LampPost_%d" % index, p + Vector3(0, 1.5, 0),
        Vector3(0.18, 3.0, 0.18), Color("#49382B"), false)
    _add_box("LampArm_%d" % index, p + Vector3(0.28, 2.75, 0),
        Vector3(0.7, 0.12, 0.12), Color("#49382B"), false)
    var glow := MeshInstance3D.new()
    glow.name = "LanternGlow_%d" % index
    var sphere := SphereMesh.new()
    sphere.radius = 0.22
    sphere.height = 0.44
    glow.mesh = sphere
    glow.position = p + Vector3(0.52, 2.55, 0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#FFD77A")
    mat.emission_enabled = true
    mat.emission = Color("#FFB94A")
    mat.emission_energy_multiplier = 1.2
    glow.material_override = mat
    add_child(glow)


func _build_bench(p: Vector3, turn_degrees: float) -> void:
    var bench := Node3D.new()
    bench.name = "VillageBench"
    bench.position = p
    bench.rotation_degrees.y = turn_degrees
    add_child(bench)
    _add_local_box(bench, "BenchSeat", Vector3(0, 0.55, 0),
        Vector3(1.8, 0.16, 0.55), Color("#76502E"))
    _add_local_box(bench, "BenchBack", Vector3(0, 0.95, -0.22),
        Vector3(1.8, 0.65, 0.12), Color("#8B6037"))
    for x in [-0.65, 0.65]:
        _add_local_box(bench, "BenchLeg", Vector3(x, 0.27, 0),
            Vector3(0.12, 0.55, 0.4), Color("#49382B"))


func _build_barrel(p: Vector3, index: int) -> void:
    var barrel := _add_box("VillageBarrel_%d" % index,
        p + Vector3(0, 0.48, 0), Vector3(0.8, 0.96, 0.8),
        Color("#81532E"), false)
    _add_box("BarrelBandA_%d" % index, p + Vector3(0, 0.25, 0),
        Vector3(0.84, 0.08, 0.84), Color("#4C5054"), false)
    _add_box("BarrelBandB_%d" % index, p + Vector3(0, 0.72, 0),
        Vector3(0.84, 0.08, 0.84), Color("#4C5054"), false)


func _build_flower_patch(p: Vector3, index: int) -> void:
    _add_box("FlowerBed_%d" % index, p + Vector3(0, 0.12, 0),
        Vector3(1.8, 0.24, 1.1), Color("#59432E"), false)
    var colors := [Color("#E7B7D1"), Color("#F3D36C"), Color("#A9C8F0")]
    for i in range(5):
        var flower := MeshInstance3D.new()
        var mesh := SphereMesh.new()
        mesh.radius = 0.12
        mesh.height = 0.24
        flower.mesh = mesh
        flower.position = p + Vector3(-0.6 + float(i) * 0.3, 0.38, 0.0 if i % 2 == 0 else 0.25)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = colors[(i + index) % colors.size()]
        flower.material_override = mat
        add_child(flower)


func _build_sign(p: Vector3, text_value: String, sign_color: Color) -> void:
    _add_box("SignPost_" + text_value, p + Vector3(0, 1.0, 0),
        Vector3(0.16, 2.0, 0.16), Color("#593A24"), false)
    _add_box("SignBoard_" + text_value, p + Vector3(0, 1.9, 0),
        Vector3(2.4, 0.7, 0.18), sign_color, false)
    var label := Label3D.new()
    label.name = "SignLabel_" + text_value
    label.text = text_value
    label.position = p + Vector3(0, 1.9, 0.12)
    label.pixel_size = 0.006
    label.modulate = Color("#FFF4D7")
    add_child(label)


func _add_local_box(parent: Node3D, object_name: String, p: Vector3,
        size_value: Vector3, color_value: Color) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = object_name
    var mesh := BoxMesh.new()
    mesh.size = size_value
    mesh_instance.mesh = mesh
    mesh_instance.position = p
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color_value
    mesh_instance.material_override = mat
    parent.add_child(mesh_instance)


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


func _build_town_npcs() -> void:
    # NPC models are intentionally simple placeholders so their visuals can be
    # replaced later without changing their interaction logic.
    _make_town_npc("Blacksmith", Vector3(-8, 0, -2.4),
        Color("#8D5638"), Color("#C28B57"),
        "Blacksmith: Welcome, hero. Equipment upgrades will be available here soon.")
    _make_town_npc("MarketMerchant", Vector3(6, 0, -19.2),
        Color("#3E6B9A"), Color("#D6B27A"),
        "Merchant: Potions, supplies, and useful gear will be sold here.")
    _make_town_npc("WoodsGuard", Vector3(0, 0, 9.3),
        Color("#4B6845"), Color("#C9B28B"),
        "Guard: Stay alert beyond this gate. The Whispering Woods are dangerous.")
    _make_town_npc("Innkeeper", Vector3(-17, 0, -26.2),
        Color("#8B5C43"), Color("#D5B08A"),
        "Innkeeper: Rest here after your adventures. Welcome to the Hearthvale Inn.")
    _make_town_npc("Baker", Vector3(-15, 0, -16.2),
        Color("#B77B43"), Color("#E1C49B"),
        "Baker: Fresh bread for travelers! A proper shop is coming soon.")
    _make_town_npc("Apothecary", Vector3(17, 0, -29.2),
        Color("#76518A"), Color("#D2B6A0"),
        "Apothecary: I will prepare potions and remedies for your journey.")
    _make_town_npc("VillageResident", Vector3(11, 0, -8.5),
        Color("#6D796A"), Color("#C58F68"),
        "Villager: Hearthvale is growing safer thanks to brave adventurers like you.")


func _make_town_npc(npc_name: String, p: Vector3, tunic_color: Color,
        skin_color: Color, dialogue: String) -> void:
    var npc := Node3D.new()
    npc.name = npc_name
    npc.position = p
    npc.set_meta("is_town_npc", true)
    npc.set_meta("npc_dialogue", dialogue)
    add_child(npc)

    var body := MeshInstance3D.new()
    body.name = "Body"
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.38
    body_mesh.height = 1.35
    body.mesh = body_mesh
    body.position.y = 0.82
    var body_mat := StandardMaterial3D.new()
    body_mat.albedo_color = tunic_color
    body.material_override = body_mat
    npc.add_child(body)

    var head := MeshInstance3D.new()
    head.name = "Head"
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.27
    head_mesh.height = 0.54
    head.mesh = head_mesh
    head.position.y = 1.68
    var head_mat := StandardMaterial3D.new()
    head_mat.albedo_color = skin_color
    head.material_override = head_mat
    npc.add_child(head)

    # A simple colored cap/hood helps distinguish town roles before final art.
    var hood := MeshInstance3D.new()
    hood.name = "Hood"
    var hood_mesh := SphereMesh.new()
    hood_mesh.radius = 0.29
    hood_mesh.height = 0.24
    hood.mesh = hood_mesh
    hood.position.y = 1.88
    var hood_mat := StandardMaterial3D.new()
    hood_mat.albedo_color = tunic_color.darkened(0.25)
    hood.material_override = hood_mat
    npc.add_child(hood)

    var label := Label3D.new()
    label.name = "NameLabel"
    label.text = npc_name.replace("Market", " ").replace("Village", " ")
    label.position.y = 2.25
    label.pixel_size = 0.009
    label.modulate = Color("#FFF0C9")
    npc.add_child(label)

    _add_quest_marker(npc, "…", Vector3(0, 2.55, 0), Color("#9FE7E5"))


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

    # Class selection is intentionally removed from the gameplay HUD.
    # The hero class and gender come from PlayerProfile.

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

    # Collect logs for Quest 1.
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

    # Collect supply crates for Quest 4.
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

    # Talk to the Village Elder.
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

    # Talk to the nearest named town NPC.
    var nearest_npc: Node3D = null
    var nearest_npc_distance := 3.8
    for child in get_children():
        if child is Node3D and child.has_meta("is_town_npc"):
            var npc_distance := _flat_distance(p, child.global_position)
            if npc_distance <= nearest_npc_distance:
                nearest_npc_distance = npc_distance
                nearest_npc = child
    if nearest_npc != null:
        _message(str(nearest_npc.get_meta("npc_dialogue")))
        return

    # Other town interactions.
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
