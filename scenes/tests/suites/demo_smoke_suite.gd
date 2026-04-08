extends "res://scenes/tests/shared/test_harness.gd"

const DEMO_SCENE = preload("res://scenes/demo.tscn")
const TRANSFER_SCENE = preload("res://scenes/examples/transfer_playground.tscn")
const PERMISSION_SCENE = preload("res://scenes/examples/permission_lab.tscn")
const LAYOUT_SCENE = preload("res://scenes/examples/layout_gallery.tscn")
const RECIPES_SCENE = preload("res://scenes/examples/zone_recipes.tscn")

func _init() -> void:
	_suite_name = "demo-smoke"

func _run_suite() -> void:
	_test_static_demo_scene_configuration()
	await _test_demo_hub_summary_panels()
	await _reset_root()
	await _test_transfer_playground_guidance()
	await _reset_root()
	await _test_permission_lab_rule_cards_and_reject_feedback()
	await _reset_root()
	await _test_layout_gallery_mode_and_captions()
	await _reset_root()
	await _test_zone_recipes_copy_hint_and_reset()

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
		_check(tab_container.get_child_count() == 4, "demo hub should keep four static example tabs")
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
	_check(transfer_board != null and transfer_board.preset != null, "transfer playground board zone should serialize its preset")
	_check(transfer_board != null and transfer_board.permission_policy is ZoneCapacityPermission, "transfer playground board zone should serialize its capacity policy")
	_check(transfer_board != null and transfer_board.drag_visual_factory is ZoneConfigurableDragVisualFactory, "transfer playground board zone should serialize its drag visual factory")
	var permission = PERMISSION_SCENE.instantiate()
	var permission_board = permission.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardZone") as Zone
	var sanctum_zone = permission.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumZone") as Zone
	var sanctum_label = permission.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumLabel") as Label
	var permission_grid = permission.get_node_or_null("RootMargin/RootVBox/Grid") as GridContainer
	var permission_deck_cards = permission.get("deck_cards") as Array
	var permission_hand_cards = permission.get("hand_cards") as Array
	_check(permission.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardCapacityLabel") != null, "permission lab should serialize the board capacity label")
	_check(permission.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumCapacityLabel") != null, "permission lab should serialize the sanctum capacity label")
	_check(permission.theme != null, "permission lab should serialize the shared demo theme")
	_check(sanctum_label != null and sanctum_label.theme_type_variation == &"DemoVioletHeading", "permission lab sanctum label should use the shared heading theme variation")
	_check(permission_grid != null and permission_grid.theme_type_variation == &"DemoPermissionGrid", "permission lab grid should use the shared permission grid variation")
	_check(permission_deck_cards.size() == 4, "permission lab should serialize four deck sample cards")
	_check(permission_hand_cards.size() == 3, "permission lab should serialize three hand sample cards")
	_check(permission_board != null and permission_board.permission_policy is ZoneCapacityPermission, "permission lab board zone should serialize its capacity policy")
	_check(sanctum_zone != null and sanctum_zone.layout_policy is ZoneVBoxLayout, "permission lab sanctum zone should serialize its layout policy")
	_check(sanctum_zone != null and sanctum_zone.permission_policy is ZoneCompositePermission, "permission lab sanctum zone should serialize its composite permission")
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
	_check(row_zone != null and row_zone.layout_policy is ZoneHBoxLayout, "layout gallery row zone should serialize its row layout")
	_check(row_zone != null and row_zone.sort_policy is ZonePropertySort, "layout gallery row zone should serialize its row sort")
	_check(list_zone != null and list_zone.layout_policy is ZoneVBoxLayout, "layout gallery list zone should serialize its list layout")
	_check(list_zone != null and list_zone.sort_policy is ZoneGroupSort, "layout gallery list zone should serialize its list sort")
	var recipes = RECIPES_SCENE.instantiate()
	var recipes_board = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone") as Zone
	var recipes_reset = recipes.get_node_or_null("RootMargin/RootVBox/Toolbar/ResetButton") as Button
	var recipes_grid = recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid") as GridContainer
	var recipes_deck_cards = recipes.get("deck_cards") as Array
	var recipes_hand_cards = recipes.get("hand_cards") as Array
	var recipes_board_cards = recipes.get("board_cards") as Array
	_check(recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardDetails") != null, "zone recipes should serialize the static board recipe copy")
	_check(recipes.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardCapacityLabel") != null, "zone recipes should serialize the dynamic board capacity label")
	_check(recipes.theme != null, "zone recipes should serialize the shared demo theme")
	_check(recipes_reset != null and recipes_reset.theme_type_variation == &"DemoPrimaryActionButton", "zone recipes reset button should use the shared primary button variation")
	_check(recipes_grid != null and recipes_grid.theme_type_variation == &"DemoRecipeGrid", "zone recipes grid should use the shared recipe grid variation")
	_check(recipes_deck_cards.size() == 6, "zone recipes should serialize six deck sample cards")
	_check(recipes_hand_cards.size() == 4, "zone recipes should serialize four hand sample cards")
	_check(recipes_board_cards.size() == 2, "zone recipes should serialize two board sample cards")
	_check(recipes_board != null and recipes_board.preset != null, "zone recipes board zone should serialize its preset")
	_check(recipes_board != null and recipes_board.permission_policy is ZoneCapacityPermission, "zone recipes board zone should serialize its capacity policy")
	demo.free()
	transfer.free()
	permission.free()
	layouts.free()
	recipes.free()

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
	await _assert_tab_content_stays_below_tab_bar(tab_container, 2, "Content/RootMargin/RootVBox/Grid", "permission tab content should stay below the tab header")
	await _assert_tab_content_stays_below_tab_bar(tab_container, 3, "Content/RootMargin/RootVBox/Toolbar", "recipes tab toolbar should stay below the tab header")

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
	_check(hand_zone.move_item_to(hand_item, board_zone, board_zone.get_item_count()), "transfer playground smoke should move a hand card onto the board")
	await _settle_frames(3)
	_check(board_capacity_label.text.contains("3 / 5"), "transfer playground board capacity label should refresh after a successful move")
	_check(status.text.contains(hand_item.name), "transfer playground status should mention the most recent moved card")

func _test_permission_lab_rule_cards_and_reject_feedback() -> void:
	var scene = PERMISSION_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var board_rule_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardRuleLabel") as Label
	var board_capacity_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardCapacityLabel") as Label
	var sanctum_rule_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumRuleLabel") as Label
	var sanctum_capacity_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumCapacityLabel") as Label
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var hand_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandZone") as Zone
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardZone") as Zone
	_check(scene.get_node_or_null("RootMargin/RootVBox/InfoRow") == null, "permission lab should avoid large onboarding cards over the play area")
	_check(board_rule_label != null and board_rule_label.text.contains("Any source"), "permission lab should keep the board rule copy static and visible")
	_check(board_capacity_label != null and board_capacity_label.text.contains("0 / 2"), "permission lab should show the board capacity before interaction")
	_check(sanctum_rule_label != null and sanctum_rule_label.text.contains("HandZone"), "permission lab should show the sanctum source restriction before interaction")
	_check(sanctum_capacity_label != null and sanctum_capacity_label.text.contains("0 / 2"), "permission lab should show the sanctum capacity before interaction")
	_check(hand_zone != null and board_zone != null, "permission lab smoke should keep the hand and board zones accessible")
	_check(board_zone != null and board_zone.size.y >= 200.0, "permission lab should preserve enough zone height after adding guidance")
	if board_capacity_label == null or sanctum_rule_label == null or status == null or hand_zone == null or board_zone == null:
		return
	for _i in range(2):
		var item = hand_zone.get_items()[0]
		_check(hand_zone.move_item_to(item, board_zone, board_zone.get_item_count()), "permission lab should allow the first two board transfers")
		await _settle_frames(2)
	var rejected_item = hand_zone.get_items()[0]
	_check(not hand_zone.move_item_to(rejected_item, board_zone, board_zone.get_item_count()), "permission lab should reject transfers once the board is full")
	await _settle_frames(2)
	_check(board_capacity_label.text.contains("2 / 2"), "permission lab board capacity label should refresh to the full state")
	_check(status.text.contains("rejected") or status.text.contains("拒绝"), "permission lab status should surface the rejection feedback")

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

func _test_zone_recipes_copy_hint_and_reset() -> void:
	var scene = RECIPES_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var board_details = scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardDetails") as Label
	var board_capacity_label = scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardCapacityLabel") as Label
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone") as Zone
	_check(scene.get_node_or_null("RootMargin/RootVBox/InfoRow") == null, "zone recipes should keep the recipe board clear of large onboarding cards")
	_check(board_details != null and board_details.text.contains("BoardZonePreset"), "zone recipes should keep the board recipe copy static")
	_check(board_capacity_label != null and board_capacity_label.text.contains("2 / 4"), "zone recipes should show the board capacity in a dedicated dynamic label")
	_check(board_zone != null and board_zone.size.y >= 220.0, "zone recipes should keep the board recipe large enough to inspect and copy")
	if status == null:
		return
	scene.call("_reset_recipe")
	await _settle_frames(3)
	_check(status.text.contains("reset") or status.text.contains("重置"), "zone recipes status should explain what reset did")

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
