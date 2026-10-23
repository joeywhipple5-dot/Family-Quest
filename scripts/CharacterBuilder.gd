
extends Node3D
class_name CharacterBuilder

const PALETTES := {
    "Warrior": Color("#9D2428"),
    "Mage": Color("#2876D8"),
    "Rogue": Color("#49315D"),
    "Druid": Color("#347044"),
    "Ranger": Color("#7A8138")
}

const GOLD := Color("#EAC77A")
const STEEL := Color("#B9C8D8")
const DARK_STEEL := Color("#526579")
const LEATHER := Color("#62402D")
const SKIN_MALE := Color("#C99570")
const SKIN_FEMALE := Color("#E0B08D")


func build_character(hero_class_name: String, gender: String = "male") -> Node3D:
    var root := Node3D.new()
    root.name = "%s_%s" % [hero_class_name, gender.capitalize()]

    var cloth: Color = PALETTES.get(
        hero_class_name, Color("#6A8C9B")
    )
    var skin := SKIN_FEMALE if gender.to_lower() == "female" else SKIN_MALE
    var dark := cloth.darkened(0.35)
    var trim := GOLD

    var female := gender.to_lower() == "female"
    var torso_width := 0.35 if female else 0.40

    # BODY AND LIMBS
    root.add_child(_capsule(
        "Body", Vector3(0, 1.28, 0),
        torso_width, 0.82, cloth
    ))
    root.add_child(_sphere(
        "Head", Vector3(0, 2.02, 0),
        Vector3(0.27, 0.31, 0.26), skin
    ))

    root.add_child(_capsule(
        "LeftLeg", Vector3(-0.16, 0.48, 0),
        0.13, 0.66, dark
    ))
    root.add_child(_capsule(
        "RightLeg", Vector3(0.16, 0.48, 0),
        0.13, 0.66, dark
    ))

    # BOOTS
    root.add_child(_box(
        "LeftBoot", Vector3(-0.16, 0.15, 0.07),
        Vector3(0.25, 0.20, 0.36), LEATHER
    ))
    root.add_child(_box(
        "RightBoot", Vector3(0.16, 0.15, 0.07),
        Vector3(0.25, 0.20, 0.36), LEATHER
    ))

    # ARMS, GLOVES AND SHOULDERS
    root.add_child(_capsule(
        "LeftArm", Vector3(-0.45, 1.30, 0),
        0.12, 0.67, cloth.lightened(0.12)
    ))
    root.add_child(_capsule(
        "RightArm", Vector3(0.45, 1.30, 0),
        0.12, 0.67, cloth.lightened(0.12)
    ))
    root.add_child(_sphere(
        "LeftGlove", Vector3(-0.46, 0.99, 0.02),
        Vector3(0.14, 0.14, 0.14), LEATHER
    ))
    root.add_child(_sphere(
        "RightGlove", Vector3(0.46, 0.99, 0.02),
        Vector3(0.14, 0.14, 0.14), LEATHER
    ))
    root.add_child(_sphere(
        "LeftShoulder", Vector3(-0.42, 1.59, 0),
        Vector3(0.23, 0.18, 0.24), trim
    ))
    root.add_child(_sphere(
        "RightShoulder", Vector3(0.42, 1.59, 0),
        Vector3(0.23, 0.18, 0.24), trim
    ))

    # BELT AND CHEST DETAIL
    root.add_child(_box(
        "Belt", Vector3(0, 0.98, 0.03),
        Vector3(0.66, 0.13, 0.44), LEATHER
    ))
    root.add_child(_box(
        "BeltBuckle", Vector3(0, 0.99, 0.26),
        Vector3(0.13, 0.13, 0.035), GOLD
    ))
    root.add_child(_box(
        "ChestPanel", Vector3(0, 1.40, 0.28),
        Vector3(0.38, 0.38, 0.06), dark
    ))
    root.add_child(_box(
        "ChestTrim", Vector3(0, 1.48, 0.32),
        Vector3(0.30, 0.045, 0.025), trim
    ))

    # FACE AND HAIR
    var hair := Color("#49301F")
    if female:
        root.add_child(_capsule(
            "LongHair", Vector3(0, 1.91, -0.10),
            0.16, 0.53, hair
        ))
        root.add_child(_sphere(
            "HairTop", Vector3(0, 2.25, -0.015),
            Vector3(0.28, 0.13, 0.27), hair
        ))
    else:
        root.add_child(_sphere(
            "Hair", Vector3(0, 2.24, 0),
            Vector3(0.28, 0.12, 0.27), hair
        ))

    # CLASS-SPECIFIC EQUIPMENT
    match hero_class_name:
        "Warrior":
            _warrior_gear(root, cloth)
        "Mage":
            _mage_gear(root, cloth, dark)
        "Rogue":
            _rogue_gear(root, cloth, dark)
        "Druid":
            _druid_gear(root, cloth, dark)
        "Ranger":
            _ranger_gear(root, cloth, dark)

    return root


func _warrior_gear(root: Node3D, cloth: Color) -> void:
    root.add_child(_box(
        "SteelBreastplate", Vector3(0, 1.40, 0.33),
        Vector3(0.43, 0.44, 0.09), STEEL
    ))
    root.add_child(_box(
        "BreastplateCenter", Vector3(0, 1.42, 0.385),
        Vector3(0.09, 0.30, 0.025), GOLD
    ))
    root.add_child(_box(
        "LeftForearmArmor", Vector3(-0.49, 1.12, 0.09),
        Vector3(0.17, 0.24, 0.17), DARK_STEEL
    ))
    root.add_child(_box(
        "RightForearmArmor", Vector3(0.49, 1.12, 0.09),
        Vector3(0.17, 0.24, 0.17), DARK_STEEL
    ))
    root.add_child(_box(
        "Shield", Vector3(-0.66, 1.27, 0.22),
        Vector3(0.13, 0.55, 0.40), Color("#315B85")
    ))
    root.add_child(_box(
        "ShieldEmblem", Vector3(-0.735, 1.27, 0.22),
        Vector3(0.025, 0.22, 0.20), GOLD
    ))
    root.add_child(_box(
        "SwordBlade", Vector3(0.67, 1.36, 0.20),
        Vector3(0.07, 0.57, 0.07), STEEL
    ))
    root.add_child(_box(
        "SwordGuard", Vector3(0.67, 1.08, 0.20),
        Vector3(0.23, 0.06, 0.09), GOLD
    ))
    root.add_child(_box(
        "SwordHandle", Vector3(0.67, 1.00, 0.20),
        Vector3(0.065, 0.16, 0.065), LEATHER
    ))


func _mage_gear(root: Node3D, cloth: Color, dark: Color) -> void:
    root.add_child(_cone(
        "LayeredRobe", Vector3(0, 0.95, 0),
        0.43, 0.78, dark
    ))
    root.add_child(_box(
        "RobeTrim", Vector3(0, 0.62, 0.28),
        Vector3(0.36, 0.06, 0.035), GOLD
    ))
    root.add_child(_sphere(
        "MagicPendant", Vector3(0, 1.45, 0.34),
        Vector3(0.11, 0.14, 0.06), Color("#82D9FF")
    ))
    root.add_child(_rod(
        "Staff", Vector3(0.70, 1.25, 0),
        0.055, 1.75, LEATHER
    ))
    root.add_child(_sphere(
        "StaffCrystal", Vector3(0.70, 2.16, 0),
        Vector3(0.16, 0.19, 0.16), Color("#82D9FF")
    ))
    root.add_child(_sphere(
        "StaffSetting", Vector3(0.70, 2.16, 0),
        Vector3(0.22, 0.07, 0.22), GOLD
    ))
    root.add_child(_sphere(
        "MageShoulderGem", Vector3(-0.43, 1.61, 0.13),
        Vector3(0.13, 0.13, 0.13), Color("#82D9FF")
    ))


func _rogue_gear(root: Node3D, cloth: Color, dark: Color) -> void:
    root.add_child(_box(
        "LeatherVest", Vector3(0, 1.38, 0.34),
        Vector3(0.42, 0.43, 0.08), LEATHER
    ))
    root.add_child(_cape(
        "DarkHoodCape", Vector3(0, 1.38, -0.18),
        Vector3(0.46, 0.72, 0.10), dark
    ))
    root.add_child(_box(
        "ShoulderStrap", Vector3(0.08, 1.43, 0.40),
        Vector3(0.09, 0.44, 0.035), GOLD
    ))
    root.add_child(_box(
        "LeftDagger", Vector3(-0.59, 1.05, 0.12),
        Vector3(0.055, 0.42, 0.055), STEEL
    ))
    root.add_child(_box(
        "RightDagger", Vector3(0.59, 1.05, 0.12),
        Vector3(0.055, 0.42, 0.055), STEEL
    ))
    root.add_child(_box(
        "LeftDaggerGrip", Vector3(-0.59, 0.80, 0.12),
        Vector3(0.08, 0.12, 0.08), GOLD
    ))
    root.add_child(_box(
        "RightDaggerGrip", Vector3(0.59, 0.80, 0.12),
        Vector3(0.08, 0.12, 0.08), GOLD
    ))
    root.add_child(_box(
        "UtilityPouch", Vector3(0.28, 0.91, 0.27),
        Vector3(0.18, 0.20, 0.13), LEATHER
    ))


func _druid_gear(root: Node3D, cloth: Color, dark: Color) -> void:
    root.add_child(_cape(
        "LeafCloak", Vector3(0, 1.38, -0.17),
        Vector3(0.48, 0.72, 0.10), Color("#254E32")
    ))
    root.add_child(_sphere(
        "LeafShoulder", Vector3(-0.40, 1.65, 0.12),
        Vector3(0.25, 0.15, 0.20), Color("#76A84B")
    ))
    root.add_child(_sphere(
        "NaturePendant", Vector3(0, 1.43, 0.34),
        Vector3(0.12, 0.15, 0.07), Color("#A5E66B")
    ))
    root.add_child(_rod(
        "NatureStaff", Vector3(0.69, 1.24, 0),
        0.06, 1.65, LEATHER
    ))
    root.add_child(_sphere(
        "NatureGem", Vector3(0.69, 2.10, 0),
        Vector3(0.15, 0.18, 0.15), Color("#A5E66B")
    ))
    root.add_child(_sphere(
        "StaffLeaves", Vector3(0.55, 2.02, 0),
        Vector3(0.13, 0.08, 0.10), Color("#76A84B")
    ))
    root.add_child(_box(
        "VineBelt", Vector3(0, 0.98, 0.28),
        Vector3(0.42, 0.07, 0.05), Color("#76A84B")
    ))


func _ranger_gear(root: Node3D, cloth: Color, dark: Color) -> void:
    root.add_child(_cape(
        "ForestCloak", Vector3(0, 1.39, -0.18),
        Vector3(0.44, 0.70, 0.10), dark
    ))
    root.add_child(_box(
        "RangerChestArmor", Vector3(0, 1.39, 0.34),
        Vector3(0.43, 0.40, 0.08), Color("#526344")
    ))
    root.add_child(_box(
        "LeatherHarness", Vector3(0.06, 1.38, 0.40),
        Vector3(0.08, 0.43, 0.035), LEATHER
    ))
    root.add_child(_box(
        "Quiver", Vector3(-0.28, 1.57, -0.18),
        Vector3(0.16, 0.43, 0.15), LEATHER
    ))
    root.add_child(_box(
        "ArrowOne", Vector3(-0.32, 1.78, -0.13),
        Vector3(0.035, 0.48, 0.035), STEEL
    ))
    root.add_child(_box(
        "ArrowTwo", Vector3(-0.25, 1.78, -0.13),
        Vector3(0.035, 0.48, 0.035), GOLD
    ))
    root.add_child(_rod(
        "BowGrip", Vector3(0.68, 1.25, 0),
        0.045, 0.80, LEATHER
    ))
    root.add_child(_sphere(
        "RangerShoulderBadge", Vector3(0.41, 1.62, 0.12),
        Vector3(0.16, 0.12, 0.16), GOLD
    ))


func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.72
    return material


func _mesh_instance(
    node_name: String,
    mesh: Mesh,
    pos: Vector3,
    color: Color,
    scale_value: Vector3 = Vector3.ONE
) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = node_name
    item.mesh = mesh
    item.position = pos
    item.scale = scale_value
    item.material_override = _material(color)
    return item


func _capsule(
    node_name: String,
    pos: Vector3,
    radius: float,
    height: float,
    color: Color
) -> MeshInstance3D:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    return _mesh_instance(node_name, mesh, pos, color)


func _sphere(
    node_name: String,
    pos: Vector3,
    scale_value: Vector3,
    color: Color
) -> MeshInstance3D:
    return _mesh_instance(
        node_name, SphereMesh.new(), pos, color, scale_value
    )


func _box(
    node_name: String,
    pos: Vector3,
    size_value: Vector3,
    color: Color
) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size_value
    return _mesh_instance(node_name, mesh, pos, color)


func _rod(
    node_name: String,
    pos: Vector3,
    radius: float,
    height: float,
    color: Color
) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    return _mesh_instance(node_name, mesh, pos, color)


func _cone(
    node_name: String,
    pos: Vector3,
    radius: float,
    height: float,
    color: Color
) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.06
    mesh.bottom_radius = radius
    mesh.height = height
    return _mesh_instance(node_name, mesh, pos, color)


func _cape(
    node_name: String,
    pos: Vector3,
    size_value: Vector3,
    color: Color
) -> MeshInstance3D:
    return _box(node_name, pos, size_value, color)
