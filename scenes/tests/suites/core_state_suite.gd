extends "res://scenes/tests/shared/test_harness.gd"

const ZoneCompositePermissionScript = preload("res://addons/nascentsoul/impl/permissions/zone_composite_permission.gd")
const ZoneConfigurableDragVisualFactoryScript = preload("res://addons/nascentsoul/impl/factories/zone_configurable_drag_visual_factory.gd")
const ZoneGroupSortScript = preload("res://addons/nascentsoul/impl/sorts/zone_group_sort.gd")
const HAND_PRESET = preload("res://addons/nascentsoul/presets/hand_zone_preset.tres")
const BOARD_PRESET = preload("res://addons/nascentsoul/presets/board_zone_preset.tres")
const TRANSFER_PLAYGROUND_SCENE = preload("res://scenes/examples/transfer_playground.tscn")

func _init() -> void:
	_suite_name = "core-state"

func _run_suite() -> void:
	await _test_reorder_and_remove()
	await _reset_root()
	await _test_internal_roots_and_preset_override()
	await _reset_root()
	await _test_drag_transfer_and_selection_prune()
	await _reset_root()
	await _test_batch_transfer_api()
	await _reset_root()
	await _test_transfer_snapshots_preserve_animation_origins()
	await _reset_root()
	await _test_transfer_handoff_cleanup()
	await _reset_root()
	await _test_transfer_playground_hand_to_board_drag()
	await _reset_root()
	await _test_rejected_hover_hides_preview_but_still_rejects_drop()
	await _reset_root()
	await _test_composite_permission()
	await _reset_root()
	await _test_group_sort_policy()
	await _reset_root()
	await _test_drag_visual_factory()
	await _reset_root()
	await _test_permission_reject_cleanup()
	await _reset_root()
	await _test_drag_cancel_cleanup()
	await _reset_root()
	await _test_external_reconciliation()
	await _reset_root()
	await _test_freed_item_reconciliation()
	await _reset_root()
	await _test_freed_item_during_drag_session()

func _test_reorder_and_remove() -> void:
	var panel = _make_panel("ReorderPanel", Vector2(24, 24), Vector2(620, 260))
	var zone = ExampleSupport.make_zone(panel, "ReorderZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 1, ["skill"], true)
	var gamma = ExampleSupport.make_card("Gamma", 2, ["attack"], true)
	var reorder_events: Array[String] = []
	zone.item_reordered.connect(func(item: Control, from_index: int, to_index: int) -> void:
		reorder_events.append("%s:%d->%d" % [item.name, from_index, to_index])
	)
	zone.add_item(alpha)
	zone.add_item(beta)
	zone.add_item(gamma)
	await _settle_frames(2)
	_check(_zone_item_names(zone) == ["Alpha", "Beta", "Gamma"], "initial add order should match insertion order")
	_check(_managed_control_names(panel) == ["Alpha", "Beta", "Gamma"], "container child order should follow logical order after add")
	zone.reorder_item(gamma, 0)
	await _settle_frames(2)
	_check(_zone_item_names(zone) == ["Gamma", "Alpha", "Beta"], "reorder should update logical order")
	_check(_managed_control_names(panel) == ["Gamma", "Alpha", "Beta"], "reorder should resync container child order")
	_check(reorder_events == ["Gamma:2->0"], "reorder signal should describe the moved card")
	zone.select_item(gamma, false)
	await _settle_frames(1)
	zone.remove_item(gamma)
	await _settle_frames(2)
	_check(_zone_item_names(zone) == ["Alpha", "Beta"], "remove should delete the item from logical order")
	_check(_managed_control_names(panel) == ["Alpha", "Beta"], "remove should delete the item from container controls")
	_check(gamma.scale == Vector2.ONE and is_zero_approx(gamma.rotation), "removed card should not keep transformed display state")
	_check(_unmanaged_control_names(zone).is_empty(), "remove should not leave ghost or unmanaged controls behind")
	gamma.free()

func _test_internal_roots_and_preset_override() -> void:
	var panel = _make_panel("PresetPanel", Vector2(24, 24), Vector2(620, 260))
	var zone = ExampleSupport.make_zone(panel, "PresetZone", null, null, null, null, null, null, HAND_PRESET)
	var override_layout := ZoneHBoxLayout.new()
	override_layout.item_spacing = 20.0
	override_layout.padding_left = 10.0
	zone.layout_policy = override_layout
	var override_permission := ZoneCapacityPermission.new()
	override_permission.max_items = 2
	zone.permission_policy = override_permission
	await _settle_frames(2)
	_check(zone.get_items_root() != null, "zone should always create an ItemsRoot child")
	_check(zone.get_preview_root() != null, "zone should always create a PreviewRoot child")
	_check(zone.get_items_root().get_parent() == zone, "ItemsRoot should belong to the zone itself")
	_check(zone.get_preview_root().get_parent() == zone, "PreviewRoot should belong to the zone itself")
	_check(zone.get_layout_policy_resource() == override_layout, "layout override should take precedence over preset layout")
	_check(zone.get_permission_policy_resource() == override_permission, "permission override should take precedence over preset permission")
	_check(zone.get_display_style_resource() == HAND_PRESET.display_style, "preset display style should resolve when no override exists")
	_check(zone.get_drag_visual_factory_resource() == HAND_PRESET.drag_visual_factory, "preset drag visual factory should resolve when no override exists")

func _test_drag_transfer_and_selection_prune() -> void:
	var target_panel = _make_panel("TargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("SourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "SourceZone", ZoneHBoxLayout.new())
	var target_zone = ExampleSupport.make_zone(target_panel, "TargetZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	var ward = ExampleSupport.make_card("Ward", 1, ["skill"], true)
	var transfer_events: Array[String] = []
	target_zone.item_transferred.connect(func(item: Control, source_zone_ref: Zone, target_zone_ref: Zone, to_index: int) -> void:
		transfer_events.append("%s:%s->%s@%d" % [item.name, source_zone_ref.name, target_zone_ref.name, to_index])
	)
	source_zone.add_item(alpha)
	source_zone.add_item(beta)
	target_zone.add_item(ward)
	await _settle_frames(2)
	source_zone.select_item(beta, false)
	await _settle_frames(1)
	source_zone.start_drag([beta])
	var coordinator = source_zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "drag transfer should create a drag session")
	if session == null:
		return
	target_zone.get_runtime().process(0.0)
	session.hover_zone = target_zone
	session.preview_index = 1
	target_zone.get_runtime().perform_drop(session)
	await _settle_frames(2)
	_check(coordinator.get_session() == null, "successful drop should clear the drag session")
	_check(_zone_item_names(source_zone) == ["Alpha"], "drag transfer should remove the card from the source zone")
	_check(_zone_item_names(target_zone) == ["Ward", "Beta"], "drag transfer should insert the card into the target zone at preview index")
	_check(source_zone.get_runtime().selection_state.get_selected_items().is_empty(), "source selection should be pruned after transfer")
	_check(beta.visible, "transferred card should be visible after drop")
	_check(transfer_events == ["Beta:SourceZone->TargetZone@1"], "target transfer signal should describe the final target index")
	_check(_unmanaged_control_names(source_zone).is_empty(), "successful transfer should not leave a source ghost behind")
	_check(_unmanaged_control_names(target_zone).is_empty(), "successful transfer should not leave a target ghost behind")

func _test_batch_transfer_api() -> void:
	var target_panel = _make_panel("BatchTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("BatchSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "BatchSourceZone", ZoneHBoxLayout.new(), null, null, null, null, null, HAND_PRESET)
	var target_zone = ExampleSupport.make_zone(target_panel, "BatchTargetZone", ZoneHBoxLayout.new(), null, null, null, null, null, BOARD_PRESET)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	var gamma = ExampleSupport.make_card("Gamma", 3, ["power"], true)
	var ward = ExampleSupport.make_card("Ward", 1, ["skill"], true)
	source_zone.add_item(alpha)
	source_zone.add_item(beta)
	source_zone.add_item(gamma)
	target_zone.add_item(ward)
	await _settle_frames(2)
	_check(source_zone.transfer_items([gamma, alpha], target_zone, 1), "batch transfer should accept arbitrary input order and preserve logical zone order")
	await _settle_frames(2)
	_check(_zone_item_names(source_zone) == ["Beta"], "batch transfer should remove all moved items from the source zone")
	_check(_zone_item_names(target_zone) == ["Ward", "Alpha", "Gamma"], "batch transfer should insert items using the source zone's logical order")
	_check(_unmanaged_control_names(source_zone).is_empty(), "batch transfer should not leave unmanaged controls in the source zone")
	_check(_unmanaged_control_names(target_zone).is_empty(), "batch transfer should not leave unmanaged controls in the target zone")

func _test_transfer_snapshots_preserve_animation_origins() -> void:
	var panel = _make_panel("SnapshotPanel", Vector2(24, 24), Vector2(920, 280))
	var zone = ExampleSupport.make_zone(panel, "SnapshotZone", null, null, null, null, null, null, HAND_PRESET)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	zone.add_item(alpha)
	zone.add_item(beta)
	await _settle_frames(2)
	var alpha_origin = alpha.global_position
	var beta_origin = beta.global_position
	var alpha_rotation = alpha.rotation
	var beta_rotation = beta.rotation
	var runtime = zone.get_runtime()
	var baseline_snapshots = runtime._build_transfer_snapshots([alpha, beta])
	var alpha_baseline: Dictionary = baseline_snapshots.get(alpha, {})
	var beta_baseline: Dictionary = baseline_snapshots.get(beta, {})
	_check(alpha_baseline.get("global_position", Vector2.ZERO).distance_to(alpha_origin) <= 0.01, "baseline transfer snapshot should preserve the primary card global position")
	_check(beta_baseline.get("global_position", Vector2.ZERO).distance_to(beta_origin) <= 0.01, "baseline transfer snapshot should preserve the secondary card global position")
	_check(is_equal_approx(alpha_baseline.get("rotation", 0.0), alpha_rotation), "baseline transfer snapshot should preserve the primary card rotation")
	_check(is_equal_approx(beta_baseline.get("rotation", 0.0), beta_rotation), "baseline transfer snapshot should preserve the secondary card rotation")
	var drop_position = Vector2(540, 180)
	var dragged_snapshots = runtime._build_transfer_snapshots([alpha, beta], drop_position)
	var alpha_dragged: Dictionary = dragged_snapshots.get(alpha, {})
	var beta_dragged: Dictionary = dragged_snapshots.get(beta, {})
	var dragged_offset: Vector2 = beta_dragged.get("global_position", Vector2.ZERO) - alpha_dragged.get("global_position", Vector2.ZERO)
	var source_offset = beta_origin - alpha_origin
	_check(alpha_dragged.get("global_position", Vector2.ZERO).distance_to(drop_position) <= 0.01, "drag transfer snapshot should anchor the primary card at the explicit drop position")
	_check(dragged_offset.distance_to(source_offset) <= 0.01, "drag transfer snapshot should preserve relative offsets for multi-card movement")
	_check(is_equal_approx(alpha_dragged.get("rotation", 0.0), alpha_rotation), "drag transfer snapshot should preserve the primary card rotation")
	_check(is_equal_approx(beta_dragged.get("rotation", 0.0), beta_rotation), "drag transfer snapshot should preserve the secondary card rotation")

func _test_transfer_handoff_cleanup() -> void:
	var target_panel = _make_panel("HandoffTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("HandoffSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "HandoffSourceZone", ZoneHBoxLayout.new())
	var target_zone = ExampleSupport.make_zone(target_panel, "HandoffTargetZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	source_zone.add_item(alpha)
	await _settle_frames(2)
	_check(source_zone.move_item_to(alpha, target_zone, 0), "handoff cleanup smoke should move the card into the target zone")
	await _settle_frames(2)
	_check(source_zone.get_runtime()._transfer_handoffs.is_empty(), "source runtime should not retain transfer handoff data after a completed move")
	_check(target_zone.get_runtime()._transfer_handoffs.is_empty(), "target runtime should consume transfer handoff data during refresh")
	target_zone.get_runtime()._set_transfer_handoff(alpha, {"global_position": Vector2(10, 10)})
	target_zone.remove_item(alpha)
	await _settle_frames(1)
	_check(target_zone.get_runtime()._transfer_handoffs.is_empty(), "remove_item should clear any pending handoff for the removed card")
	target_zone.add_item(alpha)
	await _settle_frames(2)
	target_zone.get_runtime()._set_transfer_handoff(alpha, {"global_position": Vector2(20, 20)})
	target_zone.get_runtime().clear_display_state()
	_check(target_zone.get_runtime()._transfer_handoffs.is_empty(), "clear_display_state should clear pending handoff data")
	target_zone.get_runtime()._set_transfer_handoff(alpha, {"global_position": Vector2(30, 30)})
	target_zone.get_runtime().unbind()
	_check(target_zone.get_runtime()._transfer_handoffs.is_empty(), "unbind should clear pending handoff data")
	target_zone.get_runtime().bind()
	await _settle_frames(1)

func _test_transfer_playground_hand_to_board_drag() -> void:
	var scene = TRANSFER_PLAYGROUND_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var hand_zone = scene.get_node("RootMargin/RootVBox/HandZone") as Zone
	var board_zone = scene.get_node("RootMargin/RootVBox/TopRow/BoardColumn/BoardZone") as Zone
	_check(hand_zone != null and board_zone != null, "transfer playground should expose hand and board zones")
	if hand_zone == null or board_zone == null:
		return
	var hand_item = hand_zone.get_items()[0]
	var initial_board_count = board_zone.get_item_count()
	hand_zone.start_drag([hand_item])
	var coordinator = hand_zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "transfer playground drag should create an active session")
	if session == null:
		return
	session.hover_zone = board_zone
	session.preview_index = board_zone.get_item_count()
	hand_zone.get_runtime().finalize_drag_session(session)
	await _settle_frames(3)
	_check(board_zone.get_item_count() == initial_board_count + 1, "transfer playground drag should increase board item count")
	_check(hand_zone.get_item_count() == 4, "transfer playground drag should remove one item from hand")
	_check(board_zone.has_item(hand_item), "transfer playground drag should move the dragged item into board")
	_check(hand_item.visible, "transfer playground drag should leave the moved item visible")
	_check(_rect_inside(board_zone.get_global_rect().grow(24.0), hand_item.get_global_rect(), 24.0), "transfer playground moved card should render inside the board zone")

func _test_rejected_hover_hides_preview_but_still_rejects_drop() -> void:
	var target_panel = _make_panel("RejectHoverTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("RejectHoverSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "RejectHoverSourceZone", ZoneHBoxLayout.new())
	var capacity = ZoneCapacityPermission.new()
	capacity.max_items = 0
	capacity.reject_reason = "Reject hover target is full."
	var target_zone = ExampleSupport.make_zone(target_panel, "RejectHoverTargetZone", ZoneHBoxLayout.new(), null, capacity)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var hover_states: Array[Dictionary] = []
	var preview_indices: Array[int] = []
	var reject_events: Array[String] = []
	target_zone.drop_hover_state_changed.connect(func(items: Array, _target_zone_ref: Zone, decision: ZoneDropDecision) -> void:
		var item_name = str(items[0].name) if not items.is_empty() and items[0] is Control else "Selection"
		hover_states.append({
			"item": item_name,
			"allowed": decision.allowed,
			"target_index": decision.target_index,
			"reason": decision.reason
		})
	)
	target_zone.drop_preview_changed.connect(func(_items: Array, _target_zone_ref: Zone, target_index: int) -> void:
		preview_indices.append(target_index)
	)
	target_zone.drop_rejected.connect(func(items: Array, source_zone_ref: Zone, target_zone_ref: Zone, reason: String) -> void:
		reject_events.append("%s:%s->%s:%s" % [items[0].name, source_zone_ref.name, target_zone_ref.name, reason])
	)
	source_zone.add_item(alpha)
	await _settle_frames(2)
	source_zone.start_drag([alpha])
	var coordinator = source_zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "reject hover test requires an active drag session")
	if session == null:
		return
	var target_runtime = target_zone.get_runtime()
	var request = target_runtime._make_drop_request(target_zone, source_zone, session.items, 0, Vector2.ZERO)
	var decision = target_runtime._resolve_drop_decision(request)
	session.hover_zone = target_zone
	session.requested_index = 0
	session.preview_index = -1
	if target_runtime._apply_hover_feedback(session.items, decision, -1, alpha):
		target_zone.refresh()
	_check(not decision.allowed, "reject hover should resolve to a rejected decision")
	_check(hover_states == [{
		"item": "Alpha",
		"allowed": false,
		"target_index": 0,
		"reason": "Reject hover target is full."
	}], "reject hover should emit hover state without advertising an insertion preview")
	_check(preview_indices.is_empty(), "reject hover should not emit a preview slot when the drop is disallowed")
	_check(_find_unmanaged_control(target_zone) == null, "reject hover should not create a ghost or preview control")
	target_runtime.perform_drop(session)
	await _settle_frames(2)
	_check(reject_events == ["Alpha:RejectHoverSourceZone->RejectHoverTargetZone:Reject hover target is full."], "reject hover release should still emit drop_rejected")
	_check(source_zone.has_item(alpha), "reject hover release should keep the dragged card in the source zone")
	_check(not target_zone.has_item(alpha), "reject hover release should not insert the card into the target zone")

func _test_permission_reject_cleanup() -> void:
	var target_panel = _make_panel("RejectTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("RejectSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "RejectSourceZone", ZoneHBoxLayout.new())
	var capacity = ZoneCapacityPermission.new()
	capacity.max_items = 0
	capacity.reject_reason = "Reject target is full."
	var target_zone = ExampleSupport.make_zone(target_panel, "RejectTargetZone", ZoneHBoxLayout.new(), null, capacity)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var reject_events: Array[String] = []
	target_zone.drop_rejected.connect(func(items: Array, source_zone_ref: Zone, target_zone_ref: Zone, reason: String) -> void:
		reject_events.append("%s:%s->%s:%s" % [items[0].name, source_zone_ref.name, target_zone_ref.name, reason])
	)
	source_zone.add_item(alpha)
	await _settle_frames(2)
	source_zone.start_drag([alpha])
	var coordinator = source_zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "reject path should create a drag session")
	if session == null:
		return
	target_zone.get_runtime().process(0.0)
	session.hover_zone = target_zone
	session.preview_index = 0
	target_zone.get_runtime().perform_drop(session)
	await _settle_frames(2)
	_check(coordinator.get_session() == null, "rejected drop should clear the drag session")
	_check(_zone_item_names(source_zone) == ["Alpha"], "rejected drop should keep the item in the source zone")
	_check(_zone_item_names(target_zone).is_empty(), "rejected drop should not insert anything into the target zone")
	_check(alpha.visible, "rejected drop should restore the item visibility")
	_check(alpha.scale == Vector2.ONE and is_zero_approx(alpha.rotation), "rejected drop should clear transient transforms")
	_check(reject_events == ["Alpha:RejectSourceZone->RejectTargetZone:Reject target is full."], "drop_rejected should expose the source, target, and reason")
	_check(_unmanaged_control_names(source_zone).is_empty(), "rejected drop should not leave a source ghost behind")
	_check(_unmanaged_control_names(target_zone).is_empty(), "rejected drop should not leave a target ghost behind")

func _test_composite_permission() -> void:
	var target_panel = _make_panel("CompositeTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var hand_panel = _make_panel("CompositeHandPanel", Vector2(24, 320), Vector2(620, 260))
	var deck_panel = _make_panel("CompositeDeckPanel", Vector2(24, 616), Vector2(620, 260))
	var hand_zone = ExampleSupport.make_zone(hand_panel, "HandZone", ZoneHBoxLayout.new())
	var deck_zone = ExampleSupport.make_zone(deck_panel, "DeckZone", ZoneHBoxLayout.new())
	var source_policy := ZoneSourcePermission.new()
	source_policy.allowed_source_zone_names = PackedStringArray(["HandZone"])
	source_policy.reject_reason = "Composite target only accepts cards from HandZone."
	var capacity_policy := ZoneCapacityPermission.new()
	capacity_policy.max_items = 1
	capacity_policy.reject_reason = "Composite target is full."
	var composite_policy := ZoneCompositePermissionScript.new()
	composite_policy.combine_mode = ZoneCompositePermissionScript.CombineMode.ALL
	composite_policy.policies = [source_policy, capacity_policy]
	var target_zone = ExampleSupport.make_zone(target_panel, "CompositeTargetZone", ZoneHBoxLayout.new(), null, composite_policy)
	var hand_alpha = ExampleSupport.make_card("HandAlpha", 1, ["skill"], true)
	var hand_beta = ExampleSupport.make_card("HandBeta", 2, ["attack"], true)
	var deck_alpha = ExampleSupport.make_card("DeckAlpha", 1, ["skill"], false)
	var reject_events: Array[String] = []
	target_zone.drop_rejected.connect(func(items: Array, source_zone_ref: Zone, _target_zone_ref: Zone, reason: String) -> void:
		var item_name = items[0].name if not items.is_empty() and items[0] is Control else "Selection"
		reject_events.append("%s:%s:%s" % [item_name, source_zone_ref.name if source_zone_ref != null else "Unknown", reason])
	)
	hand_zone.add_item(hand_alpha)
	hand_zone.add_item(hand_beta)
	deck_zone.add_item(deck_alpha)
	await _settle_frames(2)
	_check(hand_zone.move_item_to(hand_alpha, target_zone, 0), "composite permission should allow a card from the allowed source zone")
	await _settle_frames(2)
	_check(_zone_item_names(target_zone) == ["HandAlpha"], "composite permission should insert the first allowed card")
	_check(not hand_zone.move_item_to(hand_beta, target_zone, 1), "composite permission should reject a second card when capacity is full")
	await _settle_frames(2)
	_check(_zone_item_names(hand_zone) == ["HandBeta"], "capacity rejection should leave the second hand card in the source zone")
	_check(not deck_zone.move_item_to(deck_alpha, target_zone, 1), "composite permission should reject a card from a disallowed source zone")
	await _settle_frames(2)
	_check(_zone_item_names(deck_zone) == ["DeckAlpha"], "source rejection should leave the deck card in the source zone")
	_check(reject_events == [
		"HandBeta:HandZone:Composite target is full.",
		"DeckAlpha:DeckZone:Composite target only accepts cards from HandZone."
	], "composite permission should surface the specific rejecting reason")

func _test_group_sort_policy() -> void:
	var panel = _make_panel("GroupSortPanel", Vector2(24, 24), Vector2(920, 280))
	var sort_policy := ZoneGroupSortScript.new()
	sort_policy.group_metadata_key = "example_primary_tag"
	sort_policy.group_order = PackedStringArray(["attack", "skill", "power"])
	sort_policy.item_metadata_key = "example_cost"
	var layout := ZoneHBoxLayout.new()
	layout.item_spacing = 12.0
	layout.padding_left = 12.0
	layout.padding_top = 12.0
	var zone = ExampleSupport.make_zone(panel, "GroupSortZone", layout, null, null, sort_policy)
	var attack_low = ExampleSupport.make_card("AttackLow", 1, ["attack"], true)
	var skill_mid = ExampleSupport.make_card("SkillMid", 2, ["skill"], true)
	var power_high = ExampleSupport.make_card("PowerHigh", 3, ["power"], true)
	var attack_high = ExampleSupport.make_card("AttackHigh", 3, ["attack"], true)
	var skill_low = ExampleSupport.make_card("SkillLow", 1, ["skill"], true)
	var skill_low_b = ExampleSupport.make_card("SkillLowB", 1, ["skill"], true)
	for item in [skill_mid, power_high, attack_high, attack_low, skill_low, skill_low_b]:
		zone.add_item(item)
	await _settle_frames(2)
	var sorted = sort_policy.sort_items(zone.get_items())
	_check(_control_name_list(sorted) == ["AttackLow", "AttackHigh", "SkillLow", "SkillLowB", "SkillMid", "PowerHigh"], "group sort should cluster by group order and then sort within each group")
	_check(skill_low.position.x < skill_low_b.position.x, "group sort should keep insertion order stable when group and item keys are equal")
	var last_x = -1.0
	for item in sorted:
		_check(item.position.x > last_x, "row layout should render cards from left to right in grouped sort order")
		last_x = item.position.x

func _test_drag_visual_factory() -> void:
	var target_panel = _make_panel("FactoryTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("FactorySourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_factory := ZoneConfigurableDragVisualFactoryScript.new()
	source_factory.prefer_item_methods = false
	source_factory.proxy_mode = ZoneConfigurableDragVisualFactoryScript.ProxyMode.COLOR_RECT
	source_factory.proxy_color = Color(0.28, 0.72, 0.96, 0.74)
	source_factory.proxy_scale = Vector2(1.12, 1.08)
	var target_factory := ZoneConfigurableDragVisualFactoryScript.new()
	target_factory.prefer_item_methods = false
	target_factory.allow_meta_ghost_scene = false
	target_factory.ghost_mode = ZoneConfigurableDragVisualFactoryScript.GhostMode.OUTLINE_PANEL
	target_factory.ghost_fill_color = Color(0.12, 0.16, 0.24, 0.18)
	target_factory.ghost_border_color = Color(0.92, 0.82, 0.36, 0.84)
	target_factory.ghost_corner_radius = 10
	var source_zone = ExampleSupport.make_zone(source_panel, "FactorySourceZone", ZoneHBoxLayout.new(), null, null, null, null, source_factory)
	var target_zone = ExampleSupport.make_zone(target_panel, "FactoryTargetZone", ZoneHBoxLayout.new(), null, null, null, null, target_factory)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	source_zone.add_item(alpha)
	await _settle_frames(2)
	source_zone.start_drag([alpha])
	var coordinator = source_zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "drag visual factory should still create a drag session")
	if session == null:
		return
	_check(session.cursor_proxy is ColorRect, "custom drag visual factory should be able to replace the drag proxy")
	if session.cursor_proxy is ColorRect:
		var proxy := session.cursor_proxy as ColorRect
		_check(proxy.color == source_factory.proxy_color, "custom drag proxy should use the configured color")
		_check(proxy.scale == source_factory.proxy_scale, "custom drag proxy should use the configured scale")
	var target_runtime = target_zone.get_runtime()
	target_runtime._create_ghost(alpha)
	session.hover_zone = target_zone
	session.preview_index = 0
	target_zone.refresh()
	var ghost = _find_unmanaged_control(target_zone)
	_check(ghost is Panel, "custom drag visual factory should be able to replace the preview ghost")
	if ghost is Panel:
		var ghost_style = (ghost as Panel).get_theme_stylebox("panel")
		_check(ghost_style is StyleBoxFlat, "custom preview ghost should install a flat panel style")
		if ghost_style is StyleBoxFlat:
			var style := ghost_style as StyleBoxFlat
			_check(style.bg_color == target_factory.ghost_fill_color, "custom preview ghost should use the configured fill color")
			_check(style.border_color == target_factory.ghost_border_color, "custom preview ghost should use the configured border color")
	source_zone.get_runtime().cancel_drag(session)
	await _settle_frames(2)
	_check(_unmanaged_control_names(source_zone).is_empty(), "custom proxy cleanup should not leave unmanaged controls in the source zone")
	_check(_unmanaged_control_names(target_zone).is_empty(), "custom ghost cleanup should not leave unmanaged controls in the target zone")

func _test_drag_cancel_cleanup() -> void:
	var panel = _make_panel("CancelPanel", Vector2(24, 24), Vector2(620, 260))
	var zone = ExampleSupport.make_zone(panel, "CancelZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	zone.add_item(alpha)
	await _settle_frames(2)
	zone.start_drag([alpha])
	var coordinator = zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "cancel path should create a drag session")
	if session == null:
		return
	zone.get_runtime().cancel_drag(session)
	await _settle_frames(2)
	_check(coordinator.get_session() == null, "cancel should clear the drag session")
	_check(alpha.visible, "cancel should restore the dragged item visibility")
	_check(_zone_item_names(zone) == ["Alpha"], "cancel should preserve the logical order")
	_check(_unmanaged_control_names(zone).is_empty(), "cancel should clear any ghost controls")

func _test_external_reconciliation() -> void:
	var panel = _make_panel("ReconcilePanel", Vector2(24, 24), Vector2(620, 260))
	var zone = ExampleSupport.make_zone(panel, "ReconcileZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	zone.add_item(alpha)
	zone.add_item(beta)
	await _settle_frames(2)
	zone.get_items_root().move_child(beta, 0)
	await _settle_frames(2)
	_check(_zone_item_names(zone) == ["Alpha", "Beta"], "external reorder should not rewrite logical order")
	_check(_managed_control_names(panel) == ["Alpha", "Beta"], "external reorder should be reconciled back to logical order")
	var gamma = ExampleSupport.make_card("Gamma", 3, ["power"], true)
	zone.get_items_root().add_child(gamma)
	zone.get_items_root().move_child(gamma, 1)
	await _settle_frames(2)
	_check(_zone_item_names(zone) == ["Alpha", "Gamma", "Beta"], "external add should be reconciled into logical order without reordering existing items")
	_check(_managed_control_names(panel) == ["Alpha", "Gamma", "Beta"], "external add should sync container order after reconciliation")
	_check(_unmanaged_control_names(zone).is_empty(), "reconciliation should not leave unmanaged controls behind")

func _test_freed_item_reconciliation() -> void:
	var panel = _make_panel("FreedPanel", Vector2(24, 24), Vector2(620, 260))
	var zone = ExampleSupport.make_zone(panel, "FreedZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	zone.add_item(alpha)
	await _settle_frames(2)
	alpha.queue_free()
	await _settle_frames(3)
	_check(zone.get_item_count() == 0, "queue_free on a managed card should be reconciled out of the zone")
	_check(_managed_control_names(panel).is_empty(), "freed managed cards should not leave orphan controls in the container")
	_check(_unmanaged_control_names(zone).is_empty(), "freed managed cards should not leave ghost controls behind")

func _test_freed_item_during_drag_session() -> void:
	var panel = _make_panel("FreedDragPanel", Vector2(24, 24), Vector2(620, 300))
	var zone = ExampleSupport.make_zone(panel, "FreedDragZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	zone.add_item(alpha)
	await _settle_frames(2)
	zone.start_drag([alpha])
	var coordinator = zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "freeing a dragged card requires an active drag session")
	if session == null:
		return
	alpha.queue_free()
	await _settle_frames(2)
	zone.get_runtime().process(0.0)
	await _settle_frames(1)
	_check(coordinator.get_session() == null, "freeing the dragged card should auto-clear the drag session")
	_check(zone.get_item_count() == 0, "freeing the dragged card should reconcile it out of the zone")
	_check(_unmanaged_control_names(zone).is_empty(), "freeing the dragged card should not leave ghost controls behind")

func _control_name_list(items: Array[Control]) -> Array[String]:
	var names: Array[String] = []
	for item in items:
		names.append(item.name)
	return names
