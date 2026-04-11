extends "res://scenes/tests/shared/test_harness.gd"

const MAIN_MENU_SCENE = preload("res://scenes/main_menu.tscn")
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
	await _test_main_menu_entry_points()
	await _reset_root()
	_test_demo_scene_resource_naming()
	_test_static_demo_scene_configuration()
	await _test_demo_hub_summary_panels()
	await _reset_root()
	await _test_demo_hub_responsive_layouts()
	await _reset_root()
	await _test_embedded_demo_scene_layouts()
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

func _test_main_menu_entry_points() -> void:
	var scene = MAIN_MENU_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var title_label = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TitleLabel") as Label
	var summary_label = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/SummaryLabel") as Label
	var content_title = scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentTitleLabel") as Label
	var content_summary = scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentSummaryLabel") as Label
	var content_host = scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentPanel/ContentHost") as Control
	var button_specs = [
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/TransferButton", "title": "Transfer", "expected_child": "TransferPlayground"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/LayoutsButton", "title": "Layouts", "expected_child": "LayoutGallery"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/RulesButton", "title": "Rules", "expected_child": "PolicyLab"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/RecipesButton", "title": "Recipes", "expected_child": "ZoneRecipes"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/SquareButton", "title": "Square", "expected_child": "BattlefieldSquareLab"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/HexButton", "title": "Hex", "expected_child": "BattlefieldHexLab"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/ModesButton", "title": "Modes", "expected_child": "BattlefieldTransferModes"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/TargetingButton", "title": "Targeting", "expected_child": "TargetingLab"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/FreeCellButton", "title": "FreeCell", "expected_child": "FreeCellShowcase"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/XiangqiButton", "title": "Xiangqi", "expected_child": "XiangqiShowcase"}
	]
	_check(scene.theme != null, "main menu should serialize the shared demo theme")
	_check(title_label != null and title_label.text.contains("Launcher"), "main menu should label itself as the launcher in the sidebar title")
	_check(summary_label != null and summary_label.text.contains("FreeCell") and summary_label.text.contains("Xiangqi"), "main menu summary should describe the direct first-screen entry list")
	_check(scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/DemoLabButton") == null, "main menu should no longer expose a Demo Lab button")
	_check(scene.get("transfer_scene") != null and scene.get("layouts_scene") != null and scene.get("rules_scene") != null and scene.get("recipes_scene") != null and scene.get("square_scene") != null and scene.get("hex_scene") != null and scene.get("modes_scene") != null and scene.get("targeting_scene") != null and scene.get("freecell_scene") != null and scene.get("xiangqi_scene") != null, "main menu should serialize direct scene references for all ten first-screen entries")
	_check(content_host != null, "main menu should include a content host for swapping scenes in place")
	_check(content_title != null and content_title.text == "Main Menu", "main menu should keep a launcher header before any entry is selected")
	var initial_summary: String = content_summary.text if content_summary != null else ""
	_check(content_summary != null and initial_summary.contains("10"), "main menu should describe the ten first-screen entries before any entry is selected")
	_check(content_host != null and content_host.get_child_count() == 0, "main menu should start on the launcher shell without preloading nested content")
	var serialized_button_count := 0
	for spec in button_specs:
		var button = scene.get_node_or_null(str(spec["path"])) as Button
		_check(button != null, "main menu should expose the %s entry button" % str(spec["title"]))
		if button == null:
			continue
		serialized_button_count += 1
		_check(button.theme_type_variation == &"DemoPrimaryActionButton", "main menu %s button should use the shared primary button variation" % str(spec["title"]))
		button.pressed.emit()
		await _settle_frames(3)
		_check(content_host != null and content_host.get_child_count() == 1 and content_host.get_child(0).name == str(spec["expected_child"]), "main menu %s entry should mount %s inside the content host" % [str(spec["title"]), str(spec["expected_child"])])
		_check(content_title != null and content_title.text == str(spec["title"]), "main menu should update the content title for %s" % str(spec["title"]))
		_check(content_summary != null and not content_summary.text.is_empty() and content_summary.text != initial_summary, "main menu should update the content summary for %s" % str(spec["title"]))
		_check(button.disabled, "main menu should mark %s as selected after mounting it" % str(spec["title"]))
	_check(serialized_button_count == button_specs.size(), "main menu should serialize ten first-screen launcher buttons")

func _test_demo_hub_summary_panels() -> void:
	var scene = DEMO_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var shell_title = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TitleLabel") as Label
	var shell_summary = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/SummaryLabel") as Label
	var shell_hint = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/HintLabel") as Label
	var transfer_button = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TransferButton") as Button
	var targeting_button = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TargetingButton") as Button
	var content_title = scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentTitleLabel") as Label
	var content_summary = scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentSummaryLabel") as Label
	var content_host = _get_demo_hub_content_host(scene)
	_check(shell_title != null and shell_title.text.contains("Shell"), "demo compatibility shell should describe itself as a shell")
	_check(shell_summary != null and shell_summary.text.contains("Main Menu"), "demo compatibility shell should remind readers that Main Menu is the public launcher")
	_check(shell_hint != null and shell_hint.text.contains("main_menu.tscn"), "demo compatibility shell should keep a footer hint pointing back to main_menu.tscn")
	_check(scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/FreeCellButton") == null and scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/XiangqiButton") == null, "demo compatibility shell should keep showcase buttons out of the sidebar")
	_check(scene.get_node_or_null("RootMargin/RootVBox/HubInfoRow") == null, "demo compatibility shell should not keep large onboarding cards above the tabs")
	_check(scene.get_node_or_null("RootMargin/RootVBox/IntroLabel") == null, "demo compatibility shell should not keep a summary label above the tabs")
	_check(content_host != null, "demo compatibility shell should keep its in-place content host")
	_check(content_host != null and content_host.size.y >= 520.0, "demo compatibility shell should preserve substantial vertical space for the mounted example")
	_check(content_host != null and content_host.get_child_count() == 1 and content_host.get_child(0).name == "TransferPlayground", "demo compatibility shell should mount Transfer by default")
	_check(content_title != null and content_title.text == "Transfer", "demo compatibility shell should reflect the mounted demo title in the content header")
	_check(transfer_button != null and transfer_button.disabled, "demo compatibility shell should mark the active demo button as selected")
	if content_host == null or targeting_button == null:
		return
	targeting_button.pressed.emit()
	await _settle_frames(3)
	_check(content_host.get_child_count() == 1 and content_host.get_child(0).name == "TargetingLab", "demo compatibility shell should swap Targeting into the content host when selected")
	_check(content_title != null and content_title.text == "Targeting", "demo compatibility shell should update the mounted demo title after switching")
	_check(content_summary != null and (content_summary.text.contains("preset") or content_summary.text.contains("style")), "demo compatibility shell should update the mounted demo summary after switching")
	_check(not transfer_button.disabled and targeting_button.disabled, "demo compatibility shell should update selected button state when switching demos")

func _test_demo_hub_responsive_layouts() -> void:
	for host_size in [Vector2(1280, 900), Vector2(960, 900)]:
		var scene = DEMO_SCENE.instantiate()
		var host = await _mount_scene_in_host(scene, host_size)
		var content_host = _get_demo_hub_content_host(scene)
		var current_content = _get_demo_hub_current_content(scene)
		_check(content_host != null, "demo compatibility shell should mount inside a %dx%d host" % [int(host_size.x), int(host_size.y)])
		_check(content_host != null and content_host.size.y >= 520.0, "demo compatibility shell should preserve substantial vertical space for mounted demos at %dpx width" % int(host_size.x))
		_check(current_content != null and current_content.name == "TransferPlayground", "demo compatibility shell should keep Transfer mounted by default at %dpx width" % int(host_size.x))
		if content_host == null or current_content == null:
			host.queue_free()
			await _settle_frames(1)
			continue
		_assert_scene_nodes_inside_host(content_host, current_content, [
			"RootMargin/RootVBox/TopRow/BoardColumn/BoardZone",
			"RootMargin/RootVBox/HandZone"
		], "demo compatibility shell transfer content")
		_assert_demo_hub_transfer_layout(content_host, current_content, "demo compatibility shell transfer content at %dpx width" % int(host_size.x))
		host.queue_free()
		await _settle_frames(1)

func _test_embedded_demo_scene_layouts() -> void:
	var transfer = TRANSFER_SCENE.instantiate()
	var transfer_host = await _mount_scene_in_host(transfer, Vector2(860, 760))
	var transfer_top_row = transfer.get_node_or_null("RootMargin/RootVBox/TopRow") as HFlowContainer
	_assert_scene_nodes_inside_host(transfer_host, transfer, [
		"RootMargin/RootVBox/TopRow/BoardColumn/BoardZone",
		"RootMargin/RootVBox/HandZone"
	], "transfer playground")
	_check(transfer_top_row != null and transfer_top_row.get_child_count() >= 1 and transfer_top_row.get_child(0).name == "BoardColumn", "transfer playground should prioritize the board column first inside the embedded host")
	transfer_host.queue_free()
	await _settle_frames(1)

	var policy = POLICY_SCENE.instantiate()
	var policy_host = await _mount_scene_in_host(policy, Vector2(860, 760))
	var policy_grid = policy.get_node_or_null("RootMargin/RootVBox/Grid") as GridContainer
	_assert_scene_nodes_inside_host(policy_host, policy, [
		"RootMargin/RootVBox/Grid/BoardColumn/BoardZone",
		"RootMargin/RootVBox/Grid/SanctumColumn/SanctumZone"
	], "policy lab")
	_check(policy_grid != null and policy_grid.columns == 2, "policy lab should collapse to a two-column grid inside the embedded host")
	policy_host.queue_free()
	await _settle_frames(1)

	var layouts = LAYOUT_SCENE.instantiate()
	var layouts_host = await _mount_scene_in_host(layouts, Vector2(860, 760))
	var layouts_grid = layouts.get_node_or_null("RootMargin/RootVBox/Grid") as GridContainer
	_assert_scene_nodes_inside_host(layouts_host, layouts, [
		"RootMargin/RootVBox/Grid/HandColumn/HandZone",
		"RootMargin/RootVBox/Grid/PileColumn/PileZone"
	], "layout gallery")
	_check(layouts_grid != null and layouts_grid.columns == 2, "layout gallery should keep a two-column comparison grid inside the embedded host")
	layouts_host.queue_free()
	await _settle_frames(1)

	var recipes = RECIPES_SCENE.instantiate()
	var recipes_host = await _mount_scene_in_host(recipes, Vector2(860, 760))
	var recipes_grid = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid") as GridContainer
	_assert_scene_nodes_inside_host(recipes_host, recipes, [
		"RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone",
		"RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardZone"
	], "zone recipes")
	_check(recipes_grid != null and recipes_grid.columns == 2, "zone recipes should keep a two-column recipe grid inside the embedded host")
	recipes_host.queue_free()
	await _settle_frames(1)

	var square = BATTLEFIELD_SQUARE_SCENE.instantiate()
	var square_host = await _mount_scene_in_host(square, Vector2(900, 760))
	_assert_scene_nodes_inside_host(square_host, square, [
		"RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel",
		"RootMargin/RootVBox/ContentRow/BattlefieldColumn/BattlefieldPanel"
	], "square battlefield")
	square_host.queue_free()
	await _settle_frames(1)

	var hex = BATTLEFIELD_HEX_SCENE.instantiate()
	var hex_host = await _mount_scene_in_host(hex, Vector2(900, 760))
	_assert_scene_nodes_inside_host(hex_host, hex, [
		"RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel",
		"RootMargin/RootVBox/ContentRow/BattlefieldColumn/BattlefieldPanel"
	], "hex battlefield")
	hex_host.queue_free()
	await _settle_frames(1)

	var modes = BATTLEFIELD_MODES_SCENE.instantiate()
	var modes_host = await _mount_scene_in_host(modes, Vector2(900, 760))
	_assert_scene_nodes_inside_host(modes_host, modes, [
		"RootMargin/RootVBox/ContentRow/SourceColumn/SourcePanel",
		"RootMargin/RootVBox/ContentRow/DirectColumn/DirectPanel",
		"RootMargin/RootVBox/ContentRow/SummonColumn/SummonPanel"
	], "battlefield transfer modes")
	modes_host.queue_free()
	await _settle_frames(1)

	var targeting = TARGETING_SCENE.instantiate()
	var targeting_host = await _mount_scene_in_host(targeting, Vector2(900, 760))
	_assert_scene_nodes_inside_host(targeting_host, targeting, [
		"RootMargin/RootVBox/ContentRow/SpellColumn/SpellHandPanel",
		"RootMargin/RootVBox/ContentRow/SpellColumn/SpellTargetPanel",
		"RootMargin/RootVBox/ContentRow/AbilityColumn/AbilityPanel"
	], "targeting lab")
	targeting_host.queue_free()
	await _settle_frames(1)

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
			spell_zone.update_targeting_session(spell_session, bulwark.global_position + bulwark.size * 0.5)
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

func _check_card_zone_sample_data(zone: Zone, expected_specs: Array, label: String, require_order: bool = true) -> void:
	_check(zone != null, "%s should expose its serialized card zone" % label)
	if zone == null:
		return
	var items := _get_zone_sample_items(zone)
	_check(items.size() == expected_specs.size(), "%s should keep %d serialized sample cards" % [label, expected_specs.size()])
	if require_order:
		for index in range(min(items.size(), expected_specs.size())):
			_check_card_sample(items[index] as ZoneCard, expected_specs[index], "%s card %d" % [label, index + 1])
		return
	for expected in expected_specs:
		var expected_title := str(expected.get("title", ""))
		var matched := _find_item_by_title(zone, expected_title) as ZoneCard
		_check(matched != null, "%s should keep sample card %s" % [label, expected_title])
		if matched != null:
			_check_card_sample(matched, expected, "%s sample %s" % [label, expected_title])

func _check_card_sample(card: ZoneCard, expected: Dictionary, label: String) -> void:
	_check(card != null, "%s should stay a ZoneCard" % label)
	if card == null:
		return
	_check(card.data != null, "%s should keep serialized CardData" % label)
	if card.data == null:
		return
	var expected_title := str(expected.get("title", ""))
	var expected_cost := int(expected.get("cost", 0))
	var expected_tags: Array = expected.get("tags", [])
	_check(card.data.title == expected_title, "%s should preserve title %s" % [label, expected_title])
	_check(card.name == expected_title, "%s should keep node name aligned with title %s" % [label, expected_title])
	_check(card.data.cost == expected_cost, "%s should preserve cost %d" % [label, expected_cost])
	_check(card.data.custom_data.get("cost") == expected_cost, "%s should preserve serialized custom cost data" % label)
	_check(card.data.tags.size() == expected_tags.size(), "%s should preserve all serialized tags" % label)
	for tag in expected_tags:
		_check(card.data.tags.has(str(tag)), "%s should preserve tag %s" % [label, str(tag)])
	var metadata = card.get_zone_item_metadata()
	var metadata_tags := _to_packed_string_array(metadata.get("example_tags", PackedStringArray()))
	_check(metadata.get("example_cost") == expected_cost, "%s should preserve example_cost metadata" % label)
	_check(metadata_tags.size() == expected_tags.size(), "%s should preserve example_tags metadata" % label)
	for tag in expected_tags:
		_check(metadata_tags.has(str(tag)), "%s should preserve example tag metadata %s" % [label, str(tag)])
	if not expected_tags.is_empty():
		_check(metadata.get("example_primary_tag") == str(expected_tags[0]), "%s should preserve example_primary_tag metadata" % label)

func _check_piece_zone_sample_data(zone: Zone, expected_specs: Array, label: String, require_order: bool = true) -> void:
	_check(zone != null, "%s should expose its serialized piece zone" % label)
	if zone == null:
		return
	var items := _get_zone_sample_items(zone)
	_check(items.size() == expected_specs.size(), "%s should keep %d serialized sample pieces" % [label, expected_specs.size()])
	if require_order:
		for index in range(min(items.size(), expected_specs.size())):
			_check_piece_sample(items[index] as ZonePiece, expected_specs[index], "%s piece %d" % [label, index + 1])
		return
	for expected in expected_specs:
		var expected_title := str(expected.get("title", ""))
		var matched := _find_item_by_title(zone, expected_title) as ZonePiece
		_check(matched != null, "%s should keep sample piece %s" % [label, expected_title])
		if matched != null:
			_check_piece_sample(matched, expected, "%s sample %s" % [label, expected_title])

func _check_piece_sample(piece: ZonePiece, expected: Dictionary, label: String) -> void:
	_check(piece != null, "%s should stay a ZonePiece" % label)
	if piece == null:
		return
	_check(piece.data != null, "%s should keep serialized PieceData" % label)
	if piece.data == null:
		return
	var expected_title := str(expected.get("title", ""))
	var expected_team := str(expected.get("team", ""))
	var expected_attack := int(expected.get("attack", 0))
	var expected_defense := int(expected.get("defense", 0))
	_check(piece.data.title == expected_title, "%s should preserve title %s" % [label, expected_title])
	_check(piece.name == expected_title, "%s should keep node name aligned with title %s" % [label, expected_title])
	_check(piece.data.team == expected_team, "%s should preserve team %s" % [label, expected_team])
	_check(piece.data.attack == expected_attack, "%s should preserve attack %d" % [label, expected_attack])
	_check(piece.data.defense == expected_defense, "%s should preserve defense %d" % [label, expected_defense])
	var metadata = piece.get_zone_item_metadata()
	_check(metadata.get("target_team") == expected_team, "%s should preserve target_team metadata" % label)
	_check(metadata.get("piece_team") == expected_team, "%s should preserve piece_team metadata" % label)
	_check(metadata.get("piece_attack") == expected_attack, "%s should preserve piece_attack metadata" % label)
	_check(metadata.get("piece_defense") == expected_defense, "%s should preserve piece_defense metadata" % label)
	if expected.has("square"):
		_check(metadata.get("demo_square") == expected["square"], "%s should preserve demo_square metadata" % label)

func _check_targeting_intent_override(item: ZoneItemControl, metadata_key: String, metadata_value, candidate_kind: int, label: String) -> void:
	_check(item != null and item.zone_targeting_intent_override != null, "%s should serialize a targeting intent override" % label)
	if item == null or item.zone_targeting_intent_override == null:
		return
	var intent = item.zone_targeting_intent_override
	_check(intent.policy != null, "%s should keep a targeting policy on the override" % label)
	_check(intent.metadata.get(metadata_key) == metadata_value, "%s should preserve targeting metadata %s" % [label, metadata_key])
	_check(intent.allowed_candidate_kinds.has(candidate_kind), "%s should preserve allowed candidate kind %d" % [label, candidate_kind])

func _find_item_by_title(zone: Zone, title: String) -> ZoneItemControl:
	if zone == null:
		return null
	for item in _get_zone_sample_items(zone):
		if item == null:
			continue
		if item.name == title:
			return item
		if item is ZoneCard and (item as ZoneCard).data != null and (item as ZoneCard).data.title == title:
			return item
		if item is ZonePiece and (item as ZonePiece).data != null and (item as ZonePiece).data.title == title:
			return item
	return null

func _get_zone_sample_items(zone: Zone) -> Array[ZoneItemControl]:
	var items: Array[ZoneItemControl] = []
	if zone == null:
		return items
	for item in zone.get_items():
		if item != null:
			items.append(item)
	if not items.is_empty():
		return items
	var items_root := zone.get_node_or_null("ItemsRoot")
	if items_root == null:
		return items
	for child in items_root.get_children():
		if child is ZoneItemControl:
			items.append(child as ZoneItemControl)
	return items

func _to_packed_string_array(value) -> PackedStringArray:
	if value is PackedStringArray:
		return value
	if value is Array:
		return PackedStringArray(value)
	return PackedStringArray()

func _get_demo_hub_content_host(scene: Control) -> Control:
	return scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentPanel/ContentHost") as Control if scene != null else null

func _get_demo_hub_current_content(scene: Control) -> Control:
	var content_host = _get_demo_hub_content_host(scene)
	if content_host == null or content_host.get_child_count() == 0:
		return null
	return content_host.get_child(0) as Control

func _assert_demo_hub_transfer_layout(content_host: Control, content: Control, label: String) -> void:
	var visible_rect = content_host.get_global_rect()
	var top_row = content.get_node_or_null("RootMargin/RootVBox/TopRow") as Control
	var hand_label = content.get_node_or_null("RootMargin/RootVBox/HandLabel") as Control
	var hand_zone = content.get_node_or_null("RootMargin/RootVBox/HandZone") as Zone
	var board_zone = content.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardZone") as Zone
	_check(top_row != null and hand_label != null and top_row.get_global_rect().end.y <= hand_label.get_global_rect().position.y + 1.0, "%s should keep the play row above the hand lane" % label)
	_check(hand_zone != null and _rect_inside(visible_rect, hand_zone.get_global_rect(), 4.0), "%s should keep the hand lane inside the visible host" % label)
	_check(board_zone != null and _rect_inside(visible_rect, board_zone.get_global_rect(), 4.0), "%s should keep the board lane inside the visible host" % label)

func _assert_scene_nodes_inside_host(host: Control, scene: Control, node_paths: Array[String], label: String) -> void:
	var visible_rect = host.get_global_rect()
	for node_path in node_paths:
		var control = scene.get_node_or_null(node_path) as Control
		_check(control != null, "%s should expose %s" % [label, node_path])
		if control != null:
			_check(_rect_inside(visible_rect, control.get_global_rect(), 4.0), "%s should keep %s inside the embedded host" % [label, node_path])
