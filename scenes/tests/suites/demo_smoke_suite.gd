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
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/FreeCellButton", "title": "FreeCell", "expected_child": "FreeCellShowcase"},
		{"path": "RootMargin/RootHBox/Sidebar/SidebarVBox/XiangqiButton", "title": "Xiangqi", "expected_child": "XiangqiShowcase"}
	]
	_check(scene.theme != null, "main menu should serialize the shared demo theme")
	_check(title_label != null and title_label.text.contains("Launcher"), "main menu should label itself as the launcher in the sidebar title")
	_check(summary_label != null and summary_label.text.contains("FreeCell") and summary_label.text.contains("Xiangqi"), "main menu summary should describe the direct first-screen entry list")
	_check(scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/DemoLabButton") == null, "main menu should no longer expose a Demo Lab button")
	_check(scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TransferButton") == null and scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TargetingButton") == null, "main menu should no longer expose the removed editor demos")
	_check(scene.get("freecell_scene") != null and scene.get("xiangqi_scene") != null, "main menu should serialize direct scene references for the two public showcase entries")
	_check(content_host != null, "main menu should include a content host for swapping scenes in place")
	_check(content_title != null and content_title.text == "Main Menu", "main menu should keep a launcher header before any entry is selected")
	var initial_summary: String = content_summary.text if content_summary != null else ""
	_check(content_summary != null and initial_summary.contains("FreeCell") and initial_summary.contains("Xiangqi"), "main menu should describe the two public showcase entries before any entry is selected")
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
	_check(serialized_button_count == button_specs.size(), "main menu should serialize two first-screen launcher buttons")

func _test_demo_hub_summary_panels() -> void:
	var scene = DEMO_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(3)
	var shell_title = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TitleLabel") as Label
	var shell_summary = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/SummaryLabel") as Label
	var shell_hint = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/HintLabel") as Label
	var freecell_button = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/FreeCellButton") as Button
	var xiangqi_button = scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/XiangqiButton") as Button
	var content_title = scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentTitleLabel") as Label
	var content_summary = scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentSummaryLabel") as Label
	var content_host = _get_demo_hub_content_host(scene)
	_check(shell_title != null and shell_title.text.contains("Shell"), "demo compatibility shell should describe itself as a shell")
	_check(shell_summary != null and shell_summary.text.contains("Main Menu") and shell_summary.text.contains("FreeCell") and shell_summary.text.contains("Xiangqi"), "demo compatibility shell should remind readers that Main Menu is the public launcher for the two showcases")
	_check(shell_hint != null and shell_hint.text.contains("main_menu.tscn"), "demo compatibility shell should keep a footer hint pointing back to main_menu.tscn")
	_check(scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TransferButton") == null and scene.get_node_or_null("RootMargin/RootHBox/Sidebar/SidebarVBox/TargetingButton") == null, "demo compatibility shell should no longer expose the removed editor demos")
	_check(scene.get_node_or_null("RootMargin/RootVBox/HubInfoRow") == null, "demo compatibility shell should not keep large onboarding cards above the tabs")
	_check(scene.get_node_or_null("RootMargin/RootVBox/IntroLabel") == null, "demo compatibility shell should not keep a summary label above the tabs")
	_check(content_host != null, "demo compatibility shell should keep its in-place content host")
	_check(content_host != null and content_host.size.y >= 520.0, "demo compatibility shell should preserve substantial vertical space for the mounted example")
	_check(content_host != null and content_host.get_child_count() == 1 and content_host.get_child(0).name == "FreeCellShowcase", "demo compatibility shell should mount FreeCell by default")
	_check(content_title != null and content_title.text == "FreeCell", "demo compatibility shell should reflect the mounted showcase title in the content header")
	_check(content_summary != null and content_summary.text.contains("FreeCell"), "demo compatibility shell should reflect the mounted showcase summary in the content header")
	_check(freecell_button != null and freecell_button.disabled, "demo compatibility shell should mark the active showcase button as selected")
	if content_host == null or xiangqi_button == null:
		return
	xiangqi_button.pressed.emit()
	await _settle_frames(3)
	_check(content_host.get_child_count() == 1 and content_host.get_child(0).name == "XiangqiShowcase", "demo compatibility shell should swap Xiangqi into the content host when selected")
	_check(content_title != null and content_title.text == "Xiangqi", "demo compatibility shell should update the mounted showcase title after switching")
	_check(content_summary != null and content_summary.text.contains("Xiangqi"), "demo compatibility shell should update the mounted showcase summary after switching")
	_check(freecell_button != null and not freecell_button.disabled and xiangqi_button.disabled, "demo compatibility shell should update selected button state when switching showcases")

func _test_demo_hub_responsive_layouts() -> void:
	for host_size in [Vector2(1280, 900), Vector2(960, 900)]:
		var scene = DEMO_SCENE.instantiate()
		var host = await _mount_scene_in_host(scene, host_size)
		var content_host = _get_demo_hub_content_host(scene)
		var current_content = _get_demo_hub_current_content(scene)
		_check(content_host != null, "demo compatibility shell should mount inside a %dx%d host" % [int(host_size.x), int(host_size.y)])
		_check(content_host != null and content_host.size.y >= 520.0, "demo compatibility shell should preserve substantial vertical space for mounted demos at %dpx width" % int(host_size.x))
		_check(current_content != null and current_content.name == "FreeCellShowcase", "demo compatibility shell should keep FreeCell mounted by default at %dpx width" % int(host_size.x))
		if content_host == null or current_content == null:
			host.queue_free()
			await _settle_frames(1)
			continue
		_check(current_content.get_node_or_null("RootMargin/RootVBox/TopRow") != null, "demo compatibility shell should keep the FreeCell top row mounted at %dpx width" % int(host_size.x))
		_check(current_content.get_node_or_null("RootMargin/RootVBox/TableauScroll") != null, "demo compatibility shell should keep the FreeCell tableau scroll mounted at %dpx width" % int(host_size.x))
		_check(current_content.get_node_or_null("RootMargin/RootVBox/StatusBar") != null, "demo compatibility shell should keep the FreeCell status bar mounted at %dpx width" % int(host_size.x))
		host.queue_free()
		await _settle_frames(1)

func _test_embedded_demo_scene_layouts() -> void:
	var freecell = FREECELL_SCENE.instantiate()
	var freecell_host = await _mount_scene_in_host(freecell, Vector2(980, 760))
	var freecell_top_row = freecell.get_node_or_null("RootMargin/RootVBox/TopRow") as Control
	var freecell_scroll = freecell.get_node_or_null("RootMargin/RootVBox/TableauScroll") as ScrollContainer
	var freecell_status = freecell.get_node_or_null("RootMargin/RootVBox/StatusBar") as Control
	var freecell_tableau = freecell.get_node_or_null("RootMargin/RootVBox/TableauScroll/TableauRow") as HBoxContainer
	_check(freecell_top_row != null and freecell_scroll != null and freecell_status != null, "freecell showcase should keep its main runtime regions mounted inside the embedded host")
	_check(freecell_tableau != null and freecell_tableau.get_child_count() >= 8, "freecell showcase should keep all tableau columns available inside the embedded host")
	freecell_host.queue_free()
	await _settle_frames(1)

	var xiangqi = XIANGQI_SCENE.instantiate()
	var xiangqi_host = await _mount_scene_in_host(xiangqi, Vector2(980, 760))
	var xiangqi_toolbar = xiangqi.get_node_or_null("RootMargin/RootVBox/Toolbar") as Control
	var xiangqi_board_panel = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel") as Control
	var xiangqi_board_host = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost") as Control
	var xiangqi_board_overlay = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost/BoardOverlay") as Control
	var xiangqi_info_row = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/InfoRow") as Control
	var xiangqi_status = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/InfoRow/TurnPanel/TurnVBox/StatusLabel") as Label
	var target_scene = xiangqi.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost/XiangqiBoardZone") as Zone
	_check(xiangqi_toolbar != null and xiangqi_board_panel != null and xiangqi_board_host != null and xiangqi_info_row != null, "xiangqi showcase should keep its toolbar, board host, and info chrome mounted inside the embedded host")
	_check(target_scene != null and xiangqi_board_overlay != null, "xiangqi showcase should keep the scene-authored battlefield zone and board overlay mounted inside the embedded host")
	_check(xiangqi_status != null and not xiangqi_status.text.is_empty(), "xiangqi showcase should expose a visible status label inside the embedded host")
	xiangqi_host.queue_free()
	await _settle_frames(1)
