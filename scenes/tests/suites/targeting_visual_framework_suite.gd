extends "res://scenes/tests/shared/test_harness.gd"

const TargetingSupport = preload("res://scenes/examples/shared/targeting_support.gd")
const MockTargetingVisualLayerScript = preload("res://scenes/tests/shared/mock_targeting_visual_layer.gd")
const ZoneLayeredTargetingStyleScript = preload("res://addons/nascentsoul/resources/zone_layered_targeting_style.gd")
const OverlayHostScript = preload("res://addons/nascentsoul/runtime/zone_targeting_overlay_host.gd")

func _init() -> void:
	_suite_name = "targeting-visual-framework"

func _run_suite() -> void:
	await _test_custom_layer_receives_item_frame()
	await _reset_root()
	await _test_custom_layer_receives_placement_frame()
	await _reset_root()
	await _test_style_override_rebuilds_overlay_layers()
	await _reset_root()
	await _test_builtin_presets_create_overlay_and_cleanup()

func _test_custom_layer_receives_item_frame() -> void:
	var source_panel = _make_panel("FrameworkSourcePanel", Vector2(24, 24), Vector2(420, 220))
	var target_panel = _make_panel("FrameworkTargetPanel", Vector2(24, 280), Vector2(720, 420))
	var source_zone = ExampleSupport.make_zone(source_panel, "FrameworkSourceZone", ZoneHBoxLayout.new())
	var battlefield = _make_square_battlefield(target_panel, "FrameworkTargetZone", 3, 2)
	var style := ZoneLayeredTargetingStyleScript.new()
	var probe_layer := MockTargetingVisualLayerScript.new()
	probe_layer.resource_name = "probe_layer"
	style.layers = [probe_layer]
	ExampleSupport.set_zone_targeting_style(source_zone, style)
	var spell = TargetingSupport.make_spell_card("Framework Meteor")
	var enemy = TargetingSupport.make_target_piece("Framework Enemy", "enemy", 3, 2)
	source_zone.add_item(spell)
	battlefield.add_item(enemy, ZonePlacementTarget.square(1, 0))
	await _settle_frames(2)
	_check(_begin_item_targeting(source_zone, spell), "custom targeting layer smoke should start a targeting session")
	var session = source_zone.get_targeting_session()
	if session == null:
		return
	source_zone._runtime_update_targeting_session(session, enemy.global_position + enemy.size * 0.5)
	var overlay = _find_targeting_overlay_host()
	var probe = overlay.get_node_or_null("00_probe_layer/Probe") as ColorRect if overlay != null else null
	_check(overlay != null and overlay.get_script() == OverlayHostScript, "layered targeting styles should render through the overlay host")
	_check(overlay != null and overlay.get_debug_layer_keys() == PackedStringArray(["probe_layer"]), "custom layered styles should preserve their layer ordering in the host")
	_check(probe != null and probe.visible, "custom visual layers should create and update their own nodes")
	_check(probe != null and int(probe.get_meta("visual_state", -1)) == ZoneTargetingVisualFrame.VisualState.VALID, "custom layer nodes should receive the resolved visual state")
	_check(probe != null and bool(probe.get_meta("is_item_target", false)), "custom layer nodes should receive item-target metadata")
	source_zone.cancel_targeting()
	await _settle_frames(1)
	_check(_find_targeting_overlay_host() == null, "cancelling a layered targeting session should remove the overlay host")

func _test_custom_layer_receives_placement_frame() -> void:
	var panel = _make_panel("FrameworkPlacementPanel", Vector2(24, 24), Vector2(860, 520))
	var battlefield = _make_square_battlefield(panel, "FrameworkPlacementZone", 4, 3)
	var style := ZoneLayeredTargetingStyleScript.new()
	var probe_layer := MockTargetingVisualLayerScript.new()
	probe_layer.resource_name = "placement_probe"
	style.layers = [probe_layer]
	ExampleSupport.set_zone_targeting_style(battlefield, style)
	var piece = TargetingSupport.make_target_piece("Framework Guardian", "ally", 2, 4)
	battlefield.add_item(piece, ZonePlacementTarget.square(0, 0))
	await _settle_frames(2)
	var intent = TargetingSupport.make_square_placement_intent("Framework Dash")
	_check(_begin_item_targeting(battlefield, piece, intent), "placement custom layer smoke should start explicit targeting")
	var session = battlefield.get_targeting_session()
	if session == null:
		return
	battlefield._runtime_update_targeting_session(session, battlefield.resolve_target_anchor(ZonePlacementTarget.square(2, 1)))
	var overlay = _find_targeting_overlay_host()
	var probe = overlay.get_node_or_null("00_placement_probe/Probe") as ColorRect if overlay != null else null
	_check(probe != null and bool(probe.get_meta("is_placement_target", false)), "custom layer nodes should receive placement-target metadata")
	_check(probe != null and bool(probe.get_meta("show_endpoint", false)), "custom layer nodes should receive endpoint visibility metadata")
	_check(probe != null and str(probe.get_meta("resolved_candidate", "")).contains("placement"), "custom layer nodes should receive the resolved placement candidate description")
	battlefield.cancel_targeting()
	await _settle_frames(1)

func _test_style_override_rebuilds_overlay_layers() -> void:
	var source_panel = _make_panel("OverrideSourcePanel", Vector2(24, 24), Vector2(420, 220))
	var target_panel = _make_panel("OverrideTargetPanel", Vector2(24, 280), Vector2(720, 420))
	var source_zone = ExampleSupport.make_zone(source_panel, "OverrideSourceZone", ZoneHBoxLayout.new())
	var battlefield = _make_square_battlefield(target_panel, "OverrideTargetZone", 3, 2)
	var spell = ExampleSupport.make_card("Override Probe", 1, ["spell"], true)
	var enemy = TargetingSupport.make_target_piece("Override Enemy", "enemy", 2, 2)
	ExampleSupport.set_zone_targeting_style(source_zone, TargetingSupport.builtin_targeting_style(&"classic"))
	source_zone.add_item(spell)
	battlefield.add_item(enemy, ZonePlacementTarget.square(1, 0))
	await _settle_frames(2)
	var default_intent = TargetingSupport.make_piece_item_intent("Default Sweep")
	_check(_begin_item_targeting(source_zone, spell, default_intent), "default preset smoke should start targeting")
	var session = source_zone.get_targeting_session()
	if session == null:
		return
	source_zone._runtime_update_targeting_session(session, enemy.global_position + enemy.size * 0.5)
	var overlay = _find_targeting_overlay_host()
	var classic_layers = overlay.get_debug_layer_keys() if overlay != null else PackedStringArray()
	var first_overlay_id = overlay.get_instance_id() if overlay != null else -1
	_check(classic_layers.has("classic_path"), "default classic preset should expose classic layer names through the host")
	source_zone.cancel_targeting()
	await _settle_frames(1)
	var override_intent = TargetingSupport.make_piece_item_intent("Override Sweep")
	override_intent.style_override = TargetingSupport.builtin_targeting_style(&"tactical")
	_check(_begin_item_targeting(source_zone, spell, override_intent), "style override smoke should start targeting with a replacement preset")
	session = source_zone.get_targeting_session()
	if session == null:
		return
	source_zone._runtime_update_targeting_session(session, enemy.global_position + enemy.size * 0.5)
	overlay = _find_targeting_overlay_host()
	var override_layers = overlay.get_debug_layer_keys() if overlay != null else PackedStringArray()
	_check(overlay != null and overlay.get_instance_id() != first_overlay_id, "switching presets between sessions should rebuild the overlay host")
	_check(override_layers.has("tactical_path") and not override_layers.has("classic_path"), "style override sessions should rebuild the host with the override layer set only")
	source_zone.cancel_targeting()
	await _settle_frames(1)

func _test_builtin_presets_create_overlay_and_cleanup() -> void:
	for style_id in TargetingSupport.builtin_targeting_style_ids():
		var source_panel = _make_panel("BuiltinSource_%s" % style_id, Vector2(24, 24), Vector2(420, 220))
		var target_panel = _make_panel("BuiltinTarget_%s" % style_id, Vector2(24, 280), Vector2(720, 420))
		var source_zone = ExampleSupport.make_zone(source_panel, "BuiltinSourceZone_%s" % style_id, ZoneHBoxLayout.new())
		var battlefield = _make_square_battlefield(target_panel, "BuiltinTargetZone_%s" % style_id, 3, 2)
		ExampleSupport.set_zone_targeting_style(source_zone, TargetingSupport.builtin_targeting_style(style_id))
		var spell = TargetingSupport.make_spell_card("Preset %s" % style_id)
		var enemy = TargetingSupport.make_target_piece("Preset Target %s" % style_id, "enemy", 3, 3)
		source_zone.add_item(spell)
		battlefield.add_item(enemy, ZonePlacementTarget.square(1, 0))
		await _settle_frames(2)
		_check(_begin_item_targeting(source_zone, spell), "%s preset should support drag-compatible targeting sessions" % style_id)
		var session = source_zone.get_targeting_session()
		if session == null:
			return
		source_zone._runtime_update_targeting_session(session, enemy.global_position + enemy.size * 0.5)
		var overlay = _find_targeting_overlay_host()
		_check(overlay != null and overlay.visible, "%s preset should create a visible overlay host" % style_id)
		_check(overlay != null and not overlay.get_debug_layer_keys().is_empty(), "%s preset should register at least one active layer" % style_id)
		_check(overlay != null and overlay.get_visual_state() == ZoneTargetingVisualFrame.VisualState.VALID, "%s preset should refresh the overlay host to the valid state" % style_id)
		source_zone.cancel_targeting()
		await _settle_frames(1)
		_check(_find_targeting_overlay_host() == null, "%s preset should clear the overlay host on cancel" % style_id)
		await _reset_root()

func _find_targeting_overlay_host() -> ZoneTargetingOverlayHost:
	var viewport = get_viewport()
	if viewport == null:
		return null
	return viewport.find_child("__NascentSoulTargetingOverlay", true, false) as ZoneTargetingOverlayHost

func _make_square_battlefield(panel: Control, zone_name: String, columns: int, rows: int) -> BattlefieldZone:
	var square_model := ZoneSquareGridSpaceModel.new()
	square_model.columns = columns
	square_model.rows = rows
	return ExampleSupport.make_battlefield_zone(panel, zone_name, square_model, ZoneOccupancyTransferPolicy.new())
