extends "res://scenes/tests/shared/test_harness.gd"

const ZoneRuleTableTransferPolicyScript = preload("res://addons/nascentsoul/impl/permissions/zone_rule_table_transfer_policy.gd")
const ZoneTransferRuleScript = preload("res://addons/nascentsoul/impl/permissions/zone_transfer_rule.gd")
const ZoneOccupancyTransferPolicyScript = preload("res://addons/nascentsoul/impl/permissions/zone_occupancy_transfer_policy.gd")
const ZoneCompositeTransferPolicyScript = preload("res://addons/nascentsoul/impl/permissions/zone_composite_transfer_policy.gd")
const ZoneCardScript = preload("res://addons/nascentsoul/cards/zone_card.gd")
const ZonePieceScript = preload("res://addons/nascentsoul/pieces/zone_piece.gd")

func _init() -> void:
	_suite_name = "battlefield-smoke"

func _run_suite() -> void:
	await _test_square_battlefield_direct_place()
	await _reset_root()
	await _test_square_occupancy_rejects_second_item()
	await _reset_root()
	await _test_hex_battlefield_direct_place()
	await _reset_root()
	await _test_spawn_piece_transfer_rule()
	await _reset_root()
	await _test_battlefield_piece_reposition()
	await _reset_root()
	await _test_piece_can_move_between_piece_battlefields()
	await _reset_root()
	await _test_modes_restrict_piece_backflow()

func _test_square_battlefield_direct_place() -> void:
	var source_panel = _make_panel("BattlefieldDirectSource", Vector2(24, 24), Vector2(620, 220))
	var target_panel = _make_panel("BattlefieldDirectTarget", Vector2(24, 280), Vector2(860, 560))
	var source_zone = ExampleSupport.make_zone(source_panel, "CardSourceZone", ZoneHBoxLayout.new())
	var occupancy = ZoneOccupancyTransferPolicyScript.new()
	var square_model = ZoneSquareGridSpaceModel.new()
	square_model.columns = 4
	square_model.rows = 3
	var battlefield = ExampleSupport.make_battlefield_zone(target_panel, "SquareBattlefieldZone", square_model, occupancy)
	var spark = ExampleSupport.make_card("Spark", 2, ["spell"], true)
	source_zone.add_item(spark)
	await _settle_frames(2)
	var target = ZonePlacementTarget.square(1, 1)
	_check(_move_item(source_zone, spark, battlefield, target), "card should move from card zone into square battlefield")
	await _settle_frames(2)
	var placed_target = battlefield.get_item_target(spark)
	_check(placed_target.is_square() and placed_target.grid_coordinates == Vector2i(1, 1), "square battlefield should retain the requested cell target")
	_check(spark is ZoneCard, "direct placement into a battlefield should keep the transferred card as a ZoneCard")
	_check(spark.scale.x < 1.0 and spark.scale.y < 1.0, "square battlefield should scale tall card visuals down to fit the target cell")
	_check(_rect_inside(battlefield.get_global_rect().grow(48.0), spark.get_global_rect(), 48.0), "card placed on square battlefield should render inside battlefield bounds")

func _test_square_occupancy_rejects_second_item() -> void:
	var source_panel = _make_panel("BattlefieldOccupancySource", Vector2(24, 24), Vector2(620, 220))
	var target_panel = _make_panel("BattlefieldOccupancyTarget", Vector2(24, 280), Vector2(860, 560))
	var source_zone = ExampleSupport.make_zone(source_panel, "OccupancySourceZone", ZoneHBoxLayout.new())
	var occupancy = ZoneOccupancyTransferPolicyScript.new()
	var square_model = ZoneSquareGridSpaceModel.new()
	square_model.columns = 3
	square_model.rows = 2
	var battlefield = ExampleSupport.make_battlefield_zone(target_panel, "OccupancyBattlefieldZone", square_model, occupancy)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], true)
	source_zone.add_item(alpha)
	source_zone.add_item(beta)
	await _settle_frames(2)
	var target = ZonePlacementTarget.square(0, 0)
	_check(_move_item(source_zone, alpha, battlefield, target), "first item should occupy a free battlefield cell")
	await _settle_frames(2)
	_check(not _move_item(source_zone, beta, battlefield, target), "second item should be rejected from an occupied battlefield cell")
	await _settle_frames(2)
	_check(source_zone.has_item(beta), "rejected battlefield transfer should leave the second item in the source zone")
	_check(battlefield.get_items_at_target(target).size() == 1, "occupied battlefield cell should still contain only one item")

func _test_hex_battlefield_direct_place() -> void:
	var source_panel = _make_panel("BattlefieldHexSource", Vector2(24, 24), Vector2(620, 220))
	var target_panel = _make_panel("BattlefieldHexTarget", Vector2(24, 280), Vector2(920, 560))
	var source_zone = ExampleSupport.make_zone(source_panel, "HexSourceZone", ZoneHBoxLayout.new())
	var occupancy = ZoneOccupancyTransferPolicyScript.new()
	var hex_model = ZoneHexGridSpaceModel.new()
	hex_model.columns = 4
	hex_model.rows = 3
	var battlefield = ExampleSupport.make_battlefield_zone(target_panel, "HexBattlefieldZone", hex_model, occupancy)
	var ember = ExampleSupport.make_card("Ember", 3, ["summon"], true)
	source_zone.add_item(ember)
	await _settle_frames(2)
	var target = ZonePlacementTarget.hex(2, 1)
	_check(_move_item(source_zone, ember, battlefield, target), "card should move from card zone into hex battlefield")
	await _settle_frames(2)
	var placed_target = battlefield.get_item_target(ember)
	_check(placed_target.is_hex() and placed_target.grid_coordinates == Vector2i(2, 1), "hex battlefield should retain the requested hex target")
	_check(_rect_inside(battlefield.get_global_rect().grow(48.0), ember.get_global_rect(), 48.0), "card placed on hex battlefield should render inside battlefield bounds")

func _test_spawn_piece_transfer_rule() -> void:
	var source_panel = _make_panel("BattlefieldSummonSource", Vector2(24, 24), Vector2(620, 220))
	var target_panel = _make_panel("BattlefieldSummonTarget", Vector2(24, 280), Vector2(860, 560))
	var source_zone = ExampleSupport.make_zone(source_panel, "SummonSourceZone", ZoneHBoxLayout.new())
	var square_model = ZoneSquareGridSpaceModel.new()
	square_model.columns = 4
	square_model.rows = 3
	var occupancy = ZoneOccupancyTransferPolicyScript.new()
	var rule_table = ZoneRuleTableTransferPolicyScript.new()
	var rule = ZoneTransferRuleScript.new()
	rule.source_item_script = ZoneCardScript
	rule.placement_target_kind = ZonePlacementTarget.TargetKind.SQUARE
	rule.transfer_mode = ZoneTransferDecision.TransferMode.SPAWN_PIECE
	var piece_scene := PackedScene.new()
	var piece_prototype := ZonePiece.new()
	piece_scene.pack(piece_prototype)
	piece_prototype.free()
	rule.spawn_scene = piece_scene
	var typed_rules: Array[ZoneTransferRule] = [rule]
	rule_table.rules = typed_rules
	var composite = ZoneCompositeTransferPolicyScript.new()
	var typed_policies: Array[ZoneTransferPolicy] = [occupancy, rule_table]
	composite.policies = typed_policies
	var battlefield = ExampleSupport.make_battlefield_zone(target_panel, "SummonBattlefieldZone", square_model, composite)
	var sigil = ExampleSupport.make_card("Sigil", 4, ["summon"], true)
	source_zone.add_item(sigil)
	await _settle_frames(2)
	var target = ZonePlacementTarget.square(2, 0)
	_check(_move_item(source_zone, sigil, battlefield, target), "summon battlefield should accept a card and spawn a piece")
	await _settle_frames(2)
	_check(source_zone.get_item_count() == 0, "spawn-piece transfer should consume the source card from the source zone")
	_check(battlefield.get_item_count() == 1, "spawn-piece transfer should create exactly one battlefield item")
	var summoned = battlefield.get_items()[0]
	_check(summoned is ZonePiece, "spawn-piece transfer should insert a ZonePiece into the battlefield")
	_check(battlefield.get_item_target(summoned).grid_coordinates == Vector2i(2, 0), "spawned piece should land on the requested battlefield target")
	_check((summoned as ZonePiece).data != null and (summoned as ZonePiece).data.title == "Sigil", "spawned piece should inherit the source card title")

func _test_battlefield_piece_reposition() -> void:
	var host_panel = _make_panel("BattlefieldMoveTarget", Vector2(24, 24), Vector2(860, 560))
	var occupancy = ZoneOccupancyTransferPolicyScript.new()
	var square_model = ZoneSquareGridSpaceModel.new()
	square_model.columns = 4
	square_model.rows = 3
	var battlefield = ExampleSupport.make_battlefield_zone(host_panel, "PieceMoveBattlefieldZone", square_model, occupancy)
	var piece = ExampleSupport.make_piece("Guardian", "blue", 3, 5)
	var initial_target = ZonePlacementTarget.square(0, 0)
	var moved_target = ZonePlacementTarget.square(1, 0)
	_check(battlefield.add_item(piece, initial_target), "piece should be placeable directly onto a battlefield target")
	await _settle_frames(2)
	_check(_move_item(battlefield, piece, battlefield, moved_target), "piece should be movable within the same battlefield zone")
	await _settle_frames(2)
	_check(battlefield.get_item_target(piece).grid_coordinates == Vector2i(1, 0), "moving a piece inside battlefield should update its target coordinates")

func _test_piece_can_move_between_piece_battlefields() -> void:
	var left_panel = _make_panel("BattlefieldPieceLeft", Vector2(24, 24), Vector2(420, 420))
	var right_panel = _make_panel("BattlefieldPieceRight", Vector2(476, 24), Vector2(420, 420))
	var left_space = ZoneSquareGridSpaceModel.new()
	left_space.columns = 3
	left_space.rows = 2
	var right_space = ZoneSquareGridSpaceModel.new()
	right_space.columns = 3
	right_space.rows = 2
	var left_zone = ExampleSupport.make_battlefield_zone(left_panel, "PieceSourceBattlefieldZone", left_space, ZoneOccupancyTransferPolicyScript.new())
	var right_zone = ExampleSupport.make_battlefield_zone(right_panel, "PieceTargetBattlefieldZone", right_space, ZoneOccupancyTransferPolicyScript.new())
	var piece = ExampleSupport.make_piece("Relay", "blue", 2, 2)
	_check(left_zone.add_item(piece, ZonePlacementTarget.square(0, 0)), "piece should be placeable in the first battlefield zone")
	await _settle_frames(2)
	_check(_move_item(left_zone, piece, right_zone, ZonePlacementTarget.square(1, 0)), "piece should be movable into another piece-friendly battlefield zone")
	await _settle_frames(2)
	_check(right_zone.get_item_count() == 1 and right_zone.get_items()[0] == piece, "moved piece should arrive in the destination battlefield zone")
	_check(right_zone.get_item_target(piece).grid_coordinates == Vector2i(1, 0), "moved piece should keep the requested target in the destination battlefield")

func _test_modes_restrict_piece_backflow() -> void:
	var source_panel = _make_panel("BattlefieldModesSource", Vector2(24, 24), Vector2(620, 220))
	var direct_panel = _make_panel("BattlefieldModesDirect", Vector2(24, 280), Vector2(420, 420))
	var summon_panel = _make_panel("BattlefieldModesSummon", Vector2(476, 280), Vector2(420, 420))
	var source_zone = ExampleSupport.make_zone(source_panel, "ModesSourceZone", ZoneHBoxLayout.new())
	ExampleSupport.set_zone_transfer_policy(source_zone, _make_cards_only_rule_table("cards only zone"))
	var direct_space = ZoneSquareGridSpaceModel.new()
	direct_space.columns = 3
	direct_space.rows = 2
	var direct_composite = ZoneCompositeTransferPolicyScript.new()
	var direct_policies: Array[ZoneTransferPolicy] = [ZoneOccupancyTransferPolicyScript.new(), _make_cards_only_rule_table("direct place rejects pieces")]
	direct_composite.policies = direct_policies
	var direct_zone = ExampleSupport.make_battlefield_zone(direct_panel, "DirectBattlefieldZone", direct_space, direct_composite)
	var summon_space = ZoneSquareGridSpaceModel.new()
	summon_space.columns = 3
	summon_space.rows = 2
	var summon_composite = ZoneCompositeTransferPolicyScript.new()
	var summon_rule_table = ZoneRuleTableTransferPolicyScript.new()
	var spawn_rule = _make_spawn_piece_rule()
	var summon_rules: Array[ZoneTransferRule] = [spawn_rule]
	summon_rule_table.rules = summon_rules
	var summon_policies: Array[ZoneTransferPolicy] = [ZoneOccupancyTransferPolicyScript.new(), summon_rule_table]
	summon_composite.policies = summon_policies
	var summon_zone = ExampleSupport.make_battlefield_zone(summon_panel, "SummonBattlefieldZone", summon_space, summon_composite)
	var direct_card = ExampleSupport.make_card("Aegis", 1, ["unit"], true)
	var summon_card = ExampleSupport.make_card("Bloom", 2, ["summon"], true)
	source_zone.add_item(direct_card)
	source_zone.add_item(summon_card)
	await _settle_frames(2)
	_check(_move_item(source_zone, direct_card, direct_zone, ZonePlacementTarget.square(0, 0)), "card should enter Direct Place battlefield")
	await _settle_frames(2)
	_check(direct_zone.get_item_count() == 1 and direct_zone.get_items()[0] is ZoneCard, "Direct Place should keep the transferred object as a card")
	_check(_move_item(source_zone, summon_card, summon_zone, ZonePlacementTarget.square(0, 0)), "card should enter Spawn Piece battlefield")
	await _settle_frames(2)
	_check(summon_zone.get_item_count() == 1 and summon_zone.get_items()[0] is ZonePiece, "Spawn Piece should convert the transferred card into a piece")
	var spawned_piece = summon_zone.get_items()[0]
	_check(not _move_item(summon_zone, spawned_piece, source_zone, ZonePlacementTarget.linear(source_zone.get_item_count())), "spawned piece should not move back into the Cards zone")
	await _settle_frames(2)
	_check(not _move_item(summon_zone, spawned_piece, direct_zone, ZonePlacementTarget.square(1, 0)), "spawned piece should not move into Direct Place because that zone keeps card objects")
	await _settle_frames(2)
	_check(summon_zone.get_item_count() == 1 and summon_zone.get_items()[0] == spawned_piece, "rejected moves should leave the spawned piece in the Spawn Piece battlefield")

func _make_cards_only_rule_table(reject_reason: String) -> ZoneRuleTableTransferPolicy:
	var rule_table = ZoneRuleTableTransferPolicyScript.new()
	var reject_rule = ZoneTransferRuleScript.new()
	reject_rule.source_item_script = ZonePieceScript
	reject_rule.allowed = false
	reject_rule.reject_reason = reject_reason
	var rules: Array[ZoneTransferRule] = [reject_rule]
	rule_table.rules = rules
	return rule_table

func _make_spawn_piece_rule() -> ZoneTransferRule:
	var rule = ZoneTransferRuleScript.new()
	rule.source_item_script = ZoneCardScript
	rule.placement_target_kind = ZonePlacementTarget.TargetKind.SQUARE
	rule.transfer_mode = ZoneTransferDecision.TransferMode.SPAWN_PIECE
	var piece_scene := PackedScene.new()
	var prototype := ZonePiece.new()
	piece_scene.pack(prototype)
	prototype.free()
	rule.spawn_scene = piece_scene
	return rule
