
extends Node

const SAVE_PATH := "user://family_quest_profile.cfg"
const VALID_CLASSES := [
    "Warrior", "Mage", "Rogue", "Druid", "Ranger"
]

var selected_class: String = "Warrior"
var selected_gender: String = "male"
var character_locked: bool = false


func _ready() -> void:
    load_profile()


func set_selection(hero_class: String, gender: String) -> void:
    # Do not allow changes after the character is locked.
    if character_locked:
        return

    if hero_class in VALID_CLASSES:
        selected_class = hero_class

    if gender.to_lower() in ["male", "female"]:
        selected_gender = gender.to_lower()


func lock_selection() -> void:
    character_locked = true
    save_profile()


func save_profile() -> void:
    var config := ConfigFile.new()

    config.set_value("character", "selected_class", selected_class)
    config.set_value("character", "selected_gender", selected_gender)
    config.set_value("character", "locked", character_locked)

    var error := config.save(SAVE_PATH)
    if error != OK:
        push_error("Family Quest: Could not save character profile.")


func load_profile() -> void:
    var config := ConfigFile.new()
    var error := config.load(SAVE_PATH)

    if error != OK:
        return

    var saved_class = config.get_value(
        "character", "selected_class", "Warrior"
    )
    var saved_gender = config.get_value(
        "character", "selected_gender", "male"
    )
    var saved_locked = config.get_value(
        "character", "locked", false
    )

    if saved_class in VALID_CLASSES:
        selected_class = saved_class

    if saved_gender in ["male", "female"]:
        selected_gender = saved_gender

    character_locked = bool(saved_locked)
