extends ZoneCard

const TASK_SIZE := Vector2(188, 116)
const DEFAULT_ACCENT := Color(0.24, 0.53, 0.86, 1.0)

var task_id: String = ""
var task_title: String = ""
var task_owner: String = ""
var task_label: String = ""
var story_points: int = 1
var accent_color: Color = DEFAULT_ACCENT

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = TASK_SIZE
	if size == Vector2.ZERO:
		size = custom_minimum_size
	face_up = true
	_sync_task_metadata()
	super._ready()
	_refresh_visuals()

func configure_task(next_task_id: String, next_title: String, next_owner: String, next_label: String, next_story_points: int, next_accent: Color = DEFAULT_ACCENT):
	task_id = next_task_id
	task_title = next_title
	task_owner = next_owner
	task_label = next_label
	story_points = max(0, next_story_points)
	accent_color = next_accent
	name = task_id if task_id != "" else next_title.to_lower().replace(" ", "_")
	_sync_task_metadata()
	_refresh_visuals()
	return self

func _refresh_visuals() -> void:
	super._refresh_visuals()
	if not is_node_ready():
		return
	_ensure_nodes()
	_ensure_task_layout()
	_front_texture.visible = false
	_back_texture.visible = false
	_back_label.visible = false
	_title_label.visible = true
	_cost_label.visible = true
	_tag_label.visible = true
	_title_label.text = task_title if task_title != "" else (data.title if data != null else name)
	_cost_label.text = "%d pt" % story_points
	var chips: Array[String] = []
	if task_label != "":
		chips.append(task_label)
	if task_owner != "":
		chips.append(task_owner)
	_tag_label.text = " • ".join(chips) if not chips.is_empty() else "task"

func _apply_card_style(visual_state: ZoneItemVisualState) -> void:
	var resolved_accent = accent_color if accent_color.a > 0.0 else DEFAULT_ACCENT
	var style := StyleBoxFlat.new()
	style.bg_color = resolved_accent.lerp(Color(0.98, 0.99, 1.0, 1.0), 0.84)
	style.border_color = resolved_accent.darkened(0.18)
	if visual_state.hovered:
		style.border_color = resolved_accent.darkened(0.04)
	if visual_state.selected:
		style.border_color = Color(0.96, 0.77, 0.28, 1.0)
	style.border_width_left = 1
	style.border_width_top = 6
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	_background_panel.add_theme_stylebox_override("panel", style)
	_title_label.add_theme_color_override("font_color", Color(0.08, 0.13, 0.20, 1.0))
	_title_label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.0))
	_cost_label.add_theme_color_override("font_color", resolved_accent.darkened(0.34))
	_tag_label.add_theme_color_override("font_color", Color(0.29, 0.35, 0.44, 1.0))

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if task_title == "":
		warnings.append("WorkflowTaskCard has no title yet. Call configure_task(...) or assign task fields before using it in a board.")
	if size == Vector2.ZERO and custom_minimum_size == Vector2.ZERO:
		warnings.append("WorkflowTaskCard has no size yet. Set size or custom_minimum_size so layouts can place it predictably.")
	return warnings

func _ensure_task_layout() -> void:
	_title_label.offset_left = 14
	_title_label.offset_top = 14
	_title_label.offset_right = -86
	_title_label.offset_bottom = 62
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_title_label.add_theme_font_size_override("font_size", 15)
	_cost_label.anchor_left = 1.0
	_cost_label.anchor_right = 1.0
	_cost_label.offset_left = -82
	_cost_label.offset_top = 14
	_cost_label.offset_right = -14
	_cost_label.offset_bottom = 38
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cost_label.add_theme_font_size_override("font_size", 12)
	_tag_label.anchor_right = 1.0
	_tag_label.anchor_bottom = 1.0
	_tag_label.offset_left = 14
	_tag_label.offset_top = -34
	_tag_label.offset_right = -14
	_tag_label.offset_bottom = -12
	_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tag_label.add_theme_font_size_override("font_size", 12)

func _sync_task_metadata() -> void:
	if data == null:
		data = CardData.new()
	data.id = task_id if task_id != "" else task_title.to_lower().replace(" ", "_")
	data.title = task_title
	data.cost = story_points
	data.tags = PackedStringArray([task_label]) if task_label != "" else PackedStringArray()
	set_zone_item_metadata({
		"task_id": data.id,
		"task_title": task_title,
		"task_owner": task_owner,
		"task_label": task_label,
		"story_points": story_points
	})
