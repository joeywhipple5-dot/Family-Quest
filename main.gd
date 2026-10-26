
extends Node3D

# ==================================================
# FAMILY QUEST - HEARTHVALE
# Godot 4.3 | Main game controller
# ==================================================

const PLAYER_SCRIPT = preload("res://player.gd")
const ENEMY_SCRIPT = preload("res://enemy.gd")

const PLAYER_START := Vector3(0.0, 0.0, 10.0)
const ATTACK_RANGE := 3.5
const INTERACT_RANGE := 4.0
const MOBS_REQUIRED := 3
const PATH_MOBS_REQUIRED := 5

var player: CharacterBody3D
var camera: Camera3D

var enemies: Array[Node3D] = []
var npcs: Array[Node3D] = []
var objectives: Array[Node3D] = []

var hero_class := "Warrior"
var hero_gender := "Male"

var level := 1
var xp := 0
var xp_to_next_level := 100
var silver := 0
var chore_gold := 0
var potions := 3

var quest_stage := 0
var enemies_defeated := 0
var path_enemies_defeated := 0
var herbs_collected := 0
var crates_collected := 0

var attack_cooldown := 0.0
var message_timer := 0.0
var dead := false

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
var class_buttons: HBoxContainer


# ==================================================
# STARTUP
# ==================================================



func _ready() -> void:
    _show_startup_debug("Starting gameplay...")

    _show_startup_debug("Step 1: Environment")
    _create_environment()

    _show_startup_debug("Step 2: World")
    _create_world()

    _show_startup_debug("Step 3: Village")
    _create_village()

    _show_startup_debug("Step 4: Player")
    _create_player()

    _show_startup_debug("Step 5: NPCs")
    _create_npcs()

    _show_startup_debug("Step 6: Objectives")
    _create_objectives()

    _show_startup_debug("Step 7: Enemies")
    _create_enemies()

    _show_startup_debug("Step 8: Camera")
    _create_camera()

    _show_startup_debug("Step 9: HUD")
    _create_hud()

    _refresh()
    _show_startup_debug("Startup complete!")
    _message("Welcome to Hearthvale! Speak to the Elder.")


func _show_startup_debug(message: String) -> void:
    var layer := get_node_or_null("StartupDebugLayer") as CanvasLayer

    if layer == null:
        layer = CanvasLayer.new()
        layer.name = "StartupDebugLayer"
        layer.layer = 100
        add_child(layer)

        var background := ColorRect.new()
        background.name = "Background"
        background.color = Color(0.05, 0.05, 0.05, 0.9)
        background.position = Vector2(12, 12)
        background.size = Vector2(340, 64)
        layer.add_child(background)

        var label := Label.new()
        label.name = "Status"
        label.position = Vector2(22, 20)
        label.size = Vector2(320, 50)
        label.add_theme_color_override("font_color", Color.WHITE)
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        layer.add_child(label)

    var status := layer.get_node("Status") as Label
    status.text = message

    

func _process(delta: float) -> void:
    attack_cooldown = max(0.0, attack_cooldown - delta)
    message_timer = max(0.0, message_timer - delta)

    if message_timer <= 0.0 and is_instance_valid(message_label):
        message_label.text = ""

    _update_camera()

# ==================================================
# ENVIRONMENT AND WORLD
# ==================================================

func _create_environment() -> void:
    var world_environment := WorldEnvironment.new()
    var environment := Environment.new()

    environment.background_mode = Environment.BG_SKY
    environment.sky = Sky.new()
    environment.sky.sky_material = ProceduralSkyMaterial.new()
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.65, 0.72, 0.82)
    environment.ambient_light_energy = 0.8
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
    sun.light_energy = 1.2
    add_child(sun)


func _create_world() -> void:
    _make_box(
        "Ground",
        Vector3(360.0, 1.0, 400.0),
        Vector3(0.0, -0.6, 0.0),
        Color(0.22, 0.43, 0.19),
        true
    )

    # Village road.
    _make_box(
        "VillageRoad",
        Vector3(12.0, 0.12, 100.0),
        Vector3(0.0, 0.0, 0.0),
        Color(0.48, 0.39, 0.27),
        false
    )

    # Path leading into the forest.
    _make_box(
        "ForestPath",
        Vector3(7.0, 0.13, 100.0),
        Vector3(0.0, 0.01, -90.0),
        Color(0.48, 0.38, 0.25),
        false
    )

    # Simple boundary walls.
    _make_box(
        "NorthBoundary",
        Vector3(360.0, 5.0, 2.0),
        Vector3(0.0, 2.0, -200.0),
        Color(0.18, 0.30, 0.14),
        true
    )

    _make_box(
        "SouthBoundary",
        Vector3(360.0, 5.0, 2.0),
        Vector3(0.0, 2.0, 200.0),
        Color(0.18, 0.30, 0.14),
        true
    )

    _make_box(
        "WestBoundary",
        Vector3(2.0, 5.0, 400.0),
        Vector3(-180.0, 2.0, 0.0),
        Color(0.18, 0.30, 0.14),
        true
    )

    _make_box(
        "EastBoundary",
        Vector3(2.0, 5.0, 400.0),
        Vector3(180.0, 2.0, 0.0),
        Color(0.18, 0.30, 0.14),
        true
    )

    # Trees on both sides of the forest path.
    for i in range(18):
        var z_position := -35.0 - float(i) * 7.0

        _create_tree(
            Vector3(-12.0 - float(i % 3) * 3.0, 0.0, z_position)
        )

        _create_tree(
            Vector3(12.0 + float(i % 4) * 3.0, 0.0, z_position - 3.0)
        )


func _create_tree(pos: Vector3) -> void:
    var tree := Node3D.new()
    tree.name = "Tree"
    tree.position = pos
    add_child(tree)

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.25
    trunk_mesh.bottom_radius = 0.4
    trunk_mesh.height = 2.5
    trunk.mesh = trunk_mesh
    trunk.position.y = 1.25

    var trunk_material := StandardMaterial3D.new()
    trunk_material.albedo_color = Color(0.30, 0.18, 0.10)
    trunk.material_override = trunk_material
    tree.add_child(trunk)

    var leaves := MeshInstance3D.new()
    var leaves_mesh := SphereMesh.new()
    leaves_mesh.radius = 1.5
    leaves_mesh.height = 3.0
    leaves.mesh = leaves_mesh
    leaves.position.y = 3.0

    var leaf_material := StandardMaterial3D.new()
    leaf_material.albedo_color = Color(0.10, 0.32, 0.12)
    leaves.material_override = leaf_material
    tree.add_child(leaves)


func _create_village() -> void:
    _create_building(
        "ElderHall",
        Vector3(-10.0, 0.0, 0.0),
        Vector3(9.0, 5.0, 8.0),
        Color(0.48, 0.34, 0.23)
    )

    _create_building(
        "Blacksmith",
        Vector3(12.0, 0.0, 8.0),
        Vector3(8.0, 4.5, 7.0),
        Color(0.35, 0.34, 0.32)
    )

    _create_building(
        "GeneralStore",
        Vector3(-12.0, 0.0, 14.0),
        Vector3(7.0, 4.0, 7.0),
        Color(0.55, 0.42, 0.25)
    )

    _create_building(
        "HouseEast",
        Vector3(14.0, 0.0, -8.0),
        Vector3(7.0, 4.0, 7.0),
        Color(0.54, 0.38, 0.28)
    )

    _create_building(
        "HouseWest",
        Vector3(-14.0, 0.0, -10.0),
        Vector3(7.0, 4.0, 7.0),
        Color(0.46, 0.36, 0.27)
    )


func _create_building(
    building_name: String,
    pos: Vector3,
    dimensions: Vector3,
    wall_color: Color
) -> void:
    var building := Node3D.new()
    building.name = building_name
    building.position = pos
    add_child(building)

    _make_box(
        building_name + "_Walls",
        dimensions,
        pos + Vector3(0.0, dimensions.y * 0.5, 0.0),
        wall_color,
        true
    )

    _make_box(
        building_name + "_Roof",
        Vector3(
            dimensions.x + 1.5,
            0.7,
            dimensions.z + 1.5
        ),
        pos + Vector3(0.0, dimensions.y + 0.25, 0.0),
        Color(0.28, 0.13, 0.12),
        true
    )


func _make_box(
    object_name: String,
    dimensions: Vector3,
    pos: Vector3,
    color: Color,
    with_collision: bool = true
) -> Node3D:
    var body := StaticBody3D.new() if with_collision else Node3D.new()
    body.name = object_name
    body.position = pos
    add_child(body)

    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    mesh_instance.mesh = mesh

    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    mesh_instance.material_override = material
    body.add_child(mesh_instance)

    if with_collision:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = dimensions
        collision.shape = shape
        body.add_child(collision)

    return body


# ==================================================
# PLAYER AND CAMERA
# ==================================================

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
        player.call("set_hero_gender", hero_gender)


func _create_camera() -> void:
    camera = Camera3D.new()
    camera.name = "GameCamera"
    camera.current = true
    camera.fov = 70.0
    camera.position = Vector3(0.0, 7.0, 10.0)
    add_child(camera)

    _update_camera()


func _update_camera() -> void:
    if not is_instance_valid(camera) or not is_instance_valid(player):
        return

    var target_position := player.global_position + Vector3(0.0, 6.0, 9.0)

    camera.global_position = camera.global_position.lerp(
        target_position,
        0.12
    )

    camera.look_at(
        player.global_position + Vector3(0.0, 1.0, 0.0),
        Vector3.UP
    )


# ==================================================
# NPCS AND INTERACTABLE OBJECTS
# ==================================================

func _create_npcs() -> void:
    _create_npc(
        "Elder",
        "Elder",
        Vector3(-4.0, 0.0, 0.0),
        Color(0.75, 0.65, 0.43)
    )

    _create_npc(
        "Blacksmith",
        "Blacksmith",
        Vector3(8.0, 0.0, 8.0),
        Color(0.42, 0.43, 0.48)
    )

    _create_npc(
        "Merchant",
        "Merchant",
        Vector3(-8.0, 0.0, 12.0),
        Color(0.25, 0.48, 0.28)
    )

    _create_npc(
        "Guard",
        "Guard",
        Vector3(0.0, 0.0, -5.0),
        Color(0.25, 0.35, 0.55)
    )


func _create_npc(
    npc_name: String,
    role: String,
    pos: Vector3,
    color: Color
) -> void:
    var npc := Node3D.new()
    npc.name = npc_name
    npc.position = pos
    npc.set_meta("interactable", true)
    npc.set_meta("interaction_type", "npc")
    npc.set_meta("role", role)
    npc.set_meta("display_name", npc_name)
    add_child(npc)

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.38
    capsule.height = 1.6
    body.mesh = capsule
    body.position.y = 0.8

    var material := StandardMaterial3D.new()
    material.albedo_color = color
    body.material_override = material
    npc.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.25
    head_mesh.height = 0.5
    head.mesh = head_mesh
    head.position.y = 1.75

    var head_material := StandardMaterial3D.new()
    head_material.albedo_color = Color(0.78, 0.61, 0.47)
    head.material_override = head_material
    npc.add_child(head)

    var label := Label3D.new()
    label.text = npc_name
    label.position.y = 2.2
    label.font_size = 32
    label.pixel_size = 0.005
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    npc.add_child(label)

    npcs.append(npc)


func _create_objectives() -> void:
    _create_objective(
        "QuestBoard",
        "quest_board",
        Vector3(0.0, 0.0, 4.0),
        Color(0.42, 0.25, 0.12)
    )

    for i in range(6):
        _create_objective(
            "Herb_" + str(i + 1),
            "herb",
            Vector3(
                -7.0 + float(i % 3) * 5.0,
                0.0,
                -24.0 - float(i / 3) * 5.0
            ),
            Color(0.15, 0.8, 0.2)
        )

    for i in range(5):
        _create_objective(
            "SupplyCrate_" + str(i + 1),
            "crate",
            Vector3(
                -5.0 + float(i % 3) * 5.0,
                0.0,
                -12.0 - float(i / 3) * 5.0
            ),
            Color(0.55, 0.32, 0.12)
        )


func _create_objective(
    object_name: String,
    objective_type: String,
    pos: Vector3,
    color: Color
) -> void:
    var objective := StaticBody3D.new()
    objective.name = object_name
    objective.position = pos
    objective.set_meta("interactable", true)
    objective.set_meta("interaction_type", objective_type)
    objective.set_meta("display_name", object_name)
    objective.set_meta("collected", false)
    add_child(objective)

    var mesh_instance := MeshInstance3D.new()

    if objective_type == "herb":
        var mesh := SphereMesh.new()
        mesh.radius = 0.35
        mesh.height = 0.7
        mesh_instance.mesh = mesh
        mesh_instance.position.y = 0.35
    else:
        var mesh := BoxMesh.new()
        mesh.size = Vector3(0.9, 0.9, 0.9)
        mesh_instance.mesh = mesh
        mesh_instance.position.y = 0.45

    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh_instance.material_override = material
    objective.add_child(mesh_instance)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(1.0, 1.0, 1.0)
    collision.shape = shape
    collision.position.y = 0.5
    objective.add_child(collision)

    var label := Label3D.new()
    label.text = "Quest Board" if objective_type == "quest_board" else (
        "Herb" if objective_type == "herb" else "Supply Crate"
    )
    label.position.y = 1.2
    label.font_size = 24
    label.pixel_size = 0.004
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    objective.add_child(label)

    objectives.append(objective)


# ==================================================
# ENEMY SPAWNING
# ==================================================

func _create_enemies() -> void:
    # Village outskirts.
    _spawn_enemy("Forest Slime", Vector3(-8.0, 0.0, -28.0))
    _spawn_enemy("Forest Slime", Vector3(8.0, 0.0, -32.0))
    _spawn_enemy("Woodland Goblin", Vector3(13.0, 0.0, -38.0))

    # Forest path enemies.
    _spawn_enemy("Thornwolf", Vector3(-9.0, 0.0, -65.0))
    _spawn_enemy("Woodland Goblin", Vector3(9.0, 0.0, -72.0))
    _spawn_enemy("Forest Slime", Vector3(-10.0, 0.0, -82.0))
    _spawn_enemy("Thornwolf", Vector3(10.0, 0.0, -91.0))
    _spawn_enemy("Woodland Goblin", Vector3(0.0, 0.0, -102.0))

    # First-area boss.
    _spawn_enemy("Mossjaw", Vector3(0.0, 0.0, -125.0), true)


func _spawn_enemy(
    enemy_type: String,
    spawn_position: Vector3,
    boss: bool = false
) -> void:
    var enemy := CharacterBody3D.new()
    enemy.name = enemy_type
    enemy.set_script(ENEMY_SCRIPT)
    enemy.position = spawn_position

    enemy.set("enemy_name", enemy_type)
    enemy.set("is_boss", boss)

    add_child(enemy)

    if enemy.has_method("set"):
        enemy.set("player", player)

    enemies.append(enemy)


# ==================================================
# COMBAT
# ==================================================

func _attack() -> void:
    if dead or attack_cooldown > 0.0 or not is_instance_valid(player):
        return

    attack_cooldown = 0.5

    var closest_enemy: Node3D
    var closest_distance := ATTACK_RANGE

    for enemy in enemies:
        if not is_instance_valid(enemy):
            continue

        if enemy.get("dead") == true:
            continue

        var distance := player.global_position.distance_to(
            enemy.global_position
        )

        if distance < closest_distance:
            closest_distance = distance
            closest_enemy = enemy

    if not is_instance_valid(closest_enemy):
        _message("No enemy in attack range.")
        return

    var damage := 20

    match hero_class:
        "Warrior":
            damage = 25
        "Mage":
            damage = 22
        "Rogue":
            damage = 20
        "Druid":
            damage = 18
        "Ranger":
            damage = 21

    if closest_enemy.has_method("take_hit"):
        closest_enemy.call("take_hit", damage)
    else:
        _message("Enemy combat script is missing.")


func enemy_defeated(enemy: Node3D) -> void:
    if not is_instance_valid(enemy):
        return

    var enemy_type := str(enemy.get("enemy_name"))
    var boss := enemy.get("is_boss") == true

    xp += 35 if boss else 20
    silver += 50 if boss else 8

    if str(enemy_type) == "Forest Slime" or str(enemy_type) == "Woodland Goblin":
        enemies_defeated += 1
    else:
        path_enemies_defeated += 1

    _check_level_up()
    _update_quest_progress()
    _refresh()

    if boss:
        _message("Mossjaw defeated! The forest boss is down!")
    else:
        _message("%s defeated! Earned XP and silver." % enemy_type)


func _check_level_up() -> void:
    while xp >= xp_to_next_level:
        xp -= xp_to_next_level
        level += 1
        xp_to_next_level = level * 100

        if is_instance_valid(player):
            if player.has_method("set_max_health"):
                player.call("set_max_health", 100 + (level - 1) * 10)

            if player.has_method("heal"):
                player.call("heal", 100)

        _message("Level up! You are now level %d." % level)


# ==================================================
# INTERACTION
# Tap the world or use the Interact button.
# ==================================================

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E:
            _interact()
        elif event.keycode == KEY_H:
            _use_potion()
        elif event.keycode == KEY_ESCAPE:
            _message("Family Quest paused.")

    if event is InputEventScreenTouch and event.pressed:
        if _is_touch_over_hud(event.position):
            return

        _try_tap_interaction(event.position)


func _is_touch_over_hud(touch_position: Vector2) -> bool:
    if not is_instance_valid(attack_button):
        return false

    var controls: Array[Control] = [
        attack_button,
        interact_button,
        potion_button,
        respawn_button,
        class_buttons
    ]

    for control in controls:
        if not is_instance_valid(control):
            continue

        if control.get_global_rect().has_point(touch_position):
            return true

    return false


func _try_tap_interaction(screen_position: Vector2) -> void:
    if not is_instance_valid(camera):
        return

    var ray_origin := camera.project_ray_origin(screen_position)
    var ray_direction := camera.project_ray_normal(screen_position)
    var ray_end := ray_origin + ray_direction * 100.0

    var query := PhysicsRayQueryParameters3D.create(
        ray_origin,
        ray_end
    )

    query.exclude = [player.get_rid()]

    var result := get_world_3d().direct_space_state.intersect_ray(query)

    if result.is_empty():
        return

    var hit_object: Object = result.get("collider")

    if hit_object is Node:
        var node := hit_object as Node

        while is_instance_valid(node):
            if node.has_meta("interactable"):
                if node.get_meta("interactable") == true:
                    _interact_with_object(node)
                    return

            node = node.get_parent()

    # Tapping an enemy selects it for a short-range attack.
    if hit_object is Node:
        var hit_node := hit_object as Node

        while is_instance_valid(hit_node):
            if hit_node.is_in_group("enemies"):
                _attack_specific_enemy(hit_node as Node3D)
                return

            hit_node = hit_node.get_parent()


func _attack_specific_enemy(enemy: Node3D) -> void:
    if dead or not is_instance_valid(enemy):
        return

    var distance := player.global_position.distance_to(
        enemy.global_position
    )

    if distance > ATTACK_RANGE:
        _message("Move closer to attack.")
        return

    if attack_cooldown > 0.0:
        return

    attack_cooldown = 0.5

    if enemy.has_method("take_hit"):
        enemy.call("take_hit", 20)


func _interact() -> void:
    if dead or not is_instance_valid(player):
        return

    var nearest: Node3D
    var nearest_distance := INTERACT_RANGE

    for npc in npcs:
        if not is_instance_valid(npc):
            continue

        var distance := player.global_position.distance_to(
            npc.global_position
        )

        if distance < nearest_distance:
            nearest = npc
            nearest_distance = distance

    for objective in objectives:
        if not is_instance_valid(objective):
            continue

        if objective.get_meta("collected", false):
            continue

        var distance := player.global_position.distance_to(
            objective.global_position
        )

        if distance < nearest_distance:
            nearest = objective
            nearest_distance = distance

    if is_instance_valid(nearest):
        _interact_with_object(nearest)
    else:
        _message("Nothing nearby to interact with.")


func _interact_with_object(target: Node) -> void:
    if not is_instance_valid(target):
        return

    if not is_instance_valid(player):
        return

    var distance := player.global_position.distance_to(
        target.global_position
    )

    if distance > INTERACT_RANGE:
        _message("Move closer to interact.")
        return

    if target.has_meta("interaction_type"):
        var interaction_type := str(target.get_meta("interaction_type"))

        match interaction_type:
            "npc":
                _talk_to_npc(target)
            "herb":
                _collect_herb(target)
            "crate":
                _collect_crate(target)
            "quest_board":
                _message("Quest Board: Speak with the Elder for your next task.")
            _:
                _message("You interact with %s." % target.name)


func _talk_to_npc(npc: Node) -> void:
    var role := str(npc.get_meta("role", npc.name))

    match role:
        "Elder":
            _talk_to_elder()
        "Blacksmith":
            _message("Blacksmith: Defeat monsters to earn silver for equipment.")
        "Merchant":
            _message("Merchant: Potions cost 10 silver.")
            if silver >= 10:
                silver -= 10
                potions += 1
                _message("Purchased a potion.")
                _refresh()
        "Guard":
            _message("Guard: The forest path is dangerous. Stay alert.")
        _:
            _message("You speak with %s." % role)


func _talk_to_elder() -> void:
    match quest_stage:
        0:
            quest_stage = 1
            _message("Elder: Defeat 3 monsters near the village.")
        1:
            if enemies_defeated >= MOBS_REQUIRED:
                quest_stage = 2
                chore_gold += 10
                silver += 25
                xp += 50
                _check_level_up()
                _message("Quest complete! Earned 10 Gold and 25 Silver.")
            else:
                _message(
                    "Elder: Defeat %d more village monsters."
                    % (MOBS_REQUIRED - enemies_defeated)
                )
        2:
            _message("Elder: Collect 3 healing herbs in the forest.")
            quest_stage = 3
        3:
            if herbs_collected >= 3:
                quest_stage = 4
                chore_gold += 10
                silver += 20
                xp += 50
                _check_level_up()
                _message("Herb quest complete! Rewards earned.")
            else:
                _message(
                    "Elder: You have collected %d of 3 herbs."
                    % herbs_collected
                )
        4:
            _message("Elder: Defeat 5 enemies along the forest path.")
            quest_stage = 5
        5:
            if path_enemies_defeated >= PATH_MOBS_REQUIRED:
                quest_stage = 6
                chore_gold += 20
                silver += 50
                xp += 100
                _check_level_up()
                _message("Forest quest complete! Well done, hero.")
            else:
                _message(
                    "Elder: Defeat %d more forest enemies."
                    % (PATH_MOBS_REQUIRED - path_enemies_defeated)
                )
        _:
            _message("Elder: You have completed the current Hearthvale quests.")

    _refresh()


func _collect_herb(herb: Node) -> void:
    if herb.get_meta("collected", false):
        return

    herb.set_meta("collected", true)
    herbs_collected += 1
    xp += 5
    _check_level_up()

    herb.queue_free()
    _refresh()

    _message("Herb collected! (%d total)" % herbs_collected)


func _collect_crate(crate: Node) -> void:
    if crate.get_meta("collected", false):
        return

    crate.set_meta("collected", true)
    crates_collected += 1
    silver += 5
    xp += 5
    _check_level_up()

    crate.queue_free()
    _refresh()

    _message("Supply crate opened! +5 Silver.")


func _update_quest_progress() -> void:
    if quest_stage == 1 and enemies_defeated >= MOBS_REQUIRED:
        _message("Village monster objective complete. Return to the Elder.")

    if quest_stage == 3 and herbs_collected >= 3:
        _message("Herb objective complete. Return to the Elder.")

    if quest_stage == 5 and path_enemies_defeated >= PATH_MOBS_REQUIRED:
        _message("Forest objective complete. Return to the Elder.")


# ==================================================
# POTIONS AND RESPAWN
# ==================================================

func _use_potion() -> void:
    if dead or not is_instance_valid(player):
        return

    if potions <= 0:
        _message("You have no potions.")
        return

    if player.get("current_health") >= player.get("max_health"):
        _message("Your health is already full.")
        return

    potions -= 1

    if player.has_method("heal"):
        player.call("heal", 50)

    _refresh()
    _message("Potion used. Restored up to 50 HP.")


func _respawn_player() -> void:
    if not is_instance_valid(player):
        return

    if player.has_method("revive"):
        player.call("revive", PLAYER_START)

    dead = false

    if is_instance_valid(respawn_button):
        respawn_button.visible = false

    _refresh()
    _message("You have returned to Hearthvale.")


func _on_player_died() -> void:
    dead = true
    _message("You have fallen! Press Respawn to return to Hearthvale.")

    if is_instance_valid(respawn_button):
        respawn_button.visible = true

    _refresh()


func _on_player_revived() -> void:
    dead = false

    if is_instance_valid(respawn_button):
        respawn_button.visible = false

    _refresh()


func _on_player_health_changed(
    current_hp: int,
    maximum_hp: int
) -> void:
    if is_instance_valid(health_label):
        health_label.text = "HP: %d / %d" % [
            current_hp,
            maximum_hp
        ]


# ==================================================
# HUD
# Main HUD owns the action buttons.
# Player.gd owns the joystick.
# ==================================================

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "GameHUD"
    add_child(layer)

    var root := Control.new()
    root.name = "HUDRoot"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)

    var top_panel := PanelContainer.new()
    top_panel.position = Vector2(12.0, 12.0)
    top_panel.size = Vector2(220.0, 110.0)
    top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(top_panel)

    var top_column := VBoxContainer.new()
    top_panel.add_child(top_column)

    health_label = Label.new()
    health_label.text = "HP: 100 / 100"
    top_column.add_child(health_label)

    level_label = Label.new()
    level_label.text = "Level 1 | XP 0/100"
    top_column.add_child(level_label)

    currency_label = Label.new()
    currency_label.text = "Silver: 0 | Gold: 0"
    top_column.add_child(currency_label)

    class_label = Label.new()
    class_label.text = "Class: Warrior"
    top_column.add_child(class_label)

    var quest_panel := PanelContainer.new()
    quest_panel.position = Vector2(12.0, 132.0)
    quest_panel.size = Vector2(280.0, 86.0)
    quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(quest_panel)

    quest_label = Label.new()
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quest_panel.add_child(quest_label)

    message_label = Label.new()
    message_label.position = Vector2(300.0, 24.0)
    message_label.size = Vector2(520.0, 60.0)
    message_label.add_theme_font_size_override("font_size", 22)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(message_label)

    class_buttons = HBoxContainer.new()
    class_buttons.position = Vector2(250.0, 100.0)
    class_buttons.size = Vector2(440.0, 42.0)
    root.add_child(class_buttons)

    for class_name in ["Warrior", "Mage", "Rogue", "Druid", "Ranger"]:
        var class_button := Button.new()
        class_button.text = class_name
        class_button.custom_minimum_size = Vector2(82.0, 38.0)
        class_button.pressed.connect(
            _select_class.bind(class_name)
        )
        class_buttons.add_child(class_button)

    attack_button = Button.new()
    attack_button.text = "ATTACK"
    attack_button.size = Vector2(100.0, 66.0)
    attack_button.set_anchors_and_offsets_preset(
        Control.PRESET_BOTTOM_RIGHT
    )
    attack_button.position = Vector2(-115.0, -100.0)
    attack_button.pressed.connect(_attack)
    root.add_child(attack_button)

    interact_button = Button.new()
    interact_button.text = "INTERACT"
    interact_button.size = Vector2(100.0, 52.0)
    interact_button.set_anchors_and_offsets_preset(
        Control.PRESET_BOTTOM_RIGHT
    )
    interact_button.position = Vector2(-225.0, -88.0)
    interact_button.pressed.connect(_interact)
    root.add_child(interact_button)

    potion_button = Button.new()
    potion_button.text = "POTION"
    potion_button.size = Vector2(90.0, 52.0)
    potion_button.set_anchors_and_offsets_preset(
        Control.PRESET_BOTTOM_RIGHT
    )
    potion_button.position = Vector2(-115.0, -170.0)
    potion_button.pressed.connect(_use_potion)
    root.add_child(potion_button)

    respawn_button = Button.new()
    respawn_button.text = "RESPAWN"
    respawn_button.size = Vector2(130.0, 56.0)
    respawn_button.set_anchors_and_offsets_preset(
        Control.PRESET_CENTER
    )
    respawn_button.pressed.connect(_respawn_player)
    respawn_button.visible = false
    root.add_child(respawn_button)


func _select_class(new_class: String) -> void:
    hero_class = new_class

    if is_instance_valid(player) and player.has_method("set_hero_class"):
        player.call("set_hero_class", hero_class)

    _refresh()
    _message("Hero class changed to %s." % hero_class)


func _refresh() -> void:
    if is_instance_valid(player):
        health_label.text = "HP: %d / %d" % [
            int(player.get("current_health")),
            int(player.get("max_health"))
        ]

    if is_instance_valid(level_label):
        level_label.text = "Level %d | XP %d/%d" % [
            level,
            xp,
            xp_to_next_level
        ]

    if is_instance_valid(currency_label):
        currency_label.text = "Silver: %d | Gold: %d | Potions: %d" % [
            silver,
            chore_gold,
            potions
        ]

    if is_instance_valid(class_label):
        class_label.text = "Class: %s" % hero_class

    if is_instance_valid(quest_label):
        quest_label.text = _get_quest_text()


func _get_quest_text() -> String:
    match quest_stage:
        0:
            return "Quest: Find the Elder in Hearthvale."
        1:
            return "Quest: Defeat village monsters (%d/%d)." % [
                mini(enemies_defeated, MOBS_REQUIRED),
                MOBS_REQUIRED
            ]
        2:
            return "Quest: Return to the Elder."
        3:
            return "Quest: Collect herbs (%d/3)." % mini(herbs_collected, 3)
        4:
            return "Quest: Return to the Elder."
        5:
            return "Quest: Defeat forest enemies (%d/%d)." % [
                mini(path_enemies_defeated, PATH_MOBS_REQUIRED),
                PATH_MOBS_REQUIRED
            ]
        _:
            return "Hearthvale: Current quests completed!"


func _message(text: String) -> void:
    if not is_instance_valid(message_label):
        return

    message_label.text = text
    message_timer = 4.0
