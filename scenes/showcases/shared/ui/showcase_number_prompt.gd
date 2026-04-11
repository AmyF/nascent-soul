extends Control

signal confirmed(value: int)
signal cancelled

@export var title_text: String = "Select Value"
@export_multiline var detail_text: String = ""
@export var ok_text: String = "OK"
@export var cancel_text: String = "Cancel"
@export var min_value: float = 1.0
@export var max_value: float = 1000000.0
@export var step: float = 1.0
@export var rounded: bool = true

@onready var _title_label: Label = $DialogPanel/DialogVBox/TitleLabel
@onready var _detail_label: Label = $DialogPanel/DialogVBox/DetailLabel
@onready var _spin_box: SpinBox = $DialogPanel/DialogVBox/SelectGameSpinBox
@onready var _ok_button: Button = $DialogPanel/DialogVBox/ButtonRow/SelectGameOkButton
@onready var _cancel_button: Button = $DialogPanel/DialogVBox/ButtonRow/SelectGameCancelButton

func _ready() -> void:
	_apply_configuration()
	_ok_button.pressed.connect(_on_ok_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)

func configure_range(minimum: float, maximum: float, step_value: float = 1.0) -> void:
	min_value = minimum
	max_value = maximum
	step = step_value
	if is_node_ready():
		_apply_configuration()

func popup_prompt(initial_value: float) -> void:
	if is_node_ready():
		_spin_box.value = clampf(initial_value, min_value, max_value)
		_spin_box.grab_focus()
	visible = true

func hide_prompt() -> void:
	visible = false

func current_int_value() -> int:
	return int(_spin_box.value)

func confirm() -> void:
	confirmed.emit(current_int_value())

func _apply_configuration() -> void:
	_title_label.text = title_text
	_detail_label.text = detail_text
	_spin_box.min_value = min_value
	_spin_box.max_value = max_value
	_spin_box.step = step
	_spin_box.rounded = rounded
	_ok_button.text = ok_text
	_cancel_button.text = cancel_text

func _on_ok_pressed() -> void:
	confirm()

func _on_cancel_pressed() -> void:
	hide_prompt()
	cancelled.emit()
