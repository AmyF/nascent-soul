class_name ExampleSupport extends RefCounted

# Legacy facade. Prefer ExampleZoneSupport or ExampleItemSupport for new code.
const ExampleItemSupport = preload("res://scenes/examples/shared/example_item_support.gd")
const ExampleZoneSupport = preload("res://scenes/examples/shared/example_zone_support.gd")

static func make_zone(host: Control, zone_name: String, layout_policy: ZoneLayoutPolicy, display_style: ZoneDisplayStyle = null, transfer_policy: ZoneTransferPolicy = null, sort_policy: ZoneSortPolicy = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, config: ZoneConfig = null) -> Zone:
	return ExampleZoneSupport.make_zone(host, zone_name, layout_policy, display_style, transfer_policy, sort_policy, interaction, drag_visual_factory, config)

static func make_battlefield_zone(host: Control, zone_name: String, space_model: ZoneSpaceModel, transfer_policy: ZoneTransferPolicy = null, display_style: ZoneDisplayStyle = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, config: ZoneConfig = null) -> BattlefieldZone:
	return ExampleZoneSupport.make_battlefield_zone(host, zone_name, space_model, transfer_policy, display_style, interaction, drag_visual_factory, config)

static func make_card_zone_config(layout_policy: ZoneLayoutPolicy, display_style: ZoneDisplayStyle = null, transfer_policy: ZoneTransferPolicy = null, sort_policy: ZoneSortPolicy = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, base_config: ZoneConfig = null) -> ZoneConfig:
	return ExampleZoneSupport.make_card_zone_config(layout_policy, display_style, transfer_policy, sort_policy, interaction, drag_visual_factory, base_config)

static func make_battlefield_zone_config(space_model: ZoneSpaceModel, transfer_policy: ZoneTransferPolicy = null, display_style: ZoneDisplayStyle = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, base_config: ZoneConfig = null) -> ZoneConfig:
	return ExampleZoneSupport.make_battlefield_zone_config(space_model, transfer_policy, display_style, interaction, drag_visual_factory, base_config)

static func get_zone_config(zone: Zone) -> ZoneConfig:
	return ExampleZoneSupport.get_zone_config(zone)

static func set_zone_layout_policy(zone: Zone, layout_policy: ZoneLayoutPolicy) -> void:
	ExampleZoneSupport.set_zone_layout_policy(zone, layout_policy)

static func set_zone_display_style(zone: Zone, display_style: ZoneDisplayStyle) -> void:
	ExampleZoneSupport.set_zone_display_style(zone, display_style)

static func set_zone_interaction(zone: Zone, interaction: ZoneInteraction) -> void:
	ExampleZoneSupport.set_zone_interaction(zone, interaction)

static func set_zone_sort_policy(zone: Zone, sort_policy: ZoneSortPolicy) -> void:
	ExampleZoneSupport.set_zone_sort_policy(zone, sort_policy)

static func set_zone_transfer_policy(zone: Zone, transfer_policy: ZoneTransferPolicy) -> void:
	ExampleZoneSupport.set_zone_transfer_policy(zone, transfer_policy)

static func set_zone_drag_visual_factory(zone: Zone, drag_visual_factory: ZoneDragVisualFactory) -> void:
	ExampleZoneSupport.set_zone_drag_visual_factory(zone, drag_visual_factory)

static func set_zone_space_model(zone: Zone, space_model: ZoneSpaceModel) -> void:
	ExampleZoneSupport.set_zone_space_model(zone, space_model)

static func set_zone_targeting_style(zone: Zone, targeting_style: ZoneTargetingStyle) -> void:
	ExampleZoneSupport.set_zone_targeting_style(zone, targeting_style)

static func set_zone_targeting_policy(zone: Zone, targeting_policy: ZoneTargetingPolicy) -> void:
	ExampleZoneSupport.set_zone_targeting_policy(zone, targeting_policy)

static func get_zone_layout_policy(zone: Zone) -> ZoneLayoutPolicy:
	return ExampleZoneSupport.get_zone_layout_policy(zone)

static func get_zone_display_style(zone: Zone) -> ZoneDisplayStyle:
	return ExampleZoneSupport.get_zone_display_style(zone)

static func get_zone_interaction(zone: Zone) -> ZoneInteraction:
	return ExampleZoneSupport.get_zone_interaction(zone)

static func get_zone_sort_policy(zone: Zone) -> ZoneSortPolicy:
	return ExampleZoneSupport.get_zone_sort_policy(zone)

static func get_zone_transfer_policy(zone: Zone) -> ZoneTransferPolicy:
	return ExampleZoneSupport.get_zone_transfer_policy(zone)

static func get_zone_drag_visual_factory(zone: Zone) -> ZoneDragVisualFactory:
	return ExampleZoneSupport.get_zone_drag_visual_factory(zone)

static func get_zone_space_model(zone: Zone) -> ZoneSpaceModel:
	return ExampleZoneSupport.get_zone_space_model(zone)

static func get_zone_targeting_style(zone: Zone) -> ZoneTargetingStyle:
	return ExampleZoneSupport.get_zone_targeting_style(zone)

static func get_zone_targeting_policy(zone: Zone) -> ZoneTargetingPolicy:
	return ExampleZoneSupport.get_zone_targeting_policy(zone)

static func move_item(source_zone: Zone, item: Control, target_zone: Zone, placement_target: ZonePlacementTarget = null) -> bool:
	return ExampleZoneSupport.move_item(source_zone, item, target_zone, placement_target)

static func transfer_items(source_zone: Zone, items: Array, target_zone: Zone, placement_target: ZonePlacementTarget = null) -> bool:
	return ExampleZoneSupport.transfer_items(source_zone, items, target_zone, placement_target)

static func reorder_items(zone: Zone, items: Array, placement_target: ZonePlacementTarget = null) -> bool:
	return ExampleZoneSupport.reorder_items(zone, items, placement_target)

static func begin_item_targeting(zone: Zone, item: Control, intent: ZoneTargetingIntent = null, pointer_global_position: Vector2 = Vector2.ZERO) -> bool:
	return ExampleZoneSupport.begin_item_targeting(zone, item, intent, pointer_global_position)

static func get_first_open_target(zone: Zone, item: Control) -> ZonePlacementTarget:
	return ExampleZoneSupport.get_first_open_target(zone, item)

static func make_card(title: String, cost: int, tags, face_up: bool = true, highlighted: bool = false) -> ZoneCard:
	return ExampleItemSupport.make_card(title, cost, tags, face_up, highlighted)

static func add_cards_from_specs(zone: Zone, specs: Array, face_up: bool = true, highlighted: bool = false) -> void:
	ExampleItemSupport.add_cards_from_specs(zone, specs, face_up, highlighted)

static func make_piece(title: String, team: String, attack: int, defense: int) -> ZonePiece:
	return ExampleItemSupport.make_piece(title, team, attack, defense)

static func clear_card_texture_cache() -> void:
	ExampleItemSupport.clear_card_texture_cache()
