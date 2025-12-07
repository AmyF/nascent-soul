@tool
class_name Zone extends Node

# --- 信号定义 ---
# 当物品成功进入本 Zone 时触发 (包括从其他 Zone 拖入或本 Zone 内部重排)
signal item_dropped(item: Control, source_zone: Zone)

# 当物品离开本 Zone 时触发
signal item_removed(item: Control, target_zone: Zone)

# 当布局发生任何变化 (添加、移除、重排) 时触发
signal layout_changed()

# --- 配置 ---
@export var container: Control
@export_group("Modules")
@export var layout: ZoneLayout
@export var display: ZoneDisplay
@export var interaction: ZoneInteraction
@export var sort: ZoneSort
@export var permission: ZonePermission

# --- 内部状态 ---
var _items: Array[Control] = []
var _ghost_instance: Control = null

func _ready():
	if not container:
		return
	
	container.child_entered_tree.connect(_on_child_entered)
	container.child_exiting_tree.connect(_on_child_exited)
	
	for child in container.get_children():
		if child is Control:
			_register_item(child)
	
	call_deferred("refresh")

func _process(_delta):
	if Engine.is_editor_hint(): return
	
	if ZoneDragContext.is_dragging:
		_process_drag_state()
	else:
		if is_instance_valid(_ghost_instance):
			_clear_ghost()
			refresh()

# --- 核心刷新 ---
func refresh():
	if not container or not layout or not display: return
	
	var layout_items: Array[Control] = []
	var raw_children = container.get_children()
	
	for child in raw_children:
		if not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
		if not (child is Control):
			continue
		
		if ZoneDragContext.is_dragging and child in ZoneDragContext.dragging_items:
			continue
			
		if child.visible or child == _ghost_instance:
			layout_items.append(child)
	
	if sort and not ZoneDragContext.is_dragging:
		_items = sort.process_sort(layout_items)
	else:
		_items = layout_items

	var transforms = layout.calculate(_items, container.size, -1, Vector2.ZERO, _ghost_instance)
	
	display.apply(_items, transforms, _ghost_instance)

# --- 拖拽逻辑 ---
func start_drag(items: Array[Control]):
	if items.is_empty(): return
	
	ZoneDragContext.is_dragging = true
	ZoneDragContext.dragging_items = items
	ZoneDragContext.source_zone = self
	ZoneDragContext.drag_offset = items[0].get_global_mouse_position() - items[0].global_position
	
	var proxy = items[0].duplicate(0)
	proxy.modulate.a = 0.8
	proxy.top_level = true
	proxy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	proxy.global_position = items[0].global_position
	get_tree().root.add_child(proxy)
	ZoneDragContext.cursor_proxy = proxy
	
	for item in items:
		item.visible = false
	
	set_process(true)

func _process_drag_state():
	var global_mouse = get_viewport().get_mouse_position()
	
	if is_instance_valid(ZoneDragContext.cursor_proxy):
		ZoneDragContext.cursor_proxy.global_position = global_mouse - ZoneDragContext.drag_offset
	
	var is_hovering_me = container.get_global_rect().has_point(global_mouse)
	
	if is_hovering_me:
		ZoneDragContext.hover_zone = self
		
		if not is_instance_valid(_ghost_instance):
			_create_ghost()
			refresh()
		
		var items_for_calc: Array[Control] = []
		for item in _items:
			if item != _ghost_instance:
				items_for_calc.append(item)
		
		var local_mouse = container.get_local_mouse_position()
		var logical_index = layout.get_insertion_index(items_for_calc, container.size, local_mouse)
		var target_abs_index = _get_absolute_index_from_logical(logical_index)
		
		if is_instance_valid(_ghost_instance):
			var current_index = _ghost_instance.get_index()
			if current_index != target_abs_index:
				container.move_child(_ghost_instance, target_abs_index)
				refresh()
				
	else:
		if ZoneDragContext.hover_zone == self:
			ZoneDragContext.hover_zone = null
		
		if is_instance_valid(_ghost_instance):
			_clear_ghost()
			refresh()

	if ZoneDragContext.source_zone == self:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var target = ZoneDragContext.hover_zone
			if is_instance_valid(target) and target is Zone:
				target._perform_drop()
			else:
				_cancel_drag()

func _get_absolute_index_from_logical(logical_index: int) -> int:
	var visible_counter = 0
	var abs_index = 0
	var children = container.get_children()
	
	for child in children:
		if child is not Control:
			continue
		if child == _ghost_instance: 
			abs_index += 1
			continue
		if ZoneDragContext.is_dragging and child in ZoneDragContext.dragging_items:
			abs_index += 1
			continue
		if not child.visible:
			abs_index += 1
			continue
			
		if visible_counter == logical_index:
			return abs_index
		
		visible_counter += 1
		abs_index += 1
	
	return -1

func _perform_drop():
	var items = ZoneDragContext.dragging_items
	var source = ZoneDragContext.source_zone
	
	if permission and not permission.can_drop(self, items, source):
		if source.has_method("_cancel_drag"):
			source._cancel_drag()
		return
	
	var target_index = container.get_child_count()
	if is_instance_valid(_ghost_instance):
		target_index = _ghost_instance.get_index()
	
	var drop_visual_pos = Vector2.ZERO
	if is_instance_valid(ZoneDragContext.cursor_proxy):
		drop_visual_pos = ZoneDragContext.cursor_proxy.global_position
	
	for item in items:
		if not is_instance_valid(item): continue
		
		if item.get_parent() != container:
			item.reparent(container, false)
		
		item.visible = true
		item.global_position = drop_visual_pos
		
		if is_instance_valid(_ghost_instance):
			container.move_child(item, _ghost_instance.get_index())
		else:
			container.move_child(item, target_index)
			target_index += 1
		
		# --- 信号发射 ---
		# 1. 通知本 Zone：有东西进来了
		item_dropped.emit(item, source)
		
		# 2. 通知源 Zone：有东西走了 (如果源不是自己)
		# 注意：如果是内部重排，source == self，此时 item_dropped 和 item_removed 都会触发
		# 这符合逻辑：它既被“放下”到了新位置，也被“移出”了旧状态
		if is_instance_valid(source):
			source.item_removed.emit(item, self)
			
	_clear_ghost()
	ZoneDragContext.clear()
	
	refresh()
	layout_changed.emit()
	
	if is_instance_valid(source) and source != self:
		source.refresh()
		source.layout_changed.emit()

func _cancel_drag():
	for item in ZoneDragContext.dragging_items:
		if is_instance_valid(item):
			item.visible = true
	_clear_ghost()
	ZoneDragContext.clear()
	refresh()

func _create_ghost():
	if ZoneDragContext.dragging_items.is_empty(): return
	var drag_item = ZoneDragContext.dragging_items[0]
	
	var ghost_scn = drag_item.get_meta("zone_ghost_scene", null)
	if ghost_scn and ghost_scn is PackedScene:
		_ghost_instance = ghost_scn.instantiate()
		_ghost_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(_ghost_instance)
		if is_instance_valid(ZoneDragContext.cursor_proxy):
			_ghost_instance.global_position = ZoneDragContext.cursor_proxy.global_position
	else:
		_ghost_instance = Control.new()
		_ghost_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ghost_instance.custom_minimum_size = drag_item.size
		_ghost_instance.size = drag_item.size
		container.add_child(_ghost_instance)

func _clear_ghost():
	if is_instance_valid(_ghost_instance):
		_ghost_instance.queue_free()
	_ghost_instance = null

func _register_item(item: Control):
	if interaction:
		interaction.register_item(self, item)
	if not item.gui_input.is_connected(_on_item_gui_input):
		item.gui_input.connect(_on_item_gui_input.bind(item))

func _on_child_entered(node: Node):
	if node is Control and node != _ghost_instance:
		_register_item(node)
		if not ZoneDragContext.is_dragging:
			refresh()
			layout_changed.emit()

func _on_child_exited(node: Node):
	if node is Control:
		if not ZoneDragContext.is_dragging:
			refresh()
			layout_changed.emit()

func _on_item_gui_input(event: InputEvent, item: Control):
	if interaction:
		interaction.handle_input(self, item, event)
