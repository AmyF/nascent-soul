class_name ExampleSupport extends RefCounted

const CARD_SIZE := Vector2(120, 180)
const PIECE_SIZE := Vector2(92, 92)

static var _front_texture: Texture2D = null
static var _back_texture: Texture2D = null

static func make_zone(host: Control, zone_name: String, layout_policy: ZoneLayoutPolicy, display_style: ZoneDisplayStyle = null, transfer_policy: ZoneTransferPolicy = null, sort_policy: ZoneSortPolicy = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, config: ZoneConfig = null) -> Zone:
	var zone := CardZone.new()
	zone.name = zone_name
	zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone.offset_left = 0.0
	zone.offset_top = 0.0
	zone.offset_right = 0.0
	zone.offset_bottom = 0.0
	zone.custom_minimum_size = host.custom_minimum_size
	zone.config = make_card_zone_config(layout_policy, display_style, transfer_policy, sort_policy, interaction, drag_visual_factory, config)
	host.add_child(zone)
	return zone

static func make_battlefield_zone(host: Control, zone_name: String, space_model: ZoneSpaceModel, transfer_policy: ZoneTransferPolicy = null, display_style: ZoneDisplayStyle = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, config: ZoneConfig = null) -> BattlefieldZone:
	var zone := BattlefieldZone.new()
	zone.name = zone_name
	zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone.offset_left = 0.0
	zone.offset_top = 0.0
	zone.offset_right = 0.0
	zone.offset_bottom = 0.0
	zone.custom_minimum_size = host.custom_minimum_size
	zone.config = make_battlefield_zone_config(space_model, transfer_policy, display_style, interaction, drag_visual_factory, config)
	host.add_child(zone)
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
	return resolved.with_overrides(overrides)

static func make_battlefield_zone_config(
	space_model: ZoneSpaceModel,
	transfer_policy: ZoneTransferPolicy = null,
	display_style: ZoneDisplayStyle = null,
	interaction: ZoneInteraction = null,
	drag_visual_factory: ZoneDragVisualFactory = null,
	base_config: ZoneConfig = null
) -> ZoneConfig:
	var defaults = ZoneConfig.make_battlefield_defaults(space_model)
	var resolved: ZoneConfig = base_config.duplicate_config() if base_config != null else ZoneConfig.new()
	resolved = resolved.filled_from(defaults)
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
	return resolved.with_overrides(overrides)

static func get_zone_config(zone: Zone) -> ZoneConfig:
	if zone == null:
		return null
	if zone.config != null:
		return zone.config
	if zone is BattlefieldZone:
		return ZoneConfig.make_battlefield_defaults()
	return ZoneConfig.make_card_defaults()

static func _assign_zone_config_overrides(zone: Zone, overrides: Dictionary) -> void:
	var next_config = get_zone_config(zone)
	if next_config == null:
		return
	zone.config = next_config.with_overrides(overrides)

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
	var items: Array[ZoneItemControl] = [item as ZoneItemControl]
	return source_zone.perform_transfer(ZoneTransferCommand.transfer_between(source_zone, target_zone, items, placement_target))

static func transfer_items(source_zone: Zone, items: Array, target_zone: Zone, placement_target: ZonePlacementTarget = null) -> bool:
	if source_zone == null or target_zone == null or items.is_empty():
		return false
	var typed_items: Array[ZoneItemControl] = []
	for item in items:
		if item is ZoneItemControl and is_instance_valid(item):
			typed_items.append(item as ZoneItemControl)
	if typed_items.is_empty():
		return false
	return source_zone.perform_transfer(ZoneTransferCommand.transfer_between(source_zone, target_zone, typed_items, placement_target))

static func reorder_items(zone: Zone, items: Array, placement_target: ZonePlacementTarget = null) -> bool:
	if zone == null or items.is_empty():
		return false
	var typed_items: Array[ZoneItemControl] = []
	for item in items:
		if item is ZoneItemControl and is_instance_valid(item):
			typed_items.append(item as ZoneItemControl)
	if typed_items.is_empty():
		return false
	return zone.perform_transfer(ZoneTransferCommand.reorder_within(zone, typed_items, placement_target))

static func begin_item_targeting(zone: Zone, item: Control, intent: ZoneTargetingIntent = null, pointer_global_position: Vector2 = Vector2.ZERO) -> bool:
	if zone == null or not is_instance_valid(item) or item is not ZoneItemControl:
		return false
	return zone.begin_targeting(ZoneTargetingCommand.explicit_for_item(zone, item as ZoneItemControl, intent, pointer_global_position))

static func get_first_open_target(zone: Zone, item: Control) -> ZonePlacementTarget:
	if zone == null:
		return ZonePlacementTarget.invalid()
	return zone.get_first_open_target(item)

static func make_card(title: String, cost: int, tags, face_up: bool = true, highlighted: bool = false) -> ZoneCard:
	var normalized_tags := _normalize_tags(tags)
	var data := CardData.new()
	data.id = title.to_lower().replace(" ", "_")
	data.title = title
	data.cost = cost
	data.tags = PackedStringArray(normalized_tags)
	data.front_texture = _load_front_texture()
	data.back_texture = _load_back_texture()
	data.custom_data = {
		"cost": cost,
		"tags": normalized_tags
	}
	var card := ZoneCard.new()
	card.name = title
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	card.data = data
	card.face_up = face_up
	card.highlighted = highlighted
	card.zone_item_metadata = {
		"example_cost": cost,
		"example_tags": normalized_tags,
		"example_primary_tag": normalized_tags[0] if not normalized_tags.is_empty() else "card"
	}
	card.set_meta("example_cost", cost)
	card.set_meta("example_tags", normalized_tags)
	card.set_meta("example_primary_tag", normalized_tags[0] if not normalized_tags.is_empty() else "card")
	return card

static func add_cards_from_specs(zone: Zone, specs: Array[ExampleCardSpec], face_up: bool = true, highlighted: bool = false) -> void:
	for spec in specs:
		if spec == null:
			continue
		zone.add_item(make_card(spec.title, spec.cost, spec.tags, face_up, highlighted))

static func make_piece(title: String, team: String, attack: int, defense: int) -> ZonePiece:
	var data := PieceData.new()
	data.id = title.to_lower().replace(" ", "_")
	data.title = title
	data.team = team
	data.attack = attack
	data.defense = defense
	data.texture = _load_front_texture()
	var piece := ZonePiece.new()
	piece.name = title
	piece.custom_minimum_size = PIECE_SIZE
	piece.size = piece.custom_minimum_size
	piece.data = data
	piece.zone_item_metadata = {
		"target_team": team,
		"piece_team": team,
		"piece_attack": attack,
		"piece_defense": defense
	}
	return piece

static func bilingual(zh: String, en: String) -> String:
	if zh == "":
		return en
	if en == "":
		return zh
	return "%s\n%s" % [zh, en]

static func compact_bilingual(zh: String, en: String, separator: String = " / ") -> String:
	if zh == "":
		return en
	if en == "":
		return zh
	return "%s%s%s" % [zh, separator, en]

static func describe_target(target) -> String:
	if target == null:
		return "none"
	if target is ZonePlacementTarget:
		var placement_target = target as ZonePlacementTarget
		if placement_target.is_linear():
			return str(placement_target.linear_index)
		return placement_target.describe()
	if target is int:
		return str(target)
	return str(target)

static func _load_front_texture() -> Texture2D:
	if _front_texture == null:
		_front_texture = load("res://assets/card/card_front.png")
	return _front_texture

static func _load_back_texture() -> Texture2D:
	if _back_texture == null:
		_back_texture = load("res://assets/card/card_back.png")
	return _back_texture

static func clear_card_texture_cache() -> void:
	_front_texture = null
	_back_texture = null

static func _normalize_tags(tags) -> Array[String]:
	var normalized: Array[String] = []
	if tags is PackedStringArray:
		normalized.assign(tags)
		return normalized
	if tags is Array:
		for tag in tags:
			normalized.append(str(tag))
	return normalized
