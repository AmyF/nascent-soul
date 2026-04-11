class_name ZoneInputBindingRegistry extends RefCounted

var input_service = null
var context: ZoneContext = null
var zone = null
var item_bindings: Dictionary = {}

func _init(p_input_service, p_context: ZoneContext) -> void:
	input_service = p_input_service
	context = p_context
	zone = context.zone

func bind() -> void:
	var gui_input_callable = Callable(input_service, "on_zone_gui_input")
	if not zone.gui_input.is_connected(gui_input_callable):
		zone.gui_input.connect(gui_input_callable)
	sync_item_bindings()

func sync_item_bindings() -> void:
	var valid_items = context.get_items()
	var valid_ids: Dictionary = {}
	for item in valid_items:
		if is_instance_valid(item):
			valid_ids[item.get_instance_id()] = true
	for item in item_bindings.keys().duplicate():
		if not is_instance_valid(item) or not valid_ids.has(item.get_instance_id()):
			unregister_item(item)
	for item in valid_items:
		if is_instance_valid(item):
			register_item(item)

func register_item(item: ZoneItemControl) -> void:
	if not is_instance_valid(item) or item_bindings.has(item):
		return
	if item.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		item.mouse_filter = Control.MOUSE_FILTER_PASS
	var gui_input_callable = Callable(input_service, "on_item_gui_input").bind(item)
	var mouse_entered_callable = Callable(input_service, "on_item_mouse_entered").bind(item)
	var mouse_exited_callable = Callable(input_service, "on_item_mouse_exited").bind(item)
	if not item.gui_input.is_connected(gui_input_callable):
		item.gui_input.connect(gui_input_callable)
	if not item.mouse_entered.is_connected(mouse_entered_callable):
		item.mouse_entered.connect(mouse_entered_callable)
	if not item.mouse_exited.is_connected(mouse_exited_callable):
		item.mouse_exited.connect(mouse_exited_callable)
	item_bindings[item] = {
		"gui_input": gui_input_callable,
		"mouse_entered": mouse_entered_callable,
		"mouse_exited": mouse_exited_callable
	}

func unregister_item(item) -> void:
	if not item_bindings.has(item):
		return
	var bindings: Dictionary = item_bindings[item]
	input_service.reset_press_state_for_item(item)
	if is_instance_valid(item):
		if item.gui_input.is_connected(bindings["gui_input"]):
			item.gui_input.disconnect(bindings["gui_input"])
		if item.mouse_entered.is_connected(bindings["mouse_entered"]):
			item.mouse_entered.disconnect(bindings["mouse_entered"])
		if item.mouse_exited.is_connected(bindings["mouse_exited"]):
			item.mouse_exited.disconnect(bindings["mouse_exited"])
	item_bindings.erase(item)

func cleanup() -> void:
	for item in item_bindings.keys().duplicate():
		unregister_item(item)
	item_bindings.clear()
	var gui_input_callable = Callable(input_service, "on_zone_gui_input")
	if zone != null and is_instance_valid(zone) and zone.gui_input.is_connected(gui_input_callable):
		zone.gui_input.disconnect(gui_input_callable)
	zone = null
	context = null
	input_service = null
