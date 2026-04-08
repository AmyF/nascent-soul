extends "res://scenes/tests/shared/test_harness.gd"

func _init() -> void:
	_suite_name = "performance-smoke"

func _run_suite() -> void:
	for card_count in [50, 100, 200]:
		await _measure_card_count(card_count)
		await _reset_root()

func _measure_card_count(card_count: int) -> void:
	var source_panel = _make_panel("PerfSourcePanel%d" % card_count, Vector2(24, 24), Vector2(1200, 280))
	var target_panel = _make_panel("PerfTargetPanel%d" % card_count, Vector2(24, 340), Vector2(1200, 280))
	var source_layout := ZoneHBoxLayout.new()
	source_layout.item_spacing = 8.0
	source_layout.padding_left = 12.0
	source_layout.padding_top = 12.0
	var target_layout := ZoneHBoxLayout.new()
	target_layout.item_spacing = 8.0
	target_layout.padding_left = 12.0
	target_layout.padding_top = 12.0
	var source_zone = ExampleSupport.make_zone(source_panel, "PerfSourceZone%d" % card_count, source_layout)
	var target_zone = ExampleSupport.make_zone(target_panel, "PerfTargetZone%d" % card_count, target_layout)
	for index in range(card_count):
		source_zone.add_item(ExampleSupport.make_card("Card%d" % index, index % 4, ["perf"], true))
	await _settle_frames(3)
	var refresh_started = Time.get_ticks_usec()
	source_zone.refresh()
	await _settle_frames(1)
	var refresh_ms = float(Time.get_ticks_usec() - refresh_started) / 1000.0
	var source_items = source_zone.get_items()
	var reorder_item = source_items[source_items.size() - 1]
	var reorder_started = Time.get_ticks_usec()
	source_zone.reorder_item(reorder_item, 0)
	await _settle_frames(2)
	var reorder_ms = float(Time.get_ticks_usec() - reorder_started) / 1000.0
	var transfer_item = source_zone.get_items()[0]
	var transfer_started = Time.get_ticks_usec()
	source_zone.move_item_to(transfer_item, target_zone, target_zone.get_item_count())
	await _settle_frames(2)
	var transfer_ms = float(Time.get_ticks_usec() - transfer_started) / 1000.0
	print("%s %d cards: refresh=%.2fms reorder=%.2fms transfer=%.2fms" % [_suite_name, card_count, refresh_ms, reorder_ms, transfer_ms])
	_check(source_zone.get_item_count() == card_count - 1, "performance smoke should keep source count stable after transferring one card (%d cards)" % card_count)
	_check(target_zone.get_item_count() == 1, "performance smoke should move one card into the target zone (%d cards)" % card_count)
	_check(refresh_ms >= 0.0 and reorder_ms >= 0.0 and transfer_ms >= 0.0, "performance smoke timings should be recorded for %d cards" % card_count)
