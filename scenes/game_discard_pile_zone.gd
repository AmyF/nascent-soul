extends VisibilityControlledZone
class_name GameDiscardPileZone

func can_accept(obj: Control) -> bool:
	return obj is GameCard
