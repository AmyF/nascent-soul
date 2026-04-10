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
	await _test_victory_detection()

func _spawn_scene() -> Control:
	var scene = FREECELL_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(4)
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
