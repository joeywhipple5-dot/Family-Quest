
extends Node3D

# ============================================================
# FAMILY QUEST - GODOT 4.3
# SELF-CONTAINED MAIN GAME SCRIPT
# Android touch controls + keyboard controls
# ============================================================

const WORLD_SIZE := 100.0
const PLAYER_SPEED := 7.0
const PLAYER_MAX_HP := 150
const ATTACK_RANGE := 3.5

var player: CharacterBody3D
var camera: Camera3D
var world_environment: WorldEnvironment

var hero_class: String = "Warrior"
var hero_hp: int = PLAYER_MAX_HP
var hero_mana: int = 100
var hero_level: int = 1
var hero_xp: int = 0
var silver: int = 0
var chore_gold: int = 0
var potions: int = 3

var quest_stage: int = 0
var enemies_defeated: int = 0
var resources_collected: int = 0
var dead: bool = false
var attack_cooldown: float = 0.0
var message_timer: float = 0.0

var move_forward_pressed: bool = false
var move_back_pressed: bool = false
var move_left_pressed: bool = false
var move_right_pressed: bool = false

var enemies: Array[Node3D] = []
var objectives: Array[Node3D] = []
var npcs: Array[Node3D] = []

var hud_layer: CanvasLayer
var status_label: Label
var health_label: Label
var xp_label: Label
var quest_label: Label
var message_label: Label
var class_label: Label
var gold_label: Label

var touch_controls: Control
var attack_button: Button
var interact_button: Button

var material_grass: StandardMaterial3D
var material_stone: StandardMaterial3D
var material_wood: StandardMaterial3D
var material_roof: StandardMaterial3D
var material_player: StandardMaterial3D
var material_enemy: StandardMaterial3D
var material_gold: StandardMaterial3D
var material_water: StandardMaterial3D


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
    _show_message("Welcome to Hearthvale! Speak to the village elder.")


func _physics_process(delta: float) -> void:
    if attack_cooldown > 0.0:
        attack_cooldown -= delta

    if message_timer > 0.0:
        message_timer -= delta
        if message_timer <= 0.0 and is_instance_valid(message_label):
            message_label.text = ""

    if not is_instance_valid(player):
        return

    if dead:
        player.velocity = Vector3.ZERO
        return

    _move_player(delta)
    _check_nearby_objects()


# ============================================================
# MATERIALS AND ENVIRONMENT
# ============================================================

func _create_materials() -> void:
    material_grass = _make_material(Color(0.20, 0.39, 0.18))
    material_stone = _make_material(Color(0.42, 0.43, 0.46))
    material_wood = _make_material(Color(0.34, 0.19, 0.09))
    material_roof = _make_material(Color(0.38, 0.12, 0.10))
    material_player = _make_material(Color(0.16, 0.35, 0.80))
    material_enemy = _make_material(Color(0.68, 0.16, 0.13))
    material_gold = _make_material(Color(0.95, 0.68, 0.10))
    material_water = _make_material(Color(0.12, 0.42, 0.65))


func _make_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.85
    return material


func _create_environment() -> void:
    world_environment = WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    environment.sky = Sky.new()
    environment.sky.sky_material = ProceduralSkyMaterial.new()
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.78, 0.90)
    environment.ambient_light_energy = 0.8
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)

    var sunlight := DirectionalLight3D.new()
    sunlight.name = "Sunlight"
    sunlight.rotation_degrees = Vector3(-48.0, -30.0, 0.0)
    sunlight.light_energy = 1.2
    sunlight.shadow_enabled = true
    add_child(sunlight)


# ============================================================
# WORLD BUILDING
# ============================================================

func _create_world() -> void:
    _make_box(
        self,
        "GrassGround",
        Vector3(WORLD_SIZE, 1.0, WORLD_SIZE),
        Vector3(0.0, -0.5, 0.0),
        material_grass,
        true
    )

    # Main stone road through Hearthvale.
    _make_box(
        self,
        "VillageRoad",
        Vector3(7.0, 0.08, 58.0),
        Vector3(0.0, 0.03, -8.0),
        material_stone,
        false
    )

    # Forest path.
    _make_box(
        self,
        "ForestPath",
        Vector3(5.0, 0.09, 35.0),
        Vector3(0.0, 0.04, -39.0),
        material_stone,
        false
    )

    # World boundaries.
    _make_box(self, "BoundaryNorth",
        Vector3(WORLD_SIZE, 5.0, 1.0),
        Vector3(0.0, 2.0, -WORLD_SIZE / 2.0),
        material_stone, true)

    _make_box(self, "BoundarySouth",
        Vector3(WORLD_SIZE, 5.0, 1.0),
        Vector3(0.0, 2.0, WORLD_SIZE / 2.0),
        material_stone, true)

    _make_box(self, "BoundaryEast",
        Vector3(1.0, 5.0, WORLD_SIZE),
        Vector3(WORLD_SIZE / 2.0, 2.0, 0.0),
        material_stone, true)

    _make_box(self, "BoundaryWest",
        Vector3(1.0, 5.0, WORLD_SIZE),
        Vector3(-WORLD_SIZE / 2.0, 2.0, 0.0),
        material_stone, true)

    # Decorative trees around the forest.
    for i in range(28):
        var tree_x := randf_range(-23.0, 23.0)
        var tree_z := randf_range(-48.0, -24.0)

        if absf(tree_x) < 4.5:
            tree_x = 6.0 if tree_x >= 0.0 else -6.0

        _create_tree(Vector3(tree_x, 0.0, tree_z))


func _make_box(
    parent: Node3D,
    object_name: String,
    box_size: Vector3,
    object_position: Vector3,
    material: Material,
    with_collision: bool
) -> Node3D:
    var holder: Node3D

    if with_collision:
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
        var visual_holder := Node3D.new()
        visual_holder.name = object_name
        parent.add_child(visual_holder)
        holder = visual_holder

    var mesh_instance := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = box_size
    mesh_instance.mesh = box_mesh
    mesh_instance.material_override = material
    holder.add_child(mesh_instance)

    holder.position = object_position
    return holder


func _create_tree(tree_position: Vector3) -> void:
    var tree := Node3D.new()
    tree.name = "ForestTree"
    add_child(tree)
    tree.position = tree_position

    var trunk := MeshInstance3D.new()
    var trunk_mesh := CylinderMesh.new()
    trunk_mesh.top_radius = 0.22
    trunk_mesh.bottom_radius = 0.35
    trunk_mesh.height = 2.2
    trunk.mesh = trunk_mesh
    trunk.material_override = material_wood
    trunk.position.y = 1.1
    tree.add_child(trunk)

    var leaves := MeshInstance3D.new()
    var leaves_mesh := SphereMesh.new()
    leaves_mesh.radius = 1.35
    leaves_mesh.height = 2.5
    leaves.mesh = leaves_mesh
    leaves.material_override = _make_material(
        Color(0.10, randf_range(0.27, 0.40), 0.12)
    )
    leaves.position.y = 2.8
    tree.add_child(leaves)


func _create_building(
    building_name: String,
    building_position: Vector3,
    building_size: Vector3
) -> void:
    var building := Node3D.new()
    building.name = building_name
    add_child(building)
    building.position = building_position

    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = building_size
    body.mesh = body_mesh
    body.material_override = material_wood
    body.position.y = building_size.y / 2.0
    building.add_child(body)

    var roof := MeshInstance3D.new()
    var roof_mesh := PrismMesh.new()
    roof_mesh.size = Vector3(
        building_size.x + 1.0,
        2.0,
        building_size.z + 1.0
    )
    roof.mesh = roof_mesh
    roof.material_override = material_roof
    roof.position.y = building_size.y + 0.8
    building.add_child(roof)

    # Solid collision around the outside of the building.
    var collision_body := StaticBody3D.new()
    collision_body.name = "BuildingCollision"
    building.add_child(collision_body)

    var collision := CollisionShape3D.new()
    var collision_shape := BoxShape3D.new()
    collision_shape.size = building_size
    collision.shape = collision_shape
    collision.position.y = building_size.y / 2.0
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

    # Castle walls and towers.
    _make_box(self, "CastleWallBack",
        Vector3(24.0, 5.0, 1.0),
        Vector3(0.0, 2.5, -19.0),
        material_stone, true)

    _make_box(self, "CastleWallLeft",
        Vector3(1.0, 5.0, 13.0),
        Vector3(-12.0, 2.5, -13.0),
        material_stone, true)

    _make_box(self, "CastleWallRight",
        Vector3(1.0, 5.0, 13.0),
        Vector3(12.0, 2.5, -13.0),
        material_stone, true)

    _create_tower(Vector3(-12.0, 0.0, -19.0))
    _create_tower(Vector3(12.0, 0.0, -19.0))

    # Small campfire in the village square.
    _make_box(
        self,
        "CampfireStoneBase",
        Vector3(2.0, 0.35, 2.0),
        Vector3(0.0, 0.18, 2.0),
        material_stone,
        false
    )

    var fire := MeshInstance3D.new()
    var fire_mesh := SphereMesh.new()
    fire_mesh.radius = 0.55
    fire_mesh.height = 1.1
    fire.mesh = fire_mesh
    fire.material_override = _make_material(Color(1.0, 0.35, 0.04))
    fire.position = Vector3(0.0, 0.85, 2.0)
    add_child(fire)


func _create_tower(tower_position: Vector3) -> void:
    var tower := MeshInstance3D.new()
    var tower_mesh := CylinderMesh.new()
    tower_mesh.top_radius = 1.7
    tower_mesh.bottom_radius = 2.1
    tower_mesh.height = 8.0
    tower.mesh = tower_mesh
    tower.material_override = material_stone
    tower.position = tower_position + Vector3(0.0, 4.0, 0.0)
    add_child(tower)


# ============================================================
# PLAYER AND CAMERA
# ============================================================

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0.0, 1.2, 12.0)
    add_child(player)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.45
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)

    var body_mesh := MeshInstance3D.new()
    var body_shape := CapsuleMesh.new()
    body_shape.radius = 0.43
    body_shape.height = 1.8
    body_mesh.mesh = body_shape
    body_mesh.material_override = material_player
    body_mesh.position.y = 0.9
    body_mesh.name = "HeroBody"
    player.add_child(body_mesh)

    # Simple helmet.
    var helmet := MeshInstance3D.new()
    var helmet_mesh := SphereMesh.new()
    helmet_mesh.radius = 0.32
    helmet_mesh.height = 0.55
    helmet.mesh = helmet_mesh
    helmet.material_override = material_gold
    helmet.position.y = 1.72
    player.add_child(helmet)

    _ensure_camera()


func _ensure_camera() -> void:
    if not is_instance_valid(player):
        push_error("Family Quest: Player was not created.")
        return

    camera = Camera3D.new()
    camera.name = "GameCamera"
    camera.position = Vector3(0.0, 7.0, 12.0)
    camera.fov = 70.0
    camera.near = 0.1
    camera.far = 250.0
    player.add_child(camera)

    # Camera position is local to the player.
    camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
    camera.current = true


func _move_player(_delta: float) -> void:
    var direction := Vector3.ZERO

    if Input.is_key_pressed(KEY_W) or move_forward_pressed:
        direction.z -= 1.0

    if Input.is_key_pressed(KEY_S) or move_back_pressed:
        direction.z += 1.0

    if Input.is_key_pressed(KEY_A) or move_left_pressed:
        direction.x -= 1.0

    if Input.is_key_pressed(KEY_D) or move_right_pressed:
        direction.x += 1.0

    direction = direction.normalized()

    player.velocity.x = direction.x * PLAYER_SPEED
    player.velocity.z = direction.z * PLAYER_SPEED

    if not player.is_on_floor():
        player.velocity.y -= 22.0 * _delta
    else:
        player.velocity.y = 0.0

    player.move_and_slide()

    if direction.length() > 0.1:
        player.rotation.y = atan2(direction.x, direction.z)


# ============================================================
# NPCS AND INTERACTION OBJECTS
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
    body_mesh.radius = 0.42
    body_mesh.height = 1.7
    body.mesh = body_mesh
    body.material_override = _make_material(npc_color)
    body.position.y = 0.85
    npc.add_child(body)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.28
    head_mesh.height = 0.5
    head.mesh = head_mesh
    head.material_override = _make_material(Color(0.85, 0.67, 0.52))
    head.position.y = 1.8
    npc.add_child(head)

    npcs.append(npc)


func _create_objectives() -> void:
    _create_objective(
        "Gathering Herb",
        Vector3(-4.0, 0.0, -28.0),
        "herb"
    )

    _create_objective(
        "Gathering Herb",
        Vector3(4.0, 0.0, -32.0),
        "herb"
    )

    _create_objective(
        "Gathering Herb",
        Vector3(-7.0, 0.0, -36.0),
        "herb"
    )

    _create_objective(
        "Supply Crate",
        Vector3(7.0, 0.0, -30.0),
        "crate"
    )

    _create_objective(
        "Supply Crate",
        Vector3(-8.0, 0.0, -41.0),
        "crate"
    )


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

    if objective_type == "herb":
        var herb_mesh := MeshInstance3D.new()
        var herb_shape := SphereMesh.new()
        herb_shape.radius = 0.38
        herb_shape.height = 0.75
        herb_mesh.mesh = herb_shape
        herb_mesh.material_override = _make_material(
            Color(0.25, 0.85, 0.30)
        )
        herb_mesh.position.y = 0.45
        objective.add_child(herb_mesh)
    else:
        var crate_mesh := MeshInstance3D.new()
        var crate_shape := BoxMesh.new()
        crate_shape.size = Vector3(1.0, 0.9, 1.0)
        crate_mesh.mesh = crate_shape
        crate_mesh.material_override = material_wood
        crate_mesh.position.y = 0.45
        objective.add_child(crate_mesh)

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

    var enemy_mesh := MeshInstance3D.new()

    if enemy_name == "Forest Slime":
        var slime_shape := SphereMesh.new()
        slime_shape.radius = 0.65
        slime_shape.height = 1.0
        enemy_mesh.mesh = slime_shape
    else:
        var goblin_shape := CapsuleMesh.new()
        goblin_shape.radius = 0.48
        goblin_shape.height = 1.5
        enemy_mesh.mesh = goblin_shape

    enemy_mesh.material_override = material_enemy
    enemy_mesh.position.y = 0.65
    enemy.add_child(enemy_mesh)

    var marker := MeshInstance3D.new()
    var marker_shape := SphereMesh.new()
    marker_shape.radius = 0.15
    marker_shape.height = 0.3
    marker.mesh = marker_shape
    marker.material_override = material_gold
    marker.position.y = 1.65
    enemy.add_child(marker)

    enemies.append(enemy)


# ============================================================
# COMBAT
# ============================================================

func _perform_attack() -> void:
    if dead or attack_cooldown > 0.0:
        return

    attack_cooldown = 0.65

    var closest_enemy: Node3D = null
    var closest_distance := ATTACK_RANGE + 0.1

    for enemy in enemies:
        if not is_instance_valid(enemy):
            continue

        if bool(enemy.get_meta("dead", false)):
            continue

        var distance := player.global_position.distance_to(
            enemy.global_position
        )

        if distance < closest_distance:
            closest_distance = distance
            closest_enemy = enemy

    if closest_enemy == null:
        _show_message("No enemy in range.")
        return

    var damage := 25

    match hero_class:
        "Warrior":
            damage = 35
        "Mage":
            damage = 30
        "Rogue":
            damage = 32
        "Druid":
            damage = 27
        "Ranger":
            damage = 30

    var remaining_hp := int(closest_enemy.get_meta("hp", 1))
    remaining_hp -= damage
    closest_enemy.set_meta("hp", remaining_hp)

    if remaining_hp <= 0:
        _defeat_enemy(closest_enemy)
    else:
        _show_message(
            "%s hit for %d damage! Enemy HP: %d"
            % [
                str(closest_enemy.get_meta("enemy_name", "Enemy")),
                damage,
                remaining_hp
            ]
        )

    _refresh_hud()


func _defeat_enemy(enemy: Node3D) -> void:
    enemy.set_meta("dead", true)
    enemies_defeated += 1
    hero_xp += 25
    silver += 5

    enemy.queue_free()

    if hero_xp >= hero_level * 100:
        hero_xp -= hero_level * 100
        hero_level += 1
        hero_hp = PLAYER_MAX_HP
        hero_mana = 100
        _show_message(
            "Level up! You are now level %d." % hero_level
        )
    else:
        _show_message("Enemy defeated! +25 XP and 5 Silver.")

    _refresh_hud()


func _take_damage(amount: int) -> void:
    if dead:
        return

    hero_hp = maxi(0, hero_hp - amount)

    if hero_hp <= 0:
        dead = true
        _show_message("You have been defeated. Tap Respawn.")
        _show_respawn_button()

    _refresh_hud()


func _respawn() -> void:
    dead = false
    hero_hp = PLAYER_MAX_HP
    hero_mana = 100
    player.global_position = Vector3(0.0, 1.2, 12.0)
    player.velocity = Vector3.ZERO
    _show_message("You have returned to Hearthvale.")
    _refresh_hud()


# ============================================================
# QUESTS AND INTERACTIONS
# ============================================================

func _interact() -> void:
    if dead:
        return

    var nearest_npc: Node3D = null
    var nearest_npc_distance := 4.0

    for npc in npcs:
        if not is_instance_valid(npc):
            continue

        var distance := player.global_position.distance_to(
            npc.global_position
        )

        if distance < nearest_npc_distance:
            nearest_npc = npc
            nearest_npc_distance = distance

    if nearest_npc != null:
        _talk_to_npc(nearest_npc)
        return

    var nearest_objective: Node3D = null
    var nearest_objective_distance := 3.0

    for objective in objectives:
        if not is_instance_valid(objective):
            continue

        if bool(objective.get_meta("collected", false)):
            continue

        var distance := player.global_position.distance_to(
            objective.global_position
        )

        if distance < nearest_objective_distance:
            nearest_objective = objective
            nearest_objective_distance = distance

    if nearest_objective != null:
        _collect_objective(nearest_objective)
        return

    _show_message("Move closer to a person or an objective.")


func _talk_to_npc(npc: Node3D) -> void:
    var role := str(npc.get_meta("role", ""))

    if role == "elder":
        _advance_quest()
    elif role == "blacksmith":
        if silver >= 10:
            silver -= 10
            hero_hp = mini(PLAYER_MAX_HP, hero_hp + 40)
            _show_message("The blacksmith repaired your armor. -10 Silver.")
        else:
            _show_message("Blacksmith: Bring me 10 Silver for repairs.")
    elif role == "merchant":
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
            _show_message(
                "Quest 1: Defeat 3 forest enemies. Return to the elder."
            )
        1:
            if enemies_defeated >= 3:
                quest_stage = 2
                chore_gold += 10
                silver += 15
                hero_xp += 50
                _show_message(
                    "Quest complete! Earned 10 Gold, 15 Silver, and 50 XP."
                )
            else:
                _show_message(
                    "Elder: Defeat 3 forest enemies first. (%d/3)"
                    % mini(enemies_defeated, 3)
                )
        2:
            quest_stage = 3
            _show_message(
                "Quest 2: Gather 3 herbs from the forest."
            )
        3:
            if resources_collected >= 3:
                quest_stage = 4
                chore_gold += 10
                silver += 15
                hero_xp += 50
                _show_message(
                    "Quest complete! Gathered supplies for Hearthvale."
                )
            else:
                _show_message(
                    "Elder: Gather 3 herbs. (%d/3)"
                    % mini(resources_collected, 3)
                )
        4:
            quest_stage = 5
            _show_message(
                "Quest 3: Collect 2 supply crates in the forest."
            )
        5:
            if _count_collected_crates() >= 2:
                quest_stage = 6
                chore_gold += 15
                silver += 20
                hero_xp += 75
                _show_message(
                    "Quest complete! Hearthvale's supplies are restored."
                )
            else:
                _show_message(
                    "Elder: Find the 2 supply crates in the forest."
                )
        6:
            quest_stage = 7
            _show_message(
                "Quest 4: Defeat every remaining forest enemy."
            )
        7:
            if _all_enemies_defeated():
                quest_stage = 8
                chore_gold += 20
                silver += 30
                hero_xp += 100
                _show_message(
                    "Quest complete! The forest is safe for now."
                )
            else:
                _show_message(
                    "Elder: Finish clearing the forest of enemies."
                )
        8:
            quest_stage = 9
            _show_message(
                "Quest 5: Return to the forest and explore its far path."
            )
        9:
            if player.global_position.z < -45.0:
                quest_stage = 10
                chore_gold += 25
                silver += 40
                hero_xp += 150
                _show_message(
                    "Hearthvale chapter complete! You are a hero of the village."
                )
            else:
                _show_message(
                    "Elder: Follow the road deeper into the forest."
                )
        _:
            _show_message(
                "Elder: Thank you for protecting Hearthvale, hero!"
            )

    _refresh_hud()


func _collect_objective(objective: Node3D) -> void:
    if bool(objective.get_meta("collected", false)):
        return

    objective.set_meta("collected", true)

    var objective_type := str(
        objective.get_meta("objective_type", "")
    )

    if objective_type == "herb":
        resources_collected += 1
        hero_xp += 5
        _show_message(
            "Herb collected! Herbs: %d/3"
            % mini(resources_collected, 3)
        )
    elif objective_type == "crate":
        _show_message("Supply crate collected!")
        objective.set_meta("crate_collected", true)

    objective.queue_free()
    _refresh_hud()


func _count_collected_crates() -> int:
    var count := 0

    for objective in objectives:
        if not is_instance_valid(objective):
            continue

        if str(objective.get_meta("objective_type", "")) == "crate":
            if bool(objective.get_meta("collected", false)):
                count += 1

    return count


func _all_enemies_defeated() -> bool:
    for enemy in enemies:
        if is_instance_valid(enemy):
            if not bool(enemy.get_meta("dead", false)):
                return false

    return true


func _check_nearby_objects() -> void:
    # Keep this function lightweight for mobile performance.
    pass


# ============================================================
# CLASS SELECTION AND ABILITIES
# ============================================================

func _select_class(selected_class_name: String) -> void:
    hero_class = selected_class_name

    var class_colors := {
        "Warrior": Color(0.16, 0.35, 0.80),
        "Mage": Color(0.50, 0.20, 0.80),
        "Rogue": Color(0.22, 0.22, 0.25),
        "Druid": Color(0.18, 0.60, 0.25),
        "Ranger": Color(0.72, 0.48, 0.16)
    }

    if is_instance_valid(player):
        var body := player.get_node_or_null("HeroBody") as MeshInstance3D
        if body != null:
            body.material_override = _make_material(
                class_colors.get(selected_class_name, Color.BLUE)
            )

    var abilities := {
        "Warrior": "Titan Smash",
        "Mage": "Starfall",
        "Rogue": "Phantom Flurry",
        "Druid": "Worldroot Surge",
        "Ranger": "Heavenpiercer"
    }

    _show_message(
        "%s selected! Signature ability: %s."
        % [
            selected_class_name,
            str(abilities.get(selected_class_name, "Special Attack"))
        ]
    )

    _refresh_hud()


func _use_potion() -> void:
    if dead:
        return

    if potions <= 0:
        _show_message("You have no potions.")
        return

    if hero_hp >= PLAYER_MAX_HP:
        _show_message("Your health is already full.")
        return

    potions -= 1
    hero_hp = mini(PLAYER_MAX_HP, hero_hp + 50)
    hero_mana = mini(100, hero_mana + 20)

    _show_message("Potion used. Health restored.")
    _refresh_hud()


# ============================================================
# HUD AND ANDROID TOUCH CONTROLS
# ============================================================

func _create_hud() -> void:
    hud_layer = CanvasLayer.new()
    hud_layer.name = "GameHUD"
    add_child(hud_layer)

    var root := Control.new()
    root.name = "HUDRoot"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud_layer.add_child(root)

    # Top-left status panel.
    var panel := PanelContainer.new()
    panel.position = Vector2(12.0, 12.0)
    panel.custom_minimum_size = Vector2(280.0, 135.0)
    root.add_child(panel)

    var panel_column := VBoxContainer.new()
    panel.add_child(panel_column)

    status_label = Label.new()
    status_label.text = "FAMILY QUEST"
    panel_column.add_child(status_label)

    health_label = Label.new()
    panel_column.add_child(health_label)

    xp_label = Label.new()
    panel_column.add_child(xp_label)

    gold_label = Label.new()
    panel_column.add_child(gold_label)

    class_label = Label.new()
    panel_column.add_child(class_label)

    # Quest panel.
    var quest_panel := PanelContainer.new()
    quest_panel.position = Vector2(12.0, 160.0)
    quest_panel.custom_minimum_size = Vector2(280.0, 82.0)
    root.add_child(quest_panel)

    quest_label = Label.new()
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    quest_panel.add_child(quest_label)

    # Message at the bottom.
    message_label = Label.new()
    message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
    message_label.position.y -= 90.0
    message_label.custom_minimum_size = Vector2(500.0, 40.0)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(message_label)

    # Class selection along the top-right.
    var class_panel := PanelContainer.new()
    class_panel.anchor_left = 1.0
    class_panel.anchor_right = 1.0
    class_panel.offset_left = -390.0
    class_panel.offset_right = -12.0
    class_panel.offset_top = 12.0
    class_panel.offset_bottom = 75.0
    root.add_child(class_panel)

    var class_row := HBoxContainer.new()
    class_panel.add_child(class_row)

    for selected_class_name in [
        "Warrior",
        "Mage",
        "Rogue",
        "Druid",
        "Ranger"
    ]:
        var class_button := Button.new()
        class_button.text = selected_class_name
        class_button.custom_minimum_size = Vector2(68.0, 44.0)
        class_button.pressed.connect(
            _select_class.bind(selected_class_name)
        )
        class_row.add_child(class_button)

    # Android movement controls.
    touch_controls = Control.new()
    touch_controls.name = "TouchControls"
    touch_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(touch_controls)

    _make_hold_button(
        touch_controls, "▲", Vector2(95.0, -155.0),
        "forward"
    )

    _make_hold_button(
        touch_controls, "▼", Vector2(95.0, -65.0),
        "back"
    )

    _make_hold_button(
        touch_controls, "◀", Vector2(15.0, -110.0),
        "left"
    )

    _make_hold_button(
        touch_controls, "▶", Vector2(175.0, -110.0),
        "right"
    )

    # Attack and interaction buttons on the right.
    attack_button = _make_action_button(
        touch_controls,
        "ATTACK",
        Vector2(-170.0, -115.0),
        Vector2(145.0, 72.0)
    )
    attack_button.pressed.connect(_perform_attack)

    interact_button = _make_action_button(
        touch_controls,
        "INTERACT",
        Vector2(-170.0, -35.0),
        Vector2(145.0, 60.0)
    )
    interact_button.pressed.connect(_interact)

    var potion_button := _make_action_button(
        touch_controls,
        "POTION",
        Vector2(-320.0, -35.0),
        Vector2(125.0, 60.0)
    )
    potion_button.pressed.connect(_use_potion)

    var respawn_button := _make_action_button(
        touch_controls,
        "RESPAWN",
        Vector2(-320.0, -105.0),
        Vector2(125.0, 60.0)
    )
    respawn_button.pressed.connect(_respawn)

    _refresh_hud()


func _make_hold_button(
    parent: Control,
    button_text: String,
    button_offset: Vector2,
    direction_name: String
) -> void:
    var button := Button.new()
    button.text = button_text
    button.custom_minimum_size = Vector2(70.0, 70.0)
    button.anchor_left = 0.0
    button.anchor_right = 0.0
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.offset_left = button_offset.x
    button.offset_right = button_offset.x + 70.0
    button.offset_top = button_offset.y
    button.offset_bottom = button_offset.y + 70.0
    parent.add_child(button)

    match direction_name:
        "forward":
            button.button_down.connect(
                func(): move_forward_pressed = true
            )
            button.button_up.connect(
                func(): move_forward_pressed = false
            )
        "back":
            button.button_down.connect(
                func(): move_back_pressed = true
            )
            button.button_up.connect(
                func(): move_back_pressed = false
            )
        "left":
            button.button_down.connect(
                func(): move_left_pressed = true
            )
            button.button_up.connect(
                func(): move_left_pressed = false
            )
        "right":
            button.button_down.connect(
                func(): move_right_pressed = true
            )
            button.button_up.connect(
                func(): move_right_pressed = false
            )


func _make_action_button(
    parent: Control,
    button_text: String,
    button_offset: Vector2,
    button_size: Vector2
) -> Button:
    var button := Button.new()
    button.text = button_text
    button.custom_minimum_size = button_size
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.offset_left = button_offset.x
    button.offset_right = button_offset.x + button_size.x
    button.offset_top = button_offset.y
    button.offset_bottom = button_offset.y + button_size.y
    parent.add_child(button)
    return button


func _show_respawn_button() -> void:
    _show_message("You were defeated. Press RESPAWN to return.")


func _refresh_hud() -> void:
    if not is_instance_valid(hud_layer):
        return

    if is_instance_valid(health_label):
        health_label.text = "HP: %d / %d | Mana: %d" % [
            hero_hp,
            PLAYER_MAX_HP,
            hero_mana
        ]

    if is_instance_valid(xp_label):
        xp_label.text = "Level: %d | XP: %d" % [
            hero_level,
            hero_xp
        ]

    if is_instance_valid(gold_label):
        gold_label.text = "Gold: %d | Silver: %d | Potions: %d" % [
            chore_gold,
            silver,
            potions
        ]

    if is_instance_valid(class_label):
        class_label.text = "Class: " + hero_class

    if is_instance_valid(quest_label):
        quest_label.text = _get_quest_text()


func _get_quest_text() -> String:
    match quest_stage:
        0:
            return "QUEST: Talk to the Village Elder."
        1:
            return "QUEST 1: Defeat 3 enemies (%d/3)." % mini(enemies_defeated, 3)
        2:
            return "QUEST: Return to the elder."
        3:
            return "QUEST 2: Gather 3 herbs (%d/3)." % mini(resources_collected, 3)
        4:
            return "QUEST: Return to the elder."
        5:
            return "QUEST 3: Collect 2 supply crates (%d/2)." % _count_collected_crates()
        6:
            return "QUEST: Return to the elder."
        7:
            return "QUEST 4: Defeat the remaining enemies."
        8:
            return "QUEST: Return to the elder."
        9:
            return "QUEST 5: Explore the far forest path."
        _:
            return "HEARTHVALE: Chapter complete!"


func _show_message(message: String) -> void:
    if is_instance_valid(message_label):
        message_label.text = message
        message_timer = 5.0
    else:
        print(message)


# ============================================================
# KEYBOARD INPUT
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_SPACE:
                _perform_attack()
            KEY_E:
                _interact()
            KEY_H:
                _use_potion()
            KEY_ESCAPE:
                get_tree().quit()
