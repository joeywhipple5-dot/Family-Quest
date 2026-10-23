extends Node3D
class_name FamilyQuestHero

@export_enum("Warrior", "Mage", "Rogue", "Druid", "Ranger") var hero_class: String = "Warrior"
@export_enum("Male", "Female") var body_style: String = "Male"

const BODY := preload("res://artwork/humanoids/Models/Human_Body.fbx")
const HAIR := preload("res://artwork/humanoids/Models/Human_Hair.fbx")
const CLOTHES := preload("res://artwork/humanoids/Models/Human_Cloth_Clothes.fbx")
const LEATHER := preload("res://artwork/humanoids/Models/Human_Cloth_Leather.fbx")
const CLOAK := preload("res://artwork/humanoids/Models/Human_Cloth_Cloak.fbx")
const ROBES := preload("res://artwork/humanoids/Models/Human_Cloth_Robes.fbx")

func _ready() -> void:
    # First integration test: instantiate base human only.
    # Clothing FBXs are included in the pack but are intentionally not attached
    # until their skeleton/node structure is verified in the Godot editor.
    var human: Node3D = BODY.instantiate()
    human.name = "HumanBody"
    add_child(human)
