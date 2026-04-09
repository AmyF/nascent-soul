extends "res://scenes/tests/shared/test_harness.gd"

const TargetingSupport = preload("res://scenes/examples/shared/targeting_support.gd")
const ZoneTargetRuleTablePolicyScript = preload("res://addons/nascentsoul/impl/targeting/zone_target_rule_table_policy.gd")
const ZoneTargetRuleScript = preload("res://addons/nascentsoul/impl/targeting/zone_target_rule.gd")
const ZoneArrowTargetingOverlayScript = preload("res://addons/nascentsoul/runtime/zone_arrow_targeting_overlay.gd")

func _init() -> void:
	_suite_name = "targeting-smoke"

func _run_suite() -> void:
	await _test_drag_intent_enters_targeting()
	await _reset_root()
	await _test_regular_card_keeps_drag_transfer()
	await _reset_root()
	await _test_explicit_begin_targeting_resolves_placement_and_emits_result()
	await _reset_root()
	await _test_item_priority_and_placement_only_skip_item_targets()
	await _reset_root()
	await _test_source_and_target_policies_merge_with_reasons()
	await _reset_root()
	await _test_overlay_state_and_highlight_cleanup()

func _test_drag_intent_enters_targeting() -> void:
	var source_panel = _make_panel("TargetingDragSource", Vector2(24, 24), Vector2(420, 220))
	var target_panel = _make_panel("TargetingDragTarget", Vector2(24, 280), Vector2(720, 420))
	var source_zone = ExampleSupport.make_zone(source_panel, "DragTargetingSourceZone", ZoneHBoxLayout.new())
	var target_zone = _make_square_battlefield(target_panel, "DragTargetingBattlefieldZone", 3, 2)
	var spell = TargetingSupport.make_spell_card("Meteor")
	var enemy = TargetingSupport.make_target_piece("Enemy Sentinel", "enemy", 3, 3)
	source_zone.add_item(spell)
	target_zone.add_item(enemy, ZonePlacementTarget.square(1, 0))
	await _settle_frames(2)
	var signal_events: Array[String] = []
	source_zone.targeting_started.connect(func(_item, _zone, _intent) -> void:
		signal_events.append("targeting")
	)
	source_zone.drag_started.connect(func(_items, _zone) -> void:
		signal_events.append("drag")
	)
	_emit_mouse_button(spell, MOUSE_BUTTON_LEFT, true)
	_emit_mouse_motion(spell, enemy.global_position + enemy.size * 0.5)
	var session = source_zone.get_targeting_session()
	var drag_session = source_zone.get_drag_session()
	_check(signal_events == ["targeting"], "dragging a card with a targeting intent should emit targeting_started instead of drag_started")
	_check(session != null and session.entry_mode == &"drag", "targeting session started from drag threshold should remember the drag entry mode")
	_check(drag_session == null, "targeting drag entry should not leave an active drop drag session behind")
	_check(session != null and session.candidate.is_item() and session.candidate.target_item == enemy, "drag-triggered targeting should immediately resolve the hovered entity candidate")
	source_zone.cancel_targeting()
	await _settle_frames(1)

func _test_regular_card_keeps_drag_transfer() -> void:
	var source_panel = _make_panel("TransferDragSource", Vector2(24, 24), Vector2(420, 220))
	var source_zone = ExampleSupport.make_zone(source_panel, "RegularDragSourceZone", ZoneHBoxLayout.new())
	var regular_card = ExampleSupport.make_card("Supply", 1, ["utility"], true)
	source_zone.add_item(regular_card)
	await _settle_frames(2)
	var signal_events: Array[String] = []
	source_zone.targeting_started.connect(func(_item, _zone, _intent) -> void:
		signal_events.append("targeting")
	)
	source_zone.drag_started.connect(func(_items, _zone) -> void:
		signal_events.append("drag")
	)
	_emit_mouse_button(regular_card, MOUSE_BUTTON_LEFT, true)
	_emit_mouse_motion(regular_card, regular_card.global_position + Vector2(96, 48))
	var drag_session = source_zone.get_drag_session()
	_check(signal_events == ["drag"], "cards without a targeting intent should keep the normal drag-transfer flow")
	_check(drag_session != null, "regular drag flow should still create a drag session")
	_check(source_zone.get_targeting_session() == null, "regular drag flow should not create a targeting session")
	source_zone.cancel_drag()
	await _settle_frames(1)

func _test_explicit_begin_targeting_resolves_placement_and_emits_result() -> void:
	var field_panel = _make_panel("ExplicitAbilityField", Vector2(24, 24), Vector2(860, 520))
	var battlefield = _make_square_battlefield(field_panel, "ExplicitAbilityBattlefieldZone", 4, 3)
	var piece = TargetingSupport.make_target_piece("Guardian", "ally", 3, 5)
	battlefield.add_item(piece, ZonePlacementTarget.square(0, 0))
	await _settle_frames(2)
	var preview_candidates: Array = []
	var hover_decisions: Array = []
	var resolved_candidates: Array[ZoneTargetCandidate] = []
	battlefield.target_preview_changed.connect(func(_source_item, _target_zone, candidate) -> void:
		preview_candidates.append(candidate)
	)
	battlefield.target_hover_state_changed.connect(func(_source_item, _target_zone, decision) -> void:
		hover_decisions.append(decision)
	)
	battlefield.targeting_resolved.connect(func(_source_item, _source_zone, candidate, _decision) -> void:
		if candidate != null:
			resolved_candidates.append(candidate)
	)
	var target = ZonePlacementTarget.square(2, 1)
	var intent = TargetingSupport.make_square_placement_intent("Guardian Dash")
	_check(_begin_item_targeting(battlefield, piece, intent), "begin_targeting should explicitly start a targeting session without drag history")
	var session = battlefield.get_targeting_session()
	_check(session != null and session.entry_mode == &"explicit", "explicit targeting should store the explicit entry mode")
	if session == null:
		return
	battlefield.update_targeting_session(session, battlefield.resolve_target_anchor(target))
	_check(session.candidate.is_placement(), "explicit targeting should resolve empty or occupied board cells as placement candidates")
	_check(session.decision.allowed, "placement targeting should allow a valid board cell")
	_check(session.decision.resolved_candidate.placement_target.coordinates == Vector2i(2, 1), "explicit targeting should retain the resolved square coordinates")
	_check(not preview_candidates.is_empty() and preview_candidates[preview_candidates.size() - 1] != null and preview_candidates[preview_candidates.size() - 1].has_method("describe"), "target preview callbacks should emit candidate objects instead of index semantics")
	_check(not hover_decisions.is_empty() and hover_decisions[hover_decisions.size() - 1] != null and hover_decisions[hover_decisions.size() - 1].resolved_candidate != null, "target hover callbacks should emit decision objects")
	battlefield.finalize_targeting_session(session)
	await _settle_frames(1)
	_check(resolved_candidates.size() == 1 and resolved_candidates[0].placement_target.coordinates == Vector2i(2, 1), "releasing a valid targeting session should emit the resolved placement candidate")
	_check(battlefield.has_item(piece), "targeting resolution should not consume the source piece by default")
	_check(battlefield.get_item_target(piece).coordinates == Vector2i(0, 0), "targeting resolution should not automatically move the source piece")

func _test_item_priority_and_placement_only_skip_item_targets() -> void:
	var source_panel = _make_panel("TargetPrioritySource", Vector2(24, 24), Vector2(420, 220))
	var target_panel = _make_panel("TargetPriorityField", Vector2(24, 280), Vector2(720, 420))
	var source_zone = ExampleSupport.make_zone(source_panel, "PrioritySourceZone", ZoneHBoxLayout.new())
	var battlefield = _make_square_battlefield(target_panel, "PriorityBattlefieldZone", 3, 2)
	var source_card = ExampleSupport.make_card("Probe", 1, ["spell"], true)
	var target_piece = TargetingSupport.make_target_piece("Anchor", "enemy", 2, 2)
	source_zone.add_item(source_card)
	battlefield.add_item(target_piece, ZonePlacementTarget.square(1, 0))
	await _settle_frames(2)
	var piece_anchor = target_piece.global_position + target_piece.size * 0.5
	var dual_intent := ZoneTargetingIntent.new()
	dual_intent.allowed_candidate_kinds = PackedInt32Array([
		ZoneTargetCandidate.CandidateKind.ITEM,
		ZoneTargetCandidate.CandidateKind.PLACEMENT
	])
	_check(_begin_item_targeting(source_zone, source_card, dual_intent), "explicit targeting should allow item-plus-placement candidate sets")
	var session = source_zone.get_targeting_session()
	if session == null:
		return
	source_zone.update_targeting_session(session, piece_anchor)
	_check(session.candidate.is_item() and session.candidate.target_item == target_piece, "entity targeting should take priority over cell targeting when both are allowed")
	source_zone.cancel_targeting()
	await _settle_frames(1)
	_check(_begin_item_targeting(source_zone, source_card, TargetingSupport.make_square_placement_intent("Probe Shift")), "explicit targeting should restart cleanly with a new placement-only intent")
	session = source_zone.get_targeting_session()
	if session == null:
		return
	source_zone.update_targeting_session(session, piece_anchor)
	_check(session.candidate.is_placement(), "placement-only targeting should skip overlapped items and continue resolving the board cell")
	_check(session.candidate.placement_target.coordinates == Vector2i(1, 0), "placement-only targeting should still resolve the correct occupied square")
	source_zone.cancel_targeting()
	await _settle_frames(1)

func _test_source_and_target_policies_merge_with_reasons() -> void:
	var source_panel = _make_panel("PolicySource", Vector2(24, 24), Vector2(420, 220))
	var target_panel = _make_panel("PolicyTarget", Vector2(24, 280), Vector2(720, 420))
	var source_zone = ExampleSupport.make_zone(source_panel, "PolicySourceZone", ZoneHBoxLayout.new())
	var battlefield = _make_square_battlefield(target_panel, "PolicyBattlefieldZone", 4, 2)
	var ally_piece = TargetingSupport.make_target_piece("Bulwark", "ally", 1, 4)
	var enemy_piece = TargetingSupport.make_target_piece("Enemy Scout", "enemy", 2, 1)
	ExampleSupport.set_zone_targeting_policy(battlefield, _make_enemy_only_target_policy("Spells in this zone cannot target allies."))
	battlefield.add_item(ally_piece, ZonePlacementTarget.square(0, 0))
	battlefield.add_item(enemy_piece, ZonePlacementTarget.square(2, 0))
	var source_card = ExampleSupport.make_card("Arc", 2, ["spell"], true)
	source_zone.add_item(source_card)
	await _settle_frames(2)
	var intent = TargetingSupport.make_piece_item_intent()
	_check(_begin_item_targeting(source_zone, source_card, intent), "source policy smoke should start explicit item targeting")
	var session = source_zone.get_targeting_session()
	if session == null:
		return
	source_zone.update_targeting_session(session, ally_piece.global_position + ally_piece.size * 0.5)
	_check(not session.decision.allowed, "target zone policy should be able to reject a candidate after source policy allows it")
	_check(session.decision.reason == "Spells in this zone cannot target allies.", "target zone rejection should surface its explicit reason")
	source_zone.update_targeting_session(session, enemy_piece.global_position + enemy_piece.size * 0.5)
	_check(session.decision.allowed, "target zone should allow enemy piece candidates after source and target policies both pass")
	_check(session.decision.resolved_candidate.target_item == enemy_piece, "policy merge should preserve the resolved entity candidate")
	source_zone.cancel_targeting()
	await _settle_frames(1)

func _test_overlay_state_and_highlight_cleanup() -> void:
	var source_panel = _make_panel("OverlaySource", Vector2(24, 24), Vector2(420, 220))
	var target_panel = _make_panel("OverlayTarget", Vector2(24, 280), Vector2(720, 420))
	var source_zone = ExampleSupport.make_zone(source_panel, "OverlaySourceZone", ZoneHBoxLayout.new())
	var battlefield = _make_square_battlefield(target_panel, "OverlayBattlefieldZone", 4, 2)
	var ally_piece = TargetingSupport.make_target_piece("Beacon", "ally", 0, 2)
	var enemy_piece = TargetingSupport.make_target_piece("Raider", "enemy", 2, 1)
	ExampleSupport.set_zone_targeting_policy(battlefield, _make_enemy_only_target_policy("Allies are invalid targets."))
	battlefield.add_item(ally_piece, ZonePlacementTarget.square(0, 0))
	battlefield.add_item(enemy_piece, ZonePlacementTarget.square(2, 0))
	var spell = TargetingSupport.make_spell_card("Meteor")
	source_zone.add_item(spell)
	await _settle_frames(2)
	var cancel_events: Array[String] = []
	source_zone.targeting_cancelled.connect(func(_source_item, _source_zone_ref) -> void:
		cancel_events.append("cancel")
	)
	_check(_begin_item_targeting(source_zone, spell), "spell cards should allow explicit targeting via their built-in intent")
	var session = source_zone.get_targeting_session()
	if session == null:
		return
	source_zone.update_targeting_session(session, ally_piece.global_position + ally_piece.size * 0.5)
	var overlay = _find_targeting_overlay()
	var ally_overlay = ally_piece.get_node_or_null("PieceOverlay") as ColorRect
	_check(overlay != null and overlay.get_script() == ZoneArrowTargetingOverlayScript, "targeting should render through a dedicated arrow overlay")
	_check(overlay != null and overlay.visible, "active targeting should keep the overlay visible")
	_check(overlay != null and int(overlay.get("_state")) == 2, "rejected hover candidates should switch the overlay into the invalid state")
	_check(ally_overlay != null and ally_overlay.visible and ally_overlay.color.r > ally_overlay.color.g, "invalid item candidates should show the target highlight in an invalid color")
	source_zone.update_targeting_session(session, enemy_piece.global_position + enemy_piece.size * 0.5)
	var enemy_overlay = enemy_piece.get_node_or_null("PieceOverlay") as ColorRect
	_check(overlay != null and int(overlay.get("_state")) == 1, "valid hover candidates should switch the overlay into the valid state")
	_check(enemy_overlay != null and enemy_overlay.visible and enemy_overlay.color.g > enemy_overlay.color.r, "valid item candidates should show the target highlight in a valid color")
	_check(ally_overlay != null and not ally_overlay.visible, "moving between candidates should clear the previous item highlight")
	source_zone.cancel_targeting()
	await _settle_frames(1)
	_check(cancel_events == ["cancel"], "cancelling targeting should emit the targeting_cancelled signal once")
	_check(_find_targeting_overlay() == null, "cancelling targeting should clear the overlay node from the viewport")
	_check(enemy_overlay != null and not enemy_overlay.visible, "cancelling targeting should clear the active item highlight")

func _find_targeting_overlay() -> Control:
	var viewport = get_viewport()
	if viewport == null:
		return null
	return viewport.find_child("__NascentSoulTargetingOverlay", true, false) as Control

func _make_square_battlefield(panel: Control, zone_name: String, columns: int, rows: int) -> BattlefieldZone:
	var square_model := ZoneSquareGridSpaceModel.new()
	square_model.columns = columns
	square_model.rows = rows
	return ExampleSupport.make_battlefield_zone(panel, zone_name, square_model, ZoneOccupancyTransferPolicy.new())

func _make_enemy_only_target_policy(reject_reason: String) -> ZoneTargetingPolicy:
	var reject_allies := ZoneTargetRuleScript.new()
	reject_allies.target_candidate_kind = ZoneTargetCandidate.CandidateKind.ITEM
	reject_allies.target_item_script = preload("res://addons/nascentsoul/pieces/zone_piece.gd")
	reject_allies.required_candidate_meta_key = "target_team"
	reject_allies.required_candidate_meta_value = "ally"
	reject_allies.allowed = false
	reject_allies.reject_reason = reject_reason
	var allow_enemies := ZoneTargetRuleScript.new()
	allow_enemies.target_candidate_kind = ZoneTargetCandidate.CandidateKind.ITEM
	allow_enemies.target_item_script = preload("res://addons/nascentsoul/pieces/zone_piece.gd")
	allow_enemies.required_candidate_meta_key = "target_team"
	allow_enemies.required_candidate_meta_value = "enemy"
	var policy := ZoneTargetRuleTablePolicyScript.new()
	var rules: Array[ZoneTargetRule] = [reject_allies, allow_enemies]
	policy.rules = rules
	return policy
