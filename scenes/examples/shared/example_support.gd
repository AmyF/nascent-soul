class_name ExampleSupport extends RefCounted

const CARD_SIZE := Vector2(120, 180)

static var _front_texture: Texture2D = null
static var _back_texture: Texture2D = null

static func make_zone(host: Control, zone_name: String, layout_policy: ZoneLayoutPolicy, display_style: ZoneDisplayStyle = null, permission_policy: ZoneTransferPolicy = null, sort_policy: ZoneSortPolicy = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, preset: ZonePreset = null) -> Zone:
	var zone := CardZone.new()
	zone.name = zone_name
	zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone.offset_left = 0.0
	zone.offset_top = 0.0
	zone.offset_right = 0.0
	zone.offset_bottom = 0.0
	zone.custom_minimum_size = host.custom_minimum_size
	zone.preset = preset
	zone.layout_policy = layout_policy
	zone.display_style = display_style
	zone.permission_policy = permission_policy
	zone.sort_policy = sort_policy
	zone.interaction = interaction
	zone.drag_visual_factory = drag_visual_factory
	host.add_child(zone)
	return zone

static func make_battlefield_zone(host: Control, zone_name: String, space_model: ZoneSpaceModel, transfer_policy: ZoneTransferPolicy = null, display_style: ZoneDisplayStyle = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, preset: ZonePreset = null) -> BattlefieldZone:
	var zone := BattlefieldZone.new()
	zone.name = zone_name
	zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	zone.offset_left = 0.0
	zone.offset_top = 0.0
	zone.offset_right = 0.0
	zone.offset_bottom = 0.0
	zone.custom_minimum_size = host.custom_minimum_size
	zone.preset = preset
	zone.space_model = space_model
	zone.layout_policy = ZoneBattlefieldLayout.new()
	zone.display_style = display_style
	zone.transfer_policy = transfer_policy
	zone.interaction = interaction
	zone.drag_visual_factory = drag_visual_factory
	host.add_child(zone)
	return zone

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
	piece.custom_minimum_size = Vector2(92, 92)
	piece.size = piece.custom_minimum_size
	piece.data = data
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
			return str(placement_target.slot)
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
