extends "res://scenes/tests/shared/test_harness.gd"

const WORKFLOW_BOARD_SCENE = preload("res://scenes/showcases/workflow_board/showcase.tscn")
const BACKLOG_ZONE_PATH := "RootMargin/RootVBox/ContentRow/BacklogPanel/BacklogVBox/BacklogLaneBody/BacklogScroll/BacklogZoneHost/BacklogZone"
const IN_PROGRESS_ZONE_PATH := "RootMargin/RootVBox/ContentRow/InProgressPanel/InProgressVBox/InProgressLaneBody/InProgressScroll/InProgressZoneHost/InProgressZone"
const DONE_ZONE_PATH := "RootMargin/RootVBox/ContentRow/DonePanel/DoneVBox/DoneLaneBody/DoneScroll/DoneZoneHost/DoneZone"
const BACKLOG_SCROLL_PATH := "RootMargin/RootVBox/ContentRow/BacklogPanel/BacklogVBox/BacklogLaneBody/BacklogScroll"
const IN_PROGRESS_SCROLL_PATH := "RootMargin/RootVBox/ContentRow/InProgressPanel/InProgressVBox/InProgressLaneBody/InProgressScroll"
const DONE_SCROLL_PATH := "RootMargin/RootVBox/ContentRow/DonePanel/DoneVBox/DoneLaneBody/DoneScroll"

func _init() -> void:
	_suite_name = "workflow-board-showcase"

func _run_suite() -> void:
	await _test_initial_board_state()
	await _reset_root()
	await _test_wip_limit_status_flow()
	await _reset_root()
	await _test_reset_restores_sample_board()
	await _reset_root()
	await _test_embedded_layout_contract()

func _spawn_scene() -> Control:
	var scene = WORKFLOW_BOARD_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(4)
	return scene

func _spawn_scene_in_host(host_size: Vector2) -> Control:
	var scene = WORKFLOW_BOARD_SCENE.instantiate()
	await _mount_scene_in_host(scene, host_size)
	await _settle_frames(2)
	return scene

func _test_initial_board_state() -> void:
	var scene = await _spawn_scene()
	var reset_button = scene.get_node_or_null("RootMargin/RootVBox/HeaderVBox/ActionRow/ResetButton") as Button
	var status_label = scene.get_node_or_null("RootMargin/RootVBox/HeaderVBox/ActionRow/StatusLabel") as Label
	var teaching_label = scene.get_node_or_null("RootMargin/RootVBox/TeachingPanel/TeachingLabel") as Label
	var backlog_zone = scene.get_node_or_null(BACKLOG_ZONE_PATH) as Zone
	var in_progress_zone = scene.get_node_or_null(IN_PROGRESS_ZONE_PATH) as Zone
	var done_zone = scene.get_node_or_null(DONE_ZONE_PATH) as Zone
	var backlog_count_label = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/BacklogPanel/BacklogVBox/BacklogHeaderRow/BacklogCountPanel/BacklogCountLabel") as Label
	var in_progress_count_label = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/InProgressPanel/InProgressVBox/InProgressHeaderRow/InProgressCountPanel/InProgressCountLabel") as Label
	var done_count_label = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/DonePanel/DoneVBox/DoneHeaderRow/DoneCountPanel/DoneCountLabel") as Label
	_check(reset_button != null and reset_button.text.contains("Reset"), "workflow board should expose a reset button in its starter action row")
	_check(backlog_zone != null and in_progress_zone != null and done_zone != null, "workflow board should keep all three scene-authored lanes mounted")
	_check(backlog_zone != null and backlog_zone.get_item_count() == 2, "workflow board should seed two backlog tasks")
	_check(in_progress_zone != null and in_progress_zone.get_item_count() == 2, "workflow board should seed two in-progress tasks")
	_check(done_zone != null and done_zone.get_item_count() == 1, "workflow board should seed one done task")
	_check(backlog_count_label != null and backlog_count_label.text == "2 tasks", "workflow board should show the seeded backlog count")
	_check(in_progress_count_label != null and in_progress_count_label.text == "2 / 3", "workflow board should show the seeded in-progress count against the WIP limit")
	_check(done_count_label != null and done_count_label.text == "1 task", "workflow board should show the seeded done count")
	_check(backlog_zone != null and _zone_item_names(backlog_zone).has("tag-pills") and _zone_item_names(backlog_zone).has("policy-note"), "workflow board should seed the expected backlog task cards")
	_check(in_progress_zone != null and _zone_item_names(in_progress_zone).has("lane-copy") and _zone_item_names(in_progress_zone).has("spacing-pass"), "workflow board should seed the expected in-progress task cards")
	_check(done_zone != null and _zone_item_names(done_zone) == ["starter-shell"], "workflow board should seed the finished starter-shell task in Done")
	var sample_card = backlog_zone.get_items()[0] as ZoneCard if backlog_zone != null and backlog_zone.get_item_count() > 0 else null
	var title_label = sample_card.get_node_or_null("VisualRoot/TitleLabel") as Label if sample_card != null else null
	_check(title_label != null and title_label.get_theme_color("font_color").r < 0.35 and title_label.get_theme_color("font_color").g < 0.35, "workflow board task cards should override the shared light-on-dark label theme with a darker readable title color")
	_check(status_label != null and status_label.text.contains("Backlog") and status_label.text.contains("WIP limit"), "workflow board should expose visible starter guidance after seeding the sample board")
	_check(teaching_label != null and teaching_label.text.contains("scrollable lane bodies") and teaching_label.text.contains("WorkflowWipLimitPolicy"), "workflow board should explain its scene/config/policy split in the teaching footer")

func _test_wip_limit_status_flow() -> void:
	var scene = await _spawn_scene()
	var backlog_zone = scene.get_node_or_null(BACKLOG_ZONE_PATH) as Zone
	var in_progress_zone = scene.get_node_or_null(IN_PROGRESS_ZONE_PATH) as Zone
	var status_label = scene.get_node_or_null("RootMargin/RootVBox/HeaderVBox/ActionRow/StatusLabel") as Label
	var in_progress_count_label = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/InProgressPanel/InProgressVBox/InProgressHeaderRow/InProgressCountPanel/InProgressCountLabel") as Label
	_check(backlog_zone != null and in_progress_zone != null, "workflow board WIP test should mount both source and target lanes")
	if backlog_zone == null or in_progress_zone == null:
		return
	var first_backlog_item = backlog_zone.get_items()[0]
	_check(_move_item(backlog_zone, first_backlog_item, in_progress_zone), "workflow board should allow a backlog card into In Progress until the lane reaches the WIP limit")
	await _settle_frames(2)
	_check(backlog_zone.get_item_count() == 1 and in_progress_zone.get_item_count() == 3, "workflow board should update lane counts after a successful move into In Progress")
	_check(status_label != null and status_label.text.contains("moved to In Progress"), "workflow board should surface transfer success copy after a task changes lanes")
	_check(in_progress_count_label != null and in_progress_count_label.text == "3 / 3", "workflow board should show a full in-progress lane after the third task enters it")
	var second_backlog_item = backlog_zone.get_items()[0]
	_check(not _move_item(backlog_zone, second_backlog_item, in_progress_zone), "workflow board should reject a fourth task entering In Progress")
	await _settle_frames(2)
	_check(backlog_zone.get_item_count() == 1 and in_progress_zone.get_item_count() == 3, "workflow board should keep counts stable after a WIP rejection")
	_check(status_label != null and status_label.text.contains("Keep In Progress at 3 tasks or fewer."), "workflow board should surface the WIP rejection reason in the status row")

func _test_reset_restores_sample_board() -> void:
	var scene = await _spawn_scene()
	var reset_button = scene.get_node_or_null("RootMargin/RootVBox/HeaderVBox/ActionRow/ResetButton") as Button
	var backlog_zone = scene.get_node_or_null(BACKLOG_ZONE_PATH) as Zone
	var done_zone = scene.get_node_or_null(DONE_ZONE_PATH) as Zone
	var status_label = scene.get_node_or_null("RootMargin/RootVBox/HeaderVBox/ActionRow/StatusLabel") as Label
	_check(reset_button != null and backlog_zone != null and done_zone != null, "workflow board reset test should mount the reset button and lane zones")
	if reset_button == null or backlog_zone == null or done_zone == null:
		return
	_check(_move_item(done_zone, done_zone.get_items()[0], backlog_zone), "workflow board should allow moving a done task back to backlog before reset")
	await _settle_frames(2)
	_check(backlog_zone.get_item_count() == 3 and done_zone.get_item_count() == 0, "workflow board should reflect the manual move before reset")
	reset_button.pressed.emit()
	await _settle_frames(2)
	_check(backlog_zone.get_item_count() == 2 and done_zone.get_item_count() == 1, "workflow board reset should restore the original lane distribution")
	_check(_zone_item_names(backlog_zone).has("tag-pills") and _zone_item_names(backlog_zone).has("policy-note"), "workflow board reset should restore the original backlog sample cards")
	_check(_zone_item_names(done_zone) == ["starter-shell"], "workflow board reset should restore the original done sample card")
	_check(status_label != null and status_label.text.contains("WIP limit"), "workflow board reset should restore the starter guidance copy")

func _test_embedded_layout_contract() -> void:
	var scene = await _spawn_scene_in_host(Vector2(980, 760))
	var action_row = scene.get_node_or_null("RootMargin/RootVBox/HeaderVBox/ActionRow") as Control
	var content_row = scene.get_node_or_null("RootMargin/RootVBox/ContentRow") as Control
	var backlog_scroll = scene.get_node_or_null(BACKLOG_SCROLL_PATH) as ScrollContainer
	var in_progress_scroll = scene.get_node_or_null(IN_PROGRESS_SCROLL_PATH) as ScrollContainer
	var done_scroll = scene.get_node_or_null(DONE_SCROLL_PATH) as ScrollContainer
	var backlog_zone = scene.get_node_or_null(BACKLOG_ZONE_PATH) as Zone
	var in_progress_zone = scene.get_node_or_null(IN_PROGRESS_ZONE_PATH) as Zone
	var done_zone = scene.get_node_or_null(DONE_ZONE_PATH) as Zone
	_check(action_row != null and action_row.size.y > 0.0, "workflow board should keep its starter action row visible inside an embedded host")
	_check(content_row != null and content_row.size.y > 0.0, "workflow board should keep its three-column content row visible inside an embedded host")
	_check(backlog_scroll != null and in_progress_scroll != null and done_scroll != null, "workflow board should keep scrollable lane bodies mounted inside an embedded host")
	_check(backlog_zone != null and _all_items_within(backlog_zone, backlog_zone, 2.0), "workflow board backlog cards should stay within the embedded lane bounds")
	_check(in_progress_zone != null and _all_items_within(in_progress_zone, in_progress_zone, 2.0), "workflow board in-progress cards should stay within the embedded lane bounds")
	_check(done_zone != null and _all_items_within(done_zone, done_zone, 2.0), "workflow board done cards should stay within the embedded lane bounds")
