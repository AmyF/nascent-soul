class_name ZoneCardInteraction extends ZoneInteraction

@export var drag_threshold: float = 5.0

var _pressed_pos: Vector2 = Vector2.ZERO
var _is_pressed: bool = false

func register_item(zone: Node, item: Control):
	item.mouse_filter = Control.MOUSE_FILTER_PASS

func handle_input(zone: Node, item: Control, event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
				_pressed_pos = event.global_position
			else:
				_is_pressed = false
				
	elif event is InputEventMouseMotion:
		if _is_pressed and not ZoneDragContext.is_dragging:
			if event.global_position.distance_to(_pressed_pos) > drag_threshold:
				_is_pressed = false
				var drag_items: Array[Control] = [item]
				zone.start_drag(drag_items)
