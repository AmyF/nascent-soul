# Zone.gd
class_name Zone
extends Node

## Zone 是桌游工具库的核心协调器。
## 它本身不包含复杂逻辑，而是作为一个容器的逻辑控制器，管理一组 Control 节点（卡牌、棋子等），
## 并通过引用的五个逻辑资源 (Resource) 来驱动排序、布局、显示和交互。


#=============================================================================
# 1. 信号 (Public Signals)
#=============================================================================
signal item_clicked(item: Control, zone: Zone)
signal item_double_clicked(item: Control, zone: Zone)
signal item_mouse_entered(item: Control, zone: Zone)
signal item_mouse_exited(item: Control, zone: Zone)
signal item_drag_started(item: Control, zone: Zone)
signal item_dropped(item: Control, zone: Zone)
signal item_dragging(item: Control, global_pos: Vector2, zone: Zone)
signal selection_changed(new_selection: Array[Control], zone: Zone)


#=============================================================================
# 2. 导出属性 (Inspector配置)
#=============================================================================
## [必需] Zone所操作的UI容器。Zone将在此容器内对对象进行布局。
@export var container: Control

## [可选] 权限逻辑，决定哪些对象可以被添加或移入。
@export var permission_logic: ZonePermission
## [可选] 排序逻辑。
@export var sort_logic: ZoneSort
## [可选] 显示逻辑。
@export var display_logic: ZoneDisplay
## [可选] 布局逻辑。
@export var layout_logic: ZoneLayout
## [可选] 交互逻辑。
@export var interaction_logic: ZoneInteraction


#=============================================================================
# 3. 公共属性 (Public Properties)
#=============================================================================
## 当前区域内所有被管理对象的数组。建议外部只读访问。
var managed_items: Array[Control] = []
## 当前区域内所有被选中对象的数组。建议外部只读访问。
var selected_items: Array[Control] = []

#=============================================================================
# 4. 私有变量 (Internal State)
#=============================================================================
var _is_dirty: bool = true # “脏标记”，用于性能优化
var _item_being_dragged: Control = null
var _hovered_item: Control = null
var _ghost_index: int = -1
var _tween: Tween


#=============================================================================
# 5. Godot生命周期方法 (Lifecycle Methods)
#=============================================================================
func _ready():
	if not is_instance_valid(container):
		push_warning("Zone '%s' is missing a required 'container' reference." % self.name)
		return
	
	if permission_logic:
		permission_logic = permission_logic.duplicate()
	if sort_logic:
		sort_logic = sort_logic.duplicate()
	if display_logic:
		display_logic = display_logic.duplicate()
	if layout_logic:
		layout_logic = layout_logic.duplicate()
	if interaction_logic:
		interaction_logic = interaction_logic.duplicate()

	var logic_resources = [permission_logic, sort_logic, display_logic, layout_logic, interaction_logic]
	for resource in logic_resources:
		if resource and resource.has_method("_setup"):
			resource._setup(self)

	item_mouse_entered.connect(_on_item_mouse_entered)
	item_mouse_exited.connect(_on_item_mouse_exited)
	item_drag_started.connect(_on_item_drag_started)
	item_dropped.connect(_on_item_dropped)
	item_dragging.connect(_on_item_dragging)
	
	_request_update()


func _process(delta):
	if _is_dirty:
		_is_dirty = false
		_update_layout_and_display()


#=============================================================================
# 6. 公共方法 (Core API)
#=============================================================================
func add_item(item: Control, index: int = -1) -> bool:
	if permission_logic and not permission_logic.can_add(item, self):
		return false
	if not item in managed_items:
		if index < 0 or index >= managed_items.size():
			managed_items.append(item)
		else:
			managed_items.insert(index, item)
		if interaction_logic:
			interaction_logic.setup_item_signals(item, self)
		_request_update()
		return true
	return false


func remove_item(item: Control) -> bool:
	if item in managed_items:
		if item in selected_items:
			deselect_item(item)
		managed_items.erase(item)
		if interaction_logic:
			interaction_logic.cleanup_item_signals(item)
		_request_update()
		return true
	return false


func transfer_item_to(item: Control, target_zone: Zone, index: int = -1) -> bool:
	if not item in managed_items:
		push_error("Cannot transfer item that is not in this zone.")
		return false
	if target_zone.permission_logic and not target_zone.permission_logic.can_transfer_in(item, self, target_zone):
		return false
	remove_item(item)
	target_zone.add_item(item, index)
	return true


func reorder_item(item: Control, new_index: int) -> bool:
	var old_index = managed_items.find(item)
	if old_index == -1 or new_index < 0 or new_index > managed_items.size():
		return false
	
	managed_items.remove_at(old_index)

	if old_index < new_index:
		new_index -= 1 # 因为移除后，索引会向前移动

	managed_items.insert(new_index, item)
	_request_update()
	return true


func get_drop_index_at_global_pos(global_pos: Vector2) -> int:
	if not layout_logic or not is_instance_valid(container):
		return managed_items.size()

	var local_pos = global_pos - container.global_position
	return layout_logic.get_drop_index_at_position(local_pos, managed_items, Rect2(Vector2.ZERO, container.size))


func select_item(item: Control, additive: bool = false):
	if not item in managed_items:
		return
	var selection_has_changed = false
	if not additive:
		if not (selected_items.size() == 1 and selected_items[0] == item):
			clear_selection(false)
			selection_has_changed = true
	if not item in selected_items:
		selected_items.append(item)
		selection_has_changed = true
	if selection_has_changed:
		selection_changed.emit(selected_items, self)
		_request_update()


func deselect_item(item: Control):
	if item in selected_items:
		selected_items.erase(item)
		selection_changed.emit(selected_items, self)
		_request_update()


func clear_selection(emit_signal: bool = true):
	if not selected_items.is_empty():
		selected_items.clear()
		if emit_signal:
			selection_changed.emit(selected_items, self)
		_request_update()


func force_update_layout():
	_request_update()


func clear_items():
	for i in range(managed_items.size() - 1, -1, -1):
		remove_item(managed_items[i])
	clear_selection()

#=============================================================================
# 7. 内部回调方法 (Internal Callbacks)
#=============================================================================
func _on_item_mouse_entered(item: Control, zone: Zone):
	_hovered_item = item
	_request_update()


func _on_item_mouse_exited(item: Control, zone: Zone):
	if _hovered_item == item:
		_hovered_item = null
		_request_update()


func _on_item_drag_started(item: Control, zone: Zone):
	_item_being_dragged = item


func _on_item_dropped(item: Control, zone: Zone):
	if _item_being_dragged == item:
		_item_being_dragged = null
	
	_ghost_index = -1
	
	_request_update()


func _on_item_dragging(item: Control, global_pos: Vector2, zone: Zone):
	if layout_logic and not layout_logic.enable_ghost_slot_feedback:
		return

	if container.get_global_rect().has_point(global_pos):
		_update_ghost_slot(global_pos)
	else:
		_clear_ghost_slot()

#=============================================================================
# 8. 私有核心逻辑 (Private Core Logic)
#=============================================================================
func _update_ghost_slot(global_pos: Vector2):
	var new_ghost_index = get_drop_index_at_global_pos(global_pos)
	if new_ghost_index != _ghost_index:
		_ghost_index = new_ghost_index
		_request_update()


func _clear_ghost_slot():
	if _ghost_index != -1:
		_ghost_index = -1
		_request_update()


func _request_update():
	_is_dirty = true


func _update_layout_and_display():
	if not is_instance_valid(container):
		return
	
	# --- 步骤 1: 排序 (Sort) ---
	var sorted_items = managed_items
	if sort_logic:
		sorted_items = sort_logic.sort(managed_items)
	
	# --- 步骤 2: 筛选 (Filter) ---
	var visible_items = sorted_items
	if display_logic:
		visible_items = display_logic.filter_visible_items(sorted_items)
	
	# --- 步骤 3: 布局计算 (Layout) ---
	var transforms: Dictionary = {}
	if layout_logic:
		transforms = layout_logic.calculate_transforms(
			visible_items, 
			Rect2(Vector2.ZERO, container.size), 
			_ghost_index,
			_item_being_dragged
		)

	# --- 步骤 4: 应用变换和显示状态 ---
	for item in managed_items:
		if not item in visible_items:
			item.visible = false
	
	if visible_items.is_empty():
		return
	
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	for item in visible_items:
		if item == _item_being_dragged:
			# 拖拽中的对象由交互逻辑控制位置，不在此处更新
			continue

		item.visible = true
		var state_info = {
			"is_hovered": item == _hovered_item,
			"is_selected": item in selected_items
		}
		
		var base_transform = transforms.get(item, {})
		var hover_adjustment = display_logic.get_hover_transform_adjustment(item, state_info.is_hovered) if display_logic else {}
		
		var final_pos = container.position + base_transform.get("position", item.position) + hover_adjustment.get("offset", Vector2.ZERO)
		var final_rot = base_transform.get("rotation_degrees", item.rotation_degrees)
		var final_scale = base_transform.get("scale", item.scale) * hover_adjustment.get("scale", Vector2.ONE)
		var final_z = base_transform.get("z_index", item.z_index) + hover_adjustment.get("z_index", 0)

		_tween.tween_property(item, "position", final_pos, 0.2)
		_tween.tween_property(item, "rotation_degrees", final_rot, 0.2)
		_tween.tween_property(item, "scale", final_scale, 0.2)
		item.z_index = final_z
		
		if display_logic:
			display_logic.apply_display_state(item, state_info)
