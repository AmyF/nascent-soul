extends "res://scenes/tests/shared/test_harness.gd"

const RECIPE_SCENE = preload("res://scenes/examples/zone_recipes.tscn")

func _init() -> void:
	_suite_name = "layout-visual-contract"

func _run_suite() -> void:
	await _test_default_layouts_stay_inside_panels()
	await _reset_root()
	await _test_pile_preview_stays_inside_panel()
	await _reset_root()
	await _test_recipe_scene_loads()

func _test_default_layouts_stay_inside_panels() -> void:
	var hand_panel = _make_panel("HandPanel", Vector2(24, 24), Vector2(720, 260))
	var row_panel = _make_panel("RowPanel", Vector2(24, 320), Vector2(720, 220))
	var list_panel = _make_panel("ListPanel", Vector2(780, 24), Vector2(260, 980))
	var pile_panel = _make_panel("PilePanel", Vector2(1080, 24), Vector2(260, 520))
	var hand_layout := ZoneHandLayout.new()
	hand_layout.arch_angle_deg = 36.0
	hand_layout.arch_height = 22.0
	hand_layout.card_spacing_angle = 6.0
	var row_layout := ZoneHBoxLayout.new()
	row_layout.item_spacing = 14.0
	row_layout.padding_left = 16.0
	row_layout.padding_top = 12.0
	var list_layout := ZoneVBoxLayout.new()
	list_layout.item_spacing = 10.0
	list_layout.padding_top = 12.0
	var pile_layout := ZonePileLayout.new()
	pile_layout.overlap_x = 18.0
	pile_layout.padding_left = 16.0
	pile_layout.padding_top = 20.0
	var hand_zone = ExampleSupport.make_zone(hand_panel, "HandContractZone", hand_layout)
	var row_zone = ExampleSupport.make_zone(row_panel, "RowContractZone", row_layout)
	var list_zone = ExampleSupport.make_zone(list_panel, "ListContractZone", list_layout)
	var pile_zone = ExampleSupport.make_zone(pile_panel, "PileContractZone", pile_layout)
	for spec in [
		{"title": "Pulse", "cost": 2, "tags": ["attack"]},
		{"title": "Ward", "cost": 1, "tags": ["skill"]},
		{"title": "Anchor", "cost": 3, "tags": ["power"]},
		{"title": "Burst", "cost": 1, "tags": ["attack"]},
		{"title": "Loom", "cost": 2, "tags": ["skill"]}
	]:
		hand_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
		row_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
		list_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], true))
		pile_zone.add_item(ExampleSupport.make_card(spec["title"], spec["cost"], spec["tags"], false))
	await _settle_frames(3)
	_check(_all_items_within(hand_zone, hand_panel), "hand layout should keep default cards inside the panel bounds")
	_check(_all_items_within(row_zone, row_panel), "horizontal layout should keep default cards inside the panel bounds")
	_check(_all_items_within(list_zone, list_panel), "vertical layout should keep default cards inside the panel bounds")
	_check(_all_items_within(pile_zone, pile_panel), "pile layout should keep default cards inside the panel bounds")

func _test_pile_preview_stays_inside_panel() -> void:
	var source_panel = _make_panel("PreviewSourcePanel", Vector2(24, 24), Vector2(620, 260))
	var pile_panel = _make_panel("PreviewPilePanel", Vector2(24, 320), Vector2(280, 320))
	var source_zone = ExampleSupport.make_zone(source_panel, "PreviewSourceZone", ZoneHBoxLayout.new())
	var pile_layout := ZonePileLayout.new()
	pile_layout.overlap_x = 20.0
	pile_layout.padding_left = 16.0
	pile_layout.padding_top = 16.0
	var pile_zone = ExampleSupport.make_zone(pile_panel, "PreviewPileZone", pile_layout)
	var alpha = ExampleSupport.make_card("Alpha", 1, ["skill"], true)
	var beta = ExampleSupport.make_card("Beta", 2, ["attack"], false)
	source_zone.add_item(alpha)
	pile_zone.add_item(beta)
	await _settle_frames(2)
	source_zone.start_drag([alpha])
	var coordinator = source_zone.get_drag_coordinator(false)
	var session = coordinator.get_session() if coordinator != null else null
	_check(session != null, "pile preview contract requires an active drag session")
	if session == null:
		return
	pile_zone.get_runtime()._create_ghost(alpha)
	session.hover_zone = pile_zone
	session.preview_index = 1
	pile_zone.refresh()
	var ghost = _find_unmanaged_control(pile_zone)
	_check(ghost != null, "pile preview should create a ghost control")
	if ghost != null:
		_check(_rect_inside(pile_panel.get_global_rect(), ghost.get_global_rect()), "pile preview ghost should stay inside the pile panel bounds")
	source_zone.get_runtime().cancel_drag(session)
	await _settle_frames(2)

func _test_recipe_scene_loads() -> void:
	var recipe_scene = RECIPE_SCENE.instantiate()
	add_child(recipe_scene)
	await _settle_frames(2)
	_check(recipe_scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/DeckColumn/DeckZone") is Zone, "recipe scene should include a ready-to-use deck zone")
	_check(recipe_scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/HandColumn/HandZone") is Zone, "recipe scene should include a ready-to-use hand zone")
	_check(recipe_scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/BoardColumn/BoardZone") is Zone, "recipe scene should include a ready-to-use board zone")
	_check(recipe_scene.get_node_or_null("RootMargin/RootVBox/RecipesGrid/DiscardColumn/DiscardZone") is Zone, "recipe scene should include a ready-to-use discard zone")
