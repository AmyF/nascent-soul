extends ZoneItemControl

const PIECE_SIZE := Vector2(70, 70)

var side: StringName = &"red"
var piece_type: StringName = &"soldier"
var glyph: String = "兵"
var latin_name: String = "Soldier"

var _hovered_visual: bool = false
var _selected_visual: bool = false
var _target_candidate_active: bool = false
var _target_candidate_allowed: bool = false
var _panel: Panel = null
var _glyph_label: Label = null
var _name_label: Label = null
var _overlay: ColorRect = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = PIECE_SIZE
	if size == Vector2.ZERO:
		size = custom_minimum_size
	_ensure_nodes()
	_refresh_visuals()

func configure(p_side: StringName, p_piece_type: StringName, p_glyph: String, p_latin_name: String) -> void:
	side = p_side
	piece_type = p_piece_type
	glyph = p_glyph
	latin_name = p_latin_name
	name = "%s_%s" % [String(side), String(piece_type)]
	set_zone_item_metadata({
		"xiangqi_side": String(side),
		"xiangqi_piece_type": String(piece_type),
		"piece_label": latin_name
	})
	_refresh_visuals()

func create_zone_drag_ghost(_context: ZoneContext) -> Control:
	var ghost := Panel.new()
	ghost.custom_minimum_size = _resolved_piece_size()
	ghost.size = ghost.custom_minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.08)
	style.border_color = _accent_color()
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 35
	style.corner_radius_top_right = 35
	style.corner_radius_bottom_right = 35
	style.corner_radius_bottom_left = 35
	ghost.add_theme_stylebox_override("panel", style)
	return ghost

func create_zone_drag_proxy(_context: ZoneContext) -> Control:
	var proxy = duplicate(0)
	if proxy is Control:
		var control_proxy := proxy as Control
		control_proxy.modulate.a = 0.96
		control_proxy.global_position = global_position
		return control_proxy
	return super.create_zone_drag_proxy(_context)

func display_name() -> String:
	return "%s %s" % [_side_name(), latin_name]

func apply_zone_visual_state(state: ZoneItemVisualState) -> void:
	var next_state = state if state != null else ZoneItemVisualState.new()
	var changed = _hovered_visual != next_state.hovered \
		or _selected_visual != next_state.selected \
		or _target_candidate_active != next_state.target_candidate_active \
		or _target_candidate_allowed != next_state.target_candidate_allowed
	super.apply_zone_visual_state(next_state)
	_hovered_visual = next_state.hovered
	_selected_visual = next_state.selected
	_target_candidate_active = next_state.target_candidate_active
	_target_candidate_allowed = next_state.target_candidate_allowed
	if changed:
		_refresh_visuals()

func _ensure_nodes() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = Panel.new()
		_panel.name = "PiecePanel"
		_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_panel)
	if _glyph_label == null or not is_instance_valid(_glyph_label):
		_glyph_label = Label.new()
		_glyph_label.name = "GlyphLabel"
		_glyph_label.anchor_right = 1.0
		_glyph_label.anchor_bottom = 1.0
		_glyph_label.offset_left = 8.0
		_glyph_label.offset_top = 4.0
		_glyph_label.offset_right = -8.0
		_glyph_label.offset_bottom = -18.0
		_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_glyph_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_glyph_label)
	if _name_label == null or not is_instance_valid(_name_label):
		_name_label = Label.new()
		_name_label.name = "NameLabel"
		_name_label.anchor_right = 1.0
		_name_label.anchor_bottom = 1.0
		_name_label.offset_left = 6.0
		_name_label.offset_top = -18.0
		_name_label.offset_right = -6.0
		_name_label.offset_bottom = -4.0
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_name_label)
	if _overlay == null or not is_instance_valid(_overlay):
		_overlay = ColorRect.new()
		_overlay.name = "PieceOverlay"
		_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_overlay)

func _refresh_visuals() -> void:
	if not is_node_ready():
		return
	_ensure_nodes()
	var accent = _accent_color()
	var fill = Color(0.98, 0.93, 0.78, 0.98)
	var border = accent if _selected_visual else Color(accent.r, accent.g, accent.b, 0.88)
	if _hovered_visual and not _selected_visual:
		border = Color(accent.r, accent.g, accent.b, 1.0)
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 35
	style.corner_radius_top_right = 35
	style.corner_radius_bottom_right = 35
	style.corner_radius_bottom_left = 35
	_panel.add_theme_stylebox_override("panel", style)

	_glyph_label.text = glyph
	_glyph_label.add_theme_color_override("font_color", accent)
	_glyph_label.add_theme_font_size_override("font_size", 24)
	_name_label.text = latin_name
	_name_label.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.82))
	_name_label.add_theme_font_size_override("font_size", 10)

	var overlay_color = Color(0, 0, 0, 0)
	if _target_candidate_active:
		overlay_color = Color(0.38, 0.92, 0.60, 0.26) if _target_candidate_allowed else Color(1.0, 0.42, 0.42, 0.26)
	elif _selected_visual:
		overlay_color = Color(accent.r, accent.g, accent.b, 0.18)
	elif _hovered_visual:
		overlay_color = Color(accent.r, accent.g, accent.b, 0.12)
	_overlay.color = overlay_color
	_overlay.visible = _overlay.color.a > 0.0

func _accent_color() -> Color:
	return Color(0.75, 0.16, 0.16, 1.0) if side == &"red" else Color(0.10, 0.12, 0.16, 1.0)

func _resolved_piece_size() -> Vector2:
	if size != Vector2.ZERO:
		return size
	if custom_minimum_size != Vector2.ZERO:
		return custom_minimum_size
	return PIECE_SIZE

func _side_name() -> String:
	return "Red" if side == &"red" else "Black"
