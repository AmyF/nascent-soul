extends "res://scenes/tests/suites/freecell_showcase_support.gd"

func _init() -> void:
	_suite_name = "freecell-showcase-history"

func _run_suite() -> void:
	await _test_history_helper_contract()
	await _reset_root()
	await _test_toolbar_buttons_and_undo_history()
	await _reset_root()
	await _test_manual_free_cell_moves_do_not_auto_promote()
	await _reset_root()
	await _test_revealed_foundation_cards_wait_for_player_action()
	await _reset_root()
	await _test_manual_auto_foundation_moves_any_legal_card()
	await _reset_root()
	await _test_victory_detection()
