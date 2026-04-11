class_name ZoneTargetingService extends RefCounted

# Internal runtime helper for targeting candidate resolution and feedback.

const ZoneRuntimePortScript = preload("res://addons/nascentsoul/runtime/zone_runtime_port.gd")
const ZoneTargetResolutionScript = preload("res://addons/nascentsoul/runtime/zone_target_resolution.gd")
const ZoneTargetFeedbackScript = preload("res://addons/nascentsoul/runtime/zone_target_feedback.gd")

var context: ZoneContext
var zone: Zone
var runtime_port = null

var _resolution = null
var _feedback = null

func _init(p_context: ZoneContext, p_runtime_port) -> void:
	context = p_context
	zone = context.zone
	runtime_port = p_runtime_port
	_resolution = ZoneTargetResolutionScript.new(self, context)
	_feedback = ZoneTargetFeedbackScript.new(self)

## Clears targeting feedback and releases resolution helpers for this zone.
func cleanup() -> void:
	if _feedback != null:
		_feedback.cleanup()
	if _resolution != null:
		_resolution.cleanup()
	_feedback = null
	_resolution = null
	runtime_port = null
	zone = null
	context = null

## Starts an explicit targeting session for command, filling in a missing pointer position from the viewport when needed.
func begin_targeting(command: ZoneTargetingCommand) -> bool:
	if command == null or not is_instance_valid(command.source_item):
		return false
	var resolved_command = command.duplicate_command()
	if resolved_command.pointer_global_position == Vector2.ZERO:
		if zone.get_viewport() != null:
			resolved_command.pointer_global_position = zone.get_viewport().get_mouse_position()
		else:
			resolved_command.pointer_global_position = resolved_command.source_item.global_position
	return start_targeting_internal(resolved_command)

## Starts drag-driven targeting for item when it can resolve a drag intent.
func try_start_drag_targeting(item: ZoneItemControl, global_position: Vector2) -> bool:
	var command = ZoneTargetingCommand.drag_for_item(zone, item, null, global_position)
	command.intent = resolve_targeting_intent(command, &"drag")
	if command.intent == null:
		return false
	return start_targeting_internal(command)

## Cancels the active targeting session owned by this zone, if any.
func cancel_targeting() -> void:
	var coordinator = get_targeting_coordinator(false)
	if coordinator == null:
		return
	var session = coordinator.get_session()
	if session == null or session.source_zone != zone:
		return
	cancel_targeting_session(session, true)

## Recomputes candidate and decision feedback for session at global_position and refreshes overlays.
func update_targeting_session(session: ZoneTargetingSession, global_position: Vector2) -> void:
	if session == null or session.source_zone != zone or not is_instance_valid(session.source_item):
		return
	session.pointer_global_position = global_position
	var next_candidate = resolve_target_candidate(session.intent, global_position)
	var next_decision = resolve_target_decision(session.source_item, session.intent, next_candidate, global_position)
	apply_targeting_feedback(session, next_candidate, next_decision)
	var coordinator = get_targeting_coordinator(false)
	if coordinator != null and coordinator.get_session() == session:
		coordinator.refresh_overlay()

## Resolves session when its latest decision is allowed; otherwise cancels it.
func finalize_targeting_session(session: ZoneTargetingSession) -> void:
	if session == null or session.source_zone != zone:
		return
	if session.decision != null and session.decision.allowed and session.decision.resolved_candidate != null and session.decision.resolved_candidate.is_valid():
		clear_targeting_feedback(true, session.source_item)
		if runtime_port != null:
			runtime_port.emit_targeting_resolved(session.source_item, zone, session.decision.resolved_candidate, session.decision)
		var coordinator = get_targeting_coordinator(false)
		if coordinator != null:
			coordinator.clear_session()
		return
	cancel_targeting_session(session, true)

## Clears session feedback and optionally emits targeting_cancelled before removing the session.
func cancel_targeting_session(session: ZoneTargetingSession, emit_signal: bool) -> void:
	if session == null or session.source_zone != zone:
		return
	clear_targeting_feedback(emit_signal, session.source_item)
	if emit_signal and is_instance_valid(session.source_item):
		if runtime_port != null:
			runtime_port.emit_targeting_cancelled(session.source_item, zone)
	var coordinator = get_targeting_coordinator(false)
	if coordinator != null:
		coordinator.clear_session()

## Validates command ownership, resolves intent, and creates the runtime targeting session.
func start_targeting_internal(command: ZoneTargetingCommand) -> bool:
	if command == null or not context.has_item(command.source_item):
		return false
	var resolved_intent = command.intent if command.intent != null else resolve_targeting_intent(command, command.entry_mode)
	if resolved_intent == null:
		return false
	var coordinator = get_targeting_coordinator(true)
	if coordinator == null:
		return false
	var drag_coordinator = get_drag_coordinator(false)
	if drag_coordinator != null and drag_coordinator.get_session() != null:
		return false
	command.intent = resolved_intent
	var source_anchor = resolve_item_target_anchor_global(command.source_item)
	var session = coordinator.start_targeting(zone, context, command.source_item, resolved_intent, command.entry_mode, source_anchor, command.pointer_global_position)
	if session == null:
		return false
	update_targeting_session(session, command.pointer_global_position)
	if runtime_port != null:
		runtime_port.emit_targeting_started(command.source_item, zone, resolved_intent)
	return true

## Asks the source item for the targeting intent to use for this command and entry mode.
func resolve_targeting_intent(command: ZoneTargetingCommand, entry_mode: StringName) -> ZoneTargetingIntent:
	if command == null or not is_instance_valid(command.source_item):
		return null
	return command.source_item.create_zone_targeting_intent(command, entry_mode)

func resolve_item_target_anchor_global(item: ZoneItemControl) -> Vector2:
	return _resolution.resolve_item_target_anchor_global(item)

func resolve_target_candidate(intent: ZoneTargetingIntent, global_position: Vector2) -> ZoneTargetCandidate:
	return _resolution.resolve_target_candidate(intent, global_position)

func resolve_target_decision(source_item: ZoneItemControl, intent: ZoneTargetingIntent, current_candidate: ZoneTargetCandidate, global_position: Vector2) -> ZoneTargetDecision:
	return _resolution.resolve_target_decision(source_item, intent, current_candidate, global_position)

func resolve_target_candidate_from_decision(current_decision: ZoneTargetDecision, fallback: ZoneTargetCandidate) -> ZoneTargetCandidate:
	return _resolution.resolve_target_candidate_from_decision(current_decision, fallback)

func collect_targeting_zones() -> Array[Zone]:
	return _resolution.collect_targeting_zones()

func build_item_candidate(target_zone: Zone, item: ZoneItemControl, global_position: Vector2) -> ZoneTargetCandidate:
	return _resolution.build_item_candidate(target_zone, item, global_position)

func build_placement_candidate(target_zone: Zone, placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTargetCandidate:
	return _resolution.build_placement_candidate(target_zone, placement_target, global_position)

func build_candidate_metadata(item: ZoneItemControl, placement_target: ZonePlacementTarget) -> Dictionary:
	return _resolution.build_candidate_metadata(item, placement_target)

func apply_targeting_feedback(session: ZoneTargetingSession, next_candidate: ZoneTargetCandidate, next_decision: ZoneTargetDecision) -> void:
	_feedback.apply_targeting_feedback(session, next_candidate, next_decision)

func clear_targeting_feedback(emit_clear_signals: bool, source_item: ZoneItemControl = null) -> void:
	_feedback.clear_targeting_feedback(emit_clear_signals, source_item)

func resolve_zone_context(target_zone: Zone) -> ZoneContext:
	return ZoneRuntimePortScript.resolve_context(target_zone)

func emit_target_preview_changed(source_item: ZoneItemControl, target_zone: Zone, candidate) -> void:
	if runtime_port != null:
		runtime_port.emit_target_preview_changed(source_item, target_zone, candidate)

func emit_target_hover_state_changed(source_item: ZoneItemControl, target_zone: Zone, decision) -> void:
	if runtime_port != null:
		runtime_port.emit_target_hover_state_changed(source_item, target_zone, decision)

func get_targeting_coordinator(create_if_missing: bool = true):
	return runtime_port.get_targeting_coordinator(create_if_missing) if runtime_port != null else null

func get_drag_coordinator(create_if_missing: bool = true):
	return runtime_port.get_drag_coordinator(create_if_missing) if runtime_port != null else null
