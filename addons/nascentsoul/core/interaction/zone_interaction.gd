# ZoneInteraction.gd
class_name ZoneInteraction
extends Resource

## ZoneInteraction 是交互逻辑的基类。
## 它负责为 Zone 中管理的每个对象动态地连接和断开输入信号。
## 它捕获原始的 InputEvent，解析它们（单击、双击、拖拽等），
## 然后通过 Zone 对外发出更高级别、更清晰的信号。
## 它还负责实现拖拽时的“视觉捕获”预览机制。


#=============================================================================
# 1. 导出属性 (Inspector配置)
#=============================================================================

## 定义多选的修饰键
enum ModifierKey { NONE, SHIFT, CTRL, ALT }

## 是否启用单击事件。
@export var enable_click: bool = true
## 是否启用双击事件。
@export var enable_double_click: bool = true
## 是否启用拖拽事件。
@export var enable_drag: bool = true
## 是否启用鼠标进入/离开事件 (用于悬停效果)。
@export var enable_hover_events: bool = true
## 是否启用多选功能。
@export var enable_multi_select: bool = true
## 定义多选的修饰键。
@export var multi_select_modifier: ModifierKey = ModifierKey.SHIFT
## 是否启用拖拽框选功能 (此基础类中未实现，为未来扩展保留)。
@export var enable_box_select: bool = false


#=============================================================================
# 2. 私有变量 (内部状态管理)
#=============================================================================

# 对Zone的引用，用于发射信号
var _zone_reference: Zone

# --- 拖拽状态变量 ---
const DRAG_THRESHOLD = 5.0 # 拖拽操作开始前鼠标需要移动的最小像素距离
var _is_dragging: bool = false
var _drag_start_position: Vector2
var _dragged_item: Control
var _drag_offset: Vector2 # 鼠标相对于对象左上角的偏移
var _original_z_index: int = 0

# --- 点击状态变量 ---
const DOUBLE_CLICK_TIME = 0.3 # 秒
var _click_timer: Timer
var _last_clicked_item: Control
var _click_count: int = 0

#=============================================================================
# 3. 生命周期方法 (Lifecycle Method)
#=============================================================================

## 当Zone准备就绪时，会调用此方法来初始化资源。
func _setup(zone: Zone):
	# 保存对Zone的引用，这是发射信号和访问场景树的关键
	_zone_reference = zone
		
	# 创建用于区分单击和双击的计时器
	# MOVED: 将计时器创建逻辑从 setup_item_signals 移到此处，因为它属于资源自身的初始化
	if not is_instance_valid(_click_timer):
		_click_timer = Timer.new()
		_click_timer.wait_time = DOUBLE_CLICK_TIME
		_click_timer.one_shot = true
		_click_timer.timeout.connect(_on_click_timer_timeout)
		# 将计时器添加到场景树中，否则它不会运行
		_zone_reference.add_child(_click_timer)


#=============================================================================
# 4. 公共方法 (由Zone调用)
#=============================================================================

## 当一个对象被添加到Zone时，Zone会调用此方法。
func setup_item_signals(item: Control, zone: Zone):
	# 连接必要的信号。使用bind()将item自身作为参数传递，这样回调函数就知道是哪个item触发了事件。
	if not item.gui_input.is_connected(_on_gui_input):
		item.gui_input.connect(_on_gui_input.bind(item))
		
	if enable_hover_events:
		if not item.mouse_entered.is_connected(_on_mouse_entered):
			item.mouse_entered.connect(_on_mouse_entered.bind(item))
		if not item.mouse_exited.is_connected(_on_mouse_exited):
			item.mouse_exited.connect(_on_mouse_exited.bind(item))


## 当一个对象从Zone中移除时，Zone会调用此方法。
func cleanup_item_signals(item: Control):
	# 断开所有连接，防止内存泄漏和意外行为
	if item.gui_input.is_connected(_on_gui_input):
		item.gui_input.disconnect(_on_gui_input)
	
	if enable_hover_events:
		if item.mouse_entered.is_connected(_on_mouse_entered):
			item.mouse_entered.disconnect(_on_mouse_entered)
		if item.mouse_exited.is_connected(_on_mouse_exited):
			item.mouse_exited.disconnect(_on_mouse_exited)


#=============================================================================
# 5. 信号回调 (核心逻辑)
#=============================================================================

## 处理所有鼠标进出事件
func _on_mouse_entered(item: Control):
	_zone_reference.item_mouse_entered.emit(item, _zone_reference)

func _on_mouse_exited(item: Control):
	_zone_reference.item_mouse_exited.emit(item, _zone_reference)


## 处理所有GUI输入事件，这是最核心的处理器
func _on_gui_input(event: InputEvent, item: Control):
	# 只处理鼠标按钮事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# -- 鼠标按下 --
			if enable_drag:
				_drag_start_position = event.global_position
				_dragged_item = item

			if enable_click or enable_double_click:
				_click_count += 1
				if _click_count == 1: # 第一次点击
					_last_clicked_item = item
					_click_timer.start()
				elif _click_count == 2 and _last_clicked_item == item: # 第二次点击，且是同一个item
					_click_timer.stop() # 阻止单击事件
					_handle_double_click(item)
		else:
			# -- 鼠标释放 --
			if _is_dragging:
				_stop_drag()
			
			_dragged_item = null
	
	# 处理拖拽过程中的鼠标移动
	if event is InputEventMouseMotion and _dragged_item and not _is_dragging:
		if _drag_start_position.distance_to(event.global_position) > DRAG_THRESHOLD:
			_start_drag()

	# 更新拖拽预览的位置
	if _is_dragging and event is InputEventMouseMotion:
		if is_instance_valid(_dragged_item):
			_dragged_item.global_position = event.global_position + _drag_offset


## 当单击计时器超时，意味着没有发生双击，这是一个单击
func _on_click_timer_timeout():
	if _is_dragging: # 如果在计时期间开始了拖拽，则取消单击
		_click_count = 0
		return

	if not _last_clicked_item:
		_click_count = 0
		return

	# -- 处理单击逻辑 --
	if enable_click:
		var additive = false
		if enable_multi_select:
			# 检查多选修饰键是否被按下
			match multi_select_modifier:
				ModifierKey.SHIFT:
					additive = Input.is_key_pressed(KEY_SHIFT)
				ModifierKey.CTRL:
					additive = Input.is_key_pressed(KEY_CTRL)
				ModifierKey.ALT:
					additive = Input.is_key_pressed(KEY_ALT)
		
		# 调用Zone的方法来处理选择状态
		if _last_clicked_item in _zone_reference.selected_items:
			_zone_reference.deselect_item(_last_clicked_item)
		else:
			_zone_reference.select_item(_last_clicked_item, additive)
		_zone_reference.item_clicked.emit(_last_clicked_item, _zone_reference)

	_click_count = 0
	_last_clicked_item = null


## 内部函数，用于处理双击
func _handle_double_click(item: Control):
	if enable_double_click:
		_zone_reference.item_double_clicked.emit(item, _zone_reference)
	_click_count = 0
	_last_clicked_item = null


#=============================================================================
# 6. 辅助方法 (拖拽预览实现)
#=============================================================================

## 开始拖拽操作
func _start_drag():
	if not _dragged_item: return

	_is_dragging = true
	_click_timer.stop() # 拖拽开始，取消任何待处理的单击
	_click_count = 0
	
	_drag_offset = _dragged_item.global_position - _drag_start_position
	_original_z_index = _dragged_item.z_index
	_dragged_item.z_index = 1000 # 提升z_index，确保在最上层显示
	
	_zone_reference.item_drag_started.emit(_dragged_item, _zone_reference)


## 停止拖拽操作
func _stop_drag():
	_is_dragging = false
	
	# 恢复显示原始对象
	if is_instance_valid(_dragged_item):
		_dragged_item.z_index = _original_z_index

	# 发出拖拽结束信号
	_zone_reference.item_dropped.emit(_dragged_item, _zone_reference)
