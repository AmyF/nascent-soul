extends "res://scenes/tests/shared/test_harness.gd"

const DEMO_SCENE = preload("res://scenes/demo.tscn")
const TRANSFER_SCENE = preload("res://scenes/examples/transfer_playground.tscn")
const PERMISSION_SCENE = preload("res://scenes/examples/permission_lab.tscn")
const LAYOUT_SCENE = preload("res://scenes/examples/layout_gallery.tscn")
const RECIPES_SCENE = preload("res://scenes/examples/zone_recipes.tscn")

func _init() -> void:
	_suite_name = "demo-smoke"

func _run_suite() -> void:
	await _test_demo_hub_summary_panels()
	await _reset_root()
	await _test_transfer_playground_guidance()
	await _reset_root()
	await _test_permission_lab_rule_cards_and_reject_feedback()
	await _reset_root()
	await _test_layout_gallery_mode_and_captions()
	await _reset_root()
	await _test_zone_recipes_copy_hint_and_reset()

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
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var hand_zone = scene.get_node_or_null("RootMargin/RootVBox/HandZone") as Zone
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardZone") as Zone
	_check(scene.get_node_or_null("RootMargin/RootVBox/InfoRow") == null, "transfer playground should avoid large onboarding cards over the play area")
	_check(board_rule_label != null and board_rule_label.text.contains("2 / 5"), "transfer playground should show the initial board occupancy")
	_check(hand_zone != null and board_zone != null, "transfer playground smoke should keep the hand and board zones accessible")
	_check(board_zone != null and board_zone.size.y >= 220.0, "transfer playground should keep the board zone tall enough to use comfortably")
	_check(hand_zone != null and hand_zone.size.y >= 140.0, "transfer playground should keep the hand zone tall enough to use comfortably")
	if board_rule_label == null or status == null or hand_zone == null or board_zone == null:
		return
	var hand_item = hand_zone.get_items()[0]
	_check(hand_zone.move_item_to(hand_item, board_zone, board_zone.get_item_count()), "transfer playground smoke should move a hand card onto the board")
	await _settle_frames(3)
	_check(board_rule_label.text.contains("3 / 5"), "transfer playground board rule label should refresh after a successful move")
	_check(status.text.contains(hand_item.name), "transfer playground status should mention the most recent moved card")

func _test_permission_lab_rule_cards_and_reject_feedback() -> void:
	var scene = PERMISSION_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var board_rule_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardRuleLabel") as Label
	var sanctum_rule_label = scene.get_node_or_null("RootMargin/RootVBox/Grid/SanctumColumn/SanctumRuleLabel") as Label
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var hand_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/HandColumn/HandZone") as Zone
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/Grid/BoardColumn/BoardZone") as Zone
	_check(scene.get_node_or_null("RootMargin/RootVBox/InfoRow") == null, "permission lab should avoid large onboarding cards over the play area")
	_check(board_rule_label != null and board_rule_label.text.contains("0 / 2"), "permission lab should show the board capacity rule before interaction")
	_check(sanctum_rule_label != null and sanctum_rule_label.text.contains("HandZone"), "permission lab should show the sanctum source restriction before interaction")
	_check(hand_zone != null and board_zone != null, "permission lab smoke should keep the hand and board zones accessible")
	_check(board_zone != null and board_zone.size.y >= 200.0, "permission lab should preserve enough zone height after adding guidance")
	if board_rule_label == null or sanctum_rule_label == null or status == null or hand_zone == null or board_zone == null:
		return
	for _i in range(2):
		var item = hand_zone.get_items()[0]
		_check(hand_zone.move_item_to(item, board_zone, board_zone.get_item_count()), "permission lab should allow the first two board transfers")
		await _settle_frames(2)
	var rejected_item = hand_zone.get_items()[0]
	_check(not hand_zone.move_item_to(rejected_item, board_zone, board_zone.get_item_count()), "permission lab should reject transfers once the board is full")
	await _settle_frames(2)
	_check(board_rule_label.text.contains("2 / 2"), "permission lab board rule label should refresh to the full state")
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
	_check(row_caption != null and row_caption.text.contains("升序"), "layout gallery should describe the current row ordering")
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
	var status = scene.get_node_or_null("RootMargin/RootVBox/StatusLabel") as Label
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone") as Zone
	_check(scene.get_node_or_null("RootMargin/RootVBox/InfoRow") == null, "zone recipes should keep the recipe board clear of large onboarding cards")
	_check(board_details != null and board_details.text.contains("BoardZonePreset"), "zone recipes should describe the board recipe preset")
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
