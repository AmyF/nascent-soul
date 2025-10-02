extends Control

@export var card_packed_scene: PackedScene
@export var init_card_number: int = 10

@onready var deck: GameDeck = $GameDeck
@onready var discard_pile: GameDiscardPile = $GameDiscardPile
@onready var hand: GameHand = $GameHand

func _ready() -> void:
	for i in range(init_card_number):
		var card_instance = card_packed_scene.instantiate() as GameCard
		deck.zone.add_obj(card_instance, -1, false)


func _on_draw_card_button_pressed() -> void:
	if deck.zone.get_objs().is_empty():
		return
	deck.zone.move_top_objs_to_other(1, hand.zone)


func _on_discard_card_button_pressed() -> void:
	if hand.zone.get_objs().is_empty():
		return
	
	hand.zone.move_top_objs_to_other(1, discard_pile.zone)
