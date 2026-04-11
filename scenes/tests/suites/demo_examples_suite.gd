extends "res://scenes/tests/suites/demo_smoke_support.gd"

func _init() -> void:
	_suite_name = "demo-example-stories"

func _run_suite() -> void:
	await _test_transfer_playground_guidance()
	await _reset_root()
	await _test_policy_lab_rule_cards_and_reject_feedback()
	await _reset_root()
	await _test_policy_lab_deck_drag_paths()
	await _reset_root()
	await _test_layout_gallery_mode_and_captions()
	await _reset_root()
	await _test_layout_gallery_pile_drag_proxy_layering()
	await _reset_root()
	await _test_zone_recipes_copy_hint_and_reset()
	await _reset_root()
	await _test_battlefield_examples_load()
	await _reset_root()
	await _test_showcase_examples_load()
	await _reset_root()
	await _test_targeting_example_load()

func _test_transfer_playground_guidance() -> void:
	var scene = TRANSFER_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var board_rule_label = scene.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardRuleLabel") as Label
	var board_capacity_label = scene.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardCapacityLabel") as Label
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var hand_zone = scene.get_node_or_null("RootMargin/RootVBox/HandZone") as Zone
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardZone") as Zone
	_check(scene.get_node_or_null("RootMargin/RootVBox/InfoRow") == null, "transfer playground should avoid large onboarding cards over the play area")
	_check(board_rule_label != null and (board_rule_label.text.contains("Full") or board_rule_label.text.contains("满员")), "transfer playground should keep the board rule copy static and visible")
	_check(board_capacity_label != null and board_capacity_label.text.contains("2 / 5"), "transfer playground should show the initial board occupancy in a dedicated capacity label")
	_check(hand_zone != null and board_zone != null, "transfer playground smoke should keep the hand and board zones accessible")
	_check(board_zone != null and board_zone.size.y >= 220.0, "transfer playground should keep the board zone tall enough to use comfortably")
	_check(hand_zone != null and hand_zone.size.y >= 140.0, "transfer playground should keep the hand zone tall enough to use comfortably")
	if board_capacity_label == null or status == null or hand_zone == null or board_zone == null:
		return
	var hand_item = hand_zone.get_items()[0]
	_check(ExampleSupport.move_item(hand_zone, hand_item, board_zone, ZonePlacementTarget.linear(board_zone.get_item_count())), "transfer playground smoke should move a hand card onto the board")
	await _settle_frames(3)
	_check(board_capacity_label.text.contains("3 / 5"), "transfer playground board capacity label should refresh after a successful move")
	_check(status.text.contains(hand_item.name), "transfer playground status should mention the most recent moved card")

func _test_policy_lab_rule_cards_and_reject_feedback() -> void:
	var scene = POLICY_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var board_rule_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardRuleLabel") as Label
	var board_capacity_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardCapacityLabel") as Label
	var sanctum_rule_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumRuleLabel") as Label
	var sanctum_capacity_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumCapacityLabel") as Label
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var hand_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandZone") as Zone
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardZone") as Zone
	_check(scene.get_node_or_null("RootMargin/RootVBox/InfoRow") == null, "policy lab should avoid large onboarding cards over the play area")
	_check(board_rule_label != null and board_rule_label.text.contains("Any source"), "policy lab should keep the board rule copy static and visible")
	_check(board_capacity_label != null and board_capacity_label.text.contains("0 / 2"), "policy lab should show the board capacity before interaction")
	_check(sanctum_rule_label != null and sanctum_rule_label.text.contains("HandZone"), "policy lab should show the sanctum source restriction before interaction")
	_check(sanctum_capacity_label != null and sanctum_capacity_label.text.contains("0 / 2"), "policy lab should show the sanctum capacity before interaction")
	_check(hand_zone != null and board_zone != null, "policy lab smoke should keep the hand and board zones accessible")
	_check(board_zone != null and board_zone.size.y >= 200.0, "policy lab should preserve enough zone height after adding guidance")
	if board_capacity_label == null or sanctum_rule_label == null or status == null or hand_zone == null or board_zone == null:
		return
	for _i in range(2):
		var item = hand_zone.get_items()[0]
		_check(ExampleSupport.move_item(hand_zone, item, board_zone, ZonePlacementTarget.linear(board_zone.get_item_count())), "policy lab should allow the first two board transfers")
		await _settle_frames(2)
	var rejected_item = hand_zone.get_items()[0]
	_check(not ExampleSupport.move_item(hand_zone, rejected_item, board_zone, ZonePlacementTarget.linear(board_zone.get_item_count())), "policy lab should reject transfers once the board is full")
	await _settle_frames(2)
	_check(board_capacity_label.text.contains("2 / 2"), "policy lab board capacity label should refresh to the full state")
	_check(status.text.contains("rejected") or status.text.contains("拒绝"), "policy lab status should surface the rejection feedback")

func _test_policy_lab_deck_drag_paths() -> void:
	var scene = POLICY_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var deck_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/DeckColumn/DeckZone") as Zone
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardZone") as Zone
	var sanctum_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumZone") as Zone
	_check(deck_zone != null and board_zone != null and sanctum_zone != null, "policy lab deck drag smoke should keep all target zones accessible")
	if deck_zone == null or board_zone == null or sanctum_zone == null:
		return
	var moved_card = deck_zone.get_items()[0]
	var initial_deck_count = deck_zone.get_item_count()
	deck_zone.start_drag([moved_card])
	var session = deck_zone.get_drag_session()
	_check(session != null, "policy lab deck-to-board drag should create a drag session")
	if session == null:
		return
	if is_instance_valid(session.cursor_proxy):
		session.cursor_proxy.global_position = board_zone.global_position + Vector2(24, 24)
	session.hover_zone = board_zone
	session.requested_target = ZonePlacementTarget.linear(board_zone.get_item_count())
	session.preview_target = ZonePlacementTarget.linear(board_zone.get_item_count())
	board_zone.perform_drop(session)
	await _settle_frames(3)
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.25).timeout
		await _settle_frames(1)
	_check(board_zone.has_item(moved_card), "policy lab deck-to-board drag should insert the dragged deck card into board")
	_check(moved_card.visible, "policy lab deck-to-board drag should leave the moved card visible")
	_check(moved_card is ZoneCard and (moved_card as ZoneCard).face_up, "policy lab deck-to-board drag should reveal the moved deck card")
	_check(deck_zone.get_item_count() == initial_deck_count - 1, "policy lab deck-to-board drag should remove one card from deck")
	var rejected_card = deck_zone.get_items()[0]
	deck_zone.start_drag([rejected_card])
	session = deck_zone.get_drag_session()
	_check(session != null, "policy lab deck-to-sanctum drag should create a drag session")
	if session == null:
		return
	if is_instance_valid(session.cursor_proxy):
		session.cursor_proxy.global_position = sanctum_zone.global_position + Vector2(24, 24)
	session.hover_zone = sanctum_zone
	session.requested_target = ZonePlacementTarget.linear(sanctum_zone.get_item_count())
	session.preview_target = ZonePlacementTarget.invalid()
	sanctum_zone.perform_drop(session)
	await _settle_frames(3)
	_check(deck_zone.has_item(rejected_card), "policy lab sanctum rejection should keep the dragged deck card in deck")
	_check(not sanctum_zone.has_item(rejected_card), "policy lab sanctum rejection should not insert the dragged deck card into sanctum")
	_check(rejected_card.visible, "policy lab sanctum rejection should restore the dragged deck card visibility")
	if status != null:
		_check(status.text.contains("rejected") or status.text.contains("拒绝"), "policy lab sanctum rejection should update the status feedback")

func _test_layout_gallery_mode_and_captions() -> void:
	var scene = LAYOUT_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var sort_mode_label = scene.get_node_or_null("RootMargin/RootVBox/Toolbar/SortModeLabel") as Label
	var hand_caption = scene.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandCaptionLabel") as Label
	var row_caption = scene.get_node_or_null("RootMargin/RootVBox/Grid/RowColumn/RowCaptionLabel") as Label
	var list_caption = scene.get_node_or_null("RootMargin/RootVBox/Grid/ListColumn/ListCaptionLabel") as Label
	var pile_caption = scene.get_node_or_null("RootMargin/RootVBox/Grid/PileColumn/PileCaptionLabel") as Label
	var hand_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandZone") as Zone
	var pile_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/PileColumn/PileZone") as Zone
	_check(scene.get_node_or_null("RootMargin/RootVBox/InfoRow") == null, "layout gallery should avoid large onboarding cards above the comparison grid")
	_check(sort_mode_label != null and sort_mode_label.text.contains("ascending"), "layout gallery should show the current row sort mode outside the toggle button")
	_check(hand_caption != null and not hand_caption.text.is_empty(), "layout gallery should describe the hand layout use case")
	_check(row_caption != null and row_caption.text.contains("Stable"), "layout gallery should keep the row layout caption static")
	_check(list_caption != null and list_caption.text.contains("primary tag"), "layout gallery should explain the grouped list semantics")
	_check(pile_caption != null and (pile_caption.text.contains("牌库") or pile_caption.text.contains("decks")), "layout gallery should explain the pile layout use case")
	_check(hand_zone != null and hand_zone.size.y >= 200.0, "layout gallery should keep the top-row layouts visually usable")
	_check(pile_zone != null and pile_zone.size.y >= 220.0, "layout gallery should keep the bottom-row layouts visually usable")
	scene.call("_toggle_row_sort")
	await _settle_frames(2)
	_check(sort_mode_label != null and sort_mode_label.text.contains("descending"), "layout gallery sort mode label should update after toggling the row sort")

func _test_layout_gallery_pile_drag_proxy_layering() -> void:
	var scene = LAYOUT_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var pile_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/PileColumn/PileZone") as Zone
	_check(pile_zone != null, "layout gallery pile drag smoke should keep the pile zone accessible")
	if pile_zone == null:
		return
	var pile_item = pile_zone.get_items()[pile_zone.get_item_count() - 1]
	pile_zone.start_drag([pile_item])
	var session = pile_zone.get_drag_session()
	_check(session != null, "layout gallery pile drag should create a drag session")
	if session == null:
		return
	_check(session.cursor_proxy != null and session.cursor_proxy.top_level, "layout gallery pile drag should use a top-level cursor proxy")
	if session.cursor_proxy != null:
		_check(not session.cursor_proxy.z_as_relative, "layout gallery pile drag proxy should use absolute z ordering")
		_check(session.cursor_proxy.z_index >= ZoneDragCoordinator.CURSOR_PROXY_Z_INDEX, "layout gallery pile drag proxy should render above the stacked pile cards")
	pile_zone.cancel_drag()
	await _settle_frames(2)

func _test_zone_recipes_copy_hint_and_reset() -> void:
	var scene = RECIPES_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var board_details = scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardDetails") as Label
	var board_capacity_label = scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardCapacityLabel") as Label
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone") as Zone
	_check(scene.get_node_or_null("RootMargin/RootVBox/InfoRow") == null, "zone recipes should keep the recipe board clear of large onboarding cards")
	_check(board_details != null and board_details.text.contains("BoardZoneConfig"), "zone recipes should keep the board recipe copy static")
	_check(board_capacity_label != null and board_capacity_label.text.contains("2 / 4"), "zone recipes should show the board capacity in a dedicated dynamic label")
	_check(board_zone != null and board_zone.size.y >= 220.0, "zone recipes should keep the board recipe large enough to inspect and copy")
	if status == null:
		return
	scene.call("_reset_recipe")
	await _settle_frames(3)
	_check(status.text.contains("reset") or status.text.contains("重置"), "zone recipes status should explain what reset did")

func _test_battlefield_examples_load() -> void:
	for packed_scene in [BATTLEFIELD_SQUARE_SCENE, BATTLEFIELD_HEX_SCENE, BATTLEFIELD_MODES_SCENE]:
		var scene = packed_scene.instantiate()
		add_child(scene)
		await _settle_frames(2)
		_check(scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") is Label, "%s should include a status label" % scene.name)
		_check(scene.get_node_or_null("RootMargin/RootVBox/ContentRow") is Container, "%s should include the main content row" % scene.name)
		var found_battlefield_zone = false
		for node in scene.find_children("*", "BattlefieldZone", true, false):
			if node is Zone:
				found_battlefield_zone = true
				break
		_check(found_battlefield_zone, "%s should expose at least one battlefield zone" % scene.name)
		match scene.name:
			"BattlefieldSquareLab":
				var square_source = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel/SquareSourceZone") as Zone
				_check_card_zone_sample_data(square_source, [
					{"title": "Spark", "cost": 1, "tags": ["spell"]},
					{"title": "Ward", "cost": 2, "tags": ["guard"]},
					{"title": "Anchor", "cost": 3, "tags": ["summon"]}
				], "square battlefield source cards")
			"BattlefieldHexLab":
				var hex_source = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel/HexSourceZone") as Zone
				_check_card_zone_sample_data(hex_source, [
					{"title": "Ember", "cost": 1, "tags": ["spell"]},
					{"title": "Rook", "cost": 2, "tags": ["unit"]},
					{"title": "Bloom", "cost": 3, "tags": ["summon"]}
				], "hex battlefield source cards")
			"BattlefieldTransferModes":
				var modes_source = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel/ModeSourceZone") as Zone
				var direct_zone = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/DirectColumn/DirectPanel/DirectBattlefieldZone") as Zone
				var summon_zone = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SummonColumn/SummonPanel/SummonBattlefieldZone") as Zone
				_check_card_zone_sample_data(modes_source, [
					{"title": "Aegis", "cost": 1, "tags": ["unit"]},
					{"title": "Bloom", "cost": 2, "tags": ["summon"]},
					{"title": "Beacon", "cost": 3, "tags": ["spell"]}
				], "transfer-modes source cards")
				_check(direct_zone != null and direct_zone.get_item_count() == 0, "transfer-modes direct battlefield should start empty before any sample interaction")
				_check(summon_zone != null and summon_zone.get_item_count() == 0, "transfer-modes summon battlefield should start empty before any sample interaction")
		scene.queue_free()
		await _settle_frames(1)

func _test_showcase_examples_load() -> void:
	var freecell = FREECELL_SCENE.instantiate()
	add_child(freecell)
	await _settle_frames(3)
	var freecell_status = freecell.get_node_or_null("RootMargin/RootVBox/StatusBar/StatusLabel") as Label
	var freecell_deal = freecell.get_node_or_null("RootMargin/RootVBox/Toolbar/ToolbarRow/SeedLabel") as Label
	var freecell_new_game = freecell.get_node_or_null("RootMargin/RootVBox/Toolbar/ToolbarRow/NewGameButton") as Button
	var freecell_undo = freecell.get_node_or_null("RootMargin/RootVBox/Toolbar/ToolbarRow/UndoButton") as Button
	_check(freecell_status != null and freecell_status.text.contains("FreeCell"), "freecell showcase should report initial game guidance in the status label")
	_check(freecell_deal != null and freecell_deal.text.contains("Game #"), "freecell showcase should expose the active deal number in the toolbar")
	_check(freecell_new_game != null and freecell_undo != null, "freecell showcase should expose toolbar buttons for new games and undo")
	_check(freecell.call("get_tableau_zones").size() == 8, "freecell showcase should create eight tableau lanes")
	_check(freecell.call("get_free_cell_zones").size() == 4, "freecell showcase should create four free cells")
	_check(freecell.call("get_foundation_zones").size() == 4, "freecell showcase should create four foundations")
	freecell.queue_free()
	await _settle_frames(1)

	var xiangqi = XIANGQI_SCENE.instantiate()
	add_child(xiangqi)
	await _settle_frames(3)
	var new_game_button = xiangqi.get_node_or_null("RootMargin/RootVBox/Toolbar/NewGameButton") as Button
	var undo_button = xiangqi.get_node_or_null("RootMargin/RootVBox/Toolbar/UndoButton") as Button
	var board_zone = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost/XiangqiBoardZone") as Zone
	_check(new_game_button != null and undo_button != null, "xiangqi showcase should expose toolbar buttons for new games and undo")
	_check(xiangqi.call("get_current_side") == &"red", "xiangqi showcase should start with red to move")
	_check(board_zone != null and board_zone.get_item_count() == 32, "xiangqi showcase should create the full initial board setup")
	xiangqi.queue_free()
	await _settle_frames(1)

func _test_targeting_example_load() -> void:
	var scene = TARGETING_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var content_row = scene.get_node_or_null("RootMargin/RootVBox/ContentRow") as Container
	var spell_zone = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SpellColumn/SpellHandPanel/SpellSourceZone") as Zone
	var spell_targets = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SpellColumn/SpellTargetPanel/SpellTargetZone") as Zone
	var spell_style_option = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SpellColumn/SpellToolbar/SpellStyleOption") as OptionButton
	var ability_style_option = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/AbilityStyleOption") as OptionButton
	var ability_button = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/AimAbilityButton") as Button
	var ability_zone = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityPanel/AbilityBattlefieldZone") as Zone
	_check(status != null and (status.text.contains("style override") or status.text.contains("风格")), "targeting lab should explain the preset and style-override workflow in its status label")
	_check(content_row != null, "targeting lab should serialize its main content row")
	_check(spell_zone != null and spell_zone.get_item_count() == 1, "targeting lab should create a single spell source card")
	_check(spell_targets != null and spell_targets.get_item_count() == 3, "targeting lab should create the serialized target-piece trio on the battlefield")
	_check(spell_style_option != null and spell_style_option.item_count >= 4, "targeting lab should expose built-in spell preset options")
	_check(ability_style_option != null and ability_style_option.item_count >= 4, "targeting lab should expose built-in ability override options")
	_check(ability_button != null, "targeting lab should expose the explicit begin_targeting button")
	_check(ability_zone != null and ability_zone.get_item_count() == 2, "targeting lab should create the serialized piece-ability battlefield state")
	_check_card_zone_sample_data(spell_zone, [
		{"title": "Meteor", "cost": 2, "tags": ["spell", "target"]}
	], "targeting lab spell source")
	_check_piece_zone_sample_data(spell_targets, [
		{"title": "Bulwark", "team": "ally", "attack": 1, "defense": 4, "square": Vector2(0, 0)},
		{"title": "Enemy Scout", "team": "enemy", "attack": 2, "defense": 1, "square": Vector2(2, 0)},
		{"title": "Enemy Sentinel", "team": "enemy", "attack": 3, "defense": 3, "square": Vector2(3, 1)}
	], "targeting lab spell targets")
	_check_piece_zone_sample_data(ability_zone, [
		{"title": "Guardian", "team": "blue", "attack": 3, "defense": 5, "square": Vector2(1, 1)},
		{"title": "Beacon", "team": "ally", "attack": 0, "defense": 2, "square": Vector2(2, 1)}
	], "targeting lab ability battlefield")
	var meteor = _find_item_by_title(spell_zone, "Meteor")
	var bulwark = _find_item_by_title(spell_targets, "Bulwark")
	var enemy_scout = _find_item_by_title(spell_targets, "Enemy Scout")
	var guardian = _find_item_by_title(ability_zone, "Guardian")
	_check_targeting_intent_override(meteor, "spell_name", "Meteor", 1, "targeting lab Meteor card")
	_check_targeting_intent_override(guardian, "ability_name", "Guardian Dash", 2, "targeting lab Guardian piece")
	_check(spell_targets != null and spell_targets.get_targeting_policy() != null, "targeting lab spell battlefield should keep its targeting policy after scene deserialization")
	_check(ability_zone != null and ability_zone.get_targeting_policy() != null, "targeting lab ability battlefield should keep its targeting policy after scene deserialization")
	if spell_style_option != null and spell_zone != null:
		spell_style_option.select(1)
		spell_style_option.item_selected.emit(1)
		await _settle_frames(1)
		var spell_style = ExampleSupport.get_zone_targeting_style(spell_zone)
		_check(spell_style != null and spell_style.resource_name == "Arcane Bolt", "targeting lab spell preset menu should swap the zone targeting style resource")
	if meteor != null and enemy_scout != null and bulwark != null and spell_zone != null:
		_emit_mouse_button(meteor, MOUSE_BUTTON_LEFT, true)
		_emit_mouse_motion(meteor, enemy_scout.global_position + enemy_scout.size * 0.5)
		var spell_session = spell_zone.get_targeting_session()
		_check(spell_session != null, "targeting lab spell card should enter a targeting session when dragged")
		_check(spell_session != null and spell_session.candidate.is_item() and spell_session.candidate.target_item == enemy_scout, "targeting lab spell card should resolve the hovered enemy piece as an item candidate")
		_check(spell_session != null and spell_session.decision.allowed, "targeting lab spell card should allow enemy piece targets")
		if spell_session != null:
			spell_zone._runtime_update_targeting_session(spell_session, bulwark.global_position + bulwark.size * 0.5)
			_check(spell_session.candidate.is_item() and spell_session.candidate.target_item == bulwark, "targeting lab spell card should still resolve allied pieces as hovered item candidates")
			_check(not spell_session.decision.allowed and spell_session.decision.reason == "This spell only targets enemies.", "targeting lab spell card should reject allied pieces with the serialized rule-table reason")
			spell_zone.cancel_targeting()
			await _settle_frames(1)
	if ability_button != null and ability_zone != null:
		if ability_style_option != null:
			ability_style_option.select(2)
			ability_style_option.item_selected.emit(2)
			await _settle_frames(1)
		ability_button.pressed.emit()
		await _settle_frames(1)
		_check(ability_zone.is_targeting(), "targeting lab ability button should start an explicit targeting session")
		var session = ability_zone.get_targeting_session()
		_check(session != null and session.intent != null and session.intent.metadata.get("ability_name") == "Guardian Dash", "targeting lab ability targeting session should preserve the serialized intent metadata")
		_check(session != null and session.intent != null and session.intent.style_override != null and session.intent.style_override.resource_name == "Strike Vector", "targeting lab ability preset menu should drive the explicit style_override resource")
		ability_zone.cancel_targeting()
		await _settle_frames(1)
		_check(not ability_zone.is_targeting(), "targeting lab cancel path should clear the explicit targeting session")
