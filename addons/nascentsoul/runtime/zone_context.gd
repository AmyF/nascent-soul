class_name ZoneContext extends RefCounted

# Internal runtime context shared by zone services. External code should not
# depend on this type directly.

var zone = null
var config = null
var store = null
var input_service = null
var render_service = null
var transfer_service = null
var targeting_service = null

var selection_state:
	get:
		return store.selection_state if store != null else null

func _init(p_zone, p_store = null, p_config = null) -> void:
	zone = p_zone
	store = p_store
	config = p_config

func bind_services(p_input_service, p_render_service, p_transfer_service, p_targeting_service) -> void:
	input_service = p_input_service
	render_service = p_render_service
	transfer_service = p_transfer_service
	targeting_service = p_targeting_service

func cleanup() -> void:
	zone = null
	config = null
	store = null
	input_service = null
	render_service = null
	transfer_service = null
	targeting_service = null

func update_config(next_config) -> void:
	config = next_config

func get_items_root() -> Control:
	return zone.get_items_root()

func get_preview_root() -> Control:
	return zone.get_preview_root()

func get_items() -> Array[ZoneItemControl]:
	return store.get_items() if store != null else []

func get_items_ordered() -> Array[ZoneItemControl]:
	return get_items()

func get_item_count() -> int:
	return store.get_item_count() if store != null else 0

func has_item(item: ZoneItemControl) -> bool:
	return store.has_item(item) if store != null else false

func find_item_index(item: ZoneItemControl) -> int:
	return store.find_item_index(item) if store != null else -1

func get_item_target(item: ZoneItemControl) -> ZonePlacementTarget:
	return store.get_item_target(self, item) if store != null else ZonePlacementTarget.invalid()

func get_items_at_target(target: ZonePlacementTarget) -> Array[ZoneItemControl]:
	return store.get_items_at_target(self, target) if store != null else []

func get_item_at_global_position(global_position: Vector2) -> ZoneItemControl:
	return store.get_item_at_global_position(global_position) if store != null else null

func get_space_model() -> ZoneSpaceModel:
	return config.space_model if config != null else null

func get_layout_policy() -> ZoneLayoutPolicy:
	return config.layout_policy if config != null else null

func get_display_style() -> ZoneDisplayStyle:
	return config.display_style if config != null else null

func get_interaction() -> ZoneInteraction:
	return config.interaction if config != null else null

func get_sort_policy() -> ZoneSortPolicy:
	return config.sort_policy if config != null else null

func get_transfer_policy() -> ZoneTransferPolicy:
	return config.transfer_policy if config != null else null

func get_drag_visual_factory() -> ZoneDragVisualFactory:
	return config.drag_visual_factory if config != null else null

func get_targeting_style() -> ZoneTargetingStyle:
	return config.targeting_style if config != null else null

func get_targeting_policy() -> ZoneTargetingPolicy:
	return config.targeting_policy if config != null else null

func resolve_item_size(item: ZoneItemControl) -> Vector2:
	if render_service != null:
		return render_service.resolve_item_size(item)
	var layout_policy = get_layout_policy()
	if layout_policy != null:
		return layout_policy.resolve_item_size(item)
	if not is_instance_valid(item):
		return Vector2.ZERO
	if item.size != Vector2.ZERO:
		return item.size
	if item.custom_minimum_size != Vector2.ZERO:
		return item.custom_minimum_size
	return Vector2(100, 150)

func resolve_target_position(target: ZonePlacementTarget, container_size: Vector2, item_size: Vector2) -> Vector2:
	var space_model = get_space_model()
	if space_model == null:
		return Vector2.ZERO
	return space_model.resolve_item_position(self, target, container_size, item_size)

func resolve_target_size(target: ZonePlacementTarget) -> Vector2:
	var space_model = get_space_model()
	if space_model == null:
		return Vector2.ZERO
	return space_model.resolve_target_size(self, target)

func resolve_target_anchor(target: ZonePlacementTarget) -> Vector2:
	var space_model = get_space_model()
	if space_model == null:
		return zone.global_position + zone.size * 0.5
	return space_model.resolve_target_anchor(self, target)

func get_display_state(style: Resource) -> Dictionary:
	return render_service.get_display_state(style) if render_service != null else {}

func consume_transfer_handoff(item: ZoneItemControl) -> Dictionary:
	return store.consume_transfer_handoff(item) if store != null else {}

func set_transfer_handoff(item: ZoneItemControl, snapshot: Dictionary) -> void:
	if store != null:
		store.set_transfer_handoff(item, snapshot)

func clear_transfer_handoffs() -> void:
	if store != null:
		store.clear_transfer_handoffs()

func has_transfer_handoff(item: ZoneItemControl) -> bool:
	return store.has_transfer_handoff(item) if store != null else false

func get_transfer_handoff_count() -> int:
	return store.get_transfer_handoff_count() if store != null else 0
