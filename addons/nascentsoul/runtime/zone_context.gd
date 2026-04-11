class_name ZoneContext extends RefCounted

# Internal zone/config/runtime-state view shared by services. External code
# should not depend on this type directly.

var zone = null
var config = null
var store: ZoneStore = null
var display_state_cache = null
var transfer_staging = null

var selection_state:
	get:
		return store.selection_state if store != null else null

func _init(p_zone, p_store = null, p_config = null, p_display_state_cache = null, p_transfer_staging = null) -> void:
	attach(p_zone, p_store, p_config, p_display_state_cache, p_transfer_staging)

func attach(p_zone, p_store, p_config, p_display_state_cache = null, p_transfer_staging = null) -> void:
	zone = p_zone
	store = p_store
	config = p_config
	display_state_cache = p_display_state_cache
	transfer_staging = p_transfer_staging

func cleanup() -> void:
	zone = null
	config = null
	store = null
	display_state_cache = null
	transfer_staging = null

func update_config(next_config) -> void:
	config = next_config

func get_store() -> ZoneStore:
	return store

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
	return display_state_cache.get_state(style) if display_state_cache != null else {}

func clear_display_state() -> void:
	if display_state_cache != null:
		display_state_cache.clear(true)

func prune_display_state() -> void:
	if display_state_cache != null:
		display_state_cache.prune()

func consume_transfer_handoff(item: ZoneItemControl) -> Dictionary:
	return transfer_staging.consume_transfer_handoff(item) if transfer_staging != null else {}

func set_transfer_handoff(item: ZoneItemControl, snapshot: Dictionary) -> void:
	if transfer_staging != null:
		transfer_staging.set_transfer_handoff(item, snapshot)

func clear_transfer_handoff(item) -> void:
	if transfer_staging != null:
		transfer_staging.clear_transfer_handoff(item)

func clear_transfer_handoffs() -> void:
	if transfer_staging != null:
		transfer_staging.clear_transfer_handoffs()

func has_transfer_handoff(item: ZoneItemControl) -> bool:
	return transfer_staging.has_transfer_handoff(item) if transfer_staging != null else false

func get_transfer_handoff_count() -> int:
	return transfer_staging.get_transfer_handoff_count() if transfer_staging != null else 0

func build_transfer_snapshots(moving_items: Array[ZoneItemControl], drop_position = null, anchor_item: ZoneItemControl = null) -> Dictionary:
	return transfer_staging.build_transfer_snapshots(moving_items, drop_position, anchor_item) if transfer_staging != null else {}

func resolve_programmatic_transfer_global_position(moving_items: Array[ZoneItemControl]):
	return transfer_staging.resolve_programmatic_transfer_global_position(moving_items) if transfer_staging != null else null
