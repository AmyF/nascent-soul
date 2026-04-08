class_name ZonePlacement extends RefCounted

var item: Control = null
var position: Vector2 = Vector2.ZERO
var rotation: float = 0.0
var scale: Vector2 = Vector2.ONE
var z_index: int = 0
var instant: bool = false

func _init(p_item: Control = null, p_position: Vector2 = Vector2.ZERO, p_rotation: float = 0.0, p_scale: Vector2 = Vector2.ONE, p_z_index: int = 0, p_instant: bool = false) -> void:
	item = p_item
	position = p_position
	rotation = p_rotation
	scale = p_scale
	z_index = p_z_index
	instant = p_instant
