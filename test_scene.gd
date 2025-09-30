extends Node2D

var card_packaged = preload("res://color_card.tscn")

@onready var zone_a: Zone = $Panel/Zone
@onready var zone_b: Zone = $Panel2/Zone

func _on_button_pressed() -> void:
	var new_card = card_packaged.instantiate()
	zone_a.add_obj(new_card)


func _on_button_2_pressed() -> void:
	var objs = zone_a.get_objs()
	if objs.size() > 1:
		zone_a.move_obj_to_other(objs[0], zone_b)
