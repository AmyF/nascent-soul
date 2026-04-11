extends "res://scenes/tests/suites/demo_smoke_support.gd"

func _init() -> void:
	_suite_name = "demo-scene-contracts"

func _run_suite() -> void:
	_test_demo_scene_resource_naming()
	_test_static_demo_scene_configuration()

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
	var demo_title = demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TitleLabel") as Label
	var demo_summary = demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/SummaryLabel") as Label
	var demo_hint = demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/HintLabel") as Label
	var demo_sidebar = demo.get_node_or_null("RootMargin/RootHBox/Sidebar") as PanelContainer
	var demo_content_host = demo.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentPanel/ContentHost") as Control
	var demo_buttons: Array[Button] = [
		demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TransferButton") as Button,
		demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/LayoutsButton") as Button,
		demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/RulesButton") as Button,
		demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/RecipesButton") as Button,
		demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/SquareButton") as Button,
		demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/HexButton") as Button,
		demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/ModesButton") as Button,
		demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TargetingButton") as Button
	]
	_check(demo.theme != null, "demo compatibility shell should serialize a shared demo theme")
	_check(demo_title != null and demo_title.theme_type_variation == &"DemoHubTitle" and demo_title.text.contains("Shell"), "demo compatibility shell should label itself as a shell in the sidebar title")
	_check(demo_summary != null and demo_summary.theme_type_variation == &"DemoDetailLabel" and demo_summary.text.contains("Main Menu"), "demo compatibility shell should point readers back to Main Menu in the sidebar summary")
	_check(demo_hint != null and demo_hint.text.contains("main_menu.tscn"), "demo compatibility shell should keep a hint that the full launcher lives in main_menu.tscn")
	_check(demo_sidebar != null and demo_sidebar.custom_minimum_size.x >= 300.0, "demo compatibility shell should serialize a wide enough launcher sidebar")
	_check(demo_content_host != null, "demo compatibility shell should serialize a content host for swapping demo scenes in place")
	_check(demo.get("transfer_scene") != null and demo.get("targeting_scene") != null, "demo compatibility shell should serialize example scene references through exported properties")
	_check(demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/FreeCellButton") == null and demo.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/XiangqiButton") == null, "demo compatibility shell should keep FreeCell and Xiangqi on the main menu only")
	var serialized_button_count := 0
	for button in demo_buttons:
		if button == null:
			continue
		serialized_button_count += 1
		_check(button.theme_type_variation == &"DemoPrimaryActionButton", "demo compatibility shell launcher buttons should use the shared primary button variation")
	_check(serialized_button_count == 8, "demo compatibility shell should serialize eight editor demo launcher buttons")
	var transfer = TRANSFER_SCENE.instantiate()
	var transfer_deck = transfer.get_node_or_null("RootMargin/RootVBox/TopRow/DeckColumn/DeckZone") as Zone
	var transfer_hand = transfer.get_node_or_null("RootMargin/RootVBox/HandZone") as Zone
	var transfer_board = transfer.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardZone") as Zone
	var transfer_status = transfer.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var transfer_top_row = transfer.get_node_or_null("RootMargin/RootVBox/TopRow") as Container
	var transfer_deck_items = transfer.get_node_or_null("RootMargin/RootVBox/TopRow/DeckColumn/DeckZone/ItemsRoot") as Control
	var transfer_hand_items = transfer.get_node_or_null("RootMargin/RootVBox/HandZone/ItemsRoot") as Control
	var transfer_board_items = transfer.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardZone/ItemsRoot") as Control
	_check(transfer.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardRuleLabel") != null, "transfer playground should serialize the board rule label")
	_check(transfer.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardCapacityLabel") != null, "transfer playground should serialize the board capacity label")
	_check(transfer.theme != null, "transfer playground should serialize the shared demo theme")
	_check(transfer_status != null and transfer_status.theme_type_variation == &"DemoStatusLabel", "transfer playground status should use the shared status theme variation")
	_check(transfer_top_row != null and transfer_top_row.theme_type_variation == &"DemoWideFlow", "transfer playground top row should use the shared wide flow variation")
	_check(transfer_deck_items != null and transfer_deck_items.get_child_count() == 6, "transfer playground should serialize six deck sample cards")
	_check(transfer_hand_items != null and transfer_hand_items.get_child_count() == 5, "transfer playground should serialize five hand sample cards")
	_check(transfer_board_items != null and transfer_board_items.get_child_count() == 2, "transfer playground should serialize two board sample cards")
	_check(transfer_board != null and transfer_board.config != null, "transfer playground board zone should serialize its config")
	_check(transfer_board != null and ExampleSupport.get_zone_transfer_policy(transfer_board) is ZoneCapacityTransferPolicy, "transfer playground board zone should serialize its capacity policy")
	_check(transfer_board != null and ExampleSupport.get_zone_drag_visual_factory(transfer_board) is ZoneConfigurableDragVisualFactory, "transfer playground board zone should serialize its drag visual factory")
	_check_card_zone_sample_data(transfer_deck, [
		{"title": "Spark", "cost": 1, "tags": ["attack"]},
		{"title": "Shell", "cost": 1, "tags": ["skill"]},
		{"title": "Focus", "cost": 2, "tags": ["power"]},
		{"title": "Gale", "cost": 1, "tags": ["attack"]},
		{"title": "Echo", "cost": 2, "tags": ["skill"]},
		{"title": "Nova", "cost": 3, "tags": ["attack"]}
	], "transfer playground deck")
	_check_card_zone_sample_data(transfer_hand, [
		{"title": "Tether", "cost": 1, "tags": ["skill"]},
		{"title": "Bloom", "cost": 2, "tags": ["power"]},
		{"title": "Strike", "cost": 1, "tags": ["attack"]},
		{"title": "Ward", "cost": 1, "tags": ["skill"]},
		{"title": "Orbit", "cost": 2, "tags": ["attack"]}
	], "transfer playground hand")
	_check_card_zone_sample_data(transfer_board, [
		{"title": "Sentinel", "cost": 3, "tags": ["power"]},
		{"title": "Pulse", "cost": 2, "tags": ["attack"]}
	], "transfer playground board")
	var policy = POLICY_SCENE.instantiate()
	var policy_deck = policy.get_node_or_null("RootMargin/RootVBox/Grid/DeckColumn/DeckZone") as Zone
	var policy_hand = policy.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandZone") as Zone
	var policy_board = policy.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardZone") as Zone
	var sanctum_zone = policy.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumZone") as Zone
	var sanctum_label = policy.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumLabel") as Label
	var policy_grid = policy.get_node_or_null("RootMargin/RootVBox/Grid") as GridContainer
	var policy_deck_items = policy.get_node_or_null("RootMargin/RootVBox/Grid/DeckColumn/DeckZone/ItemsRoot") as Control
	var policy_hand_items = policy.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandZone/ItemsRoot") as Control
	_check(policy.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardCapacityLabel") != null, "policy lab should serialize the board capacity label")
	_check(policy.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumCapacityLabel") != null, "policy lab should serialize the sanctum capacity label")
	_check(policy.theme != null, "policy lab should serialize the shared demo theme")
	_check(sanctum_label != null and sanctum_label.theme_type_variation == &"DemoVioletHeading", "policy lab sanctum label should use the shared heading theme variation")
	_check(policy_grid != null and policy_grid.theme_type_variation == &"DemoPolicyGrid", "policy lab grid should use the shared policy grid variation")
	_check(policy_deck_items != null and policy_deck_items.get_child_count() == 4, "policy lab should serialize four deck sample cards")
	_check(policy_hand_items != null and policy_hand_items.get_child_count() == 3, "policy lab should serialize three hand sample cards")
	_check(policy_board != null and ExampleSupport.get_zone_transfer_policy(policy_board) is ZoneCapacityTransferPolicy, "policy lab board zone should serialize its capacity policy")
	_check(sanctum_zone != null and ExampleSupport.get_zone_layout_policy(sanctum_zone) is ZoneVBoxLayout, "policy lab sanctum zone should serialize its layout policy")
	_check(sanctum_zone != null and ExampleSupport.get_zone_transfer_policy(sanctum_zone) is ZoneCompositeTransferPolicy, "policy lab sanctum zone should serialize its composite policy")
	_check_card_zone_sample_data(policy_deck, [
		{"title": "Rune", "cost": 1, "tags": ["skill"]},
		{"title": "Shard", "cost": 1, "tags": ["attack"]},
		{"title": "Beacon", "cost": 2, "tags": ["power"]},
		{"title": "Mirror", "cost": 2, "tags": ["skill"]}
	], "policy lab deck")
	_check_card_zone_sample_data(policy_hand, [
		{"title": "Bloom", "cost": 2, "tags": ["power"]},
		{"title": "Trace", "cost": 1, "tags": ["skill"]},
		{"title": "Arc", "cost": 1, "tags": ["attack"]}
	], "policy lab hand")
	var layouts = LAYOUT_SCENE.instantiate()
	var hand_zone = layouts.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandZone") as Zone
	var row_zone = layouts.get_node_or_null("RootMargin/RootVBox/Grid/RowColumn/RowZone") as Zone
	var list_zone = layouts.get_node_or_null("RootMargin/RootVBox/Grid/ListColumn/ListZone") as Zone
	var pile_zone = layouts.get_node_or_null("RootMargin/RootVBox/Grid/PileColumn/PileZone") as Zone
	var sort_button = layouts.get_node_or_null("RootMargin/RootVBox/Toolbar/SortButton") as Button
	var reset_button = layouts.get_node_or_null("RootMargin/RootVBox/Toolbar/ResetButton") as Button
	var layout_grid = layouts.get_node_or_null("RootMargin/RootVBox/Grid") as GridContainer
	var hand_items = layouts.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandZone/ItemsRoot") as Control
	_check(layouts.get_node_or_null("RootMargin/RootVBox/Toolbar/SortModeLabel") != null, "layout gallery should serialize its sort mode label")
	_check(layouts.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandCaptionLabel") != null, "layout gallery should serialize its hand caption label")
	_check(layouts.theme != null, "layout gallery should serialize the shared demo theme")
	_check(sort_button != null and sort_button.theme_type_variation == &"DemoPrimaryActionButton", "layout gallery sort button should use the shared primary button variation")
	_check(reset_button != null and reset_button.theme_type_variation == &"DemoDangerActionButton", "layout gallery reset button should use the shared danger button variation")
	_check(layout_grid != null and layout_grid.theme_type_variation == &"DemoLayoutGrid", "layout gallery grid should use the shared layout grid variation")
	_check(hand_items != null and hand_items.get_child_count() == 5, "layout gallery should serialize five gallery sample cards in each comparison lane")
	_check(row_zone != null and ExampleSupport.get_zone_layout_policy(row_zone) is ZoneHBoxLayout, "layout gallery row zone should serialize its row layout")
	_check(row_zone != null and ExampleSupport.get_zone_sort_policy(row_zone) is ZonePropertySort, "layout gallery row zone should serialize its row sort")
	_check(list_zone != null and ExampleSupport.get_zone_layout_policy(list_zone) is ZoneVBoxLayout, "layout gallery list zone should serialize its list layout")
	_check(list_zone != null and ExampleSupport.get_zone_sort_policy(list_zone) is ZoneGroupSort, "layout gallery list zone should serialize its list sort")
	var layout_specs = [
		{"title": "Pulse", "cost": 2, "tags": ["attack"]},
		{"title": "Ward", "cost": 1, "tags": ["skill"]},
		{"title": "Anchor", "cost": 3, "tags": ["power"]},
		{"title": "Burst", "cost": 1, "tags": ["attack"]},
		{"title": "Loom", "cost": 2, "tags": ["skill"]}
	]
	_check_card_zone_sample_data(hand_zone, layout_specs, "layout gallery hand lane", false)
	_check_card_zone_sample_data(row_zone, layout_specs, "layout gallery row lane", false)
	_check_card_zone_sample_data(list_zone, layout_specs, "layout gallery list lane", false)
	_check_card_zone_sample_data(pile_zone, layout_specs, "layout gallery pile lane", false)
	var recipes = RECIPES_SCENE.instantiate()
	var recipes_deck = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckZone") as Zone
	var recipes_hand = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/HandColumn/HandZone") as Zone
	var recipes_board = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone") as Zone
	var recipes_reset = recipes.get_node_or_null("RootMargin/RootVBox/Toolbar/ResetButton") as Button
	var recipes_grid = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid") as GridContainer
	var recipes_deck_items = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckZone/ItemsRoot") as Control
	var recipes_hand_items = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/HandColumn/HandZone/ItemsRoot") as Control
	var recipes_board_items = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone/ItemsRoot") as Control
	var freecell = FREECELL_SCENE.instantiate()
	var freecell_status = freecell.get_node_or_null("RootMargin/RootVBox/StatusBar/StatusLabel") as Label
	var xiangqi = XIANGQI_SCENE.instantiate()
	var xiangqi_new_game = xiangqi.get_node_or_null("RootMargin/RootVBox/Toolbar/NewGameButton") as Button
	var xiangqi_undo = xiangqi.get_node_or_null("RootMargin/RootVBox/Toolbar/UndoButton") as Button
	var xiangqi_board_host = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost") as Control
	_check(recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardDetails") != null, "zone recipes should serialize the static board recipe copy")
	_check(recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardCapacityLabel") != null, "zone recipes should serialize the dynamic board capacity label")
	_check(recipes.theme != null, "zone recipes should serialize the shared demo theme")
	_check(recipes_reset != null and recipes_reset.theme_type_variation == &"DemoPrimaryActionButton", "zone recipes reset button should use the shared primary button variation")
	_check(recipes_grid != null and recipes_grid.theme_type_variation == &"DemoRecipeGrid", "zone recipes grid should use the shared recipe grid variation")
	_check(recipes_deck_items != null and recipes_deck_items.get_child_count() == 6, "zone recipes should serialize six deck sample cards")
	_check(recipes_hand_items != null and recipes_hand_items.get_child_count() == 4, "zone recipes should serialize four hand sample cards")
	_check(recipes_board_items != null and recipes_board_items.get_child_count() == 2, "zone recipes should serialize two board sample cards")
	_check(recipes_board != null and recipes_board.config != null, "zone recipes board zone should serialize its config")
	_check(recipes_board != null and ExampleSupport.get_zone_transfer_policy(recipes_board) is ZoneCapacityTransferPolicy, "zone recipes board zone should serialize its capacity policy")
	_check_card_zone_sample_data(recipes_deck, [
		{"title": "Spark", "cost": 1, "tags": ["attack"]},
		{"title": "Shell", "cost": 1, "tags": ["skill"]},
		{"title": "Focus", "cost": 2, "tags": ["power"]},
		{"title": "Gale", "cost": 1, "tags": ["attack"]},
		{"title": "Echo", "cost": 2, "tags": ["skill"]},
		{"title": "Nova", "cost": 3, "tags": ["attack"]}
	], "zone recipes deck")
	_check_card_zone_sample_data(recipes_hand, [
		{"title": "Tether", "cost": 1, "tags": ["skill"]},
		{"title": "Bloom", "cost": 2, "tags": ["power"]},
		{"title": "Strike", "cost": 1, "tags": ["attack"]},
		{"title": "Ward", "cost": 1, "tags": ["skill"]}
	], "zone recipes hand")
	_check_card_zone_sample_data(recipes_board, [
		{"title": "Sentinel", "cost": 3, "tags": ["power"]},
		{"title": "Pulse", "cost": 2, "tags": ["attack"]}
	], "zone recipes board")
	_check(freecell.theme != null, "freecell showcase should serialize the shared demo theme")
	_check(freecell_status != null and freecell_status.theme_type_variation == &"DemoStatusLabel", "freecell showcase should use the shared status theme variation")
	_check(freecell.get_node_or_null("RootMargin/RootVBox/TableauScroll") is ScrollContainer, "freecell showcase should serialize the tableau scroll host")
	_check(freecell.get_node_or_null("RootMargin/RootVBox/TableauScroll/TableauRow") is HBoxContainer, "freecell showcase should serialize the tableau row host inside the scroll surface")
	_check(xiangqi.theme != null, "xiangqi showcase should serialize the shared demo theme")
	_check(xiangqi_new_game != null and xiangqi_undo != null, "xiangqi showcase should serialize toolbar buttons for new games and undo")
	_check(xiangqi_board_host != null, "xiangqi showcase should serialize the board host container")
	demo.free()
	transfer.free()
	policy.free()
	layouts.free()
	recipes.free()
	freecell.free()
	xiangqi.free()
