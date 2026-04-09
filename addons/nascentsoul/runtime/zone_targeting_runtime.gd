class_name ZoneTargetingRuntime extends RefCounted

var runtime
var zone: Zone

var candidate: ZoneTargetCandidate = ZoneTargetCandidate.invalid()
var decision: ZoneTargetDecision = ZoneTargetDecision.new()
var highlight_item: Control = null

func _init(p_runtime) -> void:
	runtime = p_runtime
	zone = runtime.zone

func begin_targeting(item: Control, intent: ZoneTargetingIntent = null) -> bool:
	var pointer_global_position = Vector2.ZERO
	if zone.get_viewport() != null:
		pointer_global_position = zone.get_viewport().get_mouse_position()
	elif is_instance_valid(item):
		pointer_global_position = item.global_position
	return start_targeting_internal(item, intent, &"explicit", pointer_global_position)

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

func start_targeting_internal(item: Control, intent: ZoneTargetingIntent, entry_mode: StringName, pointer_global_position: Vector2) -> bool:
	if not runtime.has_item(item):
		return false
	var resolved_intent = intent if intent != null else resolve_targeting_intent(item, entry_mode)
	if resolved_intent == null:
		return false
	var coordinator = zone.get_targeting_coordinator(true)
	if coordinator == null:
		return false
	var drag_coordinator = zone.get_drag_coordinator(false)
	if drag_coordinator != null and drag_coordinator.get_session() != null:
		return false
	var source_anchor = resolve_item_target_anchor_global(item)
	var session = coordinator.start_targeting(zone, item, resolved_intent, entry_mode, source_anchor, pointer_global_position)
	if session == null:
		return false
	zone.targeting_started.emit(item, zone, resolved_intent)
	return true

func resolve_targeting_intent(item: Control, entry_mode: StringName) -> ZoneTargetingIntent:
	if not is_instance_valid(item) or not item.has_method("create_zone_targeting_intent"):
		return null
	var created = item.call("create_zone_targeting_intent", zone, entry_mode)
	return created as ZoneTargetingIntent if created is ZoneTargetingIntent else null

func resolve_item_target_anchor_global(item: Control) -> Vector2:
	if not is_instance_valid(item):
		return zone.global_position + zone.size * 0.5
	if item.has_method("get_zone_target_anchor_global"):
		var anchor = item.call("get_zone_target_anchor_global")
		if anchor is Vector2:
			return anchor as Vector2
	return item.global_position + item.size * 0.5

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
			var space_model = target_zone.get_space_model_resource()
			if space_model == null:
				continue
			var local_position = global_position - target_zone.global_position
			var placement_target = space_model.resolve_hover_target(target_zone, target_zone.get_runtime(), target_zone.get_items(), global_position, local_position)
			placement_target = space_model.normalize_target(target_zone, target_zone.get_runtime(), placement_target, [])
			if placement_target == null or not placement_target.is_valid():
				continue
			return build_placement_candidate(target_zone, placement_target, global_position)
	return ZoneTargetCandidate.invalid(global_position, global_position - zone.global_position)

func resolve_target_decision(source_item: Control, intent: ZoneTargetingIntent, current_candidate: ZoneTargetCandidate, global_position: Vector2) -> ZoneTargetDecision:
	if current_candidate == null or not current_candidate.is_valid():
		return ZoneTargetDecision.new(false, "", ZoneTargetCandidate.invalid(global_position, global_position - zone.global_position))
	var request = ZoneTargetRequest.new(zone, source_item, intent, current_candidate, global_position)
	var resolved_candidate = current_candidate.duplicate_candidate()
	var metadata: Dictionary = {}
	if intent != null and intent.policy != null:
		var source_decision = intent.policy.evaluate_target(request)
		if source_decision == null:
			source_decision = ZoneTargetDecision.new(resolved_candidate.is_valid(), "", resolved_candidate)
		metadata.merge(source_decision.metadata, true)
		if not source_decision.allowed:
			return ZoneTargetDecision.new(false, source_decision.reason, resolve_target_candidate_from_decision(source_decision, resolved_candidate), metadata)
		resolved_candidate = resolve_target_candidate_from_decision(source_decision, resolved_candidate)
		request = ZoneTargetRequest.new(zone, source_item, intent, resolved_candidate, global_position)
	var target_zone = resolved_candidate.target_zone as Zone
	if target_zone != null:
		var target_policy = target_zone.get_targeting_policy_resource()
		if target_policy != null:
			var target_decision = target_policy.evaluate_target(request)
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
		if target_zone.get_targeting_policy_resource() == null:
			continue
		zones.append(target_zone)
	zones.reverse()
	return zones

func build_item_candidate(target_zone: Zone, item: Control, global_position: Vector2) -> ZoneTargetCandidate:
	var placement_target = target_zone.get_item_target(item)
	var metadata = build_candidate_metadata(item, placement_target)
	var anchor = resolve_item_target_anchor_global(item)
	return ZoneTargetCandidate.item(target_zone, item, placement_target, anchor, global_position - target_zone.global_position, metadata)

func build_placement_candidate(target_zone: Zone, placement_target: ZonePlacementTarget, global_position: Vector2) -> ZoneTargetCandidate:
	var metadata = build_candidate_metadata(null, placement_target)
	var anchor = target_zone.get_runtime().resolve_target_anchor(placement_target)
	return ZoneTargetCandidate.placement(target_zone, placement_target, anchor, global_position - target_zone.global_position, metadata)

func build_candidate_metadata(item: Control, placement_target: ZonePlacementTarget) -> Dictionary:
	var metadata: Dictionary = {}
	if is_instance_valid(item):
		metadata.merge(extract_node_metadata(item), true)
	metadata["candidate_kind"] = "item" if is_instance_valid(item) else "placement"
	if placement_target != null and placement_target.is_valid():
		metadata.merge(placement_target.metadata, true)
		metadata["placement_kind"] = placement_target.kind
		metadata["cell_id"] = placement_target.cell_id
	return metadata

func extract_node_metadata(node: Object) -> Dictionary:
	var metadata: Dictionary = {}
	if node == null or not node.has_method("get_meta_list"):
		return metadata
	for key in node.get_meta_list():
		metadata[str(key)] = node.get_meta(key)
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

func clear_targeting_feedback(emit_clear_signals: bool, source_item: Control = null) -> void:
	var had_candidate = candidate != null and candidate.is_valid()
	if is_instance_valid(highlight_item):
		set_target_candidate_visual(highlight_item, false, decision.allowed if decision != null else false)
	highlight_item = null
	if emit_clear_signals and had_candidate:
		zone.target_preview_changed.emit(source_item, null, ZoneTargetCandidate.invalid())
		zone.target_hover_state_changed.emit(source_item, null, ZoneTargetDecision.new())
	candidate = ZoneTargetCandidate.invalid()
	decision = ZoneTargetDecision.new()

func set_target_candidate_visual(item: Control, active: bool, allowed: bool) -> void:
	if not is_instance_valid(item) or not item.has_method("set_target_candidate_visual"):
		return
	item.call("set_target_candidate_visual", active, allowed)

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
