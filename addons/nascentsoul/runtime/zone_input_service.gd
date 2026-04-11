class_name ZoneInputService extends RefCounted

# Internal runtime helper for gesture capture and selection plumbing.

const ZoneInputSelectionControllerScript = preload("res://addons/nascentsoul/runtime/zone_input_selection_controller.gd")
const ZoneInputBindingRegistryScript = preload("res://addons/nascentsoul/runtime/zone_input_binding_registry.gd")
const ZoneInputPointerFlowScript = preload("res://addons/nascentsoul/runtime/zone_input_pointer_flow.gd")

var context: ZoneContext
var zone: Zone
var runtime_port = null
var selection_state: ZoneSelectionState
var _selection_controller = null
var _binding_registry = null
var _pointer_flow = null
var transfer_service: ZoneTransferService = null
var targeting_service: ZoneTargetingService = null

func _init(p_context: ZoneContext, p_runtime_port) -> void:
	context = p_context
	zone = context.zone
	runtime_port = p_runtime_port
	selection_state = context.selection_state
	_selection_controller = ZoneInputSelectionControllerScript.new(self, context, selection_state)
	_binding_registry = ZoneInputBindingRegistryScript.new(self, context)
	_pointer_flow = ZoneInputPointerFlowScript.new(self, context)

# Lifecycle and binding.
## Connects transfer and targeting services so pointer handlers can start drags or targeting flows.
func bind_runtime_services(p_transfer_service: ZoneTransferService, p_targeting_service: ZoneTargetingService) -> void:
	transfer_service = p_transfer_service
	targeting_service = p_targeting_service

## Ensures timers exist and binds zone plus item input signals for the current items root.
func bind() -> void:
	ensure_long_press_timer()
	if _binding_registry != null:
		_binding_registry.bind()

## Reconciles per-item input bindings after the items root changes.
func sync_item_bindings() -> void:
	if _binding_registry != null:
		_binding_registry.sync_item_bindings()

func ensure_long_press_timer() -> void:
	if _pointer_flow != null:
		_pointer_flow.ensure_long_press_timer()

## Disconnects input bindings and drops references to runtime collaborators.
func cleanup() -> void:
	if _binding_registry != null:
		_binding_registry.cleanup()
	if _pointer_flow != null:
		_pointer_flow.cleanup()
	if _selection_controller != null:
		_selection_controller.cleanup()
	_pointer_flow = null
	_binding_registry = null
	_selection_controller = null
	selection_state = null
	transfer_service = null
	targeting_service = null
	runtime_port = null
	zone = null
	context = null

func register_item(item: ZoneItemControl) -> void:
	if _binding_registry != null:
		_binding_registry.register_item(item)

func unregister_item(item) -> void:
	if _binding_registry != null:
		_binding_registry.unregister_item(item)

func clear_selection() -> void:
	_selection_controller.clear_selection()

func select_item(item: ZoneItemControl, additive: bool = false) -> void:
	_selection_controller.select_item(item, additive)

# Input event handling.
## Routes item GUI input to button or motion handlers when interaction rules are available.
func on_item_gui_input(event: InputEvent, item: ZoneItemControl) -> void:
	if context.get_interaction() == null:
		return
	if event is InputEventMouseButton:
		handle_mouse_button(event as InputEventMouseButton, item)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event as InputEventMouseMotion, item)

## Routes background zone input, such as deselection or gesture state, through the pointer flow.
func on_zone_gui_input(event: InputEvent) -> void:
	if _pointer_flow != null:
		_pointer_flow.handle_zone_gui_input(event)

func on_item_mouse_entered(item: ZoneItemControl) -> void:
	_selection_controller.handle_item_mouse_entered(item)

func on_item_mouse_exited(item: ZoneItemControl) -> void:
	_selection_controller.handle_item_mouse_exited(item)

func handle_mouse_button(event: InputEventMouseButton, item: ZoneItemControl) -> void:
	if _pointer_flow != null:
		_pointer_flow.handle_mouse_button(event, item)

func handle_mouse_motion(event: InputEventMouseMotion, item: ZoneItemControl) -> void:
	if _pointer_flow != null:
		_pointer_flow.handle_mouse_motion(event, item)

func apply_click_selection(item: ZoneItemControl, event: InputEventMouseButton) -> void:
	_selection_controller.apply_click_selection(item, event)

## Applies keyboard navigation and selection rules. Returns true when the event was consumed.
func handle_keyboard_navigation(event: InputEvent, interaction: ZoneInteraction) -> bool:
	return _selection_controller.handle_keyboard_navigation(event, interaction)

func resolve_drag_items(item: ZoneItemControl) -> Array[ZoneItemControl]:
	return _selection_controller.resolve_drag_items(item)

func stop_long_press_timer() -> void:
	if _pointer_flow != null:
		_pointer_flow.stop_long_press_timer()

func on_long_press_timeout() -> void:
	if _pointer_flow != null:
		_pointer_flow.on_long_press_timeout()

func clear_hover_for_items(items_to_clear: Array[ZoneItemControl], emit_signal: bool) -> void:
	_selection_controller.clear_hover_for_items(items_to_clear, emit_signal)

func reset_press_state_for_item(item = null) -> void:
	if _pointer_flow != null:
		_pointer_flow.reset_press_state_for_item(item)

func clear_background_interaction() -> void:
	_selection_controller.clear_background_interaction()

# Runtime-port bridge.
func request_refresh() -> void:
	if runtime_port != null:
		runtime_port.request_refresh()

func get_drag_coordinator(create_if_missing: bool = true):
	return runtime_port.get_drag_coordinator(create_if_missing) if runtime_port != null else null

func get_targeting_coordinator(create_if_missing: bool = true):
	return runtime_port.get_targeting_coordinator(create_if_missing) if runtime_port != null else null

func emit_item_clicked(item: ZoneItemControl) -> void:
	if runtime_port != null:
		runtime_port.emit_item_clicked(item)

func emit_item_double_clicked(item: ZoneItemControl) -> void:
	if runtime_port != null:
		runtime_port.emit_item_double_clicked(item)

func emit_item_right_clicked(item: ZoneItemControl) -> void:
	if runtime_port != null:
		runtime_port.emit_item_right_clicked(item)

func emit_item_long_pressed(item: ZoneItemControl) -> void:
	if runtime_port != null:
		runtime_port.emit_item_long_pressed(item)

func emit_item_hover_entered(item: ZoneItemControl) -> void:
	if runtime_port != null:
		runtime_port.emit_item_hover_entered(item)

func emit_item_hover_exited(item: ZoneItemControl) -> void:
	if runtime_port != null:
		runtime_port.emit_item_hover_exited(item)

func emit_selection_changed() -> void:
	if runtime_port != null:
		runtime_port.emit_selection_changed()
