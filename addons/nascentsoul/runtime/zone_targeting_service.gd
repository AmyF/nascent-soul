class_name ZoneTargetingService extends RefCounted

var context: ZoneContext
var zone: Zone

var candidate: ZoneTargetCandidate = ZoneTargetCandidate.invalid()
var decision: ZoneTargetDecision = ZoneTargetDecision.new()
var highlight_item: ZoneItemControl = null

func _init(p_context: ZoneContext) -> void:
	context = p_context
	zone = context.zone

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

func try_start_drag_targeting(item: ZoneItemControl, global_position: Vector2) -> bool:
	var command = ZoneTargetingCommand.drag_for_item(zone, item, null, global_position)
	command.intent = resolve_targeting_intent(command, &"drag")
	if command.intent == null:
		return false
	return start_targeting_internal(command)

func cancel_targeting() -> void:
	var coordinator = zone.get_targeting_coordinator(false)
	if coordinator == null:
		return
	var session = coordinator.get_session()
	if session == null or session.source_zone != zone:
		return
	cancel_targeting_session(session, true)

func update_targeting_session(session: ZoneTargetingSession, global_position: Vector2) -> void:
	if session == null or session.source_zone != zone or not is_instance_valid(session.source_item):
		return
	session.pointer_global_position = global_position
	var next_candidate = resolve_target_candidate(session.intent, global_position)
	var next_decision = resolve_target_decision(session.source_item, session.intent, next_candidate, global_position)
	apply_targeting_feedback(session, next_candidate, next_decision)
	var coordinator = zone.get_targeting_coordinator(false)
	if coordinator != null and coordinator.get_session() == session:
		coordinator.refresh_overlay()

func finalize_targeting_session(session: ZoneTargetingSession) -> void:
	if session == null or session.source_zone != zone:
		return
	if session.decision != null and session.decision.allowed and session.decision.resolved_candidate != null and session.decision.resolved_candidate.is_valid():
		clear_targeting_feedback(true, session.source_item)
		zone.targeting_resolved.emit(session.source_item, zone, session.decision.resolved_candidate, session.decision)
		var coordinator = zone.get_targeting_coordinator(false)
		if coordinator != null:
			coordinator.clear_session()
		return
	cancel_targeting_session(session, true)

func cancel_targeting_session(session: ZoneTargetingSession, emit_signal: bool) -> void:
	if session == null or session.source_zone != zone:
		return
	clear_targeting_feedback(emit_signal, session.source_item)
	if emit_signal and is_instance_valid(session.source_item):
		zone.targeting_cancelled.emit(session.source_item, zone)
	var coordinator = zone.get_targeting_coordinator(false)
	if coordinator != null:
		coordinator.clear_session()

func start_targeting_internal(command: ZoneTargetingCommand) -> bool:
	if command == null or not context.has_item(command.source_item):
		return false
	var resolved_intent = command.intent if command.intent != null else resolve_targeting_intent(command, command.entry_mode)
	if resolved_intent == null:
		return false
	var coordinator = zone.get_targeting_coordinator(true)
	if coordinator == null:
		return false
	var drag_coordinator = zone.get_drag_coordinator(false)
	if drag_coordinator != null and drag_coordinator.get_session() != null:
		return false
	command.intent = resolved_intent
	var source_anchor = resolve_item_target_anchor_global(command.source_item)
	var session = coordinator.start_targeting(zone, command.source_item, resolved_intent, command.entry_mode, source_anchor, command.pointer_global_position)
	if session == null:
		return false
	update_targeting_session(session, command.pointer_global_position)
	zone.targeting_started.emit(command.source_item, zone, resolved_intent)
	return true

func resolve_targeting_intent(command: ZoneTargetingCommand, entry_mode: StringName) -> ZoneTargetingIntent:
	if command == null or not is_instance_valid(command.source_item):
		return null
	return command.source_item.create_zone_targeting_intent(command, entry_mode)

func resolve_item_target_anchor_global(item: ZoneItemControl) -> Vector2:
	if not is_instance_valid(item):
		return zone.global_position + zone.size * 0.5
	return item.get_zone_target_anchor_global()

func resolve_target_candidate(intent: ZoneTargetingIntent, global_position: Vector2) -> ZoneTargetCandidate:
	var allows_item = intent == null or intent.allows_candidate_kind(ZoneTargetCandidate.CandidateKind.ITEM)
	var allows_placement = intent == null or intent.allows_candidate_kind(ZoneTargetCandidate.CandidateKind.PLACEMENT)
	var zones = collect_targeting_zones()
	if allows_item:
		for target_zone in zones:
			var item = target_zone.get_item_at_global_position(global_position)
			if item == null:
				continue
			return build_item_candidate(target_zone, item, global_position)
	if allows_placement:
		for target_zone in zones:
			if not target_zone.get_global_rect().has_point(global_position):
				continue
			var target_context = target_zone.get_context()
			var space_model = target_context.get_space_model()
			if space_model == null:
				continue
			var local_position = global_position - target_zone.global_position
			var placement_target = space_model.resolve_hover_target(target_context, target_context.get_items(), global_position, local_position)
			placement_target = space_model.normalize_target(target_context, placement_target, [])
			if placement_target == null or not placement_target.is_valid():
				continue
			return build_placement_candidate(target_zone, placement_target, global_position)
	return ZoneTargetCandidate.invalid(global_position, global_position - zone.global_position)

func resolve_target_decision(source_item: ZoneItemControl, intent: ZoneTargetingIntent, current_candidate: ZoneTargetCandidate, global_position: Vector2) -> ZoneTargetDecision:
	if current_candidate == null or not current_candidate.is_valid():
		return ZoneTargetDecision.new(false, "", ZoneTargetCandidate.invalid(global_position, global_position - zone.global_position))
	var request = ZoneTargetRequest.new(zone, source_item, intent, current_candidate, global_position)
	var resolved_candidate = current_candidate.duplicate_candidate()
	var metadata: Dictionary = {}
	if intent != null and intent.policy != null:
		var source_decision = intent.policy.evaluate_target(context, request)
		if source_decision == null:
			source_decision = ZoneTargetDecision.new(resolved_candidate.is_valid(), "", resolved_candidate)
		metadata.merge(source_decision.metadata, true)
		if not source_decision.allowed:
			return ZoneTargetDecision.new(false, source_decision.reason, resolve_target_candidate_from_decision(source_decision, resolved_candidate), metadata)
		resolved_candidate = resolve_target_candidate_from_decision(source_decision, resolved_candidate)
		request = ZoneTargetRequest.new(zone, source_item, intent, resolved_candidate, global_position)
	var target_zone = resolved_candidate.target_zone as Zone
	if target_zone != null:
		var target_context = target_zone.get_context()
		var target_policy = target_context.get_targeting_policy()
		if target_policy != null:
			var target_decision = target_policy.evaluate_target(target_context, request)
			if target_decision == null:
				target_decision = ZoneTargetDecision.new(resolved_candidate.is_valid(), "", resolved_candidate)
			metadata.merge(target_decision.metadata, true)
			if not target_decision.allowed:
				return ZoneTargetDecision.new(false, target_decision.reason, resolve_target_candidate_from_decision(target_decision, resolved_candidate), metadata)
			resolved_candidate = resolve_target_candidate_from_decision(target_decision, resolved_candidate)
	return ZoneTargetDecision.new(resolved_candidate.is_valid(), "", resolved_candidate, metadata)

func resolve_target_candidate_from_decision(current_decision: ZoneTargetDecision, fallback: ZoneTargetCandidate) -> ZoneTargetCandidate:
	if current_decision != null and current_decision.resolved_candidate != null and current_decision.resolved_candidate.is_valid():
		return current_decision.resolved_candidate.duplicate_candidate()
	return fallback.duplicate_candidate() if fallback != null else ZoneTargetCandidate.invalid()

func collect_targeting_zones() -> Array[Zone]:
	var zones: Array[Zone] = []
	var tree = zone.get_tree()
	if tree == null:
		return zones
	for node in tree.get_nodes_in_group(Zone.TARGETING_ZONE_GROUP):
		if node is not Zone:
			continue
		var target_zone := node as Zone
		if not target_zone.is_inside_tree():
			continue
		if not target_zone.is_visible_in_tree():
			continue
		if target_zone.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if target_zone.get_context().get_targeting_policy() == null:
			continue
		zones.append(target_zone)
	zones.reverse()
	return zones

func build_item_candidate(target_zone: Zone, item: ZoneItemControl, global_position: Vector2) -> ZoneTargetCandidate:
	var placement_target = target_zone.get_item_target(item)
	var metadata = build_candidate_metadata(item, placement_target)
	var anchor = resolve_item_target_anchor_global(item)
	return ZoneTargetCandidate.item(target_zone, item, placement_target, anchor, global_position - target_zone.global_position, metadata)

func build_placement_candidate(target_zone: Zone, placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTargetCandidate:
	var metadata = build_candidate_metadata(null, placement_target)
	var anchor = target_zone.get_context().resolve_target_anchor(placement_target)
	return ZoneTargetCandidate.placement(target_zone, placement_target, anchor, global_position - target_zone.global_position, metadata)

func build_candidate_metadata(item: ZoneItemControl, placement_target: ZonePlacementTarget) -> Dictionary:
	var metadata: Dictionary = {}
	if is_instance_valid(item):
		metadata.merge(item.get_zone_item_metadata(), true)
	if placement_target != null and placement_target.is_valid():
		metadata.merge(placement_target.metadata, true)
		metadata["placement_kind"] = placement_target.kind
		metadata["cell_id"] = placement_target.cell_id
	metadata["candidate_kind"] = "item" if is_instance_valid(item) else "placement"
	return metadata

func apply_targeting_feedback(session: ZoneTargetingSession, next_candidate: ZoneTargetCandidate, next_decision: ZoneTargetDecision) -> void:
	var previous_candidate = candidate.duplicate_candidate()
	var previous_decision = decision.duplicate_decision()
	session.candidate = next_candidate.duplicate_candidate() if next_candidate != null else ZoneTargetCandidate.invalid()
	session.decision = next_decision.duplicate_decision() if next_decision != null else ZoneTargetDecision.new()
	candidate = session.candidate.duplicate_candidate()
	decision = session.decision.duplicate_decision()
	var next_item = session.decision.resolved_candidate.target_item if session.decision != null and session.decision.resolved_candidate != null and session.decision.resolved_candidate.is_valid() and is_instance_valid(session.decision.resolved_candidate.target_item) else session.candidate.target_item if session.candidate != null and is_instance_valid(session.candidate.target_item) else null
	var next_allowed = session.decision != null and session.decision.allowed
	if highlight_item != next_item or (next_item != null and previous_decision.allowed != next_allowed):
		set_target_candidate_visual(highlight_item, false, previous_decision.allowed)
		highlight_item = next_item
		set_target_candidate_visual(highlight_item, highlight_item != null, next_allowed)
	if not target_candidates_match(previous_candidate, session.candidate):
		zone.target_preview_changed.emit(session.source_item, session.candidate.target_zone, session.candidate)
	if not target_decisions_match(previous_decision, session.decision):
		zone.target_hover_state_changed.emit(session.source_item, session.candidate.target_zone, session.decision)

func clear_targeting_feedback(emit_clear_signals: bool, source_item: ZoneItemControl = null) -> void:
	var had_candidate = candidate != null and candidate.is_valid()
	if is_instance_valid(highlight_item):
		set_target_candidate_visual(highlight_item, false, decision.allowed if decision != null else false)
	highlight_item = null
	if emit_clear_signals and had_candidate:
		zone.target_preview_changed.emit(source_item, null, ZoneTargetCandidate.invalid())
		zone.target_hover_state_changed.emit(source_item, null, ZoneTargetDecision.new())
	candidate = ZoneTargetCandidate.invalid()
	decision = ZoneTargetDecision.new()

func set_target_candidate_visual(item: ZoneItemControl, active: bool, allowed: bool) -> void:
	if not is_instance_valid(item):
		return
	var visual_state = item.get_zone_visual_state()
	visual_state.target_candidate_active = active
	visual_state.target_candidate_allowed = allowed
	item.apply_zone_visual_state(visual_state)

func target_candidates_match(a: ZoneTargetCandidate, b: ZoneTargetCandidate) -> bool:
	if a == null and b == null:
		return true
	if a == null or b == null:
		return false
	return a.matches(b)

func target_decisions_match(a: ZoneTargetDecision, b: ZoneTargetDecision) -> bool:
	if a == null and b == null:
		return true
	if a == null or b == null:
		return false
	return a.allowed == b.allowed and a.reason == b.reason and target_candidates_match(a.resolved_candidate, b.resolved_candidate)
