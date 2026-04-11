extends ZoneItemControl

const CARD_SIZE := Vector2(80, 112)
const CARD_FILL := Color(0.99, 0.99, 0.97, 1.0)
const CARD_BORDER := Color(0.10, 0.10, 0.10, 1.0)
const CARD_INNER_BORDER := Color(0.82, 0.84, 0.86, 1.0)
const CARD_SHADOW := Color(0.00, 0.00, 0.00, 0.18)
const CARD_FACE_HIGHLIGHT := Color(1.00, 1.00, 1.00, 0.55)
const CARD_FACE_SHADE := Color(0.92, 0.94, 0.96, 0.35)
const RED_INK := Color(0.71, 0.08, 0.12, 1.0)
const BLACK_INK := Color(0.08, 0.09, 0.11, 1.0)
const FACE_FILL := Color(0.94, 0.95, 0.98, 1.0)
const FACE_BORDER := Color(0.72, 0.76, 0.82, 1.0)
const PIP_LAYOUTS := {
	1: [Vector2(0.50, 0.50)],
	2: [Vector2(0.50, 0.24), Vector2(0.50, 0.76)],
	3: [Vector2(0.50, 0.20), Vector2(0.50, 0.50), Vector2(0.50, 0.80)],
	4: [Vector2(0.31, 0.24), Vector2(0.69, 0.24), Vector2(0.31, 0.76), Vector2(0.69, 0.76)],
	5: [Vector2(0.31, 0.24), Vector2(0.69, 0.24), Vector2(0.50, 0.50), Vector2(0.31, 0.76), Vector2(0.69, 0.76)],
	6: [Vector2(0.31, 0.20), Vector2(0.69, 0.20), Vector2(0.31, 0.50), Vector2(0.69, 0.50), Vector2(0.31, 0.80), Vector2(0.69, 0.80)],
	7: [Vector2(0.31, 0.20), Vector2(0.69, 0.20), Vector2(0.50, 0.36), Vector2(0.31, 0.50), Vector2(0.69, 0.50), Vector2(0.31, 0.80), Vector2(0.69, 0.80)],
	8: [Vector2(0.31, 0.20), Vector2(0.69, 0.20), Vector2(0.50, 0.35), Vector2(0.31, 0.50), Vector2(0.69, 0.50), Vector2(0.50, 0.65), Vector2(0.31, 0.80), Vector2(0.69, 0.80)],
	9: [Vector2(0.31, 0.20), Vector2(0.69, 0.20), Vector2(0.50, 0.32), Vector2(0.31, 0.50), Vector2(0.69, 0.50), Vector2(0.50, 0.50), Vector2(0.31, 0.80), Vector2(0.69, 0.80), Vector2(0.50, 0.68)],
	10: [Vector2(0.31, 0.18), Vector2(0.69, 0.18), Vector2(0.31, 0.34), Vector2(0.69, 0.34), Vector2(0.31, 0.50), Vector2(0.69, 0.50), Vector2(0.31, 0.66), Vector2(0.69, 0.66), Vector2(0.31, 0.82), Vector2(0.69, 0.82)]
}

var code: String = ""
var suit: StringName = &""
var rank_value: int = 0
var rank_label: String = ""
var suit_symbol: String = ""
var suit_name: String = ""
var is_red: bool = false

var _hovered_visual: bool = false
var _selected_visual: bool = false
var _overlay: ColorRect = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = CARD_SIZE
	if size == Vector2.ZERO:
		size = custom_minimum_size
	_ensure_overlay()
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
	style.bg_color = Color(1.0, 1.0, 1.0, 0.10)
	style.border_color = _ink_color()
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	ghost.add_theme_stylebox_override("panel", style)
	return ghost

func create_zone_group_drag_ghost(context: ZoneContext, source_items: Array[ZoneItemControl], anchor_item: ZoneItemControl) -> Control:
	var cards = _group_cards(source_items, anchor_item)
	if cards.size() <= 1:
		return create_zone_drag_ghost(context)
	return _build_group_visual(context, cards, anchor_item, false)

func create_zone_drag_proxy(_context: ZoneContext) -> Control:
	var proxy = _duplicate_card()
	if proxy is Control:
		var proxy_control := proxy as Control
		proxy_control.modulate.a = 0.96
		return proxy_control
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

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, _resolved_card_size())
	if rect.size == Vector2.ZERO:
		return
	_draw_card_shell(rect)
	_draw_corners(rect)
	if rank_value >= 11:
		_draw_face_card(rect)
	elif rank_value == 1:
		_draw_center_symbol(rect, suit_symbol, 34, _ink_color())
		_draw_center_symbol(rect, suit_symbol, 54, Color(_ink_color().r, _ink_color().g, _ink_color().b, 0.12))
	else:
		_draw_center_symbol(rect, suit_symbol, 42, Color(_ink_color().r, _ink_color().g, _ink_color().b, 0.08))
		_draw_pips(rect)

func _ensure_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		return
	_overlay = ColorRect.new()
	_overlay.name = "CardOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)

func _refresh_visuals() -> void:
	queue_redraw()
	if not is_node_ready():
		return
	_ensure_overlay()
	var overlay_alpha = 0.0
	if _selected_visual:
		overlay_alpha = 0.18
	elif _hovered_visual:
		overlay_alpha = 0.10
	_overlay.visible = overlay_alpha > 0.0
	_overlay.color = Color(_ink_color().r, _ink_color().g, _ink_color().b, overlay_alpha)

func _draw_corners(rect: Rect2) -> void:
	var font = _fallback_font()
	if font == null:
		return
	var ink = _ink_color()
	var rank_font_size = 15
	var suit_font_size = 15
	var badge_gap = 2.0
	var top_left = rect.position + Vector2(6.0, 3.5)
	var rank_width = font.get_string_size(rank_label, HORIZONTAL_ALIGNMENT_LEFT, -1, rank_font_size).x
	_draw_label(font, rank_label, top_left, rank_font_size, ink)
	_draw_label(font, suit_symbol, top_left + Vector2(rank_width + badge_gap, 0.0), suit_font_size, ink)
	var suit_width = font.get_string_size(suit_symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, suit_font_size).x
	var total_width = rank_width + badge_gap + suit_width
	var bottom_right = rect.end - Vector2(6.0, 6.0)
	var bottom_badge = Vector2(bottom_right.x - total_width, bottom_right.y - 16.0)
	_draw_label(font, rank_label, bottom_badge, rank_font_size, ink)
	_draw_label(font, suit_symbol, bottom_badge + Vector2(rank_width + badge_gap, 0.0), suit_font_size, ink)

func _draw_face_card(rect: Rect2) -> void:
	var inner = rect.grow(-15.0)
	draw_style_box(_make_style_box(FACE_FILL, FACE_BORDER, 4, 1), inner)
	_draw_center_symbol(rect, rank_label, 30, _ink_color(), rect.get_center() + Vector2(0.0, -10.0))
	_draw_center_symbol(rect, suit_symbol, 20, Color(_ink_color().r, _ink_color().g, _ink_color().b, 0.86), rect.get_center() + Vector2(0.0, 14.0))
	_draw_center_symbol(rect, suit_symbol, 44, Color(_ink_color().r, _ink_color().g, _ink_color().b, 0.10))

func _draw_pips(rect: Rect2) -> void:
	var layout = PIP_LAYOUTS.get(rank_value, [])
	var font_size = 18 if rank_value <= 6 else 16
	for point in layout:
		var pip_center = rect.position + Vector2(rect.size.x * point.x, rect.size.y * point.y)
		_draw_center_symbol(rect, suit_symbol, font_size, _ink_color(), pip_center)

func _draw_center_symbol(rect: Rect2, text: String, font_size: int, color: Color, center_override: Variant = null) -> void:
	var font = _fallback_font()
	if font == null or text.is_empty():
		return
	var center = rect.get_center()
	if center_override is Vector2:
		center = center_override as Vector2
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline = center + Vector2(-text_size.x * 0.5, font.get_ascent(font_size) * 0.5 - text_size.y * 0.5)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_label(font: Font, text: String, top_left: Vector2, font_size: int, color: Color) -> void:
	var shadow_baseline = top_left + Vector2(0.5, font.get_ascent(font_size) + 0.5)
	draw_string(font, shadow_baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 1.0, 1.0, 0.20))
	var baseline = top_left + Vector2(0.0, font.get_ascent(font_size))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _border_color() -> Color:
	if _selected_visual:
		return Color(0.96, 0.74, 0.14, 1.0)
	if _hovered_visual:
		return Color(0.33, 0.38, 0.44, 1.0)
	return CARD_BORDER

func _ink_color() -> Color:
	return RED_INK if is_red else BLACK_INK

func _resolved_card_size() -> Vector2:
	if size != Vector2.ZERO:
		return size
	if custom_minimum_size != Vector2.ZERO:
		return custom_minimum_size
	return CARD_SIZE

func _fallback_font() -> Font:
	return ThemeDB.fallback_font

func _duplicate_card() -> Control:
	var clone = get_script().new()
	if clone == null:
		return null
	clone.configure(code, suit, rank_value, rank_label, suit_symbol, suit_name, is_red)
	clone.custom_minimum_size = _resolved_card_size()
	clone.size = clone.custom_minimum_size
	clone.apply_zone_visual_state(ZoneItemVisualState.new())
	return clone

func _draw_card_shell(rect: Rect2) -> void:
	var shadow_rect = Rect2(rect.position + Vector2(1.0, 2.0), rect.size)
	draw_style_box(_make_style_box(CARD_SHADOW, Color(0, 0, 0, 0), 6, 0), shadow_rect)
	draw_style_box(_make_style_box(CARD_FILL, _border_color(), 6, 1), rect)
	draw_style_box(_make_style_box(CARD_FACE_HIGHLIGHT, Color(0, 0, 0, 0), 5, 0), Rect2(rect.position + Vector2(2.0, 2.0), Vector2(rect.size.x - 4.0, 18.0)))
	draw_rect(Rect2(rect.position + Vector2(3.0, 20.0), Vector2(rect.size.x - 6.0, rect.size.y - 23.0)), CARD_FACE_SHADE, false, 1.0)
	draw_style_box(_make_style_box(Color(0, 0, 0, 0), CARD_INNER_BORDER, 5, 1), rect.grow(-2.0))

func _make_style_box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

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
