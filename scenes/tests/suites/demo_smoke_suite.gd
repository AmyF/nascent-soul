extends "res://scenes/tests/shared/test_harness.gd"

const DEMO_SCENE = preload("res://scenes/demo.tscn")
const TRANSFER_SCENE = preload("res://scenes/examples/transfer_playground.tscn")
const POLICY_SCENE = preload("res://scenes/examples/policy_lab.tscn")
const LAYOUT_SCENE = preload("res://scenes/examples/layout_gallery.tscn")
const RECIPES_SCENE = preload("res://scenes/examples/zone_recipes.tscn")
const BATTLEFIELD_SQUARE_SCENE = preload("res://scenes/examples/battlefield_square_lab.tscn")
const BATTLEFIELD_HEX_SCENE = preload("res://scenes/examples/battlefield_hex_lab.tscn")
const BATTLEFIELD_MODES_SCENE = preload("res://scenes/examples/battlefield_transfer_modes.tscn")
const TARGETING_SCENE = preload("res://scenes/examples/targeting_lab.tscn")
const FREECELL_SCENE = preload("res://scenes/examples/freecell.tscn")
const XIANGQI_SCENE = preload("res://scenes/examples/xiangqi.tscn")

func _init() -> void:
	_suite_name = "demo-smoke"

func _run_suite() -> void:
	_test_demo_scene_resource_naming()
	_test_static_demo_scene_configuration()
	await _test_demo_hub_summary_panels()
	await _reset_root()
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

func _test_demo_scene_resource_naming() -> void:
	var transfer_text = FileAccess.get_file_as_string("res://scenes/examples/transfer_playground.tscn")
	_check(transfer_text.contains("id=\"TransferBoardCapacityPolicy\""), "transfer playground should prefix scene-local policy resources with Transfer")
	_check(transfer_text.contains("id=\"TransferDeckCardSpark\""), "transfer playground should prefix scene-local card resources with Transfer")
	_check(transfer_text.contains("id=\"TransferDeckZonePanel\""), "transfer playground should prefix scene-local panel styles with Transfer")
	var policy_text = FileAccess.get_file_as_string("res://scenes/examples/policy_lab.tscn")
	_check(policy_text.contains("id=\"PolicySanctumCompositePolicy\""), "policy lab should prefix scene-local composite policies with Policy")
	_check(policy_text.contains("id=\"PolicyDeckCardRune\""), "policy lab should prefix scene-local card resources with Policy")
	_check(policy_text.contains("id=\"PolicySanctumZonePanel\""), "policy lab should prefix scene-local panel styles with Policy")
	var layout_text = FileAccess.get_file_as_string("res://scenes/examples/layout_gallery.tscn")
	_check(layout_text.contains("id=\"LayoutRowLayout\""), "layout gallery should prefix scene-local layouts with Layout")
	_check(layout_text.contains("id=\"LayoutCardPulse\""), "layout gallery should prefix scene-local card resources with Layout")
	_check(layout_text.contains("id=\"LayoutHandZonePanel\""), "layout gallery should prefix scene-local panel styles with Layout")
	var recipes_text = FileAccess.get_file_as_string("res://scenes/examples/zone_recipes.tscn")
	_check(recipes_text.contains("id=\"RecipeBoardCapacityPolicy\""), "zone recipes should prefix scene-local policies with Recipe")
	_check(recipes_text.contains("id=\"RecipeDeckCardSpark\""), "zone recipes should prefix scene-local card resources with Recipe")
	_check(recipes_text.contains("id=\"RecipeDeckZonePanel\""), "zone recipes should prefix scene-local panel styles with Recipe")
	var freecell_text = FileAccess.get_file_as_string("res://scenes/examples/freecell.tscn")
	_check(freecell_text.contains("id=\"FreeCellSlotPanel\""), "freecell showcase should prefix scene-local slot styles with FreeCell")
	_check(freecell_text.contains("id=\"FreeCellFoundationPanel\""), "freecell showcase should prefix scene-local foundation styles with FreeCell")
	_check(freecell_text.contains("id=\"FreeCellTableauPanel\""), "freecell showcase should prefix scene-local tableau styles with FreeCell")
	var xiangqi_text = FileAccess.get_file_as_string("res://scenes/examples/xiangqi.tscn")
	_check(xiangqi_text.contains("id=\"XiangqiBoardPanel\""), "xiangqi showcase should prefix scene-local board styles with Xiangqi")
	_check(xiangqi_text.contains("id=\"XiangqiSidePanel\""), "xiangqi showcase should prefix scene-local side styles with Xiangqi")

func _test_static_demo_scene_configuration() -> void:
	var demo = DEMO_SCENE.instantiate()
	var tab_container = demo.get_node_or_null("RootMargin/RootVBox/TabContainer") as TabContainer
	var demo_title = demo.get_node_or_null("RootMargin/RootVBox/TitleLabel") as Label
	var demo_margin = demo.get_node_or_null("RootMargin") as MarginContainer
	_check(tab_container != null, "demo hub should serialize its tab container")
	_check(demo.theme != null, "demo hub should serialize a shared demo theme")
	_check(demo_title != null and demo_title.theme_type_variation == &"DemoHubTitle", "demo hub title should use the shared title theme variation")
	_check(demo_margin != null and demo_margin.theme_type_variation == &"DemoHubMargin", "demo hub margin container should use the shared hub margin variation")
	if tab_container != null:
		_check(tab_container.get_child_count() == 10, "demo hub should keep ten static example tabs")
		for tab in tab_container.get_children():
			_check(tab.get_node_or_null("Content") != null, "demo hub tabs should statically embed their example scenes")
	var transfer = TRANSFER_SCENE.instantiate()
	var transfer_board = transfer.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardZone") as Zone
	var transfer_status = transfer.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var transfer_top_row = transfer.get_node_or_null("RootMargin/RootVBox/TopRow") as HBoxContainer
	var transfer_deck_cards = transfer.get("deck_cards") as Array
	var transfer_hand_cards = transfer.get("hand_cards") as Array
	var transfer_board_cards = transfer.get("board_cards") as Array
	_check(transfer.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardRuleLabel") != null, "transfer playground should serialize the board rule label")
	_check(transfer.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardCapacityLabel") != null, "transfer playground should serialize the board capacity label")
	_check(transfer.theme != null, "transfer playground should serialize the shared demo theme")
	_check(transfer_status != null and transfer_status.theme_type_variation == &"DemoStatusLabel", "transfer playground status should use the shared status theme variation")
	_check(transfer_top_row != null and transfer_top_row.theme_type_variation == &"DemoWideHBox", "transfer playground top row should use the shared wide row variation")
	_check(transfer_deck_cards.size() == 6, "transfer playground should serialize six deck sample cards")
	_check(transfer_hand_cards.size() == 5, "transfer playground should serialize five hand sample cards")
	_check(transfer_board_cards.size() == 2, "transfer playground should serialize two board sample cards")
	_check(transfer_board != null and transfer_board.config != null, "transfer playground board zone should serialize its config")
	_check(transfer_board != null and ExampleSupport.get_zone_transfer_policy(transfer_board) is ZoneCapacityTransferPolicy, "transfer playground board zone should serialize its capacity policy")
	_check(transfer_board != null and ExampleSupport.get_zone_drag_visual_factory(transfer_board) is ZoneConfigurableDragVisualFactory, "transfer playground board zone should serialize its drag visual factory")
	var policy = POLICY_SCENE.instantiate()
	var policy_board = policy.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardZone") as Zone
	var sanctum_zone = policy.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumZone") as Zone
	var sanctum_label = policy.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumLabel") as Label
	var policy_grid = policy.get_node_or_null("RootMargin/RootVBox/Grid") as GridContainer
	var policy_deck_cards = policy.get("deck_cards") as Array
	var policy_hand_cards = policy.get("hand_cards") as Array
	_check(policy.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardCapacityLabel") != null, "policy lab should serialize the board capacity label")
	_check(policy.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumCapacityLabel") != null, "policy lab should serialize the sanctum capacity label")
	_check(policy.theme != null, "policy lab should serialize the shared demo theme")
	_check(sanctum_label != null and sanctum_label.theme_type_variation == &"DemoVioletHeading", "policy lab sanctum label should use the shared heading theme variation")
	_check(policy_grid != null and policy_grid.theme_type_variation == &"DemoPolicyGrid", "policy lab grid should use the shared policy grid variation")
	_check(policy_deck_cards.size() == 4, "policy lab should serialize four deck sample cards")
	_check(policy_hand_cards.size() == 3, "policy lab should serialize three hand sample cards")
	_check(policy_board != null and ExampleSupport.get_zone_transfer_policy(policy_board) is ZoneCapacityTransferPolicy, "policy lab board zone should serialize its capacity policy")
	_check(sanctum_zone != null and ExampleSupport.get_zone_layout_policy(sanctum_zone) is ZoneVBoxLayout, "policy lab sanctum zone should serialize its layout policy")
	_check(sanctum_zone != null and ExampleSupport.get_zone_transfer_policy(sanctum_zone) is ZoneCompositeTransferPolicy, "policy lab sanctum zone should serialize its composite policy")
	var layouts = LAYOUT_SCENE.instantiate()
	var row_zone = layouts.get_node_or_null("RootMargin/RootVBox/Grid/RowColumn/RowZone") as Zone
	var list_zone = layouts.get_node_or_null("RootMargin/RootVBox/Grid/ListColumn/ListZone") as Zone
	var sort_button = layouts.get_node_or_null("RootMargin/RootVBox/Toolbar/SortButton") as Button
	var reset_button = layouts.get_node_or_null("RootMargin/RootVBox/Toolbar/ResetButton") as Button
	var layout_grid = layouts.get_node_or_null("RootMargin/RootVBox/Grid") as GridContainer
	var gallery_cards = layouts.get("gallery_cards") as Array
	_check(layouts.get_node_or_null("RootMargin/RootVBox/Toolbar/SortModeLabel") != null, "layout gallery should serialize its sort mode label")
	_check(layouts.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandCaptionLabel") != null, "layout gallery should serialize its hand caption label")
	_check(layouts.theme != null, "layout gallery should serialize the shared demo theme")
	_check(sort_button != null and sort_button.theme_type_variation == &"DemoPrimaryActionButton", "layout gallery sort button should use the shared primary button variation")
	_check(reset_button != null and reset_button.theme_type_variation == &"DemoDangerActionButton", "layout gallery reset button should use the shared danger button variation")
	_check(layout_grid != null and layout_grid.theme_type_variation == &"DemoLayoutGrid", "layout gallery grid should use the shared layout grid variation")
	_check(gallery_cards.size() == 5, "layout gallery should serialize five gallery sample cards")
	_check(row_zone != null and ExampleSupport.get_zone_layout_policy(row_zone) is ZoneHBoxLayout, "layout gallery row zone should serialize its row layout")
	_check(row_zone != null and ExampleSupport.get_zone_sort_policy(row_zone) is ZonePropertySort, "layout gallery row zone should serialize its row sort")
	_check(list_zone != null and ExampleSupport.get_zone_layout_policy(list_zone) is ZoneVBoxLayout, "layout gallery list zone should serialize its list layout")
	_check(list_zone != null and ExampleSupport.get_zone_sort_policy(list_zone) is ZoneGroupSort, "layout gallery list zone should serialize its list sort")
	var recipes = RECIPES_SCENE.instantiate()
	var recipes_board = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone") as Zone
	var recipes_reset = recipes.get_node_or_null("RootMargin/RootVBox/Toolbar/ResetButton") as Button
	var recipes_grid = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid") as GridContainer
	var recipes_deck_cards = recipes.get("deck_cards") as Array
	var recipes_hand_cards = recipes.get("hand_cards") as Array
	var recipes_board_cards = recipes.get("board_cards") as Array
	var freecell = FREECELL_SCENE.instantiate()
	var freecell_status = freecell.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var xiangqi = XIANGQI_SCENE.instantiate()
	var xiangqi_turn = xiangqi.get_node_or_null("RootMargin/RootVBox/StateRow/TurnLabel") as Label
	var xiangqi_board_host = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost") as Control
	_check(recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardDetails") != null, "zone recipes should serialize the static board recipe copy")
	_check(recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardCapacityLabel") != null, "zone recipes should serialize the dynamic board capacity label")
	_check(recipes.theme != null, "zone recipes should serialize the shared demo theme")
	_check(recipes_reset != null and recipes_reset.theme_type_variation == &"DemoPrimaryActionButton", "zone recipes reset button should use the shared primary button variation")
	_check(recipes_grid != null and recipes_grid.theme_type_variation == &"DemoRecipeGrid", "zone recipes grid should use the shared recipe grid variation")
	_check(recipes_deck_cards.size() == 6, "zone recipes should serialize six deck sample cards")
	_check(recipes_hand_cards.size() == 4, "zone recipes should serialize four hand sample cards")
	_check(recipes_board_cards.size() == 2, "zone recipes should serialize two board sample cards")
	_check(recipes_board != null and recipes_board.config != null, "zone recipes board zone should serialize its config")
	_check(recipes_board != null and ExampleSupport.get_zone_transfer_policy(recipes_board) is ZoneCapacityTransferPolicy, "zone recipes board zone should serialize its capacity policy")
	_check(freecell.theme != null, "freecell showcase should serialize the shared demo theme")
	_check(freecell_status != null and freecell_status.theme_type_variation == &"DemoStatusLabel", "freecell showcase should use the shared status theme variation")
	_check(freecell.get_node_or_null("RootMargin/RootVBox/TableauRow") is HBoxContainer, "freecell showcase should serialize the tableau row host")
	_check(xiangqi.theme != null, "xiangqi showcase should serialize the shared demo theme")
	_check(xiangqi_turn != null and xiangqi_turn.theme_type_variation == &"DemoGoldHeading", "xiangqi showcase should use the shared turn heading variation")
	_check(xiangqi_board_host != null, "xiangqi showcase should serialize the board host container")
	demo.free()
	transfer.free()
	policy.free()
	layouts.free()
	recipes.free()
	freecell.free()
	xiangqi.free()

func _test_demo_hub_summary_panels() -> void:
	var scene = DEMO_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var tab_container = scene.get_node_or_null("RootMargin/RootVBox/TabContainer") as TabContainer
	_check(scene.get_node_or_null("RootMargin/RootVBox/HubInfoRow") == null, "demo hub should not keep large onboarding cards above the tabs")
	_check(scene.get_node_or_null("RootMargin/RootVBox/IntroLabel") == null, "demo hub should not keep a summary label above the tabs")
	_check(tab_container != null, "demo hub should keep its tab container")
	_check(tab_container != null and tab_container.size.y >= 520.0, "demo hub should preserve substantial vertical space for the example tabs")
	if tab_container == null:
		return
	await _assert_tab_content_stays_below_tab_bar(tab_container, 0, "Content/RootMargin/RootVBox/TopRow", "transfer tab content should stay below the tab header")
	await _assert_tab_content_stays_below_tab_bar(tab_container, 1, "Content/RootMargin/RootVBox/Toolbar", "layout tab toolbar should stay below the tab header")
	await _assert_tab_content_stays_below_tab_bar(tab_container, 2, "Content/RootMargin/RootVBox/Grid", "policy tab content should stay below the tab header")
	await _assert_tab_content_stays_below_tab_bar(tab_container, 3, "Content/RootMargin/RootVBox/Toolbar", "recipes tab toolbar should stay below the tab header")
	await _assert_tab_content_stays_below_tab_bar(tab_container, 7, "Content/RootMargin/RootVBox/ContentRow", "targeting tab content should stay below the tab header")
	await _assert_tab_content_stays_below_tab_bar(tab_container, 8, "Content/RootMargin/RootVBox/TopRow", "freecell tab content should stay below the tab header")
	await _assert_tab_content_stays_below_tab_bar(tab_container, 9, "Content/RootMargin/RootVBox/ContentRow", "xiangqi tab content should stay below the tab header")

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
		_check(scene.get_node_or_null("RootMargin/RootVBox/ContentRow") is HBoxContainer, "%s should include the main content row" % scene.name)
		var found_battlefield_zone = false
		for node in scene.find_children("*", "BattlefieldZone", true, false):
			if node is Zone:
				found_battlefield_zone = true
				break
		_check(found_battlefield_zone, "%s should expose at least one battlefield zone" % scene.name)
		scene.queue_free()
		await _settle_frames(1)

func _test_showcase_examples_load() -> void:
	var freecell = FREECELL_SCENE.instantiate()
	add_child(freecell)
	await _settle_frames(3)
	var freecell_status = freecell.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var freecell_seed = freecell.get_node_or_null("RootMargin/RootVBox/Toolbar/SeedLabel") as Label
	_check(freecell_status != null and freecell_status.text.contains("FreeCell"), "freecell showcase should report initial game guidance in the status label")
	_check(freecell_seed != null and freecell_seed.text.contains("Seed"), "freecell showcase should expose the deal seed in the toolbar")
	_check(freecell.call("get_tableau_zones").size() == 8, "freecell showcase should create eight tableau lanes")
	_check(freecell.call("get_free_cell_zones").size() == 4, "freecell showcase should create four free cells")
	_check(freecell.call("get_foundation_zones").size() == 4, "freecell showcase should create four foundations")
	freecell.queue_free()
	await _settle_frames(1)

	var xiangqi = XIANGQI_SCENE.instantiate()
	add_child(xiangqi)
	await _settle_frames(3)
	var turn_label = xiangqi.get_node_or_null("RootMargin/RootVBox/StateRow/TurnLabel") as Label
	var status_label = xiangqi.get_node_or_null("RootMargin/RootVBox/StateRow/StatusLabel") as Label
	var board_zone = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost/XiangqiBoardZone") as Zone
	_check(turn_label != null and turn_label.text.contains("Red"), "xiangqi showcase should start with red to move")
	_check(status_label != null and status_label.text.contains("Click"), "xiangqi showcase should explain how to begin a move")
	_check(board_zone != null and board_zone.get_item_count() == 32, "xiangqi showcase should create the full initial board setup")
	xiangqi.queue_free()
	await _settle_frames(1)

func _test_targeting_example_load() -> void:
	var scene = TARGETING_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var content_row = scene.get_node_or_null("RootMargin/RootVBox/ContentRow") as HBoxContainer
	var spell_zone = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SpellColumn/SpellHandPanel/SpellSourceZone") as Zone
	var spell_targets = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SpellColumn/SpellTargetPanel/SpellTargetZone") as Zone
	var spell_style_option = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/SpellColumn/SpellToolbar/SpellStyleOption") as OptionButton
	var ability_style_option = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/AbilityStyleOption") as OptionButton
	var ability_button = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityToolbar/AimAbilityButton") as Button
	var ability_zone = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityPanel/AbilityBattlefieldZone") as Zone
	_check(status != null and (status.text.contains("style override") or status.text.contains("风格")), "targeting lab should explain the preset and style-override workflow in its status label")
	_check(content_row != null, "targeting lab should serialize its main content row")
	_check(spell_zone != null and spell_zone.get_item_count() == 1, "targeting lab should create a single spell source card")
	_check(spell_targets != null and spell_targets.get_item_count() >= 2, "targeting lab should create multiple target pieces on the battlefield")
	_check(spell_style_option != null and spell_style_option.item_count >= 4, "targeting lab should expose built-in spell preset options")
	_check(ability_style_option != null and ability_style_option.item_count >= 4, "targeting lab should expose built-in ability override options")
	_check(ability_button != null, "targeting lab should expose the explicit begin_targeting button")
	_check(ability_zone != null and ability_zone.get_item_count() >= 1, "targeting lab should create the battlefield used for piece abilities")
	if spell_style_option != null and spell_zone != null:
		spell_style_option.select(1)
		spell_style_option.item_selected.emit(1)
		await _settle_frames(1)
		var spell_style = ExampleSupport.get_zone_targeting_style(spell_zone)
		_check(spell_style != null and spell_style.resource_name == "Arcane Bolt", "targeting lab spell preset menu should swap the zone targeting style resource")
	if ability_button != null and ability_zone != null:
		if ability_style_option != null:
			ability_style_option.select(2)
			ability_style_option.item_selected.emit(2)
			await _settle_frames(1)
		ability_button.pressed.emit()
		await _settle_frames(1)
		_check(ability_zone.is_targeting(), "targeting lab ability button should start an explicit targeting session")
		var session = ability_zone.get_targeting_session()
		_check(session != null and session.intent != null and session.intent.style_override != null and session.intent.style_override.resource_name == "Strike Vector", "targeting lab ability preset menu should drive the explicit style_override resource")
		ability_zone.cancel_targeting()
		await _settle_frames(1)
		_check(not ability_zone.is_targeting(), "targeting lab cancel path should clear the explicit targeting session")

func _assert_tab_content_stays_below_tab_bar(tab_container: TabContainer, tab_index: int, node_path: String, message: String) -> void:
	tab_container.current_tab = tab_index
	await _settle_frames(2)
	var current_tab = tab_container.get_current_tab_control()
	var content: Control = null
	if current_tab != null:
		content = current_tab.get_node_or_null(node_path) as Control
	var tab_bar_bottom = tab_container.global_position.y + 32.0
	_check(content != null, "%s (content node exists)" % message)
	if content == null:
		return
	_check(content.get_global_rect().position.y >= tab_bar_bottom, message)
