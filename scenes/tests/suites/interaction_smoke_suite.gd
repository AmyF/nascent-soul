extends "res://scenes/tests/shared/test_harness.gd"

func _init() -> void:
	_suite_name = "interaction-smoke"

func _run_suite() -> void:
	await _test_hover_and_selection_visuals()
	await _reset_root()
	await _test_drag_proxy_uses_pointer_position_and_stays_on_top()
	await _reset_root()
	await _test_long_press_signal()
	await _reset_root()
	await _test_freed_item_during_long_press()
	await _reset_root()
	await _test_background_click_clears_hover_and_selection()
	await _reset_root()
	await _test_shift_range_selection()
	await _reset_root()
	await _test_keyboard_navigation_actions()
	await _reset_root()
	await _test_animated_transfer_handoff_path()
	await _reset_root()
	await _test_drop_preview_clear_signal()

func _test_hover_and_selection_visuals() -> void:
	var panel = _make_panel("VisualPanel", Vector2(24, 24), Vector2(620, 300))
	var zone = _make_test_zone(panel, "VisualZone")
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	zone.add_item(alpha)
	zone.add_item(beta)
	await _settle_frames(2)
	var base_position = alpha.position
	_emit_mouse_entered(alpha)
	await _settle_frames(1)
	_check(zone.get_runtime().selection_state.hovered_item == alpha, "mouse enter should update hovered item")
	_check(alpha.scale.x > 1.0 and alpha.position.y < base_position.y, "hover should lift and scale the hovered card")
	_check(_overlay_visible(alpha), "hover should show the card overlay")
	_emit_mouse_exited(alpha)
	await _settle_frames(1)
	_check(zone.get_runtime().selection_state.hovered_item == null, "mouse exit should clear hovered item")
	_check(alpha.scale == Vector2.ONE and is_equal_approx(alpha.position.y, base_position.y), "mouse exit should reset hover lift")
	_emit_left_click(alpha)
	await _settle_frames(1)
	_check(zone.get_runtime().selection_state.is_selected(alpha), "left click should select the clicked card")
	_check(alpha.scale.x > 1.0, "selected card should receive selected scale styling")
	_emit_left_click(beta, true)
	await _settle_frames(1)
	_check(zone.get_runtime().selection_state.is_selected(alpha) and zone.get_runtime().selection_state.is_selected(beta), "ctrl-click should multi-select cards")

func _test_drag_proxy_uses_pointer_position_and_stays_on_top() -> void:
	var panel = _make_panel("PileDragPanel", Vector2(24, 24), Vector2(420, 320))
	var pile_layout := ZonePileLayout.new()
	pile_layout.overlap_x = 22.0
	var zone = ExampleSupport.make_zone(panel, "PileDragZone", pile_layout)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], false)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], false)
	zone.add_item(alpha)
	zone.add_item(beta)
	await _settle_frames(2)
	var pointer_drag = alpha.global_position + Vector2(62, 46)
	_emit_mouse_button(alpha, MOUSE_BUTTON_LEFT, true)
	_emit_mouse_motion(alpha, pointer_drag)
	var coordinator = zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "pointer-driven pile drag should create an active session")
	if session == null:
		return
	_check(session.drag_offset.distance_to(pointer_drag - alpha.global_position) <= 0.1, "drag session should use the live mouse motion position when the drag begins")
	_check(session.cursor_proxy != null, "pile drag should create a visible cursor proxy")
	if session.cursor_proxy == null:
		return
	_check(session.cursor_proxy.top_level, "drag cursor proxy should render as a top-level control")
	_check(not session.cursor_proxy.z_as_relative, "drag cursor proxy should use absolute z ordering")
	_check(session.cursor_proxy.z_index >= ZoneDragCoordinator.CURSOR_PROXY_Z_INDEX, "drag cursor proxy should stay above stacked pile cards")
	zone.get_runtime().cancel_drag()
	await _settle_frames(2)

func _test_long_press_signal() -> void:
	var panel = _make_panel("LongPressPanel", Vector2(24, 24), Vector2(620, 300))
	var interaction = ZoneInteraction.new()
	interaction.long_press_enabled = true
	interaction.long_press_time = 0.05
	var zone = _make_test_zone(panel, "LongPressZone", interaction)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var long_pressed: Array[String] = []
	zone.item_long_pressed.connect(func(item: Control) -> void:
		long_pressed.append(item.name)
	)
	zone.add_item(alpha)
	await _settle_frames(2)
	_emit_mouse_button(alpha, MOUSE_BUTTON_LEFT, true)
	await get_tree().create_timer(0.08).timeout
	await _settle_frames(1)
	_emit_mouse_button(alpha, MOUSE_BUTTON_LEFT, false)
	await _settle_frames(1)
	_check(long_pressed == ["Alpha"], "long press should emit item_long_pressed after the configured delay")

func _test_freed_item_during_long_press() -> void:
	var panel = _make_panel("FreedLongPressPanel", Vector2(24, 24), Vector2(620, 300))
	var interaction = ZoneInteraction.new()
	interaction.long_press_enabled = true
	interaction.long_press_time = 0.05
	var zone = _make_test_zone(panel, "FreedLongPressZone", interaction)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var long_press_count = 0
	zone.item_long_pressed.connect(func(_item: Control) -> void:
		long_press_count += 1
	)
	zone.add_item(alpha)
	await _settle_frames(2)
	_emit_mouse_button(alpha, MOUSE_BUTTON_LEFT, true)
	alpha.queue_free()
	await get_tree().create_timer(0.08).timeout
	await _settle_frames(2)
	_check(long_press_count == 0, "freeing a pressed card should cancel long-press emission")
	_check(zone.get_item_count() == 0, "freeing a pressed card should also reconcile it out of the zone")

func _test_background_click_clears_hover_and_selection() -> void:
	var panel = _make_panel("BackgroundPanel", Vector2(24, 24), Vector2(720, 320))
	var zone = _make_test_zone(panel, "BackgroundZone")
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	zone.add_item(alpha)
	zone.add_item(beta)
	await _settle_frames(2)
	_emit_mouse_entered(alpha)
	_emit_left_click(alpha)
	await _settle_frames(1)
	_emit_background_left_click(panel, panel.global_position + panel.size - Vector2(24, 24))
	await _settle_frames(1)
	_check(zone.get_runtime().selection_state.hovered_item == null, "background click should clear hover state")
	_check(zone.get_runtime().selection_state.get_selected_items().is_empty(), "background click should clear selected cards")
	_check(alpha.scale == Vector2.ONE, "background click should reset the selected card transform")

func _test_shift_range_selection() -> void:
	var panel = _make_panel("ShiftPanel", Vector2(24, 24), Vector2(780, 280))
	var zone = _make_test_zone(panel, "ShiftZone")
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	var gamma = ExampleSupport.make_card("Gamma", 3, ["power"], true)
	var delta = ExampleSupport.make_card("Delta", 1, ["skill"], true)
	for card in [alpha, beta, gamma, delta]:
		zone.add_item(card)
	await _settle_frames(2)
	_emit_left_click(alpha)
	await _settle_frames(1)
	_emit_left_click(gamma, false, true)
	await _settle_frames(1)
	_check(zone.get_runtime().selection_state.get_selected_items() == [alpha, beta, gamma], "shift-click should select the range from anchor to clicked card")
	_emit_left_click(delta, false, true)
	await _settle_frames(1)
	_check(zone.get_runtime().selection_state.get_selected_items() == [alpha, beta, gamma, delta], "repeated shift-click should keep the original anchor until a normal click changes it")

func _test_keyboard_navigation_actions() -> void:
	var panel = _make_panel("KeyboardPanel", Vector2(24, 24), Vector2(780, 280))
	var interaction = ZoneInteraction.new()
	interaction.keyboard_navigation_enabled = true
	interaction.next_item_action = &"zone_test_next"
	interaction.previous_item_action = &"zone_test_prev"
	interaction.activate_item_action = &"zone_test_activate"
	interaction.clear_selection_action = &"zone_test_clear"
	var zone = _make_test_zone(panel, "KeyboardZone", interaction)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	var gamma = ExampleSupport.make_card("Gamma", 3, ["power"], true)
	var activated: Array[String] = []
	zone.item_clicked.connect(func(item: Control) -> void:
		activated.append(item.name)
	)
	for card in [alpha, beta, gamma]:
		zone.add_item(card)
	await _settle_frames(2)
	zone.grab_focus()
	await _settle_frames(1)
	_emit_action_input(zone, &"zone_test_next")
	await _settle_frames(1)
	_check(zone.get_selected_items() == [alpha], "keyboard next should select the first card when there is no active selection")
	_emit_action_input(zone, &"zone_test_next")
	await _settle_frames(1)
	_check(zone.get_selected_items() == [beta], "keyboard next should move the selection forward")
	_emit_action_input(zone, &"zone_test_prev")
	await _settle_frames(1)
	_check(zone.get_selected_items() == [alpha], "keyboard previous should move the selection backward")
	_emit_action_input(zone, &"zone_test_activate")
	await _settle_frames(1)
	_check(activated == ["Alpha"], "keyboard activate should emit item_clicked for the current item")
	_emit_action_input(zone, &"zone_test_clear")
	await _settle_frames(1)
	_check(zone.get_selected_items().is_empty(), "keyboard clear should clear the current selection")

func _test_animated_transfer_handoff_path() -> void:
	if DisplayServer.get_name() == "headless":
		_check(true, "animated transfer handoff path is GUI-only")
		return
	var target_panel = _make_panel("AnimatedTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("AnimatedSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_display := ZoneTweenDisplay.new()
	source_display.duration = 0.12
	var target_display := ZoneTweenDisplay.new()
	target_display.duration = 0.12
	var source_zone = ExampleSupport.make_zone(source_panel, "AnimatedSourceZone", ZoneHBoxLayout.new(), source_display)
	var target_zone = ExampleSupport.make_zone(target_panel, "AnimatedTargetZone", ZoneHBoxLayout.new(), target_display)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	source_zone.add_item(alpha)
	await _settle_frames(2)
	var source_origin = alpha.global_position
	_check(source_zone.move_item_to(alpha, target_zone, ZonePlacementTarget.linear(0)), "animated transfer smoke should move the card into the target zone")
	var target_state = target_zone.get_runtime().get_display_state(target_display)
	_check(target_state["active_tweens"].has(alpha), "animated transfer should create a live tween in GUI mode")
	_check(alpha.global_position.distance_to(source_origin) <= 0.5, "animated transfer should start from the source card position before tweening")
	_check(not target_zone.get_runtime().item_state.transfer_handoffs.has(alpha), "animated transfer should consume handoff data on first apply")
	await get_tree().create_timer(target_display.duration + 0.08).timeout
	await _settle_frames(1)
	_check(not target_state["active_tweens"].has(alpha), "animated transfer should clear its tween after finishing")
	_check(_rect_inside(target_zone.get_global_rect().grow(24.0), alpha.get_global_rect(), 24.0), "animated transfer should finish inside the target zone bounds")

func _test_drop_preview_clear_signal() -> void:
	var target_panel = _make_panel("PreviewTargetPanel", Vector2.ZERO, Vector2(620, 260))
	var source_panel = _make_panel("PreviewSourcePanel", Vector2(24, 320), Vector2(620, 260))
	var source_zone = _make_test_zone(source_panel, "PreviewSourceZone")
	var target_zone = _make_test_zone(target_panel, "PreviewTargetZone")
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var preview_indices: Array[int] = []
	target_zone.drop_preview_changed.connect(func(_items: Array, _target_zone_ref: Zone, target) -> void:
		var preview_target: ZonePlacementTarget = target if target is ZonePlacementTarget else ZonePlacementTarget.invalid()
		preview_indices.append(preview_target.slot if preview_target.is_linear() else -1)
	)
	source_zone.add_item(alpha)
	await _settle_frames(2)
	source_zone.start_drag([alpha])
	var coordinator = source_zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "preview clear smoke requires an active drag session")
	if session == null:
		return
	target_zone.get_runtime()._create_ghost(alpha)
	target_zone.drop_preview_changed.emit(session.items, target_zone, ZonePlacementTarget.linear(0))
	session.hover_zone = target_zone
	session.preview_target = ZonePlacementTarget.linear(0)
	source_zone.get_runtime().cancel_drag(session)
	await _settle_frames(2)
	var last_preview_index = preview_indices[preview_indices.size() - 1] if not preview_indices.is_empty() else 0
	_check(preview_indices.size() >= 2 and last_preview_index == -1, "drag cleanup should emit a preview-cleared signal with index -1")

func _make_test_zone(panel: Control, zone_name: String, interaction: ZoneInteraction = null) -> Zone:
	var display := ZoneCardDisplay.new()
	display.duration = 0.0
	return ExampleSupport.make_zone(panel, zone_name, ZoneHBoxLayout.new(), display, null, null, interaction)
