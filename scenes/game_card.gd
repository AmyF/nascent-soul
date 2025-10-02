extends Card
class_name GameCard

enum ZoneType {
	NONE,
	DECK,
	HAND,
	DISCARD_PILE
}

var zone_type: ZoneType = ZoneType.NONE

func _on_card_double_clicked() -> void:
	flip()
