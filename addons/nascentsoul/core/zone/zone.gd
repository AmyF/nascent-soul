extends Node
class_name Zone

signal obj_added(obj: Control, index: int)
signal obj_removed(obj: Control)
signal objs_reordered()

signal obj_selected(obj: Control)
signal obj_deselected(obj: Control)
signal obj_double_clicked(obj: Control)
signal obj_dropped(obj: Control, from_zone: Zone)

signal layout_changed()

const zone_group_name: String = "nascentsoul_zones"

var _objs: Array[Control] = []
var _visible_objs: Array[Control] = []
var _selected_objs: Array[Control] = []

var _hovered_obj: Control = null
var _dragging_obj: Control = null
var _reorder_preview_index: int = -1

var _tweens_map: Dictionary = {}

@export var target_container: Control

@export_group("Display")
@export var max_objs: int = -1

@export_group("Strategies")
@export var layout_strategy: ZoneLayoutStrategy
@export var sort_strategy: ZoneSortStrategy
@export var visibility_strategy: ZoneVisibilityStrategy
@export var auto_arrange: bool = true

@export_group("Behavior")
@export var interaction_enabled: bool = true
@export var multi_select_enabled: bool = false
@export var hover_enabled: bool = true
@export var drag_enabled: bool = true
@export var allow_reordering: bool = true

@export_group("Animations")
@export var layout_animation_time: float = 0.3
@export var animation_speed: float = 1.0

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


# 公共方法

func can_accept(obj: Control) -> bool:
	return not is_at_max_capacity()


func add_obj(obj: Control, index: int = -1, animate: bool = true) -> bool:
	if obj in _objs:
		return false

	if not can_add_more_objs():
		return false

	if index < 0 or index > _objs.size():
		_objs.append(obj)
		index = _objs.size() - 1
	else:
		_objs.insert(index, obj)

	if not _is_self_child(obj):
		target_container.add_child(obj)

	_setup_obj_interaction(obj)
	_update_visible_objs()
	if auto_arrange:
		update_layout(animate)
	
	obj_added.emit(obj, index)
	return true


func remove_obj(obj: Control, animate: bool = true) -> bool:
	if obj not in _objs:
		return false

	_clear_obj_in_properties(obj)

	if _is_self_child(obj):
		remove_child(obj)

	_update_visible_objs()
	if auto_arrange:
		update_layout(animate)

	obj_removed.emit(obj)
	return true


func move_obj(obj: Control, new_index: int, animate: bool = true) -> bool:
	if obj not in _objs:
		return false

	var old_index = _objs.find(obj)
	if old_index == new_index:
		return true

	_objs.erase(obj)
	_objs.insert(clamp(new_index, 0, _objs.size()), obj)

	_update_visible_objs()
	if auto_arrange:
		update_layout(animate)

	objs_reordered.emit()
	return true


func swap_objs(obj_a: Control, obj_b: Control, animate: bool = true) -> bool:
	var index_a = _objs.find(obj_a)
	var index_b = _objs.find(obj_b)

	if index_a == -1 or index_b == -1:
		return false

	if index_a == index_b:
		return true

	_objs[index_a] = obj_b
	_objs[index_b] = obj_a

	_update_visible_objs()
	if auto_arrange:
		update_layout(animate)

	objs_reordered.emit()
	return true


func move_obj_to_other(obj: Control, target_zone: Zone, animate: bool = true) -> bool:
	if obj not in _objs:
		return false

	if not target_zone.can_accept(obj):
		return false

	var obj_global_pos = obj.get_global_position()

	_clear_obj_in_properties(obj)

	_update_visible_objs()
	if auto_arrange:
		update_layout(animate)

	if _is_self_child(obj):
		target_container.remove_child(obj)

	target_zone.add_obj(obj)
	obj.global_position = obj_global_pos

	obj_removed.emit(obj)
	return true


func sort_objs(animate: bool = true) -> void:
	if not sort_strategy:
		return

	_objs = sort_strategy.sort(_objs)
	_update_visible_objs()
	if auto_arrange:
		update_layout(animate)

	objs_reordered.emit()


func select_obj(obj: Control, add_to_selection: bool = false, animate: bool = true) -> void:
	if obj not in _objs or not interaction_enabled:
		return

	if not multi_select_enabled or not add_to_selection:
		for selected in _selected_objs.duplicate():
			deselect_obj(selected)
		_selected_objs.clear()

	if obj in _selected_objs:
		return
	
	_selected_objs.append(obj)
	obj_selected.emit(obj)

	if auto_arrange:
		update_layout(animate)


func deselect_obj(obj: Control, animate: bool = true) -> void:
	if obj not in _selected_objs:
		return

	_selected_objs.erase(obj)
	obj_deselected.emit(obj)

	if auto_arrange:
		update_layout(animate)


func clear_selection(animate: bool = true) -> void:
	var to_deselect = _selected_objs.duplicate()
	_selected_objs.clear()

	for obj in to_deselect:
		obj_deselected.emit(obj)

	if auto_arrange:
		update_layout(animate)


func refresh_filter(animate: bool = true) -> void:
	_update_visible_objs()
	if auto_arrange:
		update_layout(animate)


func get_obj_at_position(position: Vector2) -> Control:
	for obj in _visible_objs:
		if obj.get_global_rect().has_point(position):
			return obj
	return null


func get_hovered_obj() -> Control:
	return _hovered_obj


func get_objs() -> Array[Control]:
	return _objs.duplicate()


func get_visible_objs() -> Array[Control]:
	return _visible_objs.duplicate()


func get_selected_objs() -> Array[Control]:
	return _selected_objs.duplicate()


func get_objs_count() -> int:
	return _objs.size()


func get_visible_count() -> int:
	return _visible_objs.size()


func get_selected_count() -> int:
	return _selected_objs.size()


func get_dragging_obj() -> Control:
	return _dragging_obj


func can_add_more_objs() -> bool:
	return max_objs < 0 or _objs.size() < max_objs


func get_remaining_capacity() -> int:
	if max_objs < 0:
		return -1
	return max_objs - _objs.size()


func is_at_max_capacity() -> bool:
	if max_objs < 0:
		return false
	return _objs.size() >= max_objs


func clear_objs(animate: bool = true) -> void:
	var to_remove = _objs.duplicate()
	_objs.clear()
	_selected_objs.clear()
	_visible_objs.clear()

	for obj in to_remove:
		_cleanup_obj_interaction(obj)
		if _is_self_child(obj):
			remove_child(obj)

		obj_removed.emit(obj)

	if auto_arrange:
		update_layout(animate)


func update_layout(animate: bool = true) -> void:
	if not layout_strategy or _visible_objs.is_empty():
		return
	
	var transforms = layout_strategy.calculate_transforms(_visible_objs, self)

	for i in range(_visible_objs.size()):
		var obj = _visible_objs[i]
		var target_transform = transforms[i]
		if obj != _dragging_obj:
			_apply_obj_transform(obj, target_transform, animate)

	layout_changed.emit()

# 私有方法

func _update_visible_objs() -> void:
	_visible_objs.clear()

	var filtered_objs = _objs.duplicate()

	if visibility_strategy:
		filtered_objs = visibility_strategy.get_visible_objs(filtered_objs, self)

	_visible_objs = filtered_objs

	for obj in _objs:
		obj.visible = obj in _visible_objs


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


func _setup_obj_interaction(obj: Control) -> void:
	if not interaction_enabled:
		return
	
	if not obj.has_node("InteractionComponent"):
		return

	var interaction_component = obj.get_node("InteractionComponent") as InteractionComponent
	if not interaction_component:
		return

	interaction_component.enable_drag = drag_enabled
	interaction_component.enable_click = true

	interaction_component.target_control.mouse_entered.connect(_on_obj_mouse_entered.bind(obj))
	interaction_component.target_control.mouse_exited.connect(_on_obj_mouse_exited.bind(obj))
	interaction_component.drag_started.connect(_on_obj_drag_started.bind(obj))
	interaction_component.dragging.connect(_on_obj_dragging.bind(obj))
	interaction_component.drag_ended.connect(_on_obj_drag_ended.bind(obj))
	interaction_component.clicked.connect(_on_obj_clicked.bind(obj))
	interaction_component.double_clicked.connect(_on_obj_double_clicked.bind(obj))


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
			update_layout(false)


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


func _is_self_child(obj: Control) -> bool:
	return obj.get_parent() == self.target_container


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


func _update_obj_original_position(obj: Control, target_transform: Dictionary) -> void:
	if obj.has_node("InteractionComponent"):
		var interaction_component = obj.get_node("InteractionComponent") as InteractionComponent
		if interaction_component:
			interaction_component._original_position = target_transform.position


func _clear_obj_in_properties(obj: Control) -> void:
	_objs.erase(obj)
	_selected_objs.erase(obj)
	_visible_objs.erase(obj)
	_cleanup_obj_interaction(obj)
	_clear_obj_tween(obj)


func _clear_obj_tween(obj: Control) -> void:
	if _tweens_map.has(obj):
		var existing_tween = _tweens_map[obj] as Tween
		if existing_tween and existing_tween.is_valid():
			existing_tween.stop()
			existing_tween.kill()
		_tweens_map.erase(obj)


# 信号处理

func _on_child_entered_tree(child: Node) -> void:
	if child is Control and child not in _objs:
		add_obj(child as Control)


func _on_child_exiting_tree(child: Node) -> void:
	if child is Control and child in _objs:
		remove_obj(child as Control)


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
				deselect_obj(_selected_obj)


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
				move_obj(obj, new_index, true)
			else:
				update_layout(true)

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
				update_layout(true)

			if _is_self_child(obj):
				target_container.remove_child(obj)

			target_zone.add_obj(obj)
			obj.global_position = obj_global_pos

			obj_dropped.emit(obj, target_zone)
			obj_removed.emit(obj)
		else:
			update_layout(true)
			obj_dropped.emit(obj, self)


func _on_obj_clicked(obj: Control) -> void:
	if not obj:
		return
	if _selected_objs.has(obj):
		deselect_obj(obj, true)
	else:
		select_obj(obj, true)


func _on_obj_double_clicked(obj: Control) -> void:
	if not obj:
		return
	obj_double_clicked.emit(obj)
