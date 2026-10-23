
extends Node3D
class_name CharacterBuilder

const PALETTES := {
    "Warrior": Color("#9D2428"),
    "Mage": Color("#2876D8"),
    "Rogue": Color("#49315D"),
    "Druid": Color("#347044"),
    "Ranger": Color("#7A8138")
}

const SKIN_MALE := Color("#C99570")
const SKIN_FEMALE := Color("#E0B08D")
const GOLD := Color("#D9B45B")
const STEEL := Color("#B8C5D3")
const DARK_STEEL := Color("#34465A")
const HAIR := Color("#49301F")


func build_character(hero_class_name: String, gender: String = "male") -> Node3D:
    var root := Node3D.new()
    root.name = "%s_%s" % [hero_class_name, gender.capitalize()]

    var is_female := gender.to_lower() == "female"
    var color: Color = PALETTES.get(
        hero_class_name, Color("#6A8C9B")
    )
    var skin: Color = SKIN_FEMALE if is_female else SKIN_MALE
    var dark := color.darkened(0.38)
    var light := color.lightened(0.22)
    var body_width := 0.36 if is_female else 0.40

    # --------------------------------------------------
    # BODY AND SILHOUETTE
    # Front of the hero faces negative Z.
    # --------------------------------------------------

    root.add_child(_capsule(
        "Torso", Vector3(0, 1.30, 0),
        body_width, 0.82, color
    ))

    root.add_child(_sphere(
        "Head", Vector3(0, 2.02, 0),
        Vector3(0.25, 0.30, 0.25), skin
    ))

    root.add_child(_capsule(
        "LeftLeg", Vector3(-0.15, 0.46, 0),
        0.12, 0.65, dark
    ))
    root.add_child(_capsule(
        "RightLeg", Vector3(0.15, 0.46, 0),
        0.12, 0.65, dark
    ))

    # Boots
    root.add_child(_box(
        "LeftBoot", Vector3(-0.15, 0.14, -0.055),
        Vector3(0.25, 0.20, 0.36), Color("#302A2A")
    ))
    root.add_child(_box(
        "RightBoot", Vector3(0.15, 0.14, -0.055),
        Vector3(0.25, 0.20, 0.36), Color("#302A2A")
    ))

    root.add_child(_capsule(
        "LeftArm", Vector3(-0.43, 1.31, 0),
        0.105, 0.62, color.lightened(0.10)
    ))
    root.add_child(_capsule(
        "RightArm", Vector3(0.43, 1.31, 0),
        0.105, 0.62, color.lightened(0.10)
    ))

    # Hands
    root.add_child(_sphere(
        "LeftHand", Vector3(-0.44, 0.99, -0.015),
        Vector3(0.11, 0.12, 0.11), skin
    ))
    root.add_child(_sphere(
        "RightHand", Vector3(0.44, 0.99, -0.015),
        Vector3(0.11, 0.12, 0.11), skin
    ))

    # Belt and central buckle
    root.add_child(_box(
        "Belt", Vector3(0, 0.98, -0.015),
        Vector3(0.43, 0.11, 0.30), Color("#493321")
    ))
    root.add_child(_box(
        "BeltBuckle", Vector3(0, 0.99, -0.18),
        Vector3(0.10, 0.10, 0.035), GOLD
    ))

    # Face details
    root.add_child(_sphere(
        "LeftEye", Vector3(-0.085, 2.05, -0.222),
        Vector3(0.045, 0.045, 0.025), Color("#F4EBDD")
    ))
    root.add_child(_sphere(
        "RightEye", Vector3(0.085, 2.05, -0.222),
        Vector3(0.045, 0.045, 0.025), Color("#F4EBDD")
    ))
    root.add_child(_sphere(
        "LeftPupil", Vector3(-0.085, 2.05, -0.246),
        Vector3(0.020, 0.025, 0.012), Color("#25232A")
    ))
    root.add_child(_sphere(
        "RightPupil", Vector3(0.085, 2.05, -0.246),
        Vector3(0.020, 0.025, 0.012), Color("#25232A")
    ))
    root.add_child(_sphere(
        "Nose", Vector3(0, 1.99, -0.245),
        Vector3(0.045, 0.065, 0.045), skin.darkened(0.08)
    ))

    # Hair and gender variation
    if is_female:
        root.add_child(_sphere(
            "HairCap", Vector3(0, 2.23, 0.015),
            Vector3(0.27, 0.13, 0.27), HAIR
        ))
        root.add_child(_capsule(
            "LongHair", Vector3(0, 1.88, 0.12),
            0.13, 0.48, HAIR
        ))
        root.add_child(_sphere(
            "HairSideLeft", Vector3(-0.23, 2.02, 0.015),
            Vector3(0.07, 0.20, 0.12), HAIR
        ))
        root.add_child(_sphere(
            "HairSideRight", Vector3(0.23, 2.02, 0.015),
            Vector3(0.07, 0.20, 0.12), HAIR
        ))
    else:
        root.add_child(_sphere(
            "Hair", Vector3(0, 2.24, 0),
            Vector3(0.27, 0.12, 0.27), HAIR
        ))

    # --------------------------------------------------
    # CLASS-SPECIFIC ARMOR AND EQUIPMENT
    # --------------------------------------------------

    match hero_class_name:

        "Warrior":
            # Heavy steel breastplate
            root.add_child(_box(
                "ChestPlate", Vector3(0, 1.38, -0.235),
                Vector3(0.51, 0.46, 0.13), STEEL
            ))
            root.add_child(_box(
                "ChestInset", Vector3(0, 1.39, -0.307),
                Vector3(0.27, 0.29, 0.025), DARK_STEEL
            ))
            root.add_child(_box(
                "ChestCrest", Vector3(0, 1.42, -0.326),
                Vector3(0.10, 0.16, 0.025), GOLD
            ))

            # Shoulder guards
            root.add_child(_sphere(
                "LeftShoulder", Vector3(-0.40, 1.58, 0),
                Vector3(0.22, 0.17, 0.22), STEEL
            ))
            root.add_child(_sphere(
                "RightShoulder", Vector3(0.40, 1.58, 0),
                Vector3(0.22, 0.17, 0.22), STEEL
            ))

            # Helmet and gold ridge
            root.add_child(_sphere(
                "WarriorHelmet", Vector3(0, 2.22, 0),
                Vector3(0.29, 0.18, 0.28), DARK_STEEL
            ))
            root.add_child(_box(
                "HelmetRidge", Vector3(0, 2.36, -0.015),
                Vector3(0.07, 0.13, 0.08), GOLD
            ))

            # Shield
            root.add_child(_box(
                "Shield", Vector3(-0.62, 1.25, -0.02),
                Vector3(0.12, 0.58, 0.38), Color("#385A83")
            ))
            root.add_child(_box(
                "ShieldEmblem", Vector3(-0.69, 1.26, -0.03),
                Vector3(0.025, 0.27, 0.12), GOLD
            ))

            # Sword
            root.add_child(_box(
                "SwordBlade", Vector3(0.65, 1.30, -0.015),
                Vector3(0.07, 0.68, 0.055), STEEL
            ))
            root.add_child(_box(
                "SwordGuard", Vector3(0.65, 0.96, -0.015),
                Vector3(0.27, 0.06, 0.07), GOLD
            ))
            root.add_child(_box(
                "SwordHandle", Vector3(0.65, 0.87, -0.015),
                Vector3(0.07, 0.15, 0.07), Color("#493321")
            ))

        "Mage":
            # Flowing robe
            root.add_child(_cone(
                "MageRobe", Vector3(0, 0.96, 0),
                0.49, 0.88, dark
            ))
            root.add_child(_box(
                "RobeTrim", Vector3(0, 0.66, -0.37),
                Vector3(0.27, 0.045, 0.025), GOLD
            ))

            # Shoulder mantle
            root.add_child(_cape(
                "MageMantle", Vector3(0, 1.58, 0.06),
                Vector3(0.65, 0.15, 0.35), color
            ))

            # Pointed wizard hat
            root.add_child(_cylinder(
                "HatBrim", Vector3(0, 2.29, 0),
                0.34, 0.055, dark
            ))
            root.add_child(_cone(
                "WizardHat", Vector3(0, 2.48, 0),
                0.28, 0.40, color
            ))
            root.add_child(_sphere(
                "HatGem", Vector3(0, 2.30, -0.30),
                Vector3(0.065, 0.065, 0.035), Color("#82D9FF")
            ))

            # Staff and glowing crystal
            root.add_child(_rod(
                "Staff", Vector3(0.68, 1.22, 0),
                0.055, 1.72, Color("#9C7046")
            ))
            root.add_child(_sphere(
                "StaffCrystal", Vector3(0.68, 2.12, 0),
                Vector3(0.15, 0.19, 0.15), Color("#82D9FF")
            ))
            root.add_child(_sphere(
                "StaffGlow", Vector3(0.68, 2.12, -0.02),
                Vector3(0.09, 0.12, 0.09), Color("#D2F5FF")
            ))

        "Rogue":
            # Dark fitted leather armor
            root.add_child(_box(
                "LeatherChest", Vector3(0, 1.39, -0.235),
                Vector3(0.48, 0.45, 0.12), dark
            ))
            root.add_child(_box(
                "LeatherStrap", Vector3(0, 1.38, -0.305),
                Vector3(0.09, 0.48, 0.025), Color("#B38B52")
            ))

            # Hood and face shadow
            root.add_child(_cape(
                "RogueHood", Vector3(0, 2.16, 0.07),
                Vector3(0.48, 0.32, 0.22), dark
            ))
            root.add_child(_box(
                "HoodFront", Vector3(0, 2.10, -0.18),
                Vector3(0.37, 0.18, 0.10), dark
            ))

            # Shoulder leather and forearm guards
            root.add_child(_sphere(
                "LeftLeatherShoulder", Vector3(-0.40, 1.55, 0),
                Vector3(0.19, 0.13, 0.18), Color("#33253F")
            ))
            root.add_child(_sphere(
                "RightLeatherShoulder", Vector3(0.40, 1.55, 0),
                Vector3(0.19, 0.13, 0.18), Color("#33253F")
            ))

            # Twin daggers
            root.add_child(_box(
                "LeftDaggerBlade", Vector3(-0.57, 1.02, -0.03),
                Vector3(0.055, 0.35, 0.045), STEEL
            ))
            root.add_child(_box(
                "RightDaggerBlade", Vector3(0.57, 1.02, -0.03),
                Vector3(0.055, 0.35, 0.045), STEEL
            ))
            root.add_child(_box(
                "LeftDaggerHandle", Vector3(-0.57, 0.81, -0.03),
                Vector3(0.07, 0.11, 0.07), GOLD
            ))
            root.add_child(_box(
                "RightDaggerHandle", Vector3(0.57, 0.81, -0.03),
                Vector3(0.07, 0.11, 0.07), GOLD
            ))

            root.add_child(_cape(
                "RogueCape", Vector3(0, 1.40, 0.20),
                Vector3(0.42, 0.60, 0.08), dark
            ))

        "Druid":
            # Natural green tunic and leaf mantle
            root.add_child(_box(
                "DruidTunic", Vector3(0, 1.35, -0.23),
                Vector3(0.47, 0.48, 0.10), Color("#254E32")
            ))
            root.add_child(_cape(
                "LeafCloak", Vector3(0, 1.43, 0.18),
                Vector3(0.50, 0.66, 0.10), Color("#254E32")
            ))

            # Leaf-shaped shoulder decorations
            root.add_child(_sphere(
                "LeafShoulderLeft", Vector3(-0.36, 1.65, -0.02),
                Vector3(0.22, 0.12, 0.22), Color("#76A84B")
            ))
            root.add_child(_sphere(
                "LeafShoulderRight", Vector3(0.36, 1.65, -0.02),
                Vector3(0.22, 0.12, 0.22), Color("#76A84B")
            ))
            root.add_child(_sphere(
                "LeafChestGem", Vector3(0, 1.42, -0.31),
                Vector3(0.10, 0.13, 0.04), Color("#A5E66B")
            ))

            # Nature circlet
            root.add_child(_sphere(
                "DruidCirclet", Vector3(0, 2.25, 0),
                Vector3(0.29, 0.06, 0.27), GOLD
            ))
            root.add_child(_sphere(
                "CircletGem", Vector3(0, 2.28, -0.23),
                Vector3(0.07, 0.07, 0.04), Color("#A5E66B")
            ))

            # Wooden staff and living crystal
            root.add_child(_rod(
                "NatureStaff", Vector3(0.67, 1.18, 0),
                0.06, 1.58, Color("#8C6742")
            ))
            root.add_child(_sphere(
                "NatureGem", Vector3(0.67, 2.03, 0),
                Vector3(0.13, 0.18, 0.13), Color("#A5E66B")
            ))
            root.add_child(_sphere(
                "StaffLeaf", Vector3(0.78, 1.96, 0),
                Vector3(0.08, 0.15, 0.045), Color("#76A84B")
            ))

        "Ranger":
            # Practical leather and forest cloak
            root.add_child(_box(
                "RangerChest", Vector3(0, 1.38, -0.23),
                Vector3(0.48, 0.46, 0.12), Color("#48532D")
            ))
            root.add_child(_box(
                "RangerStrap", Vector3(0, 1.39, -0.30),
                Vector3(0.08, 0.47, 0.025), Color("#B38B52")
            ))
            root.add_child(_cape(
                "ForestCloak", Vector3(0, 1.44, 0.19),
                Vector3(0.44, 0.66, 0.08), dark
            ))

            # Ranger hood
            root.add_child(_cape(
                "RangerHood", Vector3(0, 2.18, 0.07),
                Vector3(0.43, 0.25, 0.20), dark
            ))

            # Quiver and arrows
            root.add_child(_box(
                "Quiver", Vector3(-0.28, 1.58, 0.23),
                Vector3(0.16, 0.44, 0.15), Color("#70482D")
            ))
            root.add_child(_rod(
                "ArrowOne", Vector3(-0.31, 1.84, 0.20),
                0.018, 0.42, Color("#E5D9B6")
            ))
            root.add_child(_rod(
                "ArrowTwo", Vector3(-0.25, 1.84, 0.20),
                0.018, 0.42, Color("#E5D9B6")
            ))

            # Bow: tall curved-looking wooden frame
            var bow_upper := _rod(
                "BowUpper", Vector3(0.62, 1.63, 0),
                0.035, 0.48, Color("#A77B43")
            )
            bow_upper.rotation.z = -0.25
            root.add_child(bow_upper)

            var bow_lower := _rod(
                "BowLower", Vector3(0.62, 1.13, 0),
                0.035, 0.48, Color("#A77B43")
            )
            bow_lower.rotation.z = 0.25
            root.add_child(bow_lower)

            root.add_child(_rod(
                "BowGrip", Vector3(0.62, 1.38, 0),
                0.045, 0.18, Color("#70482D")
            ))

    # Class-colored shoulder accents help distinguish silhouettes.
    if hero_class_name != "Warrior":
        root.add_child(_sphere(
            "ClassShoulderAccent", Vector3(-0.38, 1.60, -0.01),
            Vector3(0.16, 0.12, 0.17), light
        ))

    return root


# --------------------------------------------------
# MATERIALS AND MESH HELPERS
# --------------------------------------------------

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.78
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


func _cylinder(
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
    mesh.top_radius = 0.0
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
