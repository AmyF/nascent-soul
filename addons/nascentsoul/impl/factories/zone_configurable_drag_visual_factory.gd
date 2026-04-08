@tool
class_name ZoneConfigurableDragVisualFactory extends ZoneDragVisualFactory

enum GhostMode {
	OUTLINE_PANEL,
	COLOR_RECT,
	DUPLICATE
}

enum ProxyMode {
	DUPLICATE,
	COLOR_RECT
}

@export_group("Fallback Sources")
@export var prefer_item_methods: bool = true
@export var allow_meta_ghost_scene: bool = true

@export_group("Ghost")
@export var ghost_mode: GhostMode = GhostMode.OUTLINE_PANEL
@export var ghost_fill_color: Color = Color(1, 1, 1, 0.08)
@export var ghost_border_color: Color = Color(1, 1, 1, 0.45)
@export_range(0, 8, 1) var ghost_border_width: int = 2
@export_range(0, 48, 1) var ghost_corner_radius: int = 18
@export var ghost_duplicate_modulate: Color = Color(1, 1, 1, 0.22)

@export_group("Proxy")
@export var proxy_mode: ProxyMode = ProxyMode.DUPLICATE
@export var proxy_modulate: Color = Color(1, 1, 1, 0.92)
@export var proxy_color: Color = Color(1, 1, 1, 0.72)
@export var proxy_scale: Vector2 = Vector2.ONE

func create_ghost(_zone: Node, runtime, source_item: Control) -> Control:
	var item_size = runtime.resolve_item_size(source_item)
	var fallback = _create_item_ghost(source_item)
	if fallback != null:
		return fallback
	match ghost_mode:
		GhostMode.COLOR_RECT:
			return _make_color_rect(item_size, ghost_fill_color)
		GhostMode.DUPLICATE:
			return _make_duplicate(source_item, ghost_duplicate_modulate, Vector2.ONE)
		_:
			return _make_outline_panel(item_size)

func create_drag_proxy(_zone: Node, runtime, source_item: Control) -> Control:
	var item_size = runtime.resolve_item_size(source_item)
	var fallback = _create_item_proxy(source_item)
	if fallback != null:
		return fallback
	match proxy_mode:
		ProxyMode.COLOR_RECT:
			var proxy = _make_color_rect(item_size, proxy_color)
			proxy.scale = proxy_scale
			proxy.global_position = source_item.global_position
			return proxy
		_:
			var duplicate_proxy = _make_duplicate(source_item, proxy_modulate, proxy_scale)
			if duplicate_proxy != null:
				duplicate_proxy.global_position = source_item.global_position
				return duplicate_proxy
	var fallback_proxy = _make_color_rect(item_size, proxy_color)
	fallback_proxy.scale = proxy_scale
	fallback_proxy.global_position = source_item.global_position
	return fallback_proxy

func _create_item_ghost(source_item: Control) -> Control:
	if prefer_item_methods and source_item.has_method("create_zone_ghost"):
		var created = source_item.call("create_zone_ghost")
		if created is Control:
			return created as Control
	if allow_meta_ghost_scene and source_item.has_meta("zone_ghost_scene"):
		var ghost_scene = source_item.get_meta("zone_ghost_scene")
		if ghost_scene is PackedScene:
			var instance = ghost_scene.instantiate()
			if instance is Control:
				return instance as Control
	return null

func _create_item_proxy(source_item: Control) -> Control:
	if prefer_item_methods and source_item.has_method("create_drag_proxy"):
		var created = source_item.call("create_drag_proxy")
		if created is Control:
			return created as Control
	return null

func _make_outline_panel(item_size: Vector2) -> Control:
	var ghost := Panel.new()
	ghost.custom_minimum_size = item_size
	ghost.size = item_size
	var style := StyleBoxFlat.new()
	style.bg_color = ghost_fill_color
	style.border_color = ghost_border_color
	style.border_width_left = ghost_border_width
	style.border_width_top = ghost_border_width
	style.border_width_right = ghost_border_width
	style.border_width_bottom = ghost_border_width
	style.corner_radius_top_left = ghost_corner_radius
	style.corner_radius_top_right = ghost_corner_radius
	style.corner_radius_bottom_right = ghost_corner_radius
	style.corner_radius_bottom_left = ghost_corner_radius
	ghost.add_theme_stylebox_override("panel", style)
	return ghost

func _make_color_rect(item_size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = item_size
	rect.size = item_size
	return rect

func _make_duplicate(source_item: Control, modulate_color: Color, scale_value: Vector2) -> Control:
	var duplicate = source_item.duplicate(0)
	if duplicate is not Control:
		return null
	var duplicate_control := duplicate as Control
	duplicate_control.modulate = modulate_color
	duplicate_control.scale = scale_value
	return duplicate_control
