@tool
class_name ZoneInteraction extends Resource

@export_group("Gestures")
@export var drag_enabled: bool = true
@export var drag_threshold: float = 5.0
@export var long_press_enabled: bool = false
@export var long_press_time: float = 0.5

@export_group("Selection")
@export var select_on_click: bool = true
@export var multi_select_enabled: bool = true
@export var ctrl_toggles_selection: bool = true
@export var shift_range_select_enabled: bool = true
@export var clear_selection_on_background_click: bool = true
