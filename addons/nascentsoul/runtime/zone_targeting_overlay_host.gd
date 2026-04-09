class_name ZoneTargetingOverlayHost extends Control

var _layers: Array[ZoneTargetingVisualLayer] = []
var _layer_roots: Dictionary = {}
var _last_frame: ZoneTargetingVisualFrame = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = get_viewport_rect().size
	visible = false
	set_process(true)

func _process(_delta: float) -> void:
	var viewport = get_viewport()
	if viewport == null:
		return
	var next_size = viewport.get_visible_rect().size
	if size == next_size:
		return
	size = next_size

func set_layers(next_layers: Array[ZoneTargetingVisualLayer]) -> void:
	var resolved: Array[ZoneTargetingVisualLayer] = []
	for layer in next_layers:
		if layer != null:
			resolved.append(layer)
	if _layers_match(resolved):
		return
	_rebuild_layer_roots(resolved)

func get_layers() -> Array[ZoneTargetingVisualLayer]:
	return _layers.duplicate()

func get_layer_root(layer: ZoneTargetingVisualLayer) -> Control:
	if layer == null:
		return null
	return _layer_roots.get(layer.get_instance_id(), null) as Control

func apply_frame(frame: ZoneTargetingVisualFrame) -> void:
	if frame == null or not frame.active:
		clear_state()
		return
	_last_frame = frame.duplicate_frame()
	visible = true
	for layer in _layers:
		layer.update_nodes(self, _last_frame)

func clear_state() -> void:
	for layer in _layers:
		layer.clear_nodes(self)
	_last_frame = null
	visible = false

func clear_overlay() -> void:
	clear_state()
	_clear_layer_roots()
	_layers.clear()

func get_visual_state() -> int:
	return _last_frame.visual_state if _last_frame != null else -1

func get_last_frame() -> ZoneTargetingVisualFrame:
	return _last_frame.duplicate_frame() if _last_frame != null else null

func get_debug_layer_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	for layer in _layers:
		keys.append(String(layer.get_layer_key()))
	return keys

func _layers_match(next_layers: Array[ZoneTargetingVisualLayer]) -> bool:
	if _layers.size() != next_layers.size():
		return false
	for index in range(_layers.size()):
		if _layers[index] != next_layers[index]:
			return false
	return true

func _rebuild_layer_roots(next_layers: Array[ZoneTargetingVisualLayer]) -> void:
	clear_state()
	_clear_layer_roots()
	_layers = next_layers
	for index in range(_layers.size()):
		var layer = _layers[index]
		var root := Control.new()
		root.name = "%02d_%s" % [index, String(layer.get_layer_key())]
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.offset_left = 0.0
		root.offset_top = 0.0
		root.offset_right = 0.0
		root.offset_bottom = 0.0
		add_child(root)
		_layer_roots[layer.get_instance_id()] = root
		layer.create_nodes(self)

func _clear_layer_roots() -> void:
	for root in _layer_roots.values():
		if root == null or not is_instance_valid(root):
			continue
		if root.get_parent() != null:
			root.get_parent().remove_child(root)
		root.free()
	_layer_roots.clear()
