@tool
class_name ZoneArrowTargetingStyle extends ZoneTargetingStyle

@export_group("Colors")
@export var neutral_color: Color = Color(0.84, 0.88, 0.96, 0.85)
@export var valid_color: Color = Color(0.42, 0.90, 0.62, 0.92)
@export var invalid_color: Color = Color(1.0, 0.42, 0.42, 0.92)

@export_group("Geometry")
@export_range(1.0, 18.0, 0.5) var line_width: float = 6.0
@export_range(4.0, 48.0, 0.5) var arrow_head_size: float = 18.0
@export_range(0.02, 0.40, 0.01) var curvature: float = 0.16
@export_range(8.0, 48.0, 0.5) var target_ring_radius: float = 24.0

@export_group("Motion")
@export var pulse_enabled: bool = true
@export_range(0.5, 12.0, 0.1) var pulse_speed: float = 4.0

func create_overlay(_coordinator: Node) -> Control:
	return ZoneArrowTargetingOverlay.new()

func update_overlay(overlay: Control, _session, source_anchor: Vector2, candidate: ZoneTargetCandidate, decision: ZoneTargetDecision, pointer_global_position: Vector2) -> void:
	if overlay == null or not is_instance_valid(overlay) or overlay is not ZoneArrowTargetingOverlay:
		return
	var resolved_candidate = decision.resolved_candidate if decision != null and decision.resolved_candidate != null and decision.resolved_candidate.is_valid() else candidate
	var visual_state = ZoneArrowTargetingOverlay.VisualState.NEUTRAL
	var show_ring = false
	var end_anchor = pointer_global_position
	if resolved_candidate != null and resolved_candidate.is_valid():
		end_anchor = resolved_candidate.global_position
		show_ring = true
		if decision != null and decision.allowed:
			visual_state = ZoneArrowTargetingOverlay.VisualState.VALID
		else:
			visual_state = ZoneArrowTargetingOverlay.VisualState.INVALID
	(overlay as ZoneArrowTargetingOverlay).set_arrow_state(
		source_anchor,
		end_anchor,
		visual_state,
		line_width,
		arrow_head_size,
		curvature,
		target_ring_radius,
		show_ring,
		neutral_color,
		valid_color,
		invalid_color,
		pulse_enabled,
		pulse_speed
	)
