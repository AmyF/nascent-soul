extends "res://scenes/tests/suites/freecell_showcase_support.gd"

func _init() -> void:
	_suite_name = "freecell-showcase-interaction"

func _run_suite() -> void:
	await _test_slot_layout_matches_classic_freecell()
	await _reset_root()
	await _test_drag_drop_diamond_across_all_free_cells()
	await _reset_root()
	await _test_drag_start_rules_and_group_drag_visuals()
	await _reset_root()
	await _test_hover_feedback_stays_static()
	await _reset_root()
	await _test_compact_layout_keeps_tableau_operable()
