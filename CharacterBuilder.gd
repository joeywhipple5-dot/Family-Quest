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

func build_character(hero_class_name: String, gender: String = "male") -> Node3D:
    var root := Node3D.new()
    root.name = "%s_%s" % [hero_class_name, gender.capitalize()]
    var color: Color = PALETTES.get(hero_class_name, Color("#6A8C9B"))
    var skin := SKIN_FEMALE if gender.to_lower() == "female" else SKIN_MALE
    var dark := color.darkened(0.3)
    var trim := Color("#D9B45B")

    # Main body, armor/robes, head, arms and boots.
    root.add_child(_capsule("Torso", Vector3(0, 1.32, 0), 0.38 if gender == "female" else 0.42, 0.88, color))
    root.add_child(_sphere("Head", Vector3(0, 2.03, 0), Vector3(0.27, 0.31, 0.26), skin))
    root.add_child(_capsule("LeftLeg", Vector3(-0.16, 0.48, 0), 0.13, 0.66, dark))
    root.add_child(_capsule("RightLeg", Vector3(0.16, 0.48, 0), 0.13, 0.66, dark))
    root.add_child(_capsule("LeftArm", Vector3(-0.46, 1.34, 0), 0.12, 0.68, color.lightened(0.12)))
    root.add_child(_capsule("RightArm", Vector3(0.46, 1.34, 0), 0.12, 0.68, color.lightened(0.12)))
    root.add_child(_sphere("Belt", Vector3(0, 1.0, -0.015), Vector3(0.38, 0.09, 0.25), trim))

    # Hair/hood and class silhouette accents.
    var hair_color := Color("#49301F")
    if gender.to_lower() == "female":
        root.add_child(_capsule("LongHair", Vector3(0, 1.91, 0.11), 0.13, 0.48, hair_color))
    else:
        root.add_child(_sphere("Hair", Vector3(0, 2.24, 0), Vector3(0.28, 0.12, 0.27), hair_color))

    match hero_class_name:
        "Warrior":
            root.add_child(_box("ChestPlate", Vector3(0, 1.43, -0.28), Vector3(0.48, 0.46, 0.08), Color("#B8C3CE")))
            root.add_child(_box("Shield", Vector3(-0.61, 1.2, -0.02), Vector3(0.12, 0.56, 0.38), Color("#6F8499")))
            root.add_child(_box("Sword", Vector3(0.65, 1.18, -0.02), Vector3(0.09, 0.72, 0.09), Color("#DCE6EF")))
        "Mage":
            root.add_child(_cone("Robe", Vector3(0, 0.98, 0), 0.48, 0.75, dark))
            root.add_child(_rod("Staff", Vector3(0.67, 1.2, 0), 0.055, 1.65, Color("#9C7046")))
            root.add_child(_sphere("StaffCrystal", Vector3(0.67, 2.08, 0), Vector3(0.16, 0.16, 0.16), Color("#82D9FF")))
        "Rogue":
            root.add_child(_box("ChestLeather", Vector3(0, 1.4, -0.27), Vector3(0.44, 0.45, 0.08), dark))
            root.add_child(_box("LeftDagger", Vector3(-0.55, 1.05, 0), Vector3(0.06, 0.42, 0.06), Color("#DCE6EF")))
            root.add_child(_box("RightDagger", Vector3(0.55, 1.05, 0), Vector3(0.06, 0.42, 0.06), Color("#DCE6EF")))
            root.add_child(_cape("HoodCape", Vector3(0, 1.43, 0.2), Vector3(0.42, 0.62, 0.08), dark))
        "Druid":
            root.add_child(_cape("LeafCloak", Vector3(0, 1.45, 0.18), Vector3(0.48, 0.68, 0.1), Color("#254E32")))
            root.add_child(_rod("NatureStaff", Vector3(0.66, 1.2, 0), 0.06, 1.55, Color("#8C6742")))
            root.add_child(_sphere("NatureGem", Vector3(0.66, 2.04, 0), Vector3(0.14, 0.18, 0.14), Color("#A5E66B")))
            root.add_child(_sphere("LeafShoulder", Vector3(-0.35, 1.67, 0), Vector3(0.22, 0.12, 0.22), Color("#76A84B")))
        "Ranger":
            root.add_child(_cape("ForestCloak", Vector3(0, 1.45, 0.19), Vector3(0.42, 0.65, 0.08), dark))
            root.add_child(_rod("BowGrip", Vector3(0.62, 1.25, 0), 0.045, 0.8, Color("#A77B43")))
            root.add_child(_box("Quiver", Vector3(-0.27, 1.57, 0.23), Vector3(0.16, 0.42, 0.14), Color("#70482D")))
            root.add_child(_box("Arrow", Vector3(-0.27, 1.8, 0.13), Vector3(0.04, 0.48, 0.04), Color("#E5D9B6")))
    return root

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.78
    return material

func _mesh_instance(node_name: String, mesh: Mesh, pos: Vector3, color: Color, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = node_name
    item.mesh = mesh
    item.position = pos
    item.scale = scale_value
    item.material_override = _material(color)
    return item

func _capsule(node_name: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    return _mesh_instance(node_name, mesh, pos, color)

func _sphere(node_name: String, pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
    return _mesh_instance(node_name, SphereMesh.new(), pos, color, scale_value)

func _box(node_name: String, pos: Vector3, size_value: Vector3, color: Color) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size_value
    return _mesh_instance(node_name, mesh, pos, color)

func _rod(node_name: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    return _mesh_instance(node_name, mesh, pos, color)

func _cone(node_name: String, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.06
    mesh.bottom_radius = radius
    mesh.height = height
    return _mesh_instance(node_name, mesh, pos, color)

func _cape(node_name: String, pos: Vector3, size_value: Vector3, color: Color) -> MeshInstance3D:
    return _box(node_name, pos, size_value, color)
