extends Node
class_name InteractionComponent

signal clicked
signal double_clicked
signal drag_started
signal drag_ended
signal dragging(delta_position: Vector2)

@export var target_control: Control

@export var double_click_time_threshold: float = 0.2
@export var click_distance_threshold: float = 5.0
@export var drag_distance_threshold: float = 10.0
@export var drag_z_index: int = 1000

@export var enable_drag: bool = true
@export var enable_click: bool = true
@export var enable_double_click: bool = true

var _is_dragging: bool = false
var _is_mouse_pressed: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO

var _click_timer: Timer
var _click_count: int = 0
var _last_click_position: Vector2 = Vector2.ZERO
var _mouse_start_position: Vector2 = Vector2.ZERO
var _has_moved_enough_for_drag: bool = false

func _ready() -> void:
	if not target_control:
		push_error("DraggableClickableControl requires a target_control to function.")
		return
	
	if target_control.focus_mode == Control.FOCUS_NONE:
		target_control.focus_mode = Control.FOCUS_CLICK

	_click_timer = Timer.new()
	_click_timer.wait_time = double_click_time_threshold
	_click_timer.one_shot = true
	_click_timer.timeout.connect(_on_click_timer_timeout)
	add_child(_click_timer)

	target_control.gui_input.connect(_on_target_gui_input)


# 公共方法

func set_target(control: Control) -> void:
	if target_control:
		if target_control.gui_input.is_connected(_on_target_gui_input):
			target_control.gui_input.disconnect(_on_target_gui_input)
	
	target_control = control

	if target_control:
		target_control.gui_input.connect(_on_target_gui_input)


func reset_position() -> void:
	if target_control:
		target_control.rect_position = _original_position


func is_dragging() -> bool:
	return _is_dragging


# 私有方法

func _handle_mouse_down(event: InputEventMouseButton) -> void:
	_is_mouse_pressed = true
	_mouse_start_position = event.position
	_has_moved_enough_for_drag = false

	if enable_click:
		_drag_offset = target_control.global_position - event.global_position
		_original_position = target_control.position


func _handle_mouse_up(event: InputEventMouseButton) -> void:
	_is_mouse_pressed = false
	var was_dragging = _is_dragging

	if _is_dragging:
		_is_dragging = false
		drag_ended.emit()
		target_control.release_focus()

	if not was_dragging and not _has_moved_enough_for_drag:
		_handle_click(event)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not enable_drag:
		return

	if not _is_dragging:
		var distance = _mouse_start_position.distance_to(event.position)
		if distance > drag_distance_threshold:
			_has_moved_enough_for_drag = true
			_is_dragging = true
			target_control.z_index = drag_z_index
			drag_started.emit()
			target_control.grab_focus()

	if _is_dragging:
		var new_position = event.global_position + _drag_offset
		var delta = new_position - target_control.global_position
		target_control.global_position = new_position
		dragging.emit(delta)


func _handle_click(event: InputEventMouseButton) -> void:
	if not enable_click:
		return
	
	var current_position = event.position

	if _click_count > 0:
		var distance = _last_click_position.distance_to(current_position)
		if distance > click_distance_threshold:
			_click_count = 0

	_last_click_position = current_position
	_click_count += 1

	if _click_count == 1:
		_click_timer.start()
	elif _click_count == 2 and enable_double_click:
		_click_timer.start()
		_click_count = 0
		double_clicked.emit()


# 信号处理

func _on_target_gui_input(event: InputEvent) -> void:
	if not target_control:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_mouse_down(event)
			else:
				_handle_mouse_up(event)
	elif event is InputEventMouseMotion and _is_mouse_pressed:
		_handle_mouse_motion(event)


func _on_click_timer_timeout() -> void:
	if _click_count == 1:
		clicked.emit()
	_click_count = 0
