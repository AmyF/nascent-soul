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

@export_group("Keyboard")
@export var keyboard_navigation_enabled: bool = true
@export var wrap_navigation: bool = true
@export var next_item_action: StringName = &"ui_right"
@export var previous_item_action: StringName = &"ui_left"
@export var activate_item_action: StringName = &"ui_accept"
@export var clear_selection_action: StringName = &"ui_cancel"
