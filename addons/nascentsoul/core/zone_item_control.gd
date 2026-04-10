@tool
class_name ZoneItemControl extends Control

@export var zone_item_metadata: Dictionary = {}
@export var zone_targeting_intent_override: ZoneTargetingIntent = null

var _zone_visual_state := ZoneItemVisualState.new()

func create_zone_group_drag_ghost(context: ZoneContext, _source_items: Array[ZoneItemControl], _anchor_item: ZoneItemControl) -> Control:
	return create_zone_drag_ghost(context)

func create_zone_drag_ghost(_context: ZoneContext) -> Control:
	var ghost := ColorRect.new()
	ghost.color = Color(1, 1, 1, 0.18)
	ghost.custom_minimum_size = _resolved_item_size()
	ghost.size = ghost.custom_minimum_size
	return ghost

func create_zone_group_drag_proxy(context: ZoneContext, _source_items: Array[ZoneItemControl], _anchor_item: ZoneItemControl) -> Control:
	return create_zone_drag_proxy(context)

func create_zone_drag_proxy(_context: ZoneContext) -> Control:
	var proxy = duplicate(0)
	if proxy is Control:
		var control_proxy := proxy as Control
		control_proxy.modulate.a = 0.92
		control_proxy.global_position = global_position
		return control_proxy
	var fallback := ColorRect.new()
	fallback.color = Color(1, 1, 1, 0.72)
	fallback.custom_minimum_size = _resolved_item_size()
	fallback.size = fallback.custom_minimum_size
	fallback.global_position = global_position
	return fallback

func create_zone_spawned_item(
	_context: ZoneContext,
	_decision: ZoneTransferDecision,
	_placement_target: ZonePlacementTarget
) -> ZoneItemControl:
	return null

func configure_zone_spawned_item(
	_spawned_item: ZoneItemControl,
	_context: ZoneContext,
	_placement_target: ZonePlacementTarget
) -> void:
	pass

func create_zone_targeting_intent(_command: ZoneTargetingCommand, _entry_mode: StringName) -> ZoneTargetingIntent:
	if zone_targeting_intent_override == null:
		return null
	return zone_targeting_intent_override.duplicate(true)

func get_zone_target_anchor_global() -> Vector2:
	return global_position + size * 0.5

func get_zone_item_metadata() -> Dictionary:
	return zone_item_metadata.duplicate(true)

func set_zone_item_metadata(metadata: Dictionary) -> void:
	zone_item_metadata = metadata.duplicate(true)

func apply_zone_visual_state(state: ZoneItemVisualState) -> void:
	_zone_visual_state = state.duplicate_state() if state != null else ZoneItemVisualState.new()

func get_zone_visual_state() -> ZoneItemVisualState:
	return _zone_visual_state.duplicate_state()

func _resolved_item_size() -> Vector2:
	if size != Vector2.ZERO:
		return size
	if custom_minimum_size != Vector2.ZERO:
		return custom_minimum_size
	return Vector2(100, 150)
