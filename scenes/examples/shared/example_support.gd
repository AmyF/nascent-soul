class_name ExampleSupport extends RefCounted

const CARD_SIZE := Vector2(120, 180)

static var _front_texture: Texture2D = null
static var _back_texture: Texture2D = null

static func make_zone(container: Control, zone_name: String, layout_policy: ZoneLayoutPolicy, display_style: ZoneDisplayStyle = null, permission_policy: ZonePermissionPolicy = null, sort_policy: ZoneSortPolicy = null, interaction: ZoneInteraction = null) -> Zone:
	var zone := Zone.new()
	zone.name = zone_name
	zone.container = container
	zone.layout_policy = layout_policy
	zone.display_style = display_style if display_style != null else ZoneCardDisplay.new()
	zone.permission_policy = permission_policy if permission_policy != null else ZoneAllowAllPermission.new()
	zone.sort_policy = sort_policy if sort_policy != null else ZoneManualSort.new()
	zone.interaction = interaction if interaction != null else ZoneInteraction.new()
	container.add_child(zone)
	return zone

static func make_card(title: String, cost: int, tags: Array, face_up: bool = true, highlighted: bool = false) -> ZoneCard:
	var data := CardData.new()
	data.id = title.to_lower().replace(" ", "_")
	data.title = title
	data.cost = cost
	data.tags = PackedStringArray(tags)
	data.front_texture = _load_front_texture()
	data.back_texture = _load_back_texture()
	data.custom_data = {
		"cost": cost,
		"tags": tags
	}
	var card := ZoneCard.new()
	card.name = title
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	card.data = data
	card.face_up = face_up
	card.highlighted = highlighted
	card.set_meta("example_cost", cost)
	card.set_meta("example_tags", tags)
	return card

static func configure_panel(panel: Panel, accent: Color = Color(0.22, 0.25, 0.32, 1.0), clip_contents: bool = false) -> void:
	panel.clip_contents = clip_contents
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.96)
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	panel.add_theme_stylebox_override("panel", style)

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
