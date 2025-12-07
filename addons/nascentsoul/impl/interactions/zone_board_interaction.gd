class_name ZoneBoardInteraction extends ZoneInteraction

@export var long_press_time: float = 0.3
@export var drag_threshold: float = 5.0

var _pressed_pos: Vector2 = Vector2.ZERO
var _is_pressed: bool = false
var _timer: Timer = null
var _current_item: Control = null
var _current_zone: Node = null

func register_item(zone: Node, item: Control):
	item.mouse_filter = Control.MOUSE_FILTER_PASS

func handle_input(zone: Node, item: Control, event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_pressed = true
				_pressed_pos = event.global_position
				_current_item = item
				_current_zone = zone
				_start_timer(zone)
			else:
				_is_pressed = false
				_stop_timer()
				
	elif event is InputEventMouseMotion:
		if _is_pressed and not ZoneDragContext.is_dragging:
			if event.global_position.distance_to(_pressed_pos) > drag_threshold:
				_stop_timer()
				_is_pressed = false
				var drag_items: Array[Control] = [_current_item]
				_current_zone.start_drag(drag_items)

func _start_timer(zone: Node):
	if not is_instance_valid(_timer):
		_timer = Timer.new()
		_timer.one_shot = true
		zone.add_child(_timer)
		_timer.timeout.connect(_on_timeout)
	_timer.wait_time = long_press_time
	_timer.start()

func _stop_timer():
	if is_instance_valid(_timer):
		_timer.stop()

func _on_timeout():
	if _is_pressed and not ZoneDragContext.is_dragging:
		_is_pressed = false
		if is_instance_valid(_current_zone) and is_instance_valid(_current_item):
			var drag_items: Array[Control] = [_current_item]
			_current_zone.start_drag(drag_items)