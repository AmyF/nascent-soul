extends "res://scenes/tests/shared/test_harness.gd"

const FREECELL_SCENE = preload("res://scenes/examples/freecell.tscn")
const FREECELL_HISTORY_SCRIPT = preload("res://scenes/examples/freecell/freecell_history.gd")
const ZONE_TRANSFER_REQUEST_SCRIPT = preload("res://addons/nascentsoul/model/zone_transfer_request.gd")

func _init() -> void:
	_suite_name = "freecell-showcase"

func _run_suite() -> void:
	await _test_initial_deal_and_zone_population()
	await _reset_root()
	await _test_classic_deal_number_one_layout()
	await _reset_root()
	await _test_legal_moves_between_tableau_free_cells_and_foundations()
	await _reset_root()
	await _test_transfer_policy_surface_contract()
	await _reset_root()
	await _test_history_helper_contract()
	await _reset_root()
	await _test_toolbar_buttons_and_undo_history()
	await _reset_root()
	await _test_slot_layout_matches_classic_freecell()
	await _reset_root()
	await _test_drag_drop_diamond_across_all_free_cells()
	await _reset_root()
	await _test_manual_free_cell_moves_do_not_auto_promote()
	await _reset_root()
	await _test_revealed_foundation_cards_wait_for_player_action()
	await _reset_root()
	await _test_manual_auto_foundation_moves_any_legal_card()
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
	scene.call("start_new_game", 1)
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
	var deal_label = scene.get_node_or_null("RootMargin/RootVBox/Toolbar/ToolbarRow/SeedLabel") as Label
	_check(deal_label != null and deal_label.text.contains("Game #1"), "freecell should surface the active deal number")

func _test_classic_deal_number_one_layout() -> void:
	var scene = await _spawn_scene()
	scene.call("start_new_game", 1)
	await _settle_frames(3)
	var tableaus: Array = scene.call("get_tableau_zones")
	_check(_zone_codes(tableaus[0] as Zone) == ["JD", "KD", "2S", "4C", "3S", "6D", "6S"], "freecell deal #1 should match the classic Microsoft first tableau")
	_check(_zone_codes(tableaus[7] as Zone) == ["5H", "3H", "3C", "7S", "7D", "10C"], "freecell deal #1 should match the classic Microsoft eighth tableau")

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
	var foundations: Array = scene.call("get_foundation_zones")
	_check(scene.call("try_move_cards", _card_array(scene, ["AH"]), foundations[0]), "freecell should let any ace start any empty foundation slot")
	await _settle_frames(4)
	_check(scene.call("foundation_total") == 1, "freecell should place only the moved ace onto the chosen foundation")
	var opened_foundation = foundations[0] as Zone
	_check(opened_foundation != null and opened_foundation.get_item_count() == 1, "freecell should start exactly one foundation pile with the ace")
	_check(scene.call("try_move_cards", _card_array(scene, ["2H"]), foundations[0]), "freecell should let the next suited rank build onto the started foundation")
	await _settle_frames(2)
	_check(opened_foundation != null and opened_foundation.get_item_count() == 2, "freecell should continue building the started foundation in the same slot")
	var tableaus: Array = scene.call("get_tableau_zones")
	var free_cells: Array = scene.call("get_free_cell_zones")
	_check(scene.call("try_move_cards", _card_array(scene, ["7C"]), tableaus[3]), "freecell should allow descending alternating tableau moves")
	await _settle_frames(2)
	_check((tableaus[2] as Zone).get_item_count() == 0, "successful tableau moves should remove the card from the source column")
	_check((tableaus[3] as Zone).get_item_count() == 2, "successful tableau moves should add the card to the destination column")
	_check(scene.call("try_move_cards", _card_array(scene, ["6S"]), free_cells[0]), "freecell should allow moving a single exposed card into an empty free cell")
	await _settle_frames(2)
	_check((free_cells[0] as Zone).get_item_count() == 1, "freecell should leave the moved card in the chosen free cell")
	_check(scene.call("try_move_cards", _card_array(scene, ["5H"]), free_cells[1]), "freecell free cells should accept any suit, not just a pre-bound slot suit")
	await _settle_frames(2)
	_check((free_cells[1] as Zone).get_item_count() == 1, "freecell should allow a different-suit card into any other empty free cell")

func _test_transfer_policy_surface_contract() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [
			["8C", "7H"],
			["9D"],
			["KC"],
			["QS"],
			["JC"],
			["10H"],
			["9S"],
			["8D"]
		],
		"free_cells": ["AH", "2C", "3D", "4S"],
		"foundations": {}
	})
	await _settle_frames(3)
	var tableaus: Array = scene.call("get_tableau_zones")
	var source_zone = tableaus[0] as Zone
	var target_zone = tableaus[1] as Zone
	var move_request = ZONE_TRANSFER_REQUEST_SCRIPT.new(
		target_zone,
		source_zone,
		_card_array(scene, ["8C", "7H"]),
		ZonePlacementTarget.linear(target_zone.get_item_count())
	)
	var decision = scene.call("evaluate_freecell_transfer", &"tableau", 1, null, move_request)
	_check(decision is ZoneTransferDecision and not decision.allowed, "freecell should keep transfer evaluation available through the scene controller surface")
	_check(decision is ZoneTransferDecision and String(decision.reason).contains("Not enough free cells"), "freecell transfer surface should preserve the carry-capacity rejection reason")
	var reorder_request = ZONE_TRANSFER_REQUEST_SCRIPT.new(
		source_zone,
		source_zone,
		_card_array(scene, ["7H"]),
		ZonePlacementTarget.linear(0)
	)
	var reorder_decision = scene.call("evaluate_freecell_transfer", &"tableau", 0, null, reorder_request)
	_check(reorder_decision is ZoneTransferDecision and not reorder_decision.allowed, "freecell transfer surface should reject same-lane reorders")
	_check(reorder_decision is ZoneTransferDecision and String(reorder_decision.reason).contains("Reordering within the same lane"), "freecell transfer surface should keep the no-reorder contract readable")

func _test_history_helper_contract() -> void:
	var history = FREECELL_HISTORY_SCRIPT.new(3)
	var base_state = {
		"deal_number": 1,
		"tableaus": [["AH"], [], [], [], [], [], [], []],
		"free_cells": ["", "", "", ""],
		"foundation_slots": [[], [], [], []]
	}
	var moved_state = {
		"deal_number": 1,
		"tableaus": [[], ["AH"], [], [], [], [], [], []],
		"free_cells": ["", "", "", ""],
		"foundation_slots": [[], [], [], []]
	}
	history.reset_to_snapshot(base_state)
	_check(not history.can_undo(), "freecell history helper should start with a single snapshot after reset")
	_check(history.schedule_checkpoint(), "freecell history helper should allow scheduling a checkpoint once")
	_check(not history.schedule_checkpoint(), "freecell history helper should reject duplicate pending checkpoints")
	_check(not history.commit_checkpoint(base_state), "freecell history helper should deduplicate identical snapshots")
	_check(not history.can_undo(), "freecell history helper should keep undo disabled after a duplicate snapshot")
	_check(history.schedule_checkpoint(), "freecell history helper should allow a new checkpoint after commit")
	_check(history.commit_checkpoint(moved_state), "freecell history helper should accept a distinct snapshot")
	_check(history.can_undo(), "freecell history helper should enable undo after a distinct snapshot")
	var restored_state = history.undo_snapshot()
	var restored_tableaus: Array = restored_state.get("tableaus", [])
	_check(restored_tableaus.size() > 0 and restored_tableaus[0] == ["AH"], "freecell history helper undo should return the previous serialized state")
	_check(not history.can_undo(), "freecell history helper should return to a single baseline snapshot after undo")

func _test_slot_layout_matches_classic_freecell() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [[], [], [], [], [], [], [], []],
		"free_cells": ["AD", "2D", "", ""],
		"foundations": {
			"hearts": ["AH", "2H", "3H"]
		}
	})
	await _settle_frames(3)
	var free_cells: Array = scene.call("get_free_cell_zones")
	var free_cell_card_a = scene.call("get_card_by_code", "AD") as Control
	var free_cell_card_b = scene.call("get_card_by_code", "2D") as Control
	var foundation_zone = _foundation_zone_with_suit(scene, &"hearts")
	var heart_ace = scene.call("get_card_by_code", "AH") as Control
	var heart_three = scene.call("get_card_by_code", "3H") as Control
	_check(free_cell_card_a != null and (free_cells[0] as Zone).get_global_rect().has_point(free_cell_card_a.get_global_rect().get_center()), "freecell should keep a card visibly inside the first free cell slot")
	_check(free_cell_card_b != null and (free_cells[1] as Zone).get_global_rect().has_point(free_cell_card_b.get_global_rect().get_center()), "freecell should keep a card visibly inside the second free cell slot")
	_check(foundation_zone != null and foundation_zone.get_item_count() == 3, "freecell layout test should load three cards into one foundation")
	_check(heart_ace != null and heart_three != null and abs(heart_ace.global_position.x - heart_three.global_position.x) <= 1.0, "freecell foundations should stack cards in one slot instead of spreading them horizontally")
	_check(heart_ace != null and heart_three != null and abs(heart_ace.global_position.y - heart_three.global_position.y) <= 1.0, "freecell foundations should share the same stacked anchor position")

func _test_toolbar_buttons_and_undo_history() -> void:
	var scene = await _spawn_scene()
	var new_game_button = scene.get_node_or_null("RootMargin/RootVBox/Toolbar/ToolbarRow/NewGameButton") as Button
	var undo_button = scene.get_node_or_null("RootMargin/RootVBox/Toolbar/ToolbarRow/UndoButton") as Button
	_check(new_game_button != null, "freecell should expose a New Game toolbar button")
	_check(undo_button != null, "freecell should expose an Undo toolbar button")
	_check(undo_button != null and undo_button.disabled, "freecell should disable Undo before any move has been made")
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
	_check(scene.call("try_move_cards", _card_array(scene, ["7C"]), tableaus[1]), "freecell undo test should make a valid tableau move first")
	await _settle_frames(3)
	_check(not undo_button.disabled and scene.call("can_undo"), "freecell should enable Undo after a successful move")
	undo_button.pressed.emit()
	await _settle_frames(3)
	_check((tableaus[0] as Zone).get_item_count() == 1 and (tableaus[1] as Zone).get_item_count() == 1, "freecell undo should restore the previous tableau state")
	_check(undo_button.disabled and not scene.call("can_undo"), "freecell should disable Undo again after returning to the initial snapshot")
	new_game_button.pressed.emit()
	await _settle_frames(3)
	tableaus = scene.call("get_tableau_zones")
	var free_cells: Array = scene.call("get_free_cell_zones")
	var foundations: Array = scene.call("get_foundation_zones")
	var total_cards := 0
	for zone in tableaus:
		if zone is Zone:
			total_cards += (zone as Zone).get_item_count()
	for zone in free_cells:
		if zone is Zone:
			_check((zone as Zone).get_item_count() == 0, "freecell new game should clear every free cell")
	for zone in foundations:
		if zone is Zone:
			_check((zone as Zone).get_item_count() == 0, "freecell new game should clear every foundation")
	_check(total_cards == 52, "freecell new game button should deal a fresh 52-card layout")
	_check(undo_button.disabled and not scene.call("can_undo"), "freecell new game should reset the undo history")

func _test_drag_drop_diamond_across_all_free_cells() -> void:
	for target_index in range(4):
		var scene = await _spawn_scene()
		scene.call("load_debug_state", {
			"tableaus": [
				["4D"],
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
		var tableaus: Array = scene.call("get_tableau_zones")
		var free_cells: Array = scene.call("get_free_cell_zones")
		var source_zone = tableaus[0] as Zone
		var target_zone = free_cells[target_index] as Zone
		var card = scene.call("get_card_by_code", "4D") as ZoneItemControl
		source_zone.start_drag([card], card)
		var session = source_zone.get_drag_session()
		_check(session != null, "freecell should start a drag session for an exposed diamond card")
		if session != null:
			session.hover_zone = target_zone
			session.preview_target = ZonePlacementTarget.linear(0)
			_check(target_zone.perform_drop(session), "freecell should allow dragging a diamond card into free cell %d" % (target_index + 1))
		await _settle_frames(3)
		_check(scene.call("get_card_by_code", "4D") != null, "freecell drag-drop should not lose the diamond card when targeting free cell %d" % (target_index + 1))
		_check((target_zone as Zone).get_item_count() == 1, "freecell drag-drop should place the diamond card into free cell %d" % (target_index + 1))
		_check((source_zone as Zone).get_item_count() == 0, "freecell drag-drop should clear the source tableau after moving to free cell %d" % (target_index + 1))
		await _reset_root()

	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [[], [], [], [], [], [], [], []],
		"free_cells": ["", "", "4D", ""],
		"foundations": {}
	})
	await _settle_frames(3)
	var free_cells: Array = scene.call("get_free_cell_zones")
	var source_cell = free_cells[2] as Zone
	var target_cell = free_cells[3] as Zone
	var moved_card = scene.call("get_card_by_code", "4D") as ZoneItemControl
	source_cell.start_drag([moved_card], moved_card)
	var cell_session = source_cell.get_drag_session()
	_check(cell_session != null, "freecell should start dragging a diamond card from a free cell")
	if cell_session != null:
		cell_session.hover_zone = target_cell
		cell_session.preview_target = ZonePlacementTarget.linear(0)
		_check(target_cell.perform_drop(cell_session), "freecell should allow dragging a diamond card between the later free cells")
	await _settle_frames(3)
	_check(scene.call("get_card_by_code", "4D") != null, "freecell should not lose a diamond card when dragging between free cells")
	_check(target_cell.get_item_count() == 1 and source_cell.get_item_count() == 0, "freecell should move the diamond card between free cells without making it disappear")

func _test_manual_free_cell_moves_do_not_auto_promote() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [
			["AH"],
			["8D"],
			["7C"],
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
	var free_cells: Array = scene.call("get_free_cell_zones")
	_check(scene.call("try_move_cards", _card_array(scene, ["AH"]), free_cells[0]), "freecell should allow manually parking an ace in a free cell")
	await _settle_frames(4)
	_check((free_cells[0] as Zone).get_item_count() == 1, "freecell should keep the manually parked card in the free cell instead of auto-promoting it immediately")
	_check(scene.call("foundation_total") == 0, "freecell should not auto-send a card to the foundations on the same move that parks it in a free cell")

func _test_revealed_foundation_cards_wait_for_player_action() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [
			["3H", "7C"],
			["8D"],
			[],
			[],
			[],
			[],
			[],
			[]
		],
		"free_cells": ["", "", "", ""],
		"foundations": {
			"hearts": ["AH", "2H"],
			"clubs": ["AC"],
			"spades": ["AS"]
		}
	})
	await _settle_frames(3)
	var tableaus: Array = scene.call("get_tableau_zones")
	_check(scene.call("try_move_cards", _card_array(scene, ["7C"]), tableaus[1]), "freecell should still allow the player move that reveals a safe foundation card")
	await _settle_frames(4)
	_check((tableaus[0] as Zone).get_item_count() == 1, "freecell should leave the newly revealed foundation card in place until the player acts")
	_check(scene.call("foundation_total") == 4, "freecell should not auto-move newly revealed cards after a normal transfer")
	_check(scene.call("try_auto_foundation", scene.call("get_card_by_code", "3H")), "freecell double-click style auto-foundation should still move an exposed legal card")
	await _settle_frames(2)
	var hearts_foundation = _foundation_zone_with_suit(scene, &"hearts")
	_check(hearts_foundation != null and hearts_foundation.get_item_count() == 3, "freecell should extend the matching suit foundation when the player requests auto-foundation")

func _test_manual_auto_foundation_moves_any_legal_card() -> void:
	var scene = await _spawn_scene()
	scene.call("load_debug_state", {
		"tableaus": [
			["5C", "7D"],
			["8S"],
			[],
			[],
			[],
			[],
			[],
			[]
		],
		"free_cells": ["", "", "", ""],
		"foundations": {
			"clubs": ["AC", "2C", "3C", "4C"],
			"hearts": ["AH"],
			"spades": ["AS"]
		}
	})
	await _settle_frames(3)
	var tableaus: Array = scene.call("get_tableau_zones")
	_check(scene.call("try_move_cards", _card_array(scene, ["7D"]), tableaus[1]), "freecell should still allow revealing a legal-but-unsafe foundation candidate")
	await _settle_frames(4)
	_check((tableaus[0] as Zone).get_item_count() == 1, "freecell should leave an exposed but unsafe card in the tableau")
	_check(scene.call("foundation_total") == 6, "freecell should not move any newly revealed card until the player asks for it")
	_check(scene.call("try_auto_foundation", scene.call("get_card_by_code", "5C")), "freecell manual auto-foundation should move any exposed legal card, even when it is strategically risky")
	await _settle_frames(2)
	_check(scene.call("foundation_total") == 7, "freecell manual auto-foundation should increase the foundation count by one successful move")

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
	var foundation_zone = _foundation_zone_with_suit(scene, &"hearts")
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
	_check(tableau_row != null and tableau_row.custom_minimum_size.x >= 700.0, "freecell compact layout should preserve readable tableau lane widths")
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

func _zone_codes(zone: Zone) -> Array[String]:
	return _card_codes(zone.get_items()) if zone != null else []

func _foundation_zone_with_suit(scene: Control, suit: StringName) -> Zone:
	var foundations: Array = scene.call("get_foundation_zones")
	for foundation in foundations:
		if foundation is not Zone:
			continue
		var zone = foundation as Zone
		for item in zone.get_items():
			if item.get("suit") == suit or StringName(str(item.get("suit"))) == suit:
				return zone
	return null
