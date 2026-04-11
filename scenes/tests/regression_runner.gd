extends Control

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")

const SUITE_SCENES := [
	preload("res://scenes/tests/suites/battlefield_smoke_suite.tscn"),
	preload("res://scenes/tests/suites/core_state_suite.tscn"),
	preload("res://scenes/tests/suites/core_transfer_suite.tscn"),
	preload("res://scenes/tests/suites/core_runtime_resilience_suite.tscn"),
	preload("res://scenes/tests/suites/demo_smoke_suite.tscn"),
	preload("res://scenes/tests/suites/freecell_showcase_suite.tscn"),
	preload("res://scenes/tests/suites/freecell_history_suite.tscn"),
	preload("res://scenes/tests/suites/freecell_interaction_suite.tscn"),
	preload("res://scenes/tests/suites/interaction_smoke_suite.tscn"),
	preload("res://scenes/tests/suites/layout_visual_contract_suite.tscn"),
	preload("res://scenes/tests/suites/performance_smoke_suite.tscn"),
	preload("res://scenes/tests/suites/targeting_smoke_suite.tscn"),
	preload("res://scenes/tests/suites/targeting_visual_framework_suite.tscn"),
	preload("res://scenes/tests/suites/xiangqi_showcase_suite.tscn")
]

var _checks_run: int = 0
var _failures: Array[String] = []

func _ready() -> void:
	custom_minimum_size = Vector2(1400, 900)
	await _run_all()
	await _cleanup_resources()
	if _failures.is_empty():
		print("NascentSoul regressions passed (%d checks)." % _checks_run)
		_finalize_exit(0)
		return
	for failure in _failures:
		printerr(failure)
	printerr("NascentSoul regressions failed (%d/%d checks)." % [_failures.size(), _checks_run])
	_finalize_exit(1)

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

func _cleanup_resources() -> void:
	if ExampleSupport != null:
		ExampleSupport.clear_card_texture_cache()
	_cleanup_viewport_helpers()
	await get_tree().process_frame

func _cleanup_viewport_helpers() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var helpers := viewport.find_children("__NascentSoul*", "", true, false)
	for helper in helpers:
		if not is_instance_valid(helper):
			continue
		if helper.has_method("clear_session"):
			helper.call("clear_session")
		helper.free()

func _finalize_exit(code: int) -> void:
	Engine.print_error_messages = false
	Engine.print_to_stdout = false
	get_tree().quit(code)
