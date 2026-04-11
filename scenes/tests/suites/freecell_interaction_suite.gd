extends "res://scenes/tests/suites/freecell_showcase_support.gd"

func _init() -> void:
	_suite_name = "freecell-showcase-interaction"

func _run_suite() -> void:
	await _test_toolbar_menu_chrome_stays_readable()
	await _reset_root()
	await _test_slot_layout_matches_classic_freecell()
	await _reset_root()
	await _test_drag_drop_diamond_across_all_free_cells()
	await _reset_root()
	await _test_drag_start_rules_and_group_drag_visuals()
	await _reset_root()
	await _test_hover_feedback_stays_static()
	await _reset_root()
	await _test_compact_layout_keeps_tableau_operable()

func _test_toolbar_menu_chrome_stays_readable() -> void:
	var scene = await _spawn_scene()
	var game_menu_button = scene.get_node_or_null("RootMargin/RootVBox/Toolbar/ToolbarRow/GameMenuButton") as MenuButton
	var help_menu_button = scene.get_node_or_null("RootMargin/RootVBox/Toolbar/ToolbarRow/HelpMenuButton") as MenuButton
	_check(game_menu_button != null and not game_menu_button.flat and game_menu_button.has_theme_stylebox_override("normal"), "freecell should serialize an explicit high-contrast style for the Game menu button")
	_check(help_menu_button != null and help_menu_button.has_theme_color_override("font_hover_color"), "freecell should serialize explicit hover text contrast for the Help menu button")
	if game_menu_button == null:
		return
	var game_popup = game_menu_button.get_popup()
	_check(game_popup != null and game_popup.has_theme_stylebox_override("panel"), "freecell should style the Game popup panel for readable menu contrast")
	_check(game_popup != null and game_popup.has_theme_color_override("font_hover_color"), "freecell should style popup hover text contrast for readable menu actions")
