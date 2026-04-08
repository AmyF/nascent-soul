class_name ExampleSupport extends RefCounted

const CARD_SIZE := Vector2(120, 180)

static var _front_texture: Texture2D = null
static var _back_texture: Texture2D = null

static func make_zone(host: Control, zone_name: String, layout_policy: ZoneLayoutPolicy, display_style: ZoneDisplayStyle = null, permission_policy: ZonePermissionPolicy = null, sort_policy: ZoneSortPolicy = null, interaction: ZoneInteraction = null, drag_visual_factory: ZoneDragVisualFactory = null, preset: ZonePreset = null) -> Zone:
	var zone := Zone.new()
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
