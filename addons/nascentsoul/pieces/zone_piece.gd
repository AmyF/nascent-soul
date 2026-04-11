@tool
class_name ZonePiece extends ZoneItemControl

var _data: PieceData = null
var _highlighted: bool = false

@export var data: PieceData:
	get:
		return _data
	set(value):
		if _data == value:
			return
		_data = value
		_refresh_visuals()

@export var highlighted: bool = false:
	get:
		return _highlighted
	set(value):
		if _highlighted == value:
			return
		_highlighted = value
		_refresh_visuals()

var _panel: Panel = null
var _icon: TextureRect = null
var _title_label: Label = null
var _stats_label: Label = null
var _overlay: ColorRect = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(92, 92)
	if size == Vector2.ZERO:
		size = custom_minimum_size
	_ensure_nodes()
	_refresh_visuals()

func configure_from_transfer_source(source_item: ZoneItemControl, _context: ZoneContext, _target: ZonePlacementTarget) -> void:
	if source_item is ZoneCard:
		var source_card = source_item as ZoneCard
		var next_data := PieceData.new()
		if source_card.data != null:
			next_data.id = source_card.data.id
			next_data.title = source_card.data.title
			next_data.texture = source_card.data.front_texture
			next_data.custom_data = source_card.data.custom_data.duplicate(true)
			next_data.attack = int(source_card.data.custom_data.get("cost", source_card.data.cost))
			next_data.defense = max(1, int(source_card.data.custom_data.get("defense", 1)))
		else:
			next_data.title = source_card.name
		data = next_data

func apply_transfer_source(source_item: Control, _source_zone: Zone, _target_zone: Zone, _target: ZonePlacementTarget) -> void:
	if source_item is ZoneItemControl:
		configure_from_transfer_source(source_item as ZoneItemControl, null, _target)

func apply_zone_visual_state(state: ZoneItemVisualState) -> void:
	var next_state = state if state != null else ZoneItemVisualState.new()
	var changed = did_zone_visual_state_change(next_state)
	super.apply_zone_visual_state(next_state)
	if changed:
		_refresh_visuals()

func _ensure_nodes() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = Panel.new()
		_panel.name = "PiecePanel"
		_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_panel)
	if _icon == null or not is_instance_valid(_icon):
		_icon = TextureRect.new()
		_icon.name = "PieceIcon"
		_icon.anchor_right = 1.0
		_icon.anchor_bottom = 1.0
		_icon.offset_left = 10.0
		_icon.offset_top = 10.0
		_icon.offset_right = -10.0
		_icon.offset_bottom = -34.0
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_icon)
	if _title_label == null or not is_instance_valid(_title_label):
		_title_label = Label.new()
		_title_label.name = "PieceTitle"
		_title_label.anchor_right = 1.0
		_title_label.offset_left = 8.0
		_title_label.offset_top = 56.0
		_title_label.offset_right = -8.0
		_title_label.offset_bottom = 74.0
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_title_label)
	if _stats_label == null or not is_instance_valid(_stats_label):
		_stats_label = Label.new()
		_stats_label.name = "PieceStats"
		_stats_label.anchor_right = 1.0
		_stats_label.anchor_bottom = 1.0
		_stats_label.offset_left = 8.0
		_stats_label.offset_top = -24.0
		_stats_label.offset_right = -8.0
		_stats_label.offset_bottom = -8.0
		_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_stats_label)
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
	var visual_state = get_zone_visual_state()
	var title = data.title if data != null and data.title != "" else name
	_title_label.text = title
	_stats_label.text = "%d / %d" % [
		data.attack if data != null else 0,
		data.defense if data != null else 0
	]
	_icon.texture = data.texture if data != null else null
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.14, 0.18, 0.96)
	style.border_color = Color(0.84, 0.69, 0.29, 1.0) if visual_state.selected else Color(0.42, 0.52, 0.64, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	_panel.add_theme_stylebox_override("panel", style)
	var overlay_color = Color(1.0, 0.86, 0.4, 0.22) if highlighted or visual_state.hovered else Color(0.2, 0.5, 1.0, 0.18) if visual_state.selected else Color(0, 0, 0, 0)
	if visual_state.target_candidate_active:
		overlay_color = Color(0.44, 0.92, 0.62, 0.28) if visual_state.target_candidate_allowed else Color(1.0, 0.42, 0.42, 0.28)
	_overlay.color = overlay_color
	_overlay.visible = _overlay.color.a > 0.0
