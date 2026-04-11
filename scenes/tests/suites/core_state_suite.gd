extends "res://scenes/tests/shared/test_harness.gd"

const ZoneCompositeTransferPolicyScript = preload("res://addons/nascentsoul/impl/permissions/zone_composite_transfer_policy.gd")
const ZoneConfigurableDragVisualFactoryScript = preload("res://addons/nascentsoul/impl/factories/zone_configurable_drag_visual_factory.gd")
const ZoneGroupSortScript = preload("res://addons/nascentsoul/impl/sorts/zone_group_sort.gd")
const ZoneRuntimePortScript = preload("res://addons/nascentsoul/runtime/zone_runtime_port.gd")
const HAND_CONFIG = preload("res://addons/nascentsoul/presets/hand_zone_config.tres")
const BOARD_CONFIG = preload("res://addons/nascentsoul/presets/board_zone_config.tres")
const TRANSFER_PLAYGROUND_SCENE = preload("res://scenes/examples/transfer_playground.tscn")
const ZoneDragStartDecisionScript = preload("res://addons/nascentsoul/model/zone_drag_start_decision.gd")

class RejectDragStartPolicy extends ZoneTransferPolicy:
	func evaluate_drag_start(_context: ZoneContext, anchor_item: ZoneItemControl, _selected_items: Array[ZoneItemControl]):
		return ZoneDragStartDecisionScript.new(false, "Dragging %s is disabled." % anchor_item.name, [anchor_item])

class GroupVisualTestItem extends ZoneItemControl:
	func _init(label: String = "") -> void:
		name = label
		custom_minimum_size = Vector2(72, 96)
		size = custom_minimum_size

	func create_zone_drag_ghost(_context: ZoneContext) -> Control:
		var ghost := Panel.new()
		ghost.name = "SingleGhost"
		ghost.custom_minimum_size = custom_minimum_size
		ghost.size = custom_minimum_size
		return ghost

	func create_zone_drag_proxy(_context: ZoneContext) -> Control:
		var proxy := ColorRect.new()
		proxy.name = "SingleProxy"
		proxy.color = Color(0.32, 0.46, 0.88, 0.72)
		proxy.custom_minimum_size = custom_minimum_size
		proxy.size = custom_minimum_size
		return proxy

	func create_zone_group_drag_ghost(_context: ZoneContext, source_items: Array[ZoneItemControl], _anchor_item: ZoneItemControl) -> Control:
		return _make_group_root("GroupGhost", Color(0.92, 0.82, 0.36, 0.22), source_items.size())

	func create_zone_group_drag_proxy(_context: ZoneContext, source_items: Array[ZoneItemControl], _anchor_item: ZoneItemControl) -> Control:
		return _make_group_root("GroupProxy", Color(0.22, 0.72, 0.92, 0.72), source_items.size())

	func _make_group_root(root_name: String, color: Color, item_count: int) -> Control:
		var root := Control.new()
		root.name = root_name
		root.custom_minimum_size = Vector2(custom_minimum_size.x, custom_minimum_size.y + max(0, item_count - 1) * 22.0)
		root.size = root.custom_minimum_size
		for index in range(item_count):
			var rect := ColorRect.new()
			rect.name = "Layer%d" % index
			rect.color = color
			rect.custom_minimum_size = custom_minimum_size
			rect.size = custom_minimum_size
			rect.position = Vector2(0, index * 22.0)
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(rect)
		return root

func _init() -> void:
	_suite_name = "core-state"

func _run_suite() -> void:
	await _test_reorder_and_remove()
	await _reset_root()
	await _test_internal_roots_and_config_override()
	await _reset_root()
	await _test_zone_config_helpers()
	await _reset_root()
	await _test_base_zone_defaults()
	await _reset_root()
	await _test_runtime_port_contract()
	await _reset_root()
	_test_placement_target_contract()
	await _reset_root()
	await _test_drag_transfer_and_selection_prune()
	await _reset_root()
	await _test_transfer_signal_chain()
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
	await _test_composite_policy()
	await _reset_root()
	await _test_group_sort_policy()
	await _reset_root()
	await _test_drag_visual_factory()
	await _reset_root()
	await _test_drag_start_rejection_signal()
	await _reset_root()
	await _test_group_drag_visual_hooks_and_anchor_snapshots()
	await _reset_root()
	await _test_policy_reject_cleanup()
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
	_reorder_items(zone, [gamma], ZonePlacementTarget.linear(0))
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

func _test_internal_roots_and_config_override() -> void:
	var panel = _make_panel("ConfigPanel", Vector2(24, 24), Vector2(620, 260))
	var zone = ExampleSupport.make_zone(panel, "ConfigZone", null, null, null, null, null, null, HAND_CONFIG)
	var override_layout := ZoneHBoxLayout.new()
	override_layout.item_spacing = 20.0
	override_layout.padding_left = 10.0
	ExampleSupport.set_zone_layout_policy(zone, override_layout)
	var override_policy := ZoneCapacityTransferPolicy.new()
	override_policy.max_items = 2
	ExampleSupport.set_zone_transfer_policy(zone, override_policy)
	await _settle_frames(2)
	_check(zone.get_items_root() != null, "zone should always create an ItemsRoot child")
	_check(zone.get_preview_root() != null, "zone should always create a PreviewRoot child")
	_check(zone.get_items_root().get_parent() == zone, "ItemsRoot should belong to the zone itself")
	_check(zone.get_preview_root().get_parent() == zone, "PreviewRoot should belong to the zone itself")
	_check(ExampleSupport.get_zone_layout_policy(zone) == override_layout, "layout override should take precedence over config layout")
	_check(ExampleSupport.get_zone_transfer_policy(zone) == override_policy, "transfer override should take precedence over config transfer policy")
	_check(ExampleSupport.get_zone_display_style(zone) == HAND_CONFIG.display_style, "config display style should resolve when no override exists")
	_check(ExampleSupport.get_zone_drag_visual_factory(zone) == HAND_CONFIG.drag_visual_factory, "config drag visual factory should resolve when no override exists")

func _test_zone_config_helpers() -> void:
	var defaults = ZoneConfig.make_card_defaults()
	_check(defaults.space_model is ZoneLinearSpaceModel, "card config helper should provide a linear space model by default")
	_check(defaults.layout_policy is ZoneHandLayout, "card config helper should provide the default hand layout")
	_check(defaults.transfer_policy is ZoneAllowAllTransferPolicy, "card config helper should provide the default transfer policy")
	var zone_defaults = ZoneConfig.make_zone_defaults()
	_check(zone_defaults.space_model is ZoneLinearSpaceModel, "zone config helper should keep the linear space model default")
	_check(zone_defaults.layout_policy is ZoneHBoxLayout, "zone config helper should provide the row-style base Zone layout")
	_check(not (zone_defaults.layout_policy is ZoneHandLayout), "zone config helper should not fall back to the hand layout semantics")
	var base := ZoneConfig.new()
	var custom_transfer := ZoneCapacityTransferPolicy.new()
	custom_transfer.max_items = 2
	var custom_display := ZoneTweenDisplay.new()
	base.transfer_policy = custom_transfer
	base.display_style = custom_display
	var merged = base.filled_from(defaults)
	_check(merged.transfer_policy == custom_transfer, "filled_from should preserve already assigned policies")
	_check(merged.display_style == custom_display, "filled_from should preserve already assigned display styles")
	_check(merged.space_model is ZoneLinearSpaceModel, "filled_from should supply any missing default fields")
	var override_layout := ZoneHBoxLayout.new()
	override_layout.item_spacing = 22.0
	var override_sort := ZoneGroupSortScript.new()
	var overridden = merged.with_overrides({
		"layout_policy": override_layout,
		"sort_policy": override_sort
	})
	_check(overridden != merged, "with_overrides should return a duplicated ZoneConfig instance")
	_check(overridden.layout_policy == override_layout, "with_overrides should replace the requested layout policy")
	_check(overridden.sort_policy == override_sort, "with_overrides should replace the requested sort policy")
	_check(merged.layout_policy != override_layout, "with_overrides should not mutate the source config")
	var square_space := ZoneSquareGridSpaceModel.new()
	var battlefield_defaults = ZoneConfig.make_battlefield_defaults(square_space)
	_check(battlefield_defaults.space_model == square_space, "battlefield config helper should respect an explicit space model override")
	_check(battlefield_defaults.layout_policy is ZoneBattlefieldLayout, "battlefield config helper should provide the battlefield layout")
	_check(battlefield_defaults.transfer_policy is ZoneOccupancyTransferPolicy, "battlefield config helper should provide the battlefield occupancy policy")

func _test_base_zone_defaults() -> void:
	var panel = _make_panel("BaseZoneDefaultsPanel", Vector2(24, 24), Vector2(620, 260))
	var zone := Zone.new()
	zone.name = "BaseZoneDefaults"
	zone.custom_minimum_size = Vector2(360, 220)
	zone.size = zone.custom_minimum_size
	panel.add_child(zone)
	await _settle_frames(2)
	_check(zone.get_layout_policy() is ZoneHBoxLayout, "base Zone without an explicit config should resolve the row-style default layout")
	_check(not (zone.get_layout_policy() is ZoneHandLayout), "base Zone without an explicit config should not inherit the hand-layout default")
	_check(zone.get_transfer_policy() is ZoneAllowAllTransferPolicy, "base Zone default config should still use the allow-all transfer policy")
	_check(zone.get_display_style() is ZoneCardDisplay, "base Zone default config should keep the standard card display style")

func _test_runtime_port_contract() -> void:
	var panel = _make_panel("RuntimePortPanel", Vector2(24, 24), Vector2(620, 260))
	var zone = ExampleSupport.make_zone(panel, "RuntimePortZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	zone.add_item(alpha)
	await _settle_frames(2)
	var port = ZoneRuntimePortScript.for_zone(zone)
	_check(port != null, "live zones should resolve a runtime port")
	_check(ZoneRuntimePortScript.resolve_context(zone) != null, "runtime port lookup should resolve the zone context")
	_check(ZoneRuntimePortScript.resolve_input_service(zone) != null, "runtime port lookup should resolve the input service")
	_check(ZoneRuntimePortScript.resolve_render_service(zone) != null, "runtime port lookup should resolve the render service")
	_check(ZoneRuntimePortScript.resolve_transfer_service(zone) != null, "runtime port lookup should resolve the transfer service")
	zone.select_item(alpha, false)
	await _settle_frames(1)
	var selection_events: Array = []
	zone.selection_changed.connect(func(items: Array) -> void:
		var names: Array[String] = []
		for item in items:
			if item is ZoneItemControl:
				names.append((item as ZoneItemControl).name)
		selection_events.append(names)
	)
	ZoneRuntimePortScript.emit_selection_changed_for(zone)
	var hover_exit_events: Array[String] = []
	zone.item_hover_exited.connect(func(item: Control) -> void:
		hover_exit_events.append(item.name)
	)
	ZoneRuntimePortScript.emit_item_hover_exited_for(zone, alpha)
	var layout_events: Array[String] = []
	zone.layout_changed.connect(func() -> void:
		layout_events.append("layout")
	)
	ZoneRuntimePortScript.emit_layout_changed_for(zone)
	_check(selection_events == [["Alpha"]], "runtime port selection helper should surface the current selected-items snapshot")
	_check(hover_exit_events == ["Alpha"], "runtime port hover helper should emit through the public zone signal")
	_check(layout_events.size() >= 1, "runtime port layout helper should emit the public layout_changed signal")

func _test_placement_target_contract() -> void:
	var invalid = ZonePlacementTarget.invalid()
	_check(not invalid.is_valid(), "invalid placement target should remain invalid")
	_check(invalid.matches_kind(ZonePlacementTarget.TargetKind.NONE), "invalid placement target should keep the NONE kind contract")
	var linear = ZonePlacementTarget.linear(3)
	_check(linear.is_linear(), "linear placement target should report linear semantics")
	_check(not linear.is_grid(), "linear placement target should not advertise grid semantics")
	_check(linear.linear_index == 3 and linear.get_linear_index() == 3, "linear placement target should expose the resolved linear index explicitly")
	_check(linear.grid_coordinates == Vector2i(-1, -1), "linear placement target should not retain fake grid coordinates")
	_check(linear.describe() == "linear:3", "linear placement target should describe itself with the linear vocabulary")
	var square = ZonePlacementTarget.square(2, 1, &"sq_2_1")
	_check(square.is_square() and square.is_grid(), "square placement target should report grid semantics")
	_check(square.grid_coordinates == Vector2i(2, 1), "square placement target should expose its grid coordinates explicitly")
	_check(square.get_grid_column() == 2 and square.get_grid_row() == 1, "square placement target should expose column and row helpers")
	_check(square.grid_cell_id == &"sq_2_1" and square.has_grid_cell_id(), "square placement target should preserve the resolved grid cell id")
	_check(square.matches_kind(ZonePlacementTarget.TargetKind.SQUARE), "square placement target should match its own kind")
	_check(not square.matches_kind(ZonePlacementTarget.TargetKind.HEX), "square placement target should not match the hex kind")
	var hex = ZonePlacementTarget.hex(4, 2, &"hex_4_2")
	_check(hex.is_hex(), "hex placement target should report hex semantics")
	_check(hex.get_grid_coordinates() == Vector2i(4, 2), "hex placement target should expose grid coordinates through the shared helper")

func _test_drag_transfer_and_selection_prune() -> void:
	var target_panel = _make_panel("TargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("SourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "SourceZone", ZoneHBoxLayout.new())
	var target_zone = ExampleSupport.make_zone(target_panel, "TargetZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	var ward = ExampleSupport.make_card("Ward", 1, ["skill"], true)
	var transfer_events: Array[String] = []
	target_zone.item_transferred.connect(func(item: Control, source_zone_ref: Zone, target_zone_ref: Zone, target) -> void:
		var resolved_target: ZonePlacementTarget = null
		if target is ZonePlacementTarget:
			resolved_target = target as ZonePlacementTarget
		elif target is ZoneTransferDecision:
			resolved_target = (target as ZoneTransferDecision).resolved_target
		var slot = resolved_target.linear_index if resolved_target != null and resolved_target.is_linear() else -1
		transfer_events.append("%s:%s->%s@%d" % [item.name, source_zone_ref.name, target_zone_ref.name, slot])
	)
	source_zone.add_item(alpha)
	source_zone.add_item(beta)
	target_zone.add_item(ward)
	await _settle_frames(2)
	source_zone.select_item(beta, false)
	await _settle_frames(1)
	source_zone.start_drag([beta])
	var session = source_zone.get_drag_session()
	_check(session != null, "drag transfer should create a drag session")
	if session == null:
		return
	await _settle_frames(1)
	session.hover_zone = target_zone
	session.preview_target = ZonePlacementTarget.linear(1)
	target_zone.perform_drop(session)
	await _settle_frames(2)
	_check(source_zone.get_drag_session() == null, "successful drop should clear the drag session")
	_check(_zone_item_names(source_zone) == ["Alpha"], "drag transfer should remove the card from the source zone")
	_check(_zone_item_names(target_zone) == ["Ward", "Beta"], "drag transfer should insert the card into the target zone at preview index")
	_check(source_zone.get_selected_items().is_empty(), "source selection should be pruned after transfer")
	_check(beta.visible, "transferred card should be visible after drop")
	_check(transfer_events == ["Beta:SourceZone->TargetZone@1"], "target transfer signal should describe the final target index")
	_check(_unmanaged_control_names(source_zone).is_empty(), "successful transfer should not leave a source ghost behind")
	_check(_unmanaged_control_names(target_zone).is_empty(), "successful transfer should not leave a target ghost behind")

func _test_transfer_signal_chain() -> void:
	var target_panel = _make_panel("SignalTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("SignalSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "SignalSourceZone", ZoneHBoxLayout.new())
	var target_zone = ExampleSupport.make_zone(target_panel, "SignalTargetZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	source_zone.add_item(alpha)
	target_zone.add_item(beta)
	await _settle_frames(2)
	source_zone.select_item(alpha, false)
	await _settle_frames(1)
	var source_removed_events: Array[String] = []
	var source_selection_events: Array = []
	var source_layout_events: Array[String] = []
	source_zone.item_removed.connect(func(item: Control, from_index: int) -> void:
		source_removed_events.append("%s:%d" % [item.name, from_index])
	)
	source_zone.selection_changed.connect(func(items: Array) -> void:
		var names: Array[String] = []
		for item in items:
			if item is ZoneItemControl:
				names.append((item as ZoneItemControl).name)
		source_selection_events.append(names)
	)
	source_zone.layout_changed.connect(func() -> void:
		source_layout_events.append("layout")
	)
	var target_added_events: Array[String] = []
	var target_transfer_events: Array[String] = []
	var target_layout_events: Array[String] = []
	target_zone.item_added.connect(func(item: Control, index: int) -> void:
		target_added_events.append("%s:%d" % [item.name, index])
	)
	target_zone.item_transferred.connect(func(item: Control, source_zone_ref: Zone, target_zone_ref: Zone, target) -> void:
		var resolved_target := target as ZonePlacementTarget
		var linear_index := resolved_target.linear_index if resolved_target != null and resolved_target.is_linear() else -1
		target_transfer_events.append("%s:%s->%s@%d" % [item.name, source_zone_ref.name, target_zone_ref.name, linear_index])
	)
	target_zone.layout_changed.connect(func() -> void:
		target_layout_events.append("layout")
	)
	_check(_transfer_items(source_zone, [alpha], target_zone, ZonePlacementTarget.linear(1)), "programmatic transfer should still succeed through the public API")
	await _settle_frames(2)
	_check(source_removed_events == ["Alpha:0"], "source zone should emit item_removed through the public signal chain")
	_check(source_selection_events == [[]], "source zone should emit the pruned selection through the public signal chain")
	_check(source_layout_events.size() >= 1, "source zone should emit layout_changed during the transfer")
	_check(target_added_events == ["Alpha:1"], "target zone should emit item_added for the inserted transfer result")
	_check(target_transfer_events == ["Alpha:SignalSourceZone->SignalTargetZone@1"], "target zone should emit item_transferred with the resolved placement target")
	_check(target_layout_events.size() >= 1, "target zone should emit layout_changed during the transfer")
	_check(_zone_item_names(source_zone).is_empty(), "source zone should no longer contain the moved item")
	_check(_zone_item_names(target_zone) == ["Beta", "Alpha"], "target zone should contain the inserted item at the resolved index")

func _test_batch_transfer_api() -> void:
	var target_panel = _make_panel("BatchTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("BatchSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "BatchSourceZone", ZoneHBoxLayout.new(), null, null, null, null, null, HAND_CONFIG)
	var target_zone = ExampleSupport.make_zone(target_panel, "BatchTargetZone", ZoneHBoxLayout.new(), null, null, null, null, null, BOARD_CONFIG)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	var gamma = ExampleSupport.make_card("Gamma", 3, ["power"], true)
	var ward = ExampleSupport.make_card("Ward", 1, ["skill"], true)
	source_zone.add_item(alpha)
	source_zone.add_item(beta)
	source_zone.add_item(gamma)
	target_zone.add_item(ward)
	await _settle_frames(2)
	_check(_transfer_items(source_zone, [gamma, alpha], target_zone, ZonePlacementTarget.linear(1)), "batch transfer should accept arbitrary input order and preserve logical zone order")
	await _settle_frames(2)
	_check(_zone_item_names(source_zone) == ["Beta"], "batch transfer should remove all moved items from the source zone")
	_check(_zone_item_names(target_zone) == ["Ward", "Alpha", "Gamma"], "batch transfer should insert items using the source zone's logical order")
	_check(_unmanaged_control_names(source_zone).is_empty(), "batch transfer should not leave unmanaged controls in the source zone")
	_check(_unmanaged_control_names(target_zone).is_empty(), "batch transfer should not leave unmanaged controls in the target zone")

func _test_transfer_snapshots_preserve_animation_origins() -> void:
	var panel = _make_panel("SnapshotPanel", Vector2(24, 24), Vector2(920, 280))
	var zone = ExampleSupport.make_zone(panel, "SnapshotZone", null, null, null, null, null, null, HAND_CONFIG)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	zone.add_item(alpha)
	zone.add_item(beta)
	await _settle_frames(2)
	var alpha_origin = alpha.global_position
	var beta_origin = beta.global_position
	var alpha_rotation = alpha.rotation
	var beta_rotation = beta.rotation
	var baseline_snapshots = _capture_transfer_snapshots(zone, [alpha, beta])
	var alpha_baseline: Dictionary = baseline_snapshots.get(alpha, {})
	var beta_baseline: Dictionary = baseline_snapshots.get(beta, {})
	_check(alpha_baseline.get("global_position", Vector2.ZERO).distance_to(alpha_origin) <= 0.01, "baseline transfer snapshot should preserve the primary card global position")
	_check(beta_baseline.get("global_position", Vector2.ZERO).distance_to(beta_origin) <= 0.01, "baseline transfer snapshot should preserve the secondary card global position")
	_check(is_equal_approx(alpha_baseline.get("rotation", 0.0), alpha_rotation), "baseline transfer snapshot should preserve the primary card rotation")
	_check(is_equal_approx(beta_baseline.get("rotation", 0.0), beta_rotation), "baseline transfer snapshot should preserve the secondary card rotation")
	var programmatic_origin = _resolve_transfer_origin(zone, [alpha, beta])
	_check(programmatic_origin is Vector2 and (programmatic_origin as Vector2).distance_to(alpha_origin) <= 0.01, "programmatic transfer APIs should use the primary card's current global position as their animation origin")
	var programmatic_snapshots = _capture_transfer_snapshots(zone, [alpha, beta], programmatic_origin)
	var alpha_programmatic: Dictionary = programmatic_snapshots.get(alpha, {})
	var beta_programmatic: Dictionary = programmatic_snapshots.get(beta, {})
	_check(alpha_programmatic.get("global_position", Vector2.ZERO).distance_to(alpha_origin) <= 0.01, "programmatic transfer snapshots should leave the primary card anchored at its current position")
	_check(beta_programmatic.get("global_position", Vector2.ZERO).distance_to(beta_origin) <= 0.01, "programmatic transfer snapshots should preserve secondary card positions when no drag cursor offset exists")
	var drop_position = Vector2(540, 180)
	var dragged_snapshots = _capture_transfer_snapshots(zone, [alpha, beta], drop_position)
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
	_check(_move_item(source_zone, alpha, target_zone, ZonePlacementTarget.linear(0)), "handoff cleanup smoke should move the card into the target zone")
	await _settle_frames(2)
	_check(source_zone._runtime_get_transfer_handoff_count() == 0, "source runtime should not retain transfer handoff data after a completed move")
	_check(target_zone._runtime_get_transfer_handoff_count() == 0, "target runtime should consume transfer handoff data during refresh")
	target_zone._runtime_set_transfer_handoff(alpha, {"global_position": Vector2(10, 10)})
	target_zone.remove_item(alpha)
	await _settle_frames(1)
	_check(target_zone._runtime_get_transfer_handoff_count() == 0, "remove_item should clear any pending handoff for the removed card")
	target_zone.add_item(alpha)
	await _settle_frames(2)
	target_zone._runtime_set_transfer_handoff(alpha, {"global_position": Vector2(20, 20)})
	target_zone.clear_display_state()
	_check(target_zone._runtime_get_transfer_handoff_count() == 0, "clear_display_state should clear pending handoff data")

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
	var session = hand_zone.get_drag_session()
	_check(session != null, "transfer playground drag should create an active session")
	if session == null:
		return
	session.hover_zone = board_zone
	session.preview_target = ZonePlacementTarget.linear(board_zone.get_item_count())
	hand_zone._runtime_finalize_drag_session(session)
	await _settle_frames(3)
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.25).timeout
		await _settle_frames(1)
	_check(board_zone.get_item_count() == initial_board_count + 1, "transfer playground drag should increase board item count")
	_check(hand_zone.get_item_count() == 4, "transfer playground drag should remove one item from hand")
	_check(board_zone.has_item(hand_item), "transfer playground drag should move the dragged item into board")
	_check(hand_item.visible, "transfer playground drag should leave the moved item visible")
	_check(_rect_inside(board_zone.get_global_rect().grow(24.0), hand_item.get_global_rect(), 24.0), "transfer playground moved card should render inside the board zone")

func _test_rejected_hover_hides_preview_but_still_rejects_drop() -> void:
	var target_panel = _make_panel("RejectHoverTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("RejectHoverSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "RejectHoverSourceZone", ZoneHBoxLayout.new())
	var capacity = ZoneCapacityTransferPolicy.new()
	capacity.max_items = 0
	capacity.reject_reason = "Reject hover target is full."
	var target_zone = ExampleSupport.make_zone(target_panel, "RejectHoverTargetZone", ZoneHBoxLayout.new(), null, capacity)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var hover_states: Array[Dictionary] = []
	var preview_indices: Array[int] = []
	var reject_events: Array[String] = []
	target_zone.drop_hover_state_changed.connect(func(items: Array, _target_zone_ref: Zone, decision) -> void:
		var item_name = str(items[0].name) if not items.is_empty() and items[0] is Control else "Selection"
		var resolved_target: ZonePlacementTarget = decision.resolved_target if decision != null and decision.resolved_target != null else ZonePlacementTarget.invalid()
		var slot = resolved_target.linear_index if resolved_target.is_linear() else -1
		hover_states.append({
			"item": item_name,
			"allowed": decision.allowed,
			"target_slot": slot,
			"reason": decision.reason
		})
	)
	target_zone.drop_preview_changed.connect(func(_items: Array, _target_zone_ref: Zone, target) -> void:
		var preview_target: ZonePlacementTarget = target if target is ZonePlacementTarget else ZonePlacementTarget.invalid()
		var slot = preview_target.linear_index if preview_target.is_linear() else -1
		preview_indices.append(slot)
	)
	target_zone.drop_rejected.connect(func(items: Array, source_zone_ref: Zone, target_zone_ref: Zone, reason: String) -> void:
		reject_events.append("%s:%s->%s:%s" % [items[0].name, source_zone_ref.name, target_zone_ref.name, reason])
	)
	source_zone.add_item(alpha)
	await _settle_frames(2)
	source_zone.start_drag([alpha])
	var session = source_zone.get_drag_session()
	_check(session != null, "reject hover test requires an active drag session")
	if session == null:
		return
	var decision = _preview_transfer(target_zone, source_zone, session.items, ZonePlacementTarget.linear(0), Vector2.ZERO, alpha)
	session.hover_zone = target_zone
	session.requested_target = ZonePlacementTarget.linear(0)
	session.preview_target = ZonePlacementTarget.invalid()
	_check(not decision.allowed, "reject hover should resolve to a rejected decision")
	_check(decision.reason == "Reject hover target is full.", "preview transfer should surface the same rejection reason used by drag hover feedback")
	_check(decision.resolved_target != null and decision.resolved_target.is_linear() and decision.resolved_target.linear_index == 0, "preview transfer should keep the attempted target slot even when the drop is rejected")
	_check(hover_states == [{
		"item": "Alpha",
		"allowed": false,
		"target_slot": 0,
		"reason": "Reject hover target is full."
	}], "reject hover should emit hover state without advertising an insertion preview")
	_check(preview_indices.is_empty(), "reject hover should not emit a preview slot when the drop is disallowed")
	_check(_find_unmanaged_control(target_zone) == null, "reject hover should not create a ghost or preview control")
	target_zone.perform_drop(session)
	await _settle_frames(2)
	_check(reject_events == ["Alpha:RejectHoverSourceZone->RejectHoverTargetZone:Reject hover target is full."], "reject hover release should still emit drop_rejected")
	_check(source_zone.has_item(alpha), "reject hover release should keep the dragged card in the source zone")
	_check(not target_zone.has_item(alpha), "reject hover release should not insert the card into the target zone")

func _test_policy_reject_cleanup() -> void:
	var target_panel = _make_panel("RejectTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("RejectSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "RejectSourceZone", ZoneHBoxLayout.new())
	var capacity = ZoneCapacityTransferPolicy.new()
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
	var session = source_zone.get_drag_session()
	_check(session != null, "reject path should create a drag session")
	if session == null:
		return
	await _settle_frames(1)
	session.hover_zone = target_zone
	session.preview_target = ZonePlacementTarget.linear(0)
	target_zone.perform_drop(session)
	await _settle_frames(2)
	_check(source_zone.get_drag_session() == null, "rejected drop should clear the drag session")
	_check(_zone_item_names(source_zone) == ["Alpha"], "rejected drop should keep the item in the source zone")
	_check(_zone_item_names(target_zone).is_empty(), "rejected drop should not insert anything into the target zone")
	_check(alpha.visible, "rejected drop should restore the item visibility")
	_check(alpha.scale == Vector2.ONE and is_zero_approx(alpha.rotation), "rejected drop should clear transient transforms")
	_check(reject_events == ["Alpha:RejectSourceZone->RejectTargetZone:Reject target is full."], "drop_rejected should expose the source, target, and reason")
	_check(_unmanaged_control_names(source_zone).is_empty(), "rejected drop should not leave a source ghost behind")
	_check(_unmanaged_control_names(target_zone).is_empty(), "rejected drop should not leave a target ghost behind")

func _test_composite_policy() -> void:
	var target_panel = _make_panel("CompositeTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var hand_panel = _make_panel("CompositeHandPanel", Vector2(24, 320), Vector2(620, 260))
	var deck_panel = _make_panel("CompositeDeckPanel", Vector2(24, 616), Vector2(620, 260))
	var hand_zone = ExampleSupport.make_zone(hand_panel, "HandZone", ZoneHBoxLayout.new())
	var deck_zone = ExampleSupport.make_zone(deck_panel, "DeckZone", ZoneHBoxLayout.new())
	var source_policy := ZoneSourceTransferPolicy.new()
	source_policy.allowed_source_zone_names = PackedStringArray(["HandZone"])
	source_policy.reject_reason = "Composite target only accepts cards from HandZone."
	var capacity_policy := ZoneCapacityTransferPolicy.new()
	capacity_policy.max_items = 1
	capacity_policy.reject_reason = "Composite target is full."
	var composite_policy := ZoneCompositeTransferPolicyScript.new()
	composite_policy.combine_mode = ZoneCompositeTransferPolicyScript.CombineMode.ALL
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
	_check(_move_item(hand_zone, hand_alpha, target_zone, ZonePlacementTarget.linear(0)), "composite policy should allow a card from the allowed source zone")
	await _settle_frames(2)
	_check(_zone_item_names(target_zone) == ["HandAlpha"], "composite policy should insert the first allowed card")
	_check(not _move_item(hand_zone, hand_beta, target_zone, ZonePlacementTarget.linear(1)), "composite policy should reject a second card when capacity is full")
	await _settle_frames(2)
	_check(_zone_item_names(hand_zone) == ["HandBeta"], "capacity rejection should leave the second hand card in the source zone")
	_check(not _move_item(deck_zone, deck_alpha, target_zone, ZonePlacementTarget.linear(1)), "composite policy should reject a card from a disallowed source zone")
	await _settle_frames(2)
	_check(_zone_item_names(deck_zone) == ["DeckAlpha"], "source rejection should leave the deck card in the source zone")
	_check(reject_events == [
		"HandBeta:HandZone:Composite target is full.",
		"DeckAlpha:DeckZone:Composite target only accepts cards from HandZone."
		], "composite policy should surface the specific rejecting reason")

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
	var sorted = zone.get_sorted_items()
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
	var session = source_zone.get_drag_session()
	_check(session != null, "drag visual factory should still create a drag session")
	if session == null:
		return
	_check(session.cursor_proxy is ColorRect, "custom drag visual factory should be able to replace the drag proxy")
	if session.cursor_proxy is ColorRect:
		var proxy := session.cursor_proxy as ColorRect
		_check(proxy.color == source_factory.proxy_color, "custom drag proxy should use the configured color")
		_check(proxy.scale == source_factory.proxy_scale, "custom drag proxy should use the configured scale")
	_preview_transfer(target_zone, source_zone, session.items, ZonePlacementTarget.linear(0), alpha.global_position, alpha)
	session.hover_zone = target_zone
	session.preview_target = ZonePlacementTarget.linear(0)
	var ghost = _find_unmanaged_control(target_zone)
	_check(ghost is Panel, "custom drag visual factory should be able to replace the preview ghost")
	if ghost is Panel:
		var ghost_style = (ghost as Panel).get_theme_stylebox("panel")
		_check(ghost_style is StyleBoxFlat, "custom preview ghost should install a flat panel style")
		if ghost_style is StyleBoxFlat:
			var style := ghost_style as StyleBoxFlat
			_check(style.bg_color == target_factory.ghost_fill_color, "custom preview ghost should use the configured fill color")
			_check(style.border_color == target_factory.ghost_border_color, "custom preview ghost should use the configured border color")
	source_zone.cancel_drag(session)
	await _settle_frames(2)
	_check(_unmanaged_control_names(source_zone).is_empty(), "custom proxy cleanup should not leave unmanaged controls in the source zone")
	_check(_unmanaged_control_names(target_zone).is_empty(), "custom ghost cleanup should not leave unmanaged controls in the target zone")

func _test_drag_start_rejection_signal() -> void:
	var panel = _make_panel("RejectStartPanel", Vector2(24, 24), Vector2(620, 260))
	var reject_policy := RejectDragStartPolicy.new()
	var zone = ExampleSupport.make_zone(panel, "RejectStartZone", ZoneHBoxLayout.new(), null, reject_policy)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var rejection_events: Array[String] = []
	zone.drag_start_rejected.connect(func(items: Array, source_zone_ref: Zone, reason: String) -> void:
		var item_name = str(items[0].name) if not items.is_empty() and items[0] is Control else "Selection"
		rejection_events.append("%s:%s:%s" % [item_name, source_zone_ref.name, reason])
	)
	zone.add_item(alpha)
	await _settle_frames(2)
	zone.start_drag([alpha], alpha)
	await _settle_frames(2)
	_check(zone.get_drag_session() == null, "drag start rejection should not create a drag session")
	_check(alpha.visible, "drag start rejection should leave the original card visible")
	_check(rejection_events == ["Alpha:RejectStartZone:Dragging Alpha is disabled."], "drag start rejection should emit the source zone and reason")
	_check(_unmanaged_control_names(zone).is_empty(), "drag start rejection should not create unmanaged proxy or ghost controls")

func _test_group_drag_visual_hooks_and_anchor_snapshots() -> void:
	var target_panel = _make_panel("GroupVisualTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("GroupVisualSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = ExampleSupport.make_zone(source_panel, "GroupVisualSourceZone", ZoneHBoxLayout.new())
	var target_zone = ExampleSupport.make_zone(target_panel, "GroupVisualTargetZone", ZoneHBoxLayout.new())
	var alpha = GroupVisualTestItem.new("Alpha")
	var beta = GroupVisualTestItem.new("Beta")
	source_zone.add_item(alpha)
	source_zone.add_item(beta)
	await _settle_frames(2)
	source_zone.start_drag([alpha, beta], beta)
	var session = source_zone.get_drag_session()
	_check(session != null, "group drag visual test should create an active drag session")
	if session == null:
		return
	_check(session.anchor_item == beta, "multi-item drags should preserve the explicit anchor item")
	_check(_control_name_list(session.items) == ["Alpha", "Beta"], "drag start should still normalize moving items into zone order")
	_check(session.cursor_proxy != null and session.cursor_proxy.name == "GroupProxy", "group drag proxy hook should take precedence over the single-item proxy")
	_check(session.cursor_proxy.get_child_count() == 2, "group drag proxy should render every dragged item")
	var preview_decision = _preview_transfer(target_zone, source_zone, session.items, ZonePlacementTarget.linear(0), beta.global_position, session.anchor_item)
	_check(preview_decision.allowed, "group drag preview should still resolve through the normal transfer path")
	session.hover_zone = target_zone
	session.preview_target = ZonePlacementTarget.linear(0)
	var ghost = _find_unmanaged_control(target_zone)
	_check(ghost != null and ghost.name == "GroupGhost", "group drag ghost hook should take precedence over the single-item ghost")
	if ghost != null:
		_check(ghost.get_child_count() == 2, "group drag ghost should render every dragged item")
	var drop_position = Vector2(420, 180)
	var snapshots = _capture_transfer_snapshots(source_zone, session.items, drop_position, session.anchor_item)
	var alpha_snapshot: Dictionary = snapshots.get(alpha, {})
	var beta_snapshot: Dictionary = snapshots.get(beta, {})
	var dragged_offset = alpha_snapshot.get("global_position", Vector2.ZERO) - beta_snapshot.get("global_position", Vector2.ZERO)
	var source_offset = alpha.global_position - beta.global_position
	_check(beta_snapshot.get("global_position", Vector2.ZERO).distance_to(drop_position) <= 0.01, "drag transfer snapshots should anchor the explicit drag anchor at the drop position")
	_check(dragged_offset.distance_to(source_offset) <= 0.01, "drag transfer snapshots should preserve relative offsets around the explicit anchor item")
	source_zone.cancel_drag(session)
	await _settle_frames(2)
	_check(_unmanaged_control_names(source_zone).is_empty(), "group proxy cleanup should not leave unmanaged controls in the source zone")
	_check(_unmanaged_control_names(target_zone).is_empty(), "group ghost cleanup should not leave unmanaged controls in the target zone")

func _test_drag_cancel_cleanup() -> void:
	var panel = _make_panel("CancelPanel", Vector2(24, 24), Vector2(620, 260))
	var zone = ExampleSupport.make_zone(panel, "CancelZone", ZoneHBoxLayout.new())
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	zone.add_item(alpha)
	await _settle_frames(2)
	zone.start_drag([alpha])
	var session = zone.get_drag_session()
	_check(session != null, "cancel path should create a drag session")
	if session == null:
		return
	zone.cancel_drag(session)
	await _settle_frames(2)
	_check(zone.get_drag_session() == null, "cancel should clear the drag session")
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
	var session = zone.get_drag_session()
	_check(session != null, "freeing a dragged card requires an active drag session")
	if session == null:
		return
	alpha.queue_free()
	await _settle_frames(3)
	_check(zone.get_drag_session() == null, "freeing the dragged card should auto-clear the drag session")
	_check(zone.get_item_count() == 0, "freeing the dragged card should reconcile it out of the zone")
	_check(_unmanaged_control_names(zone).is_empty(), "freeing the dragged card should not leave ghost controls behind")

func _control_name_list(items: Array[ZoneItemControl]) -> Array[String]:
	var names: Array[String] = []
	for item in items:
		names.append(item.name)
	return names
