extends "res://scenes/tests/suites/core_state_support.gd"

func _init() -> void:
	_suite_name = "core-runtime-resilience"

func _run_suite() -> void:
	await _test_rejected_hover_hides_preview_but_still_rejects_drop()
	await _reset_root()
	await _test_policy_reject_cleanup()
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
	await _test_drag_cancel_cleanup()
	await _reset_root()
	await _test_invalid_targeting_feedback_handles_missing_target_zone()
	await _reset_root()
	await _test_invalid_targeting_candidate_survives_unrelated_zone_teardown()
	await _reset_root()
	await _test_external_reconciliation()
	await _reset_root()
	await _test_freed_item_reconciliation()
	await _reset_root()
	await _test_freed_item_during_drag_session()
