@tool
class_name ZoneTargetingVisualLayer extends Resource

@export_group("Colors")
@export var neutral_color: Color = Color(0.84, 0.88, 0.96, 0.85)
@export var valid_color: Color = Color(0.42, 0.90, 0.62, 0.92)
@export var invalid_color: Color = Color(1.0, 0.42, 0.42, 0.92)

func create_nodes(_host: ZoneTargetingOverlayHost) -> void:
	pass

func update_nodes(_host: ZoneTargetingOverlayHost, _frame: ZoneTargetingVisualFrame) -> void:
	pass

func clear_nodes(_host: ZoneTargetingOverlayHost) -> void:
	pass

func get_layer_key() -> StringName:
	if resource_name.strip_edges() != "":
		return StringName(_sanitize_token(resource_name))
	return StringName(_sanitize_token(get_class()))

func resolve_frame_color(frame: ZoneTargetingVisualFrame) -> Color:
	if frame == null:
		return neutral_color
	match frame.visual_state:
		ZoneTargetingVisualFrame.VisualState.VALID:
			return valid_color
		ZoneTargetingVisualFrame.VisualState.INVALID:
			return invalid_color
		_:
			return neutral_color

func _sanitize_token(value: String) -> String:
	return value.strip_edges().to_lower().replace(" ", "_").replace("/", "_").replace("-", "_")
