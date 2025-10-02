extends VisibilityControlledZone
class_name GameDeckZone

func can_accept(obj: Control) -> bool:
	return obj is GameCard
