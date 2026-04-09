extends Control

const SUITE_SCENES := [
	preload("res://scenes/tests/suites/battlefield_smoke_suite.tscn"),
	preload("res://scenes/tests/suites/core_state_suite.tscn"),
	preload("res://scenes/tests/suites/demo_smoke_suite.tscn"),
	preload("res://scenes/tests/suites/interaction_smoke_suite.tscn"),
	preload("res://scenes/tests/suites/layout_visual_contract_suite.tscn"),
	preload("res://scenes/tests/suites/performance_smoke_suite.tscn"),
	preload("res://scenes/tests/suites/targeting_smoke_suite.tscn")
]

var _checks_run: int = 0
var _failures: Array[String] = []

func _ready() -> void:
	custom_minimum_size = Vector2(1400, 900)
	await _run_all()
	if _failures.is_empty():
		print("NascentSoul regressions passed (%d checks)." % _checks_run)
		get_tree().quit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("NascentSoul regressions failed (%d/%d checks)." % [_failures.size(), _checks_run])
	get_tree().quit(1)

func _run_all() -> void:
	for suite_scene in SUITE_SCENES:
		var suite = suite_scene.instantiate()
		add_child(suite)
		var result = await suite.run_suite()
		_checks_run += result.get("checks", 0)
		print("%s passed (%d checks)." % [result.get("name", "suite"), result.get("checks", 0)])
		for failure in result.get("failures", []):
			_failures.append("%s: %s" % [result.get("name", "suite"), failure])
		suite.queue_free()
		await get_tree().process_frame
