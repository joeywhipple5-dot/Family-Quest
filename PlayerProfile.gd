extends Node

var selected_class: String = "Warrior"
var selected_gender: String = "male"

func set_selection(hero_class: String, gender: String) -> void:
    if hero_class in ["Warrior", "Mage", "Rogue", "Druid", "Ranger"]:
        selected_class = hero_class
    if gender.to_lower() in ["male", "female"]:
        selected_gender = gender.to_lower()
