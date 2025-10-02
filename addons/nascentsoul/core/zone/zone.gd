extends Node
class_name Zone

#==============================================================================
# 信号
#==============================================================================

signal obj_added(obj: Control, index: int)
signal obj_removed(obj: Control)
signal objs_reordered()

signal obj_selected(obj: Control)
signal obj_deselected(obj: Control)
signal obj_double_clicked(obj: Control)
signal obj_dropped(obj: Control, from_zone: Zone)

signal layout_changed()

#==============================================================================
# 常量
#==============================================================================

const zone_group_name: String = "nascentsoul_zones"

#==============================================================================
# 公共成员变量
#==============================================================================

@export var target_container: Control
@export var max_objs: int = -1

@export_group("Strategies")
@export var layout_strategy: ZoneLayoutStrategy
@export var sort_strategy: ZoneSortStrategy
@export var visibility_strategy: ZoneVisibilityStrategy

@export_group("Behavior")
@export var click_enabled: bool = true
@export var double_click_enabled: bool = true
@export var multi_select_enabled: bool = false
@export var hover_enabled: bool = true
@export var drag_enabled: bool = true
@export var allow_reordering: bool = true

@export_group("Animations")
@export var auto_arrange: bool = true
@export var layout_animation_time: float = 0.3
@export var animation_speed: float = 1.0

#==============================================================================
# 私有成员变量
#==============================================================================

var _objs: Array[Control] = []
var _visible_objs: Array[Control] = []
var _selected_objs: Array[Control] = []

var _hovered_obj: Control = null
var _dragging_obj: Control = null
var _reorder_preview_index: int = -1

var _tweens_map: Dictionary = {}

#==============================================================================
# Godot内建方法
#==============================================================================

func _ready() -> void:
	if not target_container:
		push_error("Zone: target_container is not set.")
	if not layout_strategy:
		push_error("Zone: layout_strategy is not set.")
	if not sort_strategy:
		push_error("Zone: sort_strategy is not set.")
	if not visibility_strategy:
		push_error("Zone: visibility_strategy is not set.")

	add_to_group(zone_group_name)

	target_container.child_entered_tree.connect(_on_child_entered_tree)
	target_container.child_exiting_tree.connect(_on_child_exiting_tree)

	_setup_existing_children()


func _exit_tree() -> void:
	remove_from_group(zone_group_name)

#==============================================================================
# 信号回调
#==============================================================================

func _on_child_entered_tree(child: Node) -> void:
	if not target_container.is_node_ready():
		return
	if child is Control and child not in _objs:
		add_obj(child as Control, -1, false)


func _on_child_exiting_tree(child: Node) -> void:
	if child is Control and child in _objs:
		var index = _objs.find(child as Control)
		remove_obj(index, false)


func _on_obj_mouse_entered(obj: Control) -> void:
	if not obj or not hover_enabled:
		return
	if _dragging_obj != null:
		return
	if _hovered_obj == obj:
		return

	var previously_hovered = _hovered_obj
	_hovered_obj = obj

	_update_hover_layout(previously_hovered, obj)


func _on_obj_mouse_exited(obj: Control) -> void:
	if not obj or not hover_enabled:
		return

	if _hovered_obj == obj:
		var previously_hovered = _hovered_obj
		_hovered_obj = null
		_update_hover_layout(previously_hovered, null)


func _on_obj_drag_started(obj: Control) -> void:
	_dragging_obj = obj

	_clear_obj_tween(obj)

	if not multi_select_enabled:
		for _selected_obj in _selected_objs.duplicate():
			if _selected_obj != obj:
				_deselect_obj(_selected_obj)


func _on_obj_dragging(delta: Vector2, obj: Control) -> void:
	if not obj or obj != _dragging_obj:
		return

	if allow_reordering and layout_strategy:
		var position = target_container.get_global_mouse_position()
		var potential_index = layout_strategy.get_drop_index_at_position(_visible_objs, self, position)
		if potential_index != _reorder_preview_index and potential_index != -1:
			_reorder_preview_index = potential_index
			_show_reorder_preview(potential_index, true)


func _on_obj_drag_ended(obj: Control) -> void:
	if not obj or obj != _dragging_obj or not obj in _objs:
		return

	var global_pos = target_container.get_global_mouse_position()
	if _is_position_in_container(global_pos):
		if allow_reordering and layout_strategy:
			var new_index = layout_strategy.get_drop_index_at_position(_visible_objs, self, global_pos)
			var current_index = _objs.find(obj)
			_dragging_obj = null
			if new_index != -1 and new_index != current_index:
				move_obj(current_index, new_index, true)
			else:
				_update_layout(true)

		_dragging_obj = null
		_reorder_preview_index = -1
				
		obj_dropped.emit(obj, self)
	else:
		_dragging_obj = null
		_reorder_preview_index = -1
		
		var target_zone = _get_zone_at_position(global_pos)
		if target_zone:
			var obj_global_pos = obj.get_global_position()

			_clear_obj_in_properties(obj)

			_update_visible_objs()
			if auto_arrange:
				_update_layout(true)

			if _is_self_child(obj):
				target_container.remove_child(obj)

			target_zone.add_obj(obj)
			obj.global_position = obj_global_pos

			obj_dropped.emit(obj, target_zone)
			obj_removed.emit(obj)
		else:
			_update_layout(true)
			obj_dropped.emit(obj, self)


func _on_obj_clicked(obj: Control) -> void:
	if not obj:
		return
	if _selected_objs.has(obj):
		_deselect_obj(obj, true)
	else:
		_select_obj(obj, true, true)


func _on_obj_double_clicked(obj: Control) -> void:
	if not obj:
		return
	obj_double_clicked.emit(obj)


#==============================================================================
# 公共方法
#==============================================================================

## 添加一个独立对象到Zone
func add_obj(obj: Control, index: int = -1, animate: bool = true) -> bool:
	if not _can_add_more_objs():
		return false
	
	if index < 0 or index > _objs.size():
		index = _objs.size() - 1
		_objs.append(obj)
	else:
		index = clamp(index, 0, _objs.size())
		_objs.insert(index, obj)

	if not _is_self_child(obj):
		target_container.add_child(obj)
	
	_setup_obj_interaction(obj)
	_update_visible_objs()
	if auto_arrange:
		_update_layout(animate)
	
	obj_added.emit(obj, index)
	return true


## 从Zone移除一个对象
func remove_obj(index: int, animate: bool = true) -> bool:
	if index < 0 or index >= _objs.size():
		return false

	var obj = _objs[index]
	_clear_obj_in_properties(obj)

	if _is_self_child(obj):
		remove_child(obj)

	_update_visible_objs()
	if auto_arrange:
		_update_layout(animate)

	obj_removed.emit(obj)
	return true


## 移动对象在Zone内的位置
func move_obj(old_index: int, new_index: int, animate: bool = true) -> bool:
	if old_index < 0 or old_index >= _objs.size():
		return false
	if new_index < 0 or new_index >= _objs.size():
		return false

	if old_index == new_index:
		return true

	var obj = _objs[old_index]
	_objs.erase(obj)
	_objs.insert(new_index, obj)

	_update_visible_objs()
	if auto_arrange:
		_update_layout(animate)

	objs_reordered.emit()
	return true


## 交换Zone内两个对象的位置
func swap_objs(index_a: int, index_b: int, animate: bool = true) -> bool:
	if index_a < 0 or index_a >= _objs.size():
		return false
	if index_b < 0 or index_b >= _objs.size():
		return false

	if index_a == index_b:
		return true

	var temp = _objs[index_a]
	_objs[index_a] = _objs[index_b]
	_objs[index_b] = temp

	_update_visible_objs()
	if auto_arrange:
		_update_layout(animate)

	objs_reordered.emit()
	return true


## 对Zone内的对象进行排序
func sort_objs(animate: bool = true) -> void:
	if not sort_strategy:
		return

	_objs = sort_strategy.sort(_objs)
	_update_visible_objs()
	if auto_arrange:
		_update_layout(animate)

	objs_reordered.emit()


## 选中Zone内的对象
func select_obj_index(index: int, add_to_selection: bool = false, animate: bool = true) -> void:
	if index < 0 or index >= _objs.size():
		return

	var obj = _objs[index]

	_select_obj(obj, add_to_selection, animate)


## 选中所有Zone内的对象
func select_all_objs(animate: bool = true) -> void:
	if not multi_select_enabled:
		return

	_set_objs_selected(_objs)

	for obj in _selected_objs:
		obj_selected.emit(obj)

	if auto_arrange:
		_update_layout(animate)


## 取消选中Zone内的对象
func deselect_obj_index(index: int, animate: bool = true) -> void:
	if index < 0 or index >= _objs.size():
		return

	_deselect_obj(_objs[index], animate)


## 取消选中所有Zone内的对象
func deselect_all_objs(animate: bool = true) -> void:
	_set_objs_deselected()

	for obj in _selected_objs:
		obj_deselected.emit(obj)

	if auto_arrange:
		_update_layout(animate)


## 清空Zone内的所有对象
func clear_all_objs() -> void:
	var to_remove = _objs.duplicate()
	_objs.clear()
	_selected_objs.clear()
	_visible_objs.clear()

	for obj in to_remove:
		_cleanup_obj_interaction(obj)
		if _is_self_child(obj):
			remove_child(obj)

		obj_removed.emit(obj)


## 刷新可见对象
func refresh_visibility(animate: bool = true) -> void:
	_update_visible_objs()
	if auto_arrange:
		_update_layout(animate)


## 能否接受另一个Zone的对象
func can_accept_obj_from_other(obj: Control, source_zone: Zone) -> bool:
	return true


func move_top_objs_to_other(count: int, target_zone: Zone, animate: bool = true) -> bool:
	if count <= 0 or _objs.is_empty():
		return false

	var actual_count = min(count, _objs.size())
	var indexArray: Array[int] = []
	indexArray.resize(actual_count)
	for i in range(actual_count):
		indexArray[i] = i
	return move_objs_to_other(indexArray, target_zone, animate)


## 移动对象到另一个Zone
func move_objs_to_other(indexArray: Array[int], target_zone: Zone, animate: bool = true) -> bool:
	var target_objs: Array[Control] = []

	for index in indexArray:
		if index < 0 or index >= _objs.size():
			return false

		var obj = _objs[index]
		target_objs.append(obj)
		if not target_zone.can_accept_obj_from_other(obj, self):
			return false
		if not target_zone._can_add_more_objs():
			return false

	for obj in target_objs:
		_clear_obj_in_properties(obj)
		if _is_self_child(obj):
			var obj_global_pos = obj.get_global_position()
			target_container.remove_child(obj)
			obj.global_position = obj_global_pos

	_update_visible_objs()
	if auto_arrange:
		_update_layout(animate)

	for obj in target_objs:
		obj_removed.emit(obj)

	target_zone._accept_objs_from_other(target_objs, self, animate)

	return true


## 根据位置获取对象
func get_obj_at_position(position: Vector2) -> Control:
	for obj in _visible_objs:
		if obj.get_global_rect().has_point(position):
			return obj
	return null


## 获取当前悬停的对象
func get_hovered_obj() -> Control:
	return _hovered_obj


## 获取Zone内的所有对象
func get_objs() -> Array[Control]:
	return _objs.duplicate()


## 获取Zone内的所有可见对象
func get_visible_objs() -> Array[Control]:
	return _visible_objs.duplicate()


## 获取Zone内的所有选中对象
func get_selected_objs() -> Array[Control]:
	return _selected_objs.duplicate()


## 获取Zone内对象的数量
func get_objs_count() -> int:
	return _objs.size()

## 获取Zone内可见对象的数量
func get_visible_count() -> int:
	return _visible_objs.size()


## 获取Zone内选中对象的数量
func get_selected_count() -> int:
	return _selected_objs.size()

## 获取当前拖拽的对象
func get_dragging_obj() -> Control:
	return _dragging_obj

#==============================================================================
# 私有方法
#==============================================================================

## 设置选中对象
func _set_objs_selected(objs: Array[Control]) -> void:
	_selected_objs = objs.duplicate()


## 取消选中对象
func _set_objs_deselected() -> void:
	_selected_objs.clear()


func _select_obj(obj: Control, add_to_selection: bool = false, animate: bool = true) -> void:
	if not multi_select_enabled or not add_to_selection:
		_set_objs_deselected()

	if obj in _selected_objs:
		return
	
	_selected_objs.append(obj)
	obj_selected.emit(obj)

	if animate:
		_update_layout(animate)


func _deselect_obj(obj: Control, animate: bool = true) -> void:
	if obj not in _selected_objs:
		return

	_selected_objs.erase(obj)
	obj_deselected.emit(obj)

	if animate:
		_update_layout(animate)


## Zone是否还能添加更多对象
func _can_add_more_objs() -> bool:
	return max_objs < 0 or _objs.size() < max_objs


## 更新布局
func _update_layout(animate: bool = true) -> void:
	if not layout_strategy or _visible_objs.is_empty():
		return
	
	var transforms = layout_strategy.calculate_transforms(_visible_objs, self)

	for i in range(_visible_objs.size()):
		var obj = _visible_objs[i]
		var target_transform = transforms[i]
		if obj != _dragging_obj:
			_apply_obj_transform(obj, target_transform, animate)

	layout_changed.emit()


## 接收另一个Zone的对象
func _accept_objs_from_other(objs: Array[Control], source_zone: Zone, animate: bool = true) -> bool:
	_objs.append_array(objs)

	for obj in objs:
		var obj_global_pos = obj.get_global_position()
		target_container.add_child(obj)
		_setup_obj_interaction(obj)
		obj.global_position = obj_global_pos

	_update_visible_objs()

	if auto_arrange:
		_update_layout(animate)

	for obj in objs:
		obj_added.emit(obj, _objs.find(obj))

	return true


## 更新可见对象列表
func _update_visible_objs() -> void:
	_visible_objs.clear()

	var filtered_objs = _objs.duplicate()

	if visibility_strategy:
		filtered_objs = visibility_strategy.get_visible_objs(filtered_objs, self)

	_visible_objs = filtered_objs

	for obj in _objs:
		obj.visible = obj in _visible_objs


## 更新悬停布局
func _update_hover_layout(previously_hovered: Control, currently_hovered: Control) -> void:
	if not layout_strategy or _visible_objs.is_empty():
		return
	
	var transforms = layout_strategy.calculate_transforms(_visible_objs, self)

	for i in range(_visible_objs.size()):
		var obj = _visible_objs[i]
		var target_transform = transforms[i]
		if obj == _dragging_obj:
			continue
		if obj == previously_hovered or obj == currently_hovered:
			_apply_obj_transform(obj, target_transform, true)


## 显示重排序预览
func _show_reorder_preview(index: int, animate: bool) -> void:
	if not _dragging_obj or not allow_reordering:
		return

	var preview_objs = _objs.duplicate()
	var current_index = preview_objs.find(_dragging_obj)

	if current_index != -1 and index != current_index:
		preview_objs.erase(_dragging_obj)
		preview_objs.insert(clamp(index, 0, preview_objs.size()), _dragging_obj)

		if visibility_strategy:
			preview_objs = visibility_strategy.get_visible_objs(preview_objs, self)

		if layout_strategy and not preview_objs.is_empty():
			var transforms = layout_strategy.calculate_transforms(preview_objs, self)
			for i in range(preview_objs.size()):
				var obj = preview_objs[i]
				if obj != _dragging_obj:
					_apply_obj_transform(obj, transforms[i], animate)


## 设置对象交互
func _setup_obj_interaction(obj: Control) -> void:
	if not obj.has_node("InteractionComponent"):
		return

	var interaction_component = obj.get_node("InteractionComponent") as InteractionComponent
	if not interaction_component:
		return

	interaction_component.enable_drag = drag_enabled
	interaction_component.enable_click = click_enabled
	interaction_component.enable_double_click = double_click_enabled

	interaction_component.target_control.mouse_entered.connect(_on_obj_mouse_entered.bind(obj))
	interaction_component.target_control.mouse_exited.connect(_on_obj_mouse_exited.bind(obj))
	interaction_component.drag_started.connect(_on_obj_drag_started.bind(obj))
	interaction_component.dragging.connect(_on_obj_dragging.bind(obj))
	interaction_component.drag_ended.connect(_on_obj_drag_ended.bind(obj))
	interaction_component.clicked.connect(_on_obj_clicked.bind(obj))
	interaction_component.double_clicked.connect(_on_obj_double_clicked.bind(obj))


## 清理对象交互
func _cleanup_obj_interaction(obj: Control) -> void:
	if not obj.has_node("InteractionComponent"):
		return

	var interaction_component = obj.get_node("InteractionComponent") as InteractionComponent
	if not interaction_component:
		return

	interaction_component.target_control.mouse_entered.disconnect(_on_obj_mouse_entered)
	interaction_component.target_control.mouse_exited.disconnect(_on_obj_mouse_exited)
	interaction_component.drag_started.disconnect(_on_obj_drag_started)
	interaction_component.dragging.disconnect(_on_obj_dragging)
	interaction_component.drag_ended.disconnect(_on_obj_drag_ended)
	interaction_component.clicked.disconnect(_on_obj_clicked)
	interaction_component.double_clicked.disconnect(_on_obj_double_clicked)


## 设置已有子节点
func _setup_existing_children() -> void:
	var existing_objs: Array[Control] = []
	for child in target_container.get_children():
		if child is Control:
			existing_objs.append(child as Control)
	
	for obj in existing_objs:
		if obj not in _objs:
			_objs.append(obj)
			_setup_obj_interaction(obj)

	if not _objs.is_empty():
		_update_visible_objs()
		if auto_arrange:
			_update_layout(false)


## 判断位置是否在容器内
func _is_position_in_container(position: Vector2) -> bool:
	if not target_container:
		return false
	var rect = target_container.get_global_rect()
	return rect.has_point(position)


func _get_zone_at_position(position: Vector2) -> Zone:
	var zones = get_tree().get_nodes_in_group(zone_group_name)
	for zone in zones:
		if zone is Zone and zone != self:
			var z = zone as Zone
			if z._is_position_in_container(position):
				return z
	return null


## 判断对象是否是当前Zone的子节点
func _is_self_child(obj: Control) -> bool:
	return obj.get_parent() == self.target_container


## 应用对象变换
func _apply_obj_transform(obj: Control, target_transform: Dictionary, animate: bool) -> void:
	var target_pos = target_transform.position
	var target_rot = target_transform.rotation
	var target_scale = target_transform.scale
	var target_z_index = target_transform.z_index

	obj.z_index = target_z_index
	_clear_obj_tween(obj)

	if animate:
		var tween = obj.create_tween()
		_tweens_map[obj] = tween
		tween.set_parallel(true)

		var duration = layout_animation_time / animation_speed
		tween.tween_property(obj, "position", target_pos, duration)
		tween.tween_property(obj, "rotation", target_rot, duration)
		tween.tween_property(obj, "scale", target_scale, duration)

		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)

		await tween.finished
	else:
		obj.position = target_pos
		obj.rotation = target_rot
		obj.scale = target_scale
	
	_update_obj_original_position(obj, target_transform)


## 更新对象原始位置
func _update_obj_original_position(obj: Control, target_transform: Dictionary) -> void:
	if obj.has_node("InteractionComponent"):
		var interaction_component = obj.get_node("InteractionComponent") as InteractionComponent
		if interaction_component:
			interaction_component._original_position = target_transform.position


## 清理对象在属性中的引用
func _clear_obj_in_properties(obj: Control) -> void:
	_objs.erase(obj)
	_selected_objs.erase(obj)
	_visible_objs.erase(obj)
	_cleanup_obj_interaction(obj)
	_clear_obj_tween(obj)


## 清理对象的tween
func _clear_obj_tween(obj: Control) -> void:
	if _tweens_map.has(obj):
		var existing_tween = _tweens_map[obj] as Tween
		if existing_tween and existing_tween.is_valid():
			existing_tween.stop()
			existing_tween.kill()
		_tweens_map.erase(obj)
