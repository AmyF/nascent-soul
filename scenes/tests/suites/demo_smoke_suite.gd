extends "res://scenes/tests/suites/demo_smoke_support.gd"

func _init() -> void:
	_suite_name = "demo-launcher"

func _run_suite() -> void:
	await _test_main_menu_entry_points()
	await _reset_root()
	await _test_demo_hub_summary_panels()
	await _reset_root()
	await _test_demo_hub_responsive_layouts()
	await _reset_root()
	await _test_embedded_demo_scene_layouts()

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
