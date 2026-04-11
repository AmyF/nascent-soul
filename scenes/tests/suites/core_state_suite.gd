extends "res://scenes/tests/suites/core_state_support.gd"

func _init() -> void:
	_suite_name = "core-zone-contracts"

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
	await _test_runtime_hook_boundary_contract()
	await _reset_root()
	_test_placement_target_contract()
