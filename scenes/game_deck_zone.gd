extends VisibilityControlledZone
class_name GameDeckZone

func can_accept_obj_from_other(obj: Control, source_zone: Zone) -> bool:
	if not super.can_accept_obj_from_other(obj, source_zone):
		return false

	var card = obj as GameCard
	return card.zone_type == GameCard.ZoneType.NONE
