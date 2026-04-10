extends "res://scenes/tests/shared/test_harness.gd"

const FREECELL_SCENE = preload("res://scenes/examples/freecell.tscn")

func _init() -> void:
	_suite_name = "freecell-showcase"

func _run_suite() -> void:
	await _test_initial_deal_and_zone_population()
	await _reset_root()
	await _test_legal_moves_between_tableau_free_cells_and_foundations()
	await _reset_root()
	await _test_illegal_moves_and_multi_card_capacity_limits()
	await _reset_root()
	await _test_drag_start_rules_and_group_drag_visuals()
	await _reset_root()
	await _test_hover_feedback_stays_static()
	await _reset_root()
	await _test_compact_layout_keeps_tableau_operable()
	await _reset_root()
	await _test_victory_detection()

func _spawn_scene() -> Control:
	var scene = FREECELL_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(4)
	return scene

func _spawn_scene_in_host(host_size: Vector2) -> Control:
	var scene = FREECELL_SCENE.instantiate()
	await _mount_scene_in_host(scene, host_size)
	await _settle_frames(2)
	return scene

func _test_initial_deal_and_zone_population() -> void:
	var scene = await _spawn_scene()
	scene.call("start_new_game", 20260410)
	await _settle_frames(3)
	var tableaus: Array = scene.call("get_tableau_zones")
	var free_cells: Array = scene.call("get_free_cell_zones")
	var foundations: Array = scene.call("get_foundation_zones")
	var total_cards := 0
	_check(tableaus.size() == 8, "freecell should create eight tableau columns")
	_check(free_cells.size() == 4, "freecell should create four free cells")
	_check(foundations.size() == 4, "freecell should create four foundations")
	for index in range(tableaus.size()):
		var zone = tableaus[index] as Zone
		var expected = 7 if index < 4 else 6
		_check(zone != null and zone.get_item_count() == expected, "freecell initial deal should distribute %d cards to tableau %d" % [expected, index + 1])
		if zone != null:
			total_cards += zone.get_item_count()
	for zone in free_cells:
		if zone is Zone:
			_check((zone as Zone).get_item_count() == 0, "freecell should start with empty free cells")
	for zone in foundations:
		if zone is Zone:
			_check((zone as Zone).get_item_count() == 0, "freecell should start with empty foundations")
	_check(total_cards == 52, "freecell initial deal should place all 52 cards into the tableau")
	var seed_label = scene.get_node_or_null("RootMargin/RootVBox/Toolbar/SeedLabel") as Label
	_check(seed_label != null and seed_label.text.contains("Seed"), "freecell should surface the active deal seed")

func _test_legal_moves_between_tableau_free_cells_and_foundations() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [
			["AH"],
			["2H"],
			["7C"],
			["8D"],
			["6S"],
			["5H"],
			["4C"],
			["3D"]
		],
		"free_cells": ["", "", "", ""],
		"foundations": {}
	})
	await _settle_frames(3)
	_check(scene.call("try_auto_foundation", scene.call("get_card_by_code", "AH")), "freecell should auto-send an exposed ace to its foundation")
	await _settle_frames(2)
	_check(scene.call("foundation_total") == 1, "freecell auto-foundation should increase the foundation count")
	_check(scene.call("try_auto_foundation", scene.call("get_card_by_code", "2H")), "freecell should allow the next matching rank onto the foundation")
	await _settle_frames(2)
	_check(scene.call("foundation_total") == 2, "freecell foundations should build upward one rank at a time")
	var tableaus: Array = scene.call("get_tableau_zones")
	var free_cells: Array = scene.call("get_free_cell_zones")
	_check(scene.call("try_move_cards", _card_array(scene, ["7C"]), tableaus[3]), "freecell should allow descending alternating tableau moves")
	await _settle_frames(2)
	_check((tableaus[2] as Zone).get_item_count() == 0, "successful tableau moves should remove the card from the source column")
	_check((tableaus[3] as Zone).get_item_count() == 2, "successful tableau moves should add the card to the destination column")
	_check(scene.call("try_move_cards", _card_array(scene, ["6S"]), free_cells[0]), "freecell should allow moving a single exposed card into an empty free cell")
	await _settle_frames(2)
	_check((free_cells[0] as Zone).get_item_count() == 1, "freecell should leave the moved card in the chosen free cell")

func _test_illegal_moves_and_multi_card_capacity_limits() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [
			["7H"],
			["8D"],
			["3C"],
			["4S"],
			["5C"],
			["6D"],
			["7S"],
			["8H"]
		],
		"free_cells": ["", "", "", ""],
		"foundations": {}
	})
	await _settle_frames(3)
	var tableaus: Array = scene.call("get_tableau_zones")
	var free_cells: Array = scene.call("get_free_cell_zones")
	var foundations: Array = scene.call("get_foundation_zones")
	_check(not scene.call("try_move_cards", _card_array(scene, ["7H"]), tableaus[1]), "freecell should reject same-color tableau builds")
	await _settle_frames(2)
	_check(not scene.call("try_move_cards", _card_array(scene, ["3C"]), foundations[0]), "freecell should reject non-ace foundation openings")
	await _settle_frames(2)
	_check(scene.call("try_move_cards", _card_array(scene, ["4S"]), free_cells[0]), "freecell should still allow a legal move into an empty free cell")
	await _settle_frames(2)
	_check(not scene.call("try_move_cards", _card_array(scene, ["5C"]), free_cells[0]), "freecell should reject moving into an occupied free cell")
	await _settle_frames(2)

	scene.call("load_debug_state", {
		"tableaus": [
			["7C", "6H", "5C"],
			[],
			["KD"],
			["QS"],
			["JH"],
			["10S"],
			["9H"],
			["8S"]
		],
		"free_cells": ["AH", "2D", "3H", ""],
		"foundations": {}
	})
	await _settle_frames(3)
	tableaus = scene.call("get_tableau_zones")
	var moving_run := _card_array(scene, ["7C", "6H", "5C"])
	_check(not scene.call("try_move_cards", moving_run, tableaus[1]), "freecell should reject moving a run larger than the current carry capacity")
	await _settle_frames(2)
	_check((tableaus[0] as Zone).get_item_count() == 3 and (tableaus[1] as Zone).get_item_count() == 0, "rejected multi-card moves should leave both tableau columns unchanged")

	scene.call("load_debug_state", {
		"tableaus": [
			["7C", "6H", "5C"],
			[],
			["KD"],
			["QS"],
			["JH"],
			["10S"],
			["9H"],
			["8S"]
		],
		"free_cells": ["AH", "2D", "", ""],
		"foundations": {}
	})
	await _settle_frames(3)
	tableaus = scene.call("get_tableau_zones")
	moving_run = _card_array(scene, ["7C", "6H", "5C"])
	_check(scene.call("try_move_cards", moving_run, tableaus[1]), "freecell should allow the same run once the carry capacity is high enough")
	await _settle_frames(2)
	_check((tableaus[0] as Zone).get_item_count() == 0 and (tableaus[1] as Zone).get_item_count() == 3, "successful multi-card moves should relocate the full exposed run")

func _test_drag_start_rules_and_group_drag_visuals() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [
			["9C", "8H", "7C"],
			[],
			["6D"],
			[],
			[],
			[],
			[],
			[]
		],
		"free_cells": ["", "", "", ""],
		"foundations": {
			"hearts": ["AH", "2H"]
		}
	})
	await _settle_frames(3)
	var tableaus: Array = scene.call("get_tableau_zones")
	var foundations: Array = scene.call("get_foundation_zones")
	var source_zone = tableaus[0] as Zone
	var target_zone = tableaus[1] as Zone
	var run_head = scene.call("get_card_by_code", "9C") as ZoneItemControl
	source_zone.start_drag([run_head], run_head)
	var session = source_zone.get_drag_session()
	_check(session != null, "freecell should allow dragging an exposed descending alternating run from its head card")
	if session != null:
		_check(_card_codes(session.items) == ["9C", "8H", "7C"], "freecell should expand the drag to the full exposed tableau run")
		_check(session.anchor_item == run_head, "freecell should preserve the clicked card as the drag anchor")
		_check(session.cursor_proxy != null and session.cursor_proxy.get_child_count() == 3, "freecell drag proxy should render the full dragged run")
		_preview_transfer(target_zone, source_zone, session.items, ZonePlacementTarget.linear(0), run_head.global_position, session.anchor_item)
		session.hover_zone = target_zone
		session.preview_target = ZonePlacementTarget.linear(0)
		var ghost = _find_unmanaged_control(target_zone)
		_check(ghost != null and ghost.get_child_count() == 3, "freecell preview ghost should render the full dragged run")
		source_zone.cancel_drag(session)
		await _settle_frames(2)
	scene.call("load_debug_state", {
		"tableaus": [
			["9C", "8H", "7H"],
			[],
			[],
			[],
			[],
			[],
			[],
			[]
		],
		"free_cells": ["", "", "", ""],
		"foundations": {}
	})
	await _settle_frames(3)
	source_zone = (scene.call("get_tableau_zones")[0] as Zone)
	var invalid_head = scene.call("get_card_by_code", "9C") as ZoneItemControl
	source_zone.start_drag([invalid_head], invalid_head)
	await _settle_frames(2)
	_check(source_zone.get_drag_session() == null, "freecell should reject dragging a tableau suffix that is not a legal descending alternating run")
	scene.call("load_debug_state", {
		"tableaus": [[], [], [], [], [], [], [], []],
		"free_cells": ["KS", "", "", ""],
		"foundations": {
			"hearts": ["AH", "2H", "3H"]
		}
	})
	await _settle_frames(3)
	var free_cells: Array = scene.call("get_free_cell_zones")
	var free_cell_zone = free_cells[0] as Zone
	var free_cell_card = scene.call("get_card_by_code", "KS") as ZoneItemControl
	free_cell_zone.start_drag([free_cell_card], free_cell_card)
	session = free_cell_zone.get_drag_session()
	_check(session != null and session.items.size() == 1, "freecell lanes should only ever start single-card drags from free cells")
	if session != null:
		free_cell_zone.cancel_drag(session)
		await _settle_frames(2)
	var foundation_zone = foundations[2] as Zone
	var foundation_top = scene.call("get_card_by_code", "3H") as ZoneItemControl
	foundation_zone.start_drag(_card_array(scene, ["AH", "2H", "3H"]), foundation_top)
	session = foundation_zone.get_drag_session()
	_check(session != null and _card_codes(session.items) == ["3H"], "freecell foundations should only drag the exposed top card even if more cards are requested")
	if session != null:
		foundation_zone.cancel_drag(session)
		await _settle_frames(2)

func _test_victory_detection() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [[], [], [], [], [], [], [], []],
		"free_cells": ["", "", "", ""],
		"foundations": {
			"clubs": _foundation_codes("C"),
			"diamonds": _foundation_codes("D"),
			"hearts": _foundation_codes("H"),
			"spades": _foundation_codes("S")
		}
	})
	await _settle_frames(3)
	_check(scene.call("foundation_total") == 52, "freecell victory state should place all 52 cards into the foundations")
	_check(scene.call("has_won"), "freecell should mark the game as won when every foundation is complete")
	var victory_label = scene.get_node_or_null("RootMargin/RootVBox/VictoryLabel") as Label
	_check(victory_label != null and victory_label.visible, "freecell should reveal the victory banner after a solved state loads")

func _test_hover_feedback_stays_static() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [
			["7C"],
			["8D"],
			[],
			[],
			[],
			[],
			[],
			[]
		],
		"free_cells": ["", "", "", ""],
		"foundations": {}
	})
	await _settle_frames(3)
	var tableaus: Array = scene.call("get_tableau_zones")
	var source_zone = tableaus[0] as Zone
	var target_zone = tableaus[1] as Zone
	var card = scene.call("get_card_by_code", "7C") as Control
	var overlay = card.get_node_or_null("CardOverlay") as ColorRect
	var before_position = card.global_position
	var before_scale = card.scale
	var before_z = card.z_index
	_emit_mouse_entered(card)
	await _settle_frames(2)
	_check(source_zone != null and source_zone.get_hovered_item() == card, "freecell hover should still register the hovered card")
	_check(card.global_position.is_equal_approx(before_position), "freecell hover should not move the card")
	_check(card.scale.is_equal_approx(before_scale), "freecell hover should not scale the card")
	_check(card.z_index == before_z, "freecell hover should not raise the card z-order")
	_check(overlay != null and overlay.visible and overlay.color.a > 0.0, "freecell hover should still light the card overlay")
	_check(scene.call("try_move_cards", _card_array(scene, ["7C"]), target_zone), "freecell hover cleanup should not break drag/drop move validation")

func _test_compact_layout_keeps_tableau_operable() -> void:
	var scene = await _spawn_scene_in_host(Vector2(960, 900))
	await _settle_frames(3)
	var top_row = scene.get_node_or_null("RootMargin/RootVBox/TopRow") as Control
	var tableau_scroll = scene.get_node_or_null("RootMargin/RootVBox/TableauScroll") as ScrollContainer
	var tableau_row = scene.get_node_or_null("RootMargin/RootVBox/TableauScroll/TableauRow") as HBoxContainer
	_check(top_row != null and tableau_scroll != null and top_row.get_global_rect().end.y <= tableau_scroll.get_global_rect().position.y + 1.0, "freecell compact layout should keep top controls above the tableau surface")
	_check(tableau_row != null and tableau_scroll != null and tableau_row.custom_minimum_size.x > tableau_scroll.size.x, "freecell compact layout should preserve lane width via scrolling")
	scene.call("load_debug_state", {
		"tableaus": [
			["7C"],
			["8D"],
			[],
			[],
			[],
			[],
			[],
			[]
		],
		"free_cells": ["", "", "", ""],
		"foundations": {}
	})
	await _settle_frames(3)
	var tableaus: Array = scene.call("get_tableau_zones")
	_check(scene.call("try_move_cards", _card_array(scene, ["7C"]), tableaus[1]), "freecell compact layout should keep tableau moves operable")

func _foundation_codes(suit_code: String) -> Array:
	var codes: Array = []
	for rank in ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]:
		codes.append("%s%s" % [rank, suit_code])
	return codes

func _card_array(scene: Control, codes: Array) -> Array[ZoneItemControl]:
	var cards: Array[ZoneItemControl] = []
	for code in codes:
		var card = scene.call("get_card_by_code", code)
		if card is ZoneItemControl:
			cards.append(card)
	return cards

func _card_codes(items: Array) -> Array[String]:
	var codes: Array[String] = []
	for item in items:
		if item is ZoneItemControl:
			codes.append((item as ZoneItemControl).name)
	return codes
