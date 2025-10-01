extends Zone
class_name VisibilityControlledZone

@export var default_face_up: bool = true
@export var allow_manual_flip: bool = false
@export var auto_set_visibility: bool = true

func add_obj(obj: Control, index: int = -1, animate: bool = true) -> bool:
    var result = super.add_obj(obj, index, animate)

    if result and auto_set_visibility and obj is Card:
        var card = obj as Card
        card.set_face_up(default_face_up, animate)

    return result


func flip_all_cards(face_up: bool, animate: bool = true) -> void:
    for obj in get_objs():
        if obj is Card:
            var card = obj as Card
            card.flip(animate)


func set_all_cards_face_up(face_up: bool, animate: bool = true) -> void:
    for obj in get_objs():
        if obj is Card:
            var card = obj as Card
            card.set_face_up(face_up, animate)