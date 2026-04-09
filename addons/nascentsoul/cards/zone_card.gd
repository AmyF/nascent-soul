@tool
class_name ZoneCard extends ZoneItemControl

var _data: CardData = null
var _face_up: bool = true
var _highlighted: bool = false

@export var data: CardData:
	get:
		return _data
	set(value):
		if _data == value:
			return
		_data = value
		_refresh_visuals()
@export var face_up: bool = true:
	get:
		return _face_up
	set(value):
		if _face_up == value:
			return
		_face_up = value
		_refresh_visuals()
@export var highlighted: bool = false:
	get:
		return _highlighted
	set(value):
		if _highlighted == value:
			return
		_highlighted = value
		_refresh_visuals()

var _hovered_visual: bool = false
var _selected_visual: bool = false
var _target_candidate_active: bool = false
var _target_candidate_allowed: bool = false
var _flip_tween: Tween = null
var _visual_root: Control
var _background_panel: Panel
var _front_texture: TextureRect
var _back_texture: TextureRect
var _title_label: Label
var _cost_label: Label
var _tag_label: Label
var _back_label: Label
var _highlight_overlay: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(120, 180)
	if size == Vector2.ZERO:
		size = custom_minimum_size
	update_configuration_warnings()
	_ensure_nodes()
	_refresh_visuals()

func _exit_tree() -> void:
	_kill_flip_tween()

func flip(to_face_up: bool = not face_up, animated: bool = true) -> void:
	_ensure_nodes()
	if not animated:
		face_up = to_face_up
		return
	_kill_flip_tween()
	_flip_tween = _visual_root.create_tween()
	_flip_tween.tween_property(_visual_root, "scale:x", 0.0, 0.08)
	_flip_tween.tween_callback(Callable(self, "_apply_flip_state").bind(to_face_up))
	_flip_tween.tween_property(_visual_root, "scale:x", 1.0, 0.08)

func _kill_flip_tween() -> void:
	if _flip_tween != null and _flip_tween.is_valid():
		_flip_tween.kill()
	_flip_tween = null

func _apply_flip_state(to_face_up: bool) -> void:
	face_up = to_face_up

func set_hovered_visual(value: bool) -> void:
	var state = get_zone_visual_state()
	state.hovered = value
	apply_zone_visual_state(state)

func set_selected_visual(value: bool) -> void:
	var state = get_zone_visual_state()
	state.selected = value
	apply_zone_visual_state(state)

func create_zone_drag_ghost(_context: ZoneContext) -> Control:
	var ghost := Panel.new()
	ghost.custom_minimum_size = _resolved_card_size()
	ghost.size = _resolved_card_size()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.08)
	style.border_color = Color(1, 1, 1, 0.45)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	ghost.add_theme_stylebox_override("panel", style)
	return ghost

func create_zone_drag_proxy(_context: ZoneContext) -> Control:
	var proxy = duplicate(0)
	if proxy is Control:
		var control_proxy := proxy as Control
		control_proxy.modulate.a = 0.92
		control_proxy.global_position = global_position
		return control_proxy
	var fallback := ColorRect.new()
	fallback.color = Color(1, 1, 1, 0.7)
	fallback.custom_minimum_size = _resolved_card_size()
	fallback.size = _resolved_card_size()
	return fallback

func create_zone_targeting_intent(_command: ZoneTargetingCommand, _entry_mode: StringName) -> ZoneTargetingIntent:
	return super.create_zone_targeting_intent(_command, _entry_mode)

func get_zone_target_anchor_global() -> Vector2:
	return global_position + size * 0.5

func set_target_candidate_visual(active: bool, allowed: bool) -> void:
	var state = get_zone_visual_state()
	state.target_candidate_active = active
	state.target_candidate_allowed = allowed
	apply_zone_visual_state(state)

func create_zone_spawned_item(
	_context: ZoneContext,
	_decision: ZoneTransferDecision,
	_placement_target: ZonePlacementTarget
) -> ZoneItemControl:
	var piece := ZonePiece.new()
	piece.name = "%sPiece" % (data.title if data != null and data.title != "" else name)
	piece.custom_minimum_size = Vector2(92, 92)
	piece.size = piece.custom_minimum_size
	var piece_data := PieceData.new()
	if data != null:
		piece_data.id = data.id
		piece_data.title = data.title
		piece_data.texture = data.front_texture
		piece_data.attack = data.cost
		piece_data.defense = max(1, data.tags.size())
		piece_data.custom_data = data.custom_data.duplicate(true)
		piece.data = piece_data
	return piece

func configure_zone_spawned_item(
	spawned_item: ZoneItemControl,
	context: ZoneContext,
	placement_target: ZonePlacementTarget
) -> void:
	if spawned_item is ZonePiece:
		(spawned_item as ZonePiece).configure_from_transfer_source(self, context, placement_target)

func create_zone_ghost() -> Control:
	return create_zone_drag_ghost(null)

func create_drag_proxy() -> Control:
	return create_zone_drag_proxy(null)

func create_zone_piece() -> Control:
	return create_zone_spawned_item(null, ZoneTransferDecision.new(), ZonePlacementTarget.invalid())

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
	if _visual_root == null or not is_instance_valid(_visual_root):
		_visual_root = Control.new()
		_visual_root.name = "VisualRoot"
		_visual_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_visual_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_visual_root)
	if _background_panel == null or not is_instance_valid(_background_panel):
		_background_panel = Panel.new()
		_background_panel.name = "BackgroundPanel"
		_background_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_background_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_background_panel)
	if _front_texture == null or not is_instance_valid(_front_texture):
		_front_texture = TextureRect.new()
		_front_texture.name = "FrontTexture"
		_front_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		_front_texture.offset_left = 12
		_front_texture.offset_top = 12
		_front_texture.offset_right = -12
		_front_texture.offset_bottom = -48
		_front_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_front_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_front_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_front_texture)
	if _back_texture == null or not is_instance_valid(_back_texture):
		_back_texture = TextureRect.new()
		_back_texture.name = "BackTexture"
		_back_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		_back_texture.offset_left = 12
		_back_texture.offset_top = 12
		_back_texture.offset_right = -12
		_back_texture.offset_bottom = -12
		_back_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_back_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_back_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_back_texture)
	if _title_label == null or not is_instance_valid(_title_label):
		_title_label = Label.new()
		_title_label.name = "TitleLabel"
		_title_label.offset_left = 16
		_title_label.offset_top = 132
		_title_label.offset_right = -16
		_title_label.offset_bottom = 156
		_title_label.anchor_right = 1.0
		_title_label.anchor_bottom = 0.0
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_title_label)
	if _cost_label == null or not is_instance_valid(_cost_label):
		_cost_label = Label.new()
		_cost_label.name = "CostLabel"
		_cost_label.anchor_left = 1.0
		_cost_label.anchor_right = 1.0
		_cost_label.offset_left = -36
		_cost_label.offset_top = 16
		_cost_label.offset_right = -16
		_cost_label.offset_bottom = 40
		_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_cost_label)
	if _tag_label == null or not is_instance_valid(_tag_label):
		_tag_label = Label.new()
		_tag_label.name = "TagLabel"
		_tag_label.anchor_right = 1.0
		_tag_label.anchor_bottom = 1.0
		_tag_label.offset_left = 16
		_tag_label.offset_top = -30
		_tag_label.offset_right = -16
		_tag_label.offset_bottom = -12
		_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_tag_label)
	if _back_label == null or not is_instance_valid(_back_label):
		_back_label = Label.new()
		_back_label.name = "BackLabel"
		_back_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_back_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_back_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_back_label.text = "NascentSoul"
		_back_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_back_label)
	if _highlight_overlay == null or not is_instance_valid(_highlight_overlay):
		_highlight_overlay = ColorRect.new()
		_highlight_overlay.name = "HighlightOverlay"
		_highlight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_highlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_root.add_child(_highlight_overlay)
	elif _highlight_overlay.get_parent() != _visual_root:
		_highlight_overlay.reparent(_visual_root, false)

func _refresh_visuals() -> void:
	if not is_node_ready():
		return
	_ensure_nodes()
	_apply_card_style()
	var title = data.title if data != null and data.title != "" else name
	var cost_text = str(data.cost) if data != null else ""
	_title_label.text = title
	_cost_label.text = cost_text
	_tag_label.text = ", ".join(data.tags) if data != null and not data.tags.is_empty() else "card"
	_front_texture.texture = data.front_texture if data != null else null
	_back_texture.texture = data.back_texture if data != null else null
	_front_texture.visible = face_up
	_title_label.visible = face_up
	_cost_label.visible = face_up
	_tag_label.visible = face_up
	_back_texture.visible = not face_up
	_back_label.visible = not face_up
	var overlay_alpha = 0.0
	var overlay_color = Color(0.92, 0.86, 0.52, 1.0)
	if _target_candidate_active:
		overlay_alpha = max(overlay_alpha, 0.30)
		overlay_color = Color(0.44, 0.92, 0.62, 1.0) if _target_candidate_allowed else Color(1.0, 0.40, 0.40, 1.0)
	if highlighted:
		overlay_alpha = max(overlay_alpha, 0.16)
	if _selected_visual:
		overlay_alpha = max(overlay_alpha, 0.26)
	if _hovered_visual:
		overlay_alpha = max(overlay_alpha, 0.20)
	_highlight_overlay.color = Color(overlay_color.r, overlay_color.g, overlay_color.b, overlay_alpha)
	_highlight_overlay.visible = overlay_alpha > 0.0

func _apply_card_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.14, 0.19, 1.0) if face_up else Color(0.09, 0.11, 0.16, 1.0)
	style.border_color = Color(1, 1, 1, 0.55) if _hovered_visual else Color(1, 1, 1, 0.2)
	if _selected_visual:
		style.border_color = Color(0.95, 0.84, 0.44, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	_background_panel.add_theme_stylebox_override("panel", style)

func _resolved_card_size() -> Vector2:
	if size != Vector2.ZERO:
		return size
	if custom_minimum_size != Vector2.ZERO:
		return custom_minimum_size
	return Vector2(120, 180)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if data == null:
		warnings.append("ZoneCard has no CardData resource. It will render with fallback title and empty textures.")
	else:
		if data.front_texture == null:
			warnings.append("CardData.front_texture is empty. Face-up cards will show labels only.")
		if data.back_texture == null:
			warnings.append("CardData.back_texture is empty. Face-down cards will use the fallback background.")
	if size == Vector2.ZERO and custom_minimum_size == Vector2.ZERO:
		warnings.append("ZoneCard has no size yet. Set size or custom_minimum_size so layouts can place it predictably.")
	return warnings
