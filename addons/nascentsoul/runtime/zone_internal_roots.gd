extends RefCounted

# Internal helper that keeps the managed item roots present, ordered, and owned
# correctly for a Zone instance.

var zone = null
var items_root_name: String = ""
var preview_root_name: String = ""

var items_root: Control = null
var preview_root: Control = null

func _init(p_zone, p_items_root_name: String, p_preview_root_name: String) -> void:
	zone = p_zone
	items_root_name = p_items_root_name
	preview_root_name = p_preview_root_name

func ensure_nodes() -> void:
	items_root = _ensure_internal_root(items_root, items_root_name)
	preview_root = _ensure_internal_root(preview_root, preview_root_name)
	if items_root != null and preview_root != null and items_root.get_index() > preview_root.get_index():
		zone.move_child(items_root, 0)
	if preview_root != null:
		zone.move_child(preview_root, zone.get_child_count() - 1)

func is_expected_direct_child(child: Node) -> bool:
	return child == items_root \
		or child == preview_root \
		or child.name.begins_with("__NascentSoul")

func _ensure_internal_root(existing: Control, node_name: String) -> Control:
	var root = existing
	if root == null or not is_instance_valid(root) or root.get_parent() != zone:
		root = _find_internal_root(node_name)
	if root == null:
		root = Control.new()
		root.name = node_name
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zone.add_child(root)
	_merge_duplicate_internal_roots(root, node_name)
	_sync_internal_root_owner(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 0.0
	root.offset_top = 0.0
	root.offset_right = 0.0
	root.offset_bottom = 0.0
	root.focus_mode = Control.FOCUS_NONE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = false
	return root

func _find_internal_root(node_name: String) -> Control:
	for child in zone.get_children():
		if child is Control and child.name == node_name:
			return child as Control
	return null

func _merge_duplicate_internal_roots(root: Control, node_name: String) -> void:
	if root == null:
		return
	var duplicate_roots: Array[Control] = []
	for child in zone.get_children():
		if child == root:
			continue
		if child is Control and child.name == node_name:
			duplicate_roots.append(child as Control)
	for duplicate_root in duplicate_roots:
		for duplicate_child in duplicate_root.get_children():
			if duplicate_child == null:
				continue
			duplicate_child.reparent(root, true)
		duplicate_root.queue_free()

func _sync_internal_root_owner(root: Node) -> void:
	if root == null:
		return
	if zone.owner != null and root.owner != zone.owner:
		root.owner = zone.owner
