class_name ExampleSupport extends RefCounted

const CARD_SIZE := Vector2(120, 180)
const BODY_TEXT_COLOR := Color(0.90, 0.93, 0.98, 0.92)
const MUTED_TEXT_COLOR := Color(0.74, 0.80, 0.88, 0.86)
const CARD_BG_COLOR := Color(0.07, 0.09, 0.13, 0.96)

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
	card.set_meta("example_primary_tag", tags[0] if not tags.is_empty() else "card")
	return card

static func configure_zone(zone: Zone, accent: Color = Color(0.22, 0.25, 0.32, 1.0), clip_contents: bool = false) -> void:
	zone.clip_contents = clip_contents
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
	zone.add_theme_stylebox_override("panel", style)
	zone.queue_redraw()

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

static func make_info_card(name: String, accent: Color, title: String, body: String, badge_texts: Array = [], eyebrow: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.name = name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG_COLOR
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.content_margin_left = 18
	style.content_margin_top = 16
	style.content_margin_right = 18
	style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)

	if eyebrow != "":
		var eyebrow_label := Label.new()
		eyebrow_label.name = "EyebrowLabel"
		eyebrow_label.text = eyebrow
		eyebrow_label.add_theme_color_override("font_color", accent.lightened(0.3))
		eyebrow_label.add_theme_font_size_override("font_size", 12)
		content.add_child(eyebrow_label)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.text = title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	title_label.add_theme_font_size_override("font_size", 18)
	content.add_child(title_label)

	if not badge_texts.is_empty():
		var badge_row := HBoxContainer.new()
		badge_row.name = "BadgeRow"
		badge_row.add_theme_constant_override("separation", 8)
		content.add_child(badge_row)
		for index in range(badge_texts.size()):
			badge_row.add_child(make_badge("Badge%d" % index, badge_texts[index], accent))

	var body_label := Label.new()
	body_label.name = "BodyLabel"
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", BODY_TEXT_COLOR)
	body_label.add_theme_font_size_override("font_size", 13)
	content.add_child(body_label)
	return card

static func make_compact_info_card(name: String, accent: Color, title: String, body: String, badge_texts: Array = [], eyebrow: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.name = name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG_COLOR
	style.border_color = accent
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 6)
	card.add_child(content)

	if eyebrow != "":
		var eyebrow_label := Label.new()
		eyebrow_label.name = "EyebrowLabel"
		eyebrow_label.text = eyebrow
		eyebrow_label.add_theme_color_override("font_color", accent.lightened(0.3))
		eyebrow_label.add_theme_font_size_override("font_size", 11)
		content.add_child(eyebrow_label)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.text = title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	title_label.add_theme_font_size_override("font_size", 15)
	content.add_child(title_label)

	if not badge_texts.is_empty():
		var badge_row := HBoxContainer.new()
		badge_row.name = "BadgeRow"
		badge_row.add_theme_constant_override("separation", 6)
		content.add_child(badge_row)
		for index in range(badge_texts.size()):
			badge_row.add_child(make_badge("Badge%d" % index, str(badge_texts[index]), accent))

	if body != "":
		var body_label := Label.new()
		body_label.name = "BodyLabel"
		body_label.text = body
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.add_theme_color_override("font_color", BODY_TEXT_COLOR)
		body_label.add_theme_font_size_override("font_size", 12)
		body_label.add_theme_constant_override("line_spacing", 3)
		content.add_child(body_label)
	return card

static func make_badge(name: String, text: String, accent: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = name
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.16)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.52)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left = 999
	style.content_margin_left = 10
	style.content_margin_top = 5
	style.content_margin_right = 10
	style.content_margin_bottom = 5
	badge.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.name = "Label"
	label.text = text
	label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	label.add_theme_font_size_override("font_size", 12)
	badge.add_child(label)
	return badge

static func make_detail_label(name: String, text: String = "") -> Label:
	var label := Label.new()
	label.name = name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", MUTED_TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_constant_override("line_spacing", 2)
	return label

static func style_heading_label(label: Label, accent: Color = Color(0.96, 0.97, 1.0)) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", accent)
	label.add_theme_font_size_override("font_size", 14)

static func style_title_label(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0))
	label.add_theme_font_size_override("font_size", 24)

static func style_status_label(label: Label, accent: Color) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_constant_override("line_spacing", 2)
	label.text = label.text
	label.set_meta("accent_color", accent)

static func style_action_button(button: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.12, 0.16, 0.98)
	normal.border_color = accent
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_right = 12
	normal.corner_radius_bottom_left = 12
	normal.content_margin_left = 12
	normal.content_margin_top = 8
	normal.content_margin_right = 12
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = Color(0.14, 0.17, 0.24, 1.0)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.16, 0.20, 0.28, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0))
	button.add_theme_font_size_override("font_size", 12)

static func insert_child(parent: Node, child: Node, index: int) -> void:
	if child.get_parent() != parent:
		parent.add_child(child)
	parent.move_child(child, clampi(index, 0, max(parent.get_child_count() - 1, 0)))

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
