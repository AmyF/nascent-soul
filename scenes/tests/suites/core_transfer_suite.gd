extends "res://scenes/tests/suites/core_state_support.gd"

func _init() -> void:
	_suite_name = "core-transfer-contracts"

func _run_suite() -> void:
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
	await _test_public_drag_finalize_transfers_between_zones()
