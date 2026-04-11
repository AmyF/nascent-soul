extends RefCounted

# Internal helper for targeting candidate discovery and policy evaluation.

var context: ZoneContext = null
var zone = null

func _init(p_context: ZoneContext) -> void:
	context = p_context
	zone = context.zone

func cleanup() -> void:
	zone = null
	context = null

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
			var target_context = target_zone._get_context()
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
		var target_context = target_zone._get_context()
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
		if target_zone.get_targeting_policy() == null:
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
	var anchor = target_zone.resolve_target_anchor(placement_target)
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
