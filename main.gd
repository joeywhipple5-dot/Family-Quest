
func _build_house(p: Vector3, house_color: Color, house_name: String) -> void:
    # Interior floor
    _add_box(
        house_name + "InteriorFloor",
        p + Vector3(0, 0.08, 0),
        Vector3(5.8, 0.16, 5.8),
        Color("#9B8060"),
        true
    )

    # Left and right walls
    _add_box(
        house_name + "LeftWall",
        p + Vector3(-2.9, 2.2, 0),
        Vector3(0.2, 4.4, 6.0),
        house_color,
        true
    )

    _add_box(
        house_name + "RightWall",
        p + Vector3(2.9, 2.2, 0),
        Vector3(0.2, 4.4, 6.0),
        house_color,
        true
    )

    # Back wall
    _add_box(
        house_name + "BackWall",
        p + Vector3(0, 2.2, -2.9),
        Vector3(6.0, 4.4, 0.2),
        house_color,
        true
    )

    # Front wall split into sections to leave a doorway
    _add_box(
        house_name + "FrontLeftWall",
        p + Vector3(-2.0, 2.2, 2.9),
        Vector3(2.0, 4.4, 0.2),
        house_color,
        true
    )

    _add_box(
        house_name + "FrontRightWall",
        p + Vector3(2.0, 2.2, 2.9),
        Vector3(2.0, 4.4, 0.2),
        house_color,
        true
    )

    # Wall section above the doorway
    _add_box(
        house_name + "DoorHeader",
        p + Vector3(0, 3.35, 2.9),
        Vector3(2.0, 2.1, 0.2),
        house_color,
        true
    )

    # Roof: visual only, so it does not block entry
    _add_box(
        house_name + "Roof",
        p + Vector3(0, 4.65, 0),
        Vector3(6.8, 0.6, 6.8),
        Color("#49352D"),
        false
    )

    # Door panel beside the open entrance.
    # The opening itself remains clear for the player.
    _add_box(
        house_name + "Door",
        p + Vector3(0.65, 1.05, 2.78),
        Vector3(0.65, 2.1, 0.12),
        Color("#4A2B1A"),
        false
    )

    # Front windows
    _add_box(
        house_name + "WindowLeft",
        p + Vector3(-2.0, 2.3, 3.02),
        Vector3(0.75, 0.9, 0.1),
        Color("#9ED5E0"),
        false
    )

    _add_box(
        house_name + "WindowRight",
        p + Vector3(2.0, 2.3, 3.02),
        Vector3(0.75, 0.9, 0.1),
        Color("#9ED5E0"),
        false
    )

    # Interior table or shop counter
    var counter_color := Color("#654329")
    var counter_position := p + Vector3(0, 0.65, -1.25)

    _add_box(
        house_name + "InteriorCounter",
        counter_position,
        Vector3(2.0, 0.9, 0.7),
        counter_color,
        true
    )
