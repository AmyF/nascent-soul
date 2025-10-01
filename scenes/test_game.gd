extends Control

@export var card_packed_scene: PackedScene
@export var init_card_number: int = 10

@onready var deck: GameDeck = $GameDeck
@onready var discard_pile: GameDeck = $GameDiscardPile
@onready var hand: GameHand = $GameHand

func _ready() -> void:
	for i in range(init_card_number):
		var card_instance = card_packed_scene.instantiate() as GameCard
		deck.zone.add_obj(card_instance)

	if discard_pile.zone is VisibilityControlledZone:
		var discard_zone = discard_pile.zone as VisibilityControlledZone
		discard_zone.default_face_up = true
		discard_zone.auto_set_visibility = true



func _on_draw_card_button_pressed() -> void:
	if deck.zone.get_objs().is_empty():
		return
	var card = deck.zone.get_objs().pop_back()
	deck.zone.move_obj_to_other(card, hand.zone)


func _on_discard_card_button_pressed() -> void:
	if hand.zone.get_objs().is_empty():
		return
	
	var card = hand.zone.get_objs().pop_back()
	hand.zone.move_obj_to_other(card, discard_pile.zone)
