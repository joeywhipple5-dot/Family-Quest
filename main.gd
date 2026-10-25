
extends Node3D

# ============================================================
# FAMILY QUEST - MAIN GAME SCRIPT
# Godot 4.3 | Designed to work with your existing player.gd
# ============================================================

const PLAYER_SCRIPT = preload("res://player.gd")

const PLAYER_START := Vector3(0.0, 0.0, 10.0)
const ATTACK_RANGE := 3.5

var player: CharacterBody3D

var hero_class := "Warrior"
var silver := 0
var chore_gold := 0
var quest_stage := 0
var enemies_defeated := 0
var herbs_collected := 0
var crates_collected := 0

var enemies: Array[Node3D] = []
var npcs: Array[Node3D] = []
var objectives: Array[Node3D] = []

var attack_cooldown := 0.0
var message_timer := 0.0

var hud: CanvasLayer
var health_label: Label
var level_label: Label
var currency_label: Label
var class_label: Label
var quest_label: Label
var message_label: Label
var attack_button: Button
var interact_button: Button
var potion_button: Button
var respawn_button: Button

var level := 1
var xp := 0
var potions := 3

var ground_material: StandardMaterial3D
var road_material: StandardMaterial3D
var stone_material: StandardMaterial3D
var wood_material: StandardMaterial3D
var roof_material: StandardMaterial3D
var herb_material: StandardMaterial3D
var enemy_material: StandardMaterial3D
var gold_material: StandardMaterial3D


func _ready() -> void:
    randomize()
    _create_materials()
    _create_environment()
    _create_world()
    _create_player()
    _create_village()
    _create_npcs()
    _create_objectives()
    _create_enemies()
    _create_hud()
    _refresh_hud()
    _show_message("Welcome to Hearthvale! Find the Village Elder.")


func _process(delta: float) -> void:
    if attack_cooldown > 0.0:
        attack_cooldown -= delta

    if message_timer > 0.0:
        message_timer -= delta
        if message_timer <= 0.0 and is_instance_valid(message_label):
            message_label.text = ""


# ============================================================
# MATERIALS
# ============================================================

func _make_material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.85
    return mat


func _create_materials() -> void:
    ground_material = _make_material(Color(0.20, 0.39, 0.18))
    road_material = _make_material(Color(0.39, 0.38, 0.34))
    stone_material = _make_material(Color(0.43, 0.44, 0.47))
    wood_material = _make_material(Color(0.34, 0.19, 0.09))
    roof_material = _make_material(Color(0.40, 0.12, 0.10))
    herb_material = _make_material(Color(0.20, 0.85, 0.25))
    enemy_material = _make_material(Color(0.70, 0.14, 0.12))
    gold_material = _make_material(Color(0.95, 0.68, 0.10))


func _create_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()

    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.75, 0.80, 0.92)
    env.ambient_light_energy = 0.8
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.name = "Sunlight"
    sun.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)


# ============================================================
# WORLD
# ============================================================

func _create_world() -> void:
    _make_box(
        self, "Ground",
        Vector3(100.0, 1.0, 100.0),
        Vector3(0.0, -0.5, 0.0),
        ground_material, true
    )

    _make_box(
        self, "VillageRoad",
        Vector3(7.0, 0.08, 55.0),
        Vector3(0.0, 0.04, -8.0),
        road_material, false
    )

    _make_box(
        self, "ForestPath",
        Vector3(5.0, 0.09, 35.0),
        Vector3(0.0, 0.05, -38.0),
        road_material, false
    )

    # Outer boundaries.
    _make_box(self, "NorthBoundary",
        Vector3(100.0, 5.0, 1.0),
        Vector3(0.0, 2.0, -50.0), stone_material, true)

    _make_box(self, "SouthBoundary",
        Vector3(100.0, 5.0, 1.0),
        Vector3(0.0, 2.0, 50.0), stone_material, true)

    _make_box(self, "EastBoundary",
        Vector3(1.0, 5.0, 100.0),
        Vector3(50.0, 2.0, 0.0), stone_material, true)

    _make_box(self, "WestBoundary",
        Vector3(1.0, 5.0, 100.0),
        Vector3(-50.0, 2.0, 0.0), stone_material, true)

    # Trees line the forest path.
    for i in range(14):
        var z := -25.0 - float(i) * 1.5
        _create_tree(Vector3(-8.0 - randf_range(0.0, 5.0), 0.0, z))
        _create_tree(Vector3(8.0 + randf_range(0.0, 5.0), 0.0, z))


func _make_box(
    parent: Node3D,
    object_name: String,
    box_size: Vector3,
    object_position: Vector3,
    mat: Material,
    collision_enabled: bool
) -> Node3D:
    var holder: Node3D

    if collision_enabled:
        var body := StaticBody3D.new()
        body.name = object_name
        parent.add_child(body)
        holder = body

        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = box_size
        collision.shape = shape
        body.add_child(collision)
    else:
        holder = Node3D.new()
        holder.name = object_name
        parent.add_child(holder)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = box_size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = mat
    holder.add_child(mesh_instance)

    holder.position = object_position
    return holder


func _create_tree(tree_position: Vector3) -> void:
    var tree := Node3D.new()
    tree.name = "ForestTree"
    tree.position = tree_position
    add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.22
    trunk_mesh.bottom_radius = 0.32
    trunk_mesh.height = 2.0
    trunk.mesh = trunk_mesh
    trunk.material_override = wood_material
    trunk.position.y = 1.0
    tree.add_child(trunk)

    var leaves := MeshInstance3D.new()
    var leaves_mesh := SphereMesh.new()
    leaves_mesh.radius = 1.25
    leaves_mesh.height = 2.4
    leaves.mesh = leaves_mesh
    leaves.material_override = _make_material(
        Color(0.10, randf_range(0.27, 0.38), 0.12)
    )
    leaves.position.y = 2.6
    tree.add_child(leaves)


func _create_building(
    building_name: String,
    building_position: Vector3,
    building_size: Vector3
) -> void:
    var building := Node3D.new()
    building.name = building_name
    building.position = building_position
    add_child(building)

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = building_size
    body.mesh = body_mesh
    body.material_override = wood_material
    body.position.y = building_size.y * 0.5
    building.add_child(body)

    var roof := MeshInstance3D.new()
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(
        building_size.x + 1.0,
        1.6,
        building_size.z + 1.0
    )
    roof.mesh = roof_mesh
    roof.material_override = roof_material
    roof.position.y = building_size.y + 0.6
    building.add_child(roof)

    var collision_body := StaticBody3D.new()
    collision_body.name = "BuildingCollision"
    building.add_child(collision_body)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = building_size
    collision.shape = shape
    collision.position.y = building_size.y * 0.5
    collision_body.add_child(collision)


func _create_village() -> void:
    _create_building(
        "VillageElderHouse",
        Vector3(-11.0, 0.0, -8.0),
        Vector3(7.0, 4.0, 6.0)
    )

    _create_building(
        "Blacksmith",
        Vector3(11.0, 0.0, -8.0),
        Vector3(7.0, 4.0, 6.0)
    )

    _create_building(
        "VillageShop",
        Vector3(-11.0, 0.0, 5.0),
        Vector3(7.0, 4.0, 6.0)
    )

    _create_building(
        "VillageInn",
        Vector3(11.0, 0.0, 5.0),
        Vector3(7.0, 4.0, 6.0)
    )

    # Castle wall behind the village.
    _make_box(self, "CastleBackWall",
        Vector3(25.0, 5.0, 1.0),
        Vector3(0.0, 2.5, -20.0), stone_material, true)

    _make_box(self, "CastleLeftWall",
        Vector3(1.0, 5.0, 12.0),
        Vector3(-12.0, 2.5, -14.0), stone_material, true)

    _make_box(self, "CastleRightWall",
        Vector3(1.0, 5.0, 12.0),
        Vector3(12.0, 2.5, -14.0), stone_material, true)

    _make_box(self, "CampfireBase",
        Vector3(2.0, 0.3, 2.0),
        Vector3(0.0, 0.15, 2.0), stone_material, false)

    var fire := MeshInstance3D.new()
    var fire_mesh := SphereMesh.new()
    fire_mesh.radius = 0.45
    fire_mesh.height = 0.9
    fire.mesh = fire_mesh
    fire.material_override = _make_material(Color(1.0, 0.30, 0.04))
    fire.position = Vector3(0.0, 0.8, 2.0)
    add_child(fire)


# ============================================================
# PLAYER
# Uses the real player.gd controller and its own camera/joystick.
# ============================================================

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCRIPT)
    player.position = PLAYER_START
    add_child(player)

    if player.has_signal("health_changed"):
        player.health_changed.connect(_on_player_health_changed)

    if player.has_signal("player_died"):
        player.player_died.connect(_on_player_died)

    if player.has_signal("player_revived"):
        player.player_revived.connect(_on_player_revived)

    if player.has_method("set_hero_class"):
        player.call("set_hero_class", hero_class)

    if player.has_method("set_hero_gender"):
        player.call("set_hero_gender", "Male")


func _on_player_health_changed(current_health: int, maximum_health: int) -> void:
    if is_instance_valid(health_label):
        health_label.text = "HP: %d / %d" % [
            current_health,
            maximum_health
        ]


func _on_player_died() -> void:
    _show_message("You have been defeated. Press RESPAWN.")


func _on_player_revived() -> void:
    _show_message("You have returned to Hearthvale.")


# ============================================================
# NPCS
# ============================================================

func _create_npcs() -> void:
    _create_npc(
        "Village Elder",
        Vector3(0.0, 0.0, -4.0),
        Color(0.75, 0.60, 0.30),
        "elder"
    )

    _create_npc(
        "Blacksmith",
        Vector3(7.0, 0.0, -6.0),
        Color(0.45, 0.45, 0.48),
        "blacksmith"
    )

    _create_npc(
        "Village Merchant",
        Vector3(-7.0, 0.0, 5.0),
        Color(0.20, 0.65, 0.35),
        "merchant"
    )


func _create_npc(
    npc_name: String,
    npc_position: Vector3,
    npc_color: Color,
    npc_role: String
) -> void:
    var npc := Node3D.new()
    npc.name = npc_name
    npc.position = npc_position
    npc.set_meta("role", npc_role)
    add_child(npc)

    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.4
    body_mesh.height = 1.6
    body.mesh = body_mesh
    body.material_override = _make_material(npc_color)
    body.position.y = 0.8
    npc.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.26
    head_mesh.height = 0.5
    head.mesh = head_mesh
    head.material_override = _make_material(Color(0.84, 0.66, 0.51))
    head.position.y = 1.7
    npc.add_child(head)

    npcs.append(npc)


# ============================================================
# QUEST OBJECTIVES
# ============================================================

func _create_objectives() -> void:
    _create_objective("Herb1", Vector3(-4.0, 0.0, -28.0), "herb")
    _create_objective("Herb2", Vector3(4.0, 0.0, -32.0), "herb")
    _create_objective("Herb3", Vector3(-7.0, 0.0, -36.0), "herb")
    _create_objective("Crate1", Vector3(7.0, 0.0, -30.0), "crate")
    _create_objective("Crate2", Vector3(-8.0, 0.0, -41.0), "crate")


func _create_objective(
    object_name: String,
    object_position: Vector3,
    objective_type: String
) -> void:
    var objective := Node3D.new()
    objective.name = object_name
    objective.position = object_position
    objective.set_meta("objective_type", objective_type)
    objective.set_meta("collected", false)
    add_child(objective)

    var mesh_instance := MeshInstance3D.new()

    if objective_type == "herb":
        var herb_mesh := SphereMesh.new()
        herb_mesh.radius = 0.35
        herb_mesh.height = 0.7
        mesh_instance.mesh = herb_mesh
        mesh_instance.material_override = herb_material
    else:
        var crate_mesh := BoxMesh.new()
        crate_mesh.size = Vector3(0.9, 0.8, 0.9)
        mesh_instance.mesh = crate_mesh
        mesh_instance.material_override = wood_material

    mesh_instance.position.y = 0.45
    objective.add_child(mesh_instance)
    objectives.append(objective)


# ============================================================
# ENEMIES
# ============================================================

func _create_enemies() -> void:
    _create_enemy("Forest Slime", Vector3(-5.0, 0.0, -33.0), 40)
    _create_enemy("Forest Slime", Vector3(5.0, 0.0, -38.0), 40)
    _create_enemy("Woodland Goblin", Vector3(10.0, 0.0, -42.0), 75)
    _create_enemy("Woodland Goblin", Vector3(-10.0, 0.0, -44.0), 75)
    _create_enemy("Forest Slime", Vector3(2.0, 0.0, -47.0), 40)


func _create_enemy(
    enemy_name: String,
    enemy_position: Vector3,
    enemy_hp: int
) -> void:
    var enemy := Node3D.new()
    enemy.name = enemy_name
    enemy.position = enemy_position
    enemy.set_meta("hp", enemy_hp)
    enemy.set_meta("max_hp", enemy_hp)
    enemy.set_meta("dead", false)
    enemy.set_meta("enemy_name", enemy_name)
    add_child(enemy)

    var body := MeshInstance3D.new()

    if enemy_name == "Forest Slime":
        var mesh := SphereMesh.new()
        mesh.radius = 0.6
        mesh.height = 1.0
        body.mesh = mesh
    else:
        var mesh := CapsuleMesh.new()
        mesh.radius = 0.43
        mesh.height = 1.5
        body.mesh = mesh

    body.material_override = enemy_material
    body.position.y = 0.65
    enemy.add_child(body)

    var marker := MeshInstance3D.new()
    var marker_mesh := SphereMesh.new()
    marker_mesh.radius = 0.13
    marker_mesh.height = 0.26
    marker.mesh = marker_mesh
    marker.material_override = gold_material
    marker.position.y = 1.55
    enemy.add_child(marker)

    enemies.append(enemy)


# ============================================================
# COMBAT
# ============================================================

func _attack() -> void:
    if not is_instance_valid(player):
        return

    if bool(player.get("is_dead")):
        return

    if attack_cooldown > 0.0:
        return

    attack_cooldown = 0.6

    var closest_enemy: Node3D = null
    var closest_distance := ATTACK_RANGE

    for enemy in enemies:
        if not is_instance_valid(enemy):
            continue

        if bool(enemy.get_meta("dead", false)):
            continue

        var distance := player.global_position.distance_to(
            enemy.global_position
        )

        if distance <= closest_distance:
            closest_enemy = enemy
            closest_distance = distance

    if closest_enemy == null:
        _show_message("No enemy in range. Move closer.")
        return

    var damage_amount := 25

    match hero_class:
        "Warrior":
            damage_amount = 35
        "Mage":
            damage_amount = 30
        "Rogue":
            damage_amount = 32
        "Druid":
            damage_amount = 27
        "Ranger":
            damage_amount = 30

    var hp := int(closest_enemy.get_meta("hp", 1))
    hp -= damage_amount
    closest_enemy.set_meta("hp", hp)

    if hp <= 0:
        _defeat_enemy(closest_enemy)
    else:
        _show_message(
            "%s hit! Enemy HP: %d" % [
                str(closest_enemy.get_meta("enemy_name", "Enemy")),
                hp
            ]
        )


func _defeat_enemy(enemy: Node3D) -> void:
    enemy.set_meta("dead", true)
    enemies_defeated += 1
    xp += 25
    silver += 5
    enemy.queue_free()

    if xp >= level * 100:
        xp -= level * 100
        level += 1
        _show_message("Level up! You reached level %d." % level)
    else:
        _show_message("Enemy defeated! +25 XP and +5 Silver.")

    _refresh_hud()


func _use_potion() -> void:
    if not is_instance_valid(player):
        return

    if bool(player.get("is_dead")):
        return

    if potions <= 0:
        _show_message("You have no potions.")
        return

    var current_hp := int(player.get("current_health"))
    var maximum_hp := int(player.get("max_health"))

    if current_hp >= maximum_hp:
        _show_message("Your health is already full.")
        return

    potions -= 1
    player.call("heal", 50)
    _show_message("Potion used.")
    _refresh_hud()


func _respawn_player() -> void:
    if not is_instance_valid(player):
        return

    player.call("revive", PLAYER_START)
    _show_message("You have returned to Hearthvale.")


# ============================================================
# INTERACTION AND QUESTS
# ============================================================

func _interact() -> void:
    if not is_instance_valid(player):
        return

    if bool(player.get("is_dead")):
        return

    var nearest_npc: Node3D = null
    var npc_distance := 4.0

    for npc in npcs:
        if not is_instance_valid(npc):
            continue

        var distance := player.global_position.distance_to(
            npc.global_position
        )

        if distance < npc_distance:
            npc_distance = distance
            nearest_npc = npc

    if nearest_npc != null:
        _talk_to_npc(nearest_npc)
        return

    var nearest_objective: Node3D = null
    var objective_distance := 3.0

    for objective in objectives:
        if not is_instance_valid(objective):
            continue

        if bool(objective.get_meta("collected", false)):
            continue

        var distance := player.global_position.distance_to(
            objective.global_position
        )

        if distance < objective_distance:
            objective_distance = distance
            nearest_objective = objective

    if nearest_objective != null:
        _collect_objective(nearest_objective)
        return

    _show_message("Move closer to a person or item.")


func _talk_to_npc(npc: Node3D) -> void:
    var role := str(npc.get_meta("role", ""))

    match role:
        "elder":
            _advance_quest()
        "blacksmith":
            if silver >= 10:
                silver -= 10
                player.call("heal", 40)
                _show_message("The blacksmith repaired your armor. -10 Silver.")
            else:
                _show_message("Blacksmith: Bring me 10 Silver for repairs.")
        "merchant":
            if silver >= 15:
                silver -= 15
                potions += 1
                _show_message("You bought a potion for 15 Silver.")
            else:
                _show_message("Merchant: A potion costs 15 Silver.")

    _refresh_hud()


func _advance_quest() -> void:
    match quest_stage:
        0:
            quest_stage = 1
            _show_message("Quest 1: Defeat 3 forest enemies.")
        1:
            if enemies_defeated >= 3:
                quest_stage = 2
                chore_gold += 10
                silver += 15
                xp += 50
                _show_message("Quest complete! Earned Gold, Silver, and XP.")
            else:
                _show_message(
                    "Defeat 3 enemies first. (%d/3)" % mini(enemies_defeated, 3)
                )
        2:
            quest_stage = 3
            _show_message("Quest 2: Gather 3 herbs from the forest.")
        3:
            if herbs_collected >= 3:
                quest_stage = 4
                chore_gold += 10
                silver += 15
                xp += 50
                _show_message("Quest complete! The herbs have been gathered.")
            else:
                _show_message(
                    "Gather 3 herbs first. (%d/3)" % mini(herbs_collected, 3)
                )
        4:
            quest_stage = 5
            _show_message("Quest 3: Collect 2 supply crates.")
        5:
            if crates_collected >= 2:
                quest_stage = 6
                chore_gold += 15
                silver += 20
                xp += 75
                _show_message("Quest complete! Hearthvale's supplies are restored.")
            else:
                _show_message(
                    "Find both supply crates. (%d/2)" % mini(crates_collected, 2)
                )
        6:
            quest_stage = 7
            _show_message("Quest 4: Defeat all remaining forest enemies.")
        7:
            if _all_enemies_defeated():
                quest_stage = 8
                chore_gold += 20
                silver += 30
                xp += 100
                _show_message("Quest complete! The forest is safe.")
            else:
                _show_message("Defeat the remaining forest enemies.")
        8:
            quest_stage = 9
            _show_message("Quest 5: Explore the far forest path.")
        9:
            if player.global_position.z < -45.0:
                quest_stage = 10
                chore_gold += 25
                silver += 40
                xp += 150
                _show_message("Hearthvale chapter complete!")
            else:
                _show_message("Follow the forest path farther north.")
        _:
            _show_message("Elder: You are a hero of Hearthvale!")

    _refresh_hud()


func _collect_objective(objective: Node3D) -> void:
    if bool(objective.get_meta("collected", false)):
        return

    objective.set_meta("collected", true)

    var kind := str(objective.get_meta("objective_type", ""))

    if kind == "herb":
        herbs_collected += 1
        xp += 5
        _show_message("Herb collected! (%d/3)" % mini(herbs_collected, 3))
    elif kind == "crate":
        crates_collected += 1
        _show_message("Supply crate collected! (%d/2)" % mini(crates_collected, 2))

    objective.queue_free()
    _refresh_hud()


func _all_enemies_defeated() -> bool:
    for enemy in enemies:
        if is_instance_valid(enemy) and not bool(enemy.get_meta("dead", false)):
            return false

    return true


# ============================================================
# HERO CLASSES
# ============================================================

func _select_class(selected_class_name: String) -> void:
    hero_class = selected_class_name

    if is_instance_valid(player):
        player.call("set_hero_class", selected_class_name)

    _show_message("Hero class changed to %s." % selected_class_name)
    _refresh_hud()


# ============================================================
# HUD
# ============================================================

func _create_hud() -> void:
    hud = CanvasLayer.new()
    hud.name = "GameHUD"
    add_child(hud)

    var root := Control.new()
    root.name = "HUDRoot"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.add_child(root)

    var info_panel := PanelContainer.new()
    info_panel.position = Vector2(12.0, 12.0)
    info_panel.custom_minimum_size = Vector2(280.0, 145.0)
    root.add_child(info_panel)

    var info_column := VBoxContainer.new()
    info_panel.add_child(info_column)

    var title := Label.new()
    title.text = "FAMILY QUEST - HEARTHVALE"
    info_column.add_child(title)

    health_label = Label.new()
    info_column.add_child(health_label)

    level_label = Label.new()
    info_column.add_child(level_label)

    currency_label = Label.new()
    info_column.add_child(currency_label)

    class_label = Label.new()
    info_column.add_child(class_label)

    var quest_panel := PanelContainer.new()
    quest_panel.position = Vector2(12.0, 165.0)
    quest_panel.custom_minimum_size = Vector2(290.0, 78.0)
    root.add_child(quest_panel)

    quest_label = Label.new()
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quest_panel.add_child(quest_label)

    message_label = Label.new()
    message_label.anchor_left = 0.5
    message_label.anchor_right = 0.5
    message_label.anchor_top = 1.0
    message_label.anchor_bottom = 1.0
    message_label.offset_left = -250.0
    message_label.offset_right = 250.0
    message_label.offset_top = -90.0
    message_label.offset_bottom = -40.0
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(message_label)

    # Class selection.
    var class_panel := PanelContainer.new()
    class_panel.anchor_left = 1.0
    class_panel.anchor_right = 1.0
    class_panel.offset_left = -385.0
    class_panel.offset_right = -10.0
    class_panel.offset_top = 12.0
    class_panel.offset_bottom = 65.0
    root.add_child(class_panel)

    var class_row := HBoxContainer.new()
    class_panel.add_child(class_row)

    for selected_class_name in ["Warrior", "Mage", "Rogue", "Druid", "Ranger"]:
        var button := Button.new()
        button.text = selected_class_name
        button.custom_minimum_size = Vector2(68.0, 40.0)
        button.pressed.connect(_select_class.bind(selected_class_name))
        class_row.add_child(button)

    # Gameplay buttons. The player.gd script supplies the joystick
    # and camera touch controls.
    attack_button = _make_hud_button(
        root, "ATTACK", Vector2(-165.0, -150.0), Vector2(145.0, 65.0)
    )
    attack_button.pressed.connect(_attack)

    interact_button = _make_hud_button(
        root, "INTERACT", Vector2(-165.0, -78.0), Vector2(145.0, 60.0)
    )
    interact_button.pressed.connect(_interact)

    potion_button = _make_hud_button(
        root, "POTION", Vector2(-315.0, -78.0), Vector2(135.0, 60.0)
    )
    potion_button.pressed.connect(_use_potion)

    respawn_button = _make_hud_button(
        root, "RESPAWN", Vector2(-315.0, -150.0), Vector2(135.0, 60.0)
    )
    respawn_button.pressed.connect(_respawn_player)

    _refresh_hud()


func _make_hud_button(
    parent: Control,
    button_text: String,
    offset: Vector2,
    button_size: Vector2
) -> Button:
    var button := Button.new()
    button.text = button_text
    button.custom_minimum_size = button_size
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.offset_left = offset.x
    button.offset_right = offset.x + button_size.x
    button.offset_top = offset.y
    button.offset_bottom = offset.y + button_size.y
    parent.add_child(button)
    return button


func _refresh_hud() -> void:
    if is_instance_valid(level_label):
        level_label.text = "Level: %d | XP: %d" % [level, xp]

    if is_instance_valid(currency_label):
        currency_label.text = "Gold: %d | Silver: %d | Potions: %d" % [
            chore_gold, silver, potions
        ]

    if is_instance_valid(class_label):
        class_label.text = "Class: " + hero_class

    if is_instance_valid(quest_label):
        quest_label.text = _quest_description()

    if is_instance_valid(player) and is_instance_valid(health_label):
        health_label.text = "HP: %d / %d" % [
            int(player.get("current_health")),
            int(player.get("max_health"))
        ]


func _quest_description() -> String:
    match quest_stage:
        0:
            return "QUEST: Talk to the Village Elder."
        1:
            return "QUEST 1: Defeat enemies (%d/3)." % mini(enemies_defeated, 3)
        2:
            return "QUEST: Return to the Village Elder."
        3:
            return "QUEST 2: Gather herbs (%d/3)." % mini(herbs_collected, 3)
        4:
            return "QUEST: Return to the Village Elder."
        5:
            return "QUEST 3: Collect crates (%d/2)." % mini(crates_collected, 2)
        6:
            return "QUEST: Return to the Village Elder."
        7:
            return "QUEST 4: Defeat remaining enemies."
        8:
            return "QUEST: Return to the Village Elder."
        9:
            return "QUEST 5: Explore the far forest path."
        _:
            return "HEARTHVALE CHAPTER COMPLETE!"


func _show_message(message: String) -> void:
    if is_instance_valid(message_label):
        message_label.text = message
        message_timer = 5.0
    else:
        print(message)


# ============================================================
# KEYBOARD INPUT FOR TESTING
# Android players use the on-screen buttons and player joystick.
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_SPACE:
                _attack()
            KEY_E:
                _interact()
            KEY_H:
                _use_potion()
