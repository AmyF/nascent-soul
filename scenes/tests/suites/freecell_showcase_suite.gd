extends "res://scenes/tests/suites/freecell_showcase_support.gd"

func _init() -> void:
	_suite_name = "freecell-showcase-rules"

func _run_suite() -> void:
	await _test_initial_deal_and_zone_population()
	await _reset_root()
	await _test_classic_deal_number_one_layout()
	await _reset_root()
	await _test_legal_moves_between_tableau_free_cells_and_foundations()
	await _reset_root()
	await _test_transfer_policy_surface_contract()
	await _reset_root()
	await _test_illegal_moves_and_multi_card_capacity_limits()
