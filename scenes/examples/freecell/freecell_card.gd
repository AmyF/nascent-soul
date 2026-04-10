extends ZoneItemControl

const CARD_SIZE := Vector2(116, 164)

var code: String = ""
var suit: StringName = &""
var rank_value: int = 0
var rank_label: String = ""
var suit_symbol: String = ""
var suit_name: String = ""
var is_red: bool = false

var _hovered_visual: bool = false
var _selected_visual: bool = false
var _panel: Panel = null
var _rank_top_label: Label = null
var _rank_bottom_label: Label = null
var _suit_top_label: Label = null
var _suit_bottom_label: Label = null
var _center_suit_label: Label = null
var _overlay: ColorRect = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = CARD_SIZE
	if size == Vector2.ZERO:
		size = custom_minimum_size
	_ensure_nodes()
	_refresh_visuals()

func configure(p_code: String, p_suit: StringName, p_rank_value: int, p_rank_label: String, p_suit_symbol: String, p_suit_name: String, p_is_red: bool) -> void:
	code = p_code
	name = p_code
	suit = p_suit
	rank_value = p_rank_value
	rank_label = p_rank_label
	suit_symbol = p_suit_symbol
	suit_name = p_suit_name
	is_red = p_is_red
	set_zone_item_metadata({
		"card_code": code,
		"suit": String(suit),
		"rank_value": rank_value,
		"rank_label": rank_label,
		"is_red": is_red
	})
	_refresh_visuals()

func create_zone_drag_ghost(_context: ZoneContext) -> Control:
	var ghost := Panel.new()
	ghost.custom_minimum_size = _resolved_card_size()
	ghost.size = ghost.custom_minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.08)
	style.border_color = _accent_color()
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	ghost.add_theme_stylebox_override("panel", style)
	return ghost

func create_zone_group_drag_ghost(context: ZoneContext, source_items: Array[ZoneItemControl], anchor_item: ZoneItemControl) -> Control:
	var cards = _group_cards(source_items, anchor_item)
	if cards.size() <= 1:
		return create_zone_drag_ghost(context)
	return _build_group_visual(context, cards, anchor_item, false)

func create_zone_drag_proxy(_context: ZoneContext) -> Control:
	var proxy = duplicate(0)
	if proxy is Control:
		var control_proxy := proxy as Control
		control_proxy.modulate.a = 0.96
		control_proxy.global_position = global_position
		return control_proxy
	return super.create_zone_drag_proxy(_context)

func create_zone_group_drag_proxy(context: ZoneContext, source_items: Array[ZoneItemControl], anchor_item: ZoneItemControl) -> Control:
	var cards = _group_cards(source_items, anchor_item)
	if cards.size() <= 1:
		return create_zone_drag_proxy(context)
	return _build_group_visual(context, cards, anchor_item, true)

func apply_zone_visual_state(state: ZoneItemVisualState) -> void:
	var next_state = state if state != null else ZoneItemVisualState.new()
	var changed = _hovered_visual != next_state.hovered or _selected_visual != next_state.selected
	super.apply_zone_visual_state(next_state)
	_hovered_visual = next_state.hovered
	_selected_visual = next_state.selected
	if changed:
		_refresh_visuals()

func display_name() -> String:
	return "%s%s" % [rank_label, suit_symbol]

func _ensure_nodes() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = Panel.new()
		_panel.name = "CardPanel"
		_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_panel)
	if _rank_top_label == null or not is_instance_valid(_rank_top_label):
		_rank_top_label = Label.new()
		_rank_top_label.name = "RankTopLabel"
		_rank_top_label.offset_left = 10.0
		_rank_top_label.offset_top = 8.0
		_rank_top_label.offset_right = 40.0
		_rank_top_label.offset_bottom = 30.0
		_rank_top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_rank_top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_rank_top_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_rank_top_label)
	if _suit_top_label == null or not is_instance_valid(_suit_top_label):
		_suit_top_label = Label.new()
		_suit_top_label.name = "SuitTopLabel"
		_suit_top_label.offset_left = 10.0
		_suit_top_label.offset_top = 28.0
		_suit_top_label.offset_right = 40.0
		_suit_top_label.offset_bottom = 50.0
		_suit_top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_suit_top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_suit_top_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_suit_top_label)
	if _rank_bottom_label == null or not is_instance_valid(_rank_bottom_label):
		_rank_bottom_label = Label.new()
		_rank_bottom_label.name = "RankBottomLabel"
		_rank_bottom_label.anchor_left = 1.0
		_rank_bottom_label.anchor_right = 1.0
		_rank_bottom_label.anchor_top = 1.0
		_rank_bottom_label.anchor_bottom = 1.0
		_rank_bottom_label.offset_left = -40.0
		_rank_bottom_label.offset_top = -50.0
		_rank_bottom_label.offset_right = -10.0
		_rank_bottom_label.offset_bottom = -28.0
		_rank_bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_rank_bottom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_rank_bottom_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_rank_bottom_label)
	if _suit_bottom_label == null or not is_instance_valid(_suit_bottom_label):
		_suit_bottom_label = Label.new()
		_suit_bottom_label.name = "SuitBottomLabel"
		_suit_bottom_label.anchor_left = 1.0
		_suit_bottom_label.anchor_right = 1.0
		_suit_bottom_label.anchor_top = 1.0
		_suit_bottom_label.anchor_bottom = 1.0
		_suit_bottom_label.offset_left = -40.0
		_suit_bottom_label.offset_top = -30.0
		_suit_bottom_label.offset_right = -10.0
		_suit_bottom_label.offset_bottom = -8.0
		_suit_bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_suit_bottom_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_suit_bottom_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_suit_bottom_label)
	if _center_suit_label == null or not is_instance_valid(_center_suit_label):
		_center_suit_label = Label.new()
		_center_suit_label.name = "CenterSuitLabel"
		_center_suit_label.anchor_right = 1.0
		_center_suit_label.anchor_bottom = 1.0
		_center_suit_label.offset_left = 12.0
		_center_suit_label.offset_top = 34.0
		_center_suit_label.offset_right = -12.0
		_center_suit_label.offset_bottom = -34.0
		_center_suit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_center_suit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_center_suit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_center_suit_label)
	if _overlay == null or not is_instance_valid(_overlay):
		_overlay = ColorRect.new()
		_overlay.name = "CardOverlay"
		_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_overlay)

func _refresh_visuals() -> void:
	if not is_node_ready():
		return
	_ensure_nodes()
	var accent = _accent_color()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.98, 0.96, 1.0)
	style.border_color = accent if _selected_visual else Color(0.24, 0.28, 0.34, 0.9)
	if _hovered_visual and not _selected_visual:
		style.border_color = Color(accent.r, accent.g, accent.b, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	_panel.add_theme_stylebox_override("panel", style)

	for label in [_rank_top_label, _rank_bottom_label]:
		label.text = rank_label
		label.add_theme_color_override("font_color", accent)
		label.add_theme_font_size_override("font_size", 20)
	for label in [_suit_top_label, _suit_bottom_label]:
		label.text = suit_symbol
		label.add_theme_color_override("font_color", accent)
		label.add_theme_font_size_override("font_size", 18)
	_center_suit_label.text = suit_symbol
	_center_suit_label.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.68))
	_center_suit_label.add_theme_font_size_override("font_size", 58)

	var overlay_alpha = 0.0
	if _selected_visual:
		overlay_alpha = 0.20
	elif _hovered_visual:
		overlay_alpha = 0.12
	_overlay.color = Color(accent.r, accent.g, accent.b, overlay_alpha)
	_overlay.visible = overlay_alpha > 0.0

func _accent_color() -> Color:
	return Color(0.74, 0.18, 0.22, 1.0) if is_red else Color(0.14, 0.19, 0.26, 1.0)

func _resolved_card_size() -> Vector2:
	if size != Vector2.ZERO:
		return size
	if custom_minimum_size != Vector2.ZERO:
		return custom_minimum_size
	return CARD_SIZE

func _group_cards(source_items: Array[ZoneItemControl], anchor_item: ZoneItemControl) -> Array[ZoneItemControl]:
	var cards: Array[ZoneItemControl] = []
	var has_anchor = false
	for item in source_items:
		if item is not ZoneItemControl or not is_instance_valid(item):
			continue
		cards.append(item as ZoneItemControl)
		if item == anchor_item:
			has_anchor = true
	if cards.is_empty():
		return cards
	if not has_anchor:
		var anchor_card = anchor_item as ZoneItemControl
		if is_instance_valid(anchor_card):
			cards = [anchor_card]
	return cards

func _build_group_visual(context: ZoneContext, cards: Array[ZoneItemControl], anchor_item: ZoneItemControl, use_proxy: bool) -> Control:
	var anchor_card = anchor_item as ZoneItemControl
	if not is_instance_valid(anchor_card):
		anchor_card = cards[0]
	var root := Control.new()
	root.name = "%s%s" % [anchor_card.name, "GroupProxy" if use_proxy else "GroupGhost"]
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var anchor_global = anchor_card.global_position
	var bounds = Rect2(Vector2.ZERO, _resolved_card_size())
	var added_children = 0
	for card in cards:
		if not is_instance_valid(card):
			continue
		var child = card.create_zone_drag_proxy(context) if use_proxy else card.create_zone_drag_ghost(context)
		if child == null:
			continue
		root.add_child(child)
		child.top_level = false
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		child.position = card.global_position - anchor_global
		var child_size = child.size if child.size != Vector2.ZERO else child.custom_minimum_size
		bounds = bounds.expand(child.position + child_size)
		added_children += 1
	if added_children == 0:
		return create_zone_drag_proxy(context) if use_proxy else create_zone_drag_ghost(context)
	root.custom_minimum_size = bounds.size
	root.size = bounds.size
	return root
