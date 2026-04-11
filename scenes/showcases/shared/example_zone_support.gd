class_name ExampleZoneSupport extends RefCounted

static func make_zone(host: Control, zone_name: String, layout_policy: ZoneLayoutPolicy, display_style: ZoneDisplayStyle = null, transfer_policy: ZoneTransferPolicy = null, sort_policy: ZoneSortPolicy = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, config: ZoneConfig = null) -> Zone:
	var zone := CardZone.new()
	_configure_zone_node(zone, host, zone_name, make_card_zone_config(layout_policy, display_style, transfer_policy, sort_policy, interaction, drag_visual_factory, config))
	return zone

static func make_battlefield_zone(host: Control, zone_name: String, space_model: ZoneSpaceModel, transfer_policy: ZoneTransferPolicy = null, display_style: ZoneDisplayStyle = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, config: ZoneConfig = null) -> BattlefieldZone:
	var zone := BattlefieldZone.new()
	_configure_zone_node(zone, host, zone_name, make_battlefield_zone_config(space_model, transfer_policy, display_style, interaction, drag_visual_factory, config))
	return zone

static func make_card_zone_config(
	layout_policy: ZoneLayoutPolicy,
	display_style: ZoneDisplayStyle = null,
	transfer_policy: ZoneTransferPolicy = null,
	sort_policy: ZoneSortPolicy = null,
	interaction: ZoneInteraction = null,
	drag_visual_factory: ZoneDragVisualFactory = null,
	base_config: ZoneConfig = null
) -> ZoneConfig:
	var resolved: ZoneConfig = base_config.duplicate_config() if base_config != null else ZoneConfig.new()
	resolved = resolved.filled_from(ZoneConfig.make_card_defaults())
	return resolved.with_overrides(_make_card_zone_overrides(layout_policy, display_style, transfer_policy, sort_policy, interaction, drag_visual_factory))

static func make_battlefield_zone_config(
	space_model: ZoneSpaceModel,
	transfer_policy: ZoneTransferPolicy = null,
	display_style: ZoneDisplayStyle = null,
	interaction: ZoneInteraction = null,
	drag_visual_factory: ZoneDragVisualFactory = null,
	base_config: ZoneConfig = null
) -> ZoneConfig:
	var resolved: ZoneConfig = base_config.duplicate_config() if base_config != null else ZoneConfig.new()
	resolved = resolved.filled_from(ZoneConfig.make_battlefield_defaults(space_model))
	return resolved.with_overrides(_make_battlefield_zone_overrides(space_model, transfer_policy, display_style, interaction, drag_visual_factory))

static func get_zone_config(zone: Zone) -> ZoneConfig:
	if zone == null:
		return null
	if zone.config != null:
		return zone.config
	if zone is BattlefieldZone:
		return ZoneConfig.make_battlefield_defaults()
	return ZoneConfig.make_card_defaults()

static func set_zone_layout_policy(zone: Zone, layout_policy: ZoneLayoutPolicy) -> void:
	_assign_zone_config_overrides(zone, {"layout_policy": layout_policy})

static func set_zone_display_style(zone: Zone, display_style: ZoneDisplayStyle) -> void:
	_assign_zone_config_overrides(zone, {"display_style": display_style})

static func set_zone_interaction(zone: Zone, interaction: ZoneInteraction) -> void:
	_assign_zone_config_overrides(zone, {"interaction": interaction})

static func set_zone_sort_policy(zone: Zone, sort_policy: ZoneSortPolicy) -> void:
	_assign_zone_config_overrides(zone, {"sort_policy": sort_policy})

static func set_zone_transfer_policy(zone: Zone, transfer_policy: ZoneTransferPolicy) -> void:
	_assign_zone_config_overrides(zone, {"transfer_policy": transfer_policy})

static func set_zone_drag_visual_factory(zone: Zone, drag_visual_factory: ZoneDragVisualFactory) -> void:
	_assign_zone_config_overrides(zone, {"drag_visual_factory": drag_visual_factory})

static func set_zone_space_model(zone: Zone, space_model: ZoneSpaceModel) -> void:
	_assign_zone_config_overrides(zone, {"space_model": space_model})

static func set_zone_targeting_style(zone: Zone, targeting_style: ZoneTargetingStyle) -> void:
	_assign_zone_config_overrides(zone, {"targeting_style": targeting_style})

static func set_zone_targeting_policy(zone: Zone, targeting_policy: ZoneTargetingPolicy) -> void:
	_assign_zone_config_overrides(zone, {"targeting_policy": targeting_policy})

static func get_zone_layout_policy(zone: Zone) -> ZoneLayoutPolicy:
	return zone.get_layout_policy() if zone != null else null

static func get_zone_display_style(zone: Zone) -> ZoneDisplayStyle:
	return zone.get_display_style() if zone != null else null

static func get_zone_interaction(zone: Zone) -> ZoneInteraction:
	return zone.get_interaction() if zone != null else null

static func get_zone_sort_policy(zone: Zone) -> ZoneSortPolicy:
	return zone.get_sort_policy() if zone != null else null

static func get_zone_transfer_policy(zone: Zone) -> ZoneTransferPolicy:
	return zone.get_transfer_policy() if zone != null else null

static func get_zone_drag_visual_factory(zone: Zone) -> ZoneDragVisualFactory:
	return zone.get_drag_visual_factory() if zone != null else null

static func get_zone_space_model(zone: Zone) -> ZoneSpaceModel:
	return zone.get_space_model() if zone != null else null

static func get_zone_targeting_style(zone: Zone) -> ZoneTargetingStyle:
	return zone.get_targeting_style() if zone != null else null

static func get_zone_targeting_policy(zone: Zone) -> ZoneTargetingPolicy:
	return zone.get_targeting_policy() if zone != null else null

static func move_item(source_zone: Zone, item: Control, target_zone: Zone, placement_target: ZonePlacementTarget = null) -> bool:
	if source_zone == null or target_zone == null or not is_instance_valid(item) or item is not ZoneItemControl:
		return false
	var moving_items: Array[ZoneItemControl] = [item as ZoneItemControl]
	return source_zone.perform_transfer(ZoneTransferCommand.transfer_between(source_zone, target_zone, moving_items, placement_target))

static func transfer_items(source_zone: Zone, items: Array, target_zone: Zone, placement_target: ZonePlacementTarget = null) -> bool:
	var moving_items = _typed_zone_items(items)
	if source_zone == null or target_zone == null or moving_items.is_empty():
		return false
	return source_zone.perform_transfer(ZoneTransferCommand.transfer_between(source_zone, target_zone, moving_items, placement_target))

static func reorder_items(zone: Zone, items: Array, placement_target: ZonePlacementTarget = null) -> bool:
	var moving_items = _typed_zone_items(items)
	if zone == null or moving_items.is_empty():
		return false
	return zone.perform_transfer(ZoneTransferCommand.reorder_within(zone, moving_items, placement_target))

static func begin_item_targeting(zone: Zone, item: Control, intent: ZoneTargetingIntent = null, pointer_global_position: Vector2 = Vector2.ZERO) -> bool:
	if zone == null or not is_instance_valid(item) or item is not ZoneItemControl:
		return false
	return zone.begin_targeting(ZoneTargetingCommand.explicit_for_item(zone, item as ZoneItemControl, intent, pointer_global_position))

static func get_first_open_target(zone: Zone, item: Control) -> ZonePlacementTarget:
	if zone == null:
		return ZonePlacementTarget.invalid()
	return zone.get_first_open_target(item)

static func _configure_zone_node(zone: Zone, host: Control, zone_name: String, config: ZoneConfig) -> void:
	zone.name = zone_name
	zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone.offset_left = 0.0
	zone.offset_top = 0.0
	zone.offset_right = 0.0
	zone.offset_bottom = 0.0
	zone.custom_minimum_size = host.custom_minimum_size
	zone.config = config
	host.add_child(zone)

static func _assign_zone_config_overrides(zone: Zone, overrides: Dictionary) -> void:
	var next_config = get_zone_config(zone)
	if next_config == null:
		return
	zone.config = next_config.with_overrides(overrides)

static func _make_card_zone_overrides(layout_policy: ZoneLayoutPolicy, display_style: ZoneDisplayStyle, transfer_policy: ZoneTransferPolicy, sort_policy: ZoneSortPolicy, interaction: ZoneInteraction, drag_visual_factory: ZoneDragVisualFactory) -> Dictionary:
	var overrides := {}
	if layout_policy != null:
		overrides["layout_policy"] = layout_policy
	if display_style != null:
		overrides["display_style"] = display_style
	if transfer_policy != null:
		overrides["transfer_policy"] = transfer_policy
	if sort_policy != null:
		overrides["sort_policy"] = sort_policy
	if interaction != null:
		overrides["interaction"] = interaction
	if drag_visual_factory != null:
		overrides["drag_visual_factory"] = drag_visual_factory
	return overrides

static func _make_battlefield_zone_overrides(space_model: ZoneSpaceModel, transfer_policy: ZoneTransferPolicy, display_style: ZoneDisplayStyle, interaction: ZoneInteraction, drag_visual_factory: ZoneDragVisualFactory) -> Dictionary:
	var overrides := {}
	if space_model != null:
		overrides["space_model"] = space_model
	if transfer_policy != null:
		overrides["transfer_policy"] = transfer_policy
	if display_style != null:
		overrides["display_style"] = display_style
	if interaction != null:
		overrides["interaction"] = interaction
	if drag_visual_factory != null:
		overrides["drag_visual_factory"] = drag_visual_factory
	return overrides

static func _typed_zone_items(items: Array) -> Array[ZoneItemControl]:
	var typed_items: Array[ZoneItemControl] = []
	for item in items:
		if item is ZoneItemControl and is_instance_valid(item):
			typed_items.append(item as ZoneItemControl)
	return typed_items
