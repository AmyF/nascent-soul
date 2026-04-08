extends "res://scenes/tests/shared/test_harness.gd"

func _init() -> void:
	_suite_name = "core-state"

func _run_suite() -> void:
	await _test_reorder_and_remove()
	await _reset_root()
	await _test_drag_transfer_and_selection_prune()
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
	panel.move_child(beta, 0)
	await _settle_frames(2)
	_check(_zone_item_names(zone) == ["Alpha", "Beta"], "external reorder should not rewrite logical order")
	_check(_managed_control_names(panel) == ["Alpha", "Beta"], "external reorder should be reconciled back to logical order")
	var gamma = ExampleSupport.make_card("Gamma", 3, ["power"], true)
	panel.add_child(gamma)
	panel.move_child(gamma, 1)
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
