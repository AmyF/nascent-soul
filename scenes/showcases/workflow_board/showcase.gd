extends Control

const WorkflowTaskCardScript = preload("res://scenes/showcases/workflow_board/workflow_task_card.gd")

const WIP_LIMIT := 3
const SAMPLE_TASKS := [
	{
		"id": "starter-shell",
		"title": "Create starter launcher shell",
		"owner": "Amy",
		"label": "setup",
		"points": 1,
		"lane": &"done"
	},
	{
		"id": "lane-copy",
		"title": "Write lane teaching copy",
		"owner": "Copilot",
		"label": "docs",
		"points": 2,
		"lane": &"in_progress"
	},
	{
		"id": "spacing-pass",
		"title": "Review lane spacing and card rhythm",
		"owner": "Amy",
		"label": "ui",
		"points": 2,
		"lane": &"in_progress"
	},
	{
		"id": "tag-pills",
		"title": "Add task label pills to the starter cards",
		"owner": "Copilot",
		"label": "ui",
		"points": 1,
		"lane": &"backlog"
	},
	{
		"id": "policy-note",
		"title": "Explain the WIP rule beside the board",
		"owner": "Amy",
		"label": "rules",
		"points": 1,
		"lane": &"backlog"
	}
]

const ACCENT_BY_LABEL := {
	"setup": Color(0.29, 0.52, 0.90, 1.0),
	"docs": Color(0.42, 0.64, 0.38, 1.0),
	"ui": Color(0.71, 0.49, 0.22, 1.0),
	"rules": Color(0.61, 0.39, 0.75, 1.0)
}

@onready var reset_button: Button = $RootMargin/RootVBox/HeaderVBox/ActionRow/ResetButton
@onready var status_label: Label = $RootMargin/RootVBox/HeaderVBox/ActionRow/StatusLabel
@onready var backlog_zone: Zone = $RootMargin/RootVBox/ContentRow/BacklogPanel/BacklogVBox/BacklogZone
@onready var in_progress_zone: Zone = $RootMargin/RootVBox/ContentRow/InProgressPanel/InProgressVBox/InProgressZone
@onready var done_zone: Zone = $RootMargin/RootVBox/ContentRow/DonePanel/DoneVBox/DoneZone
@onready var backlog_count_label: Label = $RootMargin/RootVBox/ContentRow/BacklogPanel/BacklogVBox/BacklogHeaderRow/BacklogCountPanel/BacklogCountLabel
@onready var in_progress_count_label: Label = $RootMargin/RootVBox/ContentRow/InProgressPanel/InProgressVBox/InProgressHeaderRow/InProgressCountPanel/InProgressCountLabel
@onready var done_count_label: Label = $RootMargin/RootVBox/ContentRow/DonePanel/DoneVBox/DoneHeaderRow/DoneCountPanel/DoneCountLabel
@onready var teaching_label: Label = $RootMargin/RootVBox/TeachingPanel/TeachingLabel

var _is_resetting := false

func _ready() -> void:
	reset_button.pressed.connect(_reset_board)
	_bind_zone_events(backlog_zone, "Backlog")
	_bind_zone_events(in_progress_zone, "In Progress")
	_bind_zone_events(done_zone, "Done")
	_reset_board()

func _reset_board() -> void:
	_is_resetting = true
	for zone in [backlog_zone, in_progress_zone, done_zone]:
		_clear_zone(zone)
	for spec in SAMPLE_TASKS:
		var task = _build_task_card(spec)
		_zone_for_lane(spec.get("lane", &"backlog")).add_item(task)
	_is_resetting = false
	_refresh_lane_counts()
	_refresh_teaching_copy()
	_set_status("Try moving one Backlog task into In Progress. The next extra task will hit the WIP limit.")

func _bind_zone_events(zone: Zone, lane_name: String) -> void:
	zone.item_added.connect(func(_item: ZoneItemControl, _index: int) -> void:
		_refresh_lane_counts()
	)
	zone.item_removed.connect(func(_item: ZoneItemControl, _from_index: int) -> void:
		_refresh_lane_counts()
	)
	zone.item_transferred.connect(func(item: ZoneItemControl, _source_zone: Zone, target_zone: Zone, _target) -> void:
		if _is_resetting or target_zone != zone:
			return
		_refresh_lane_counts()
		_set_status("%s moved to %s." % [_task_title(item), lane_name])
	)
	zone.drop_rejected.connect(func(items: Array, _source_zone: Zone, target_zone: Zone, reason: String) -> void:
		if _is_resetting or target_zone != zone:
			return
		var item_name = _task_title(items[0]) if not items.is_empty() and items[0] is ZoneItemControl else lane_name
		_set_status("%s: %s" % [item_name, reason])
	)

func _clear_zone(zone: Zone) -> void:
	var items = zone.get_items().duplicate()
	for item in items:
		zone.remove_item(item)
		item.queue_free()

func _build_task_card(spec: Dictionary) -> ZoneItemControl:
	var card = WorkflowTaskCardScript.new()
	card.configure_task(
		str(spec.get("id", "")),
		str(spec.get("title", "")),
		str(spec.get("owner", "")),
		str(spec.get("label", "")),
		int(spec.get("points", 0)),
		_accent_for_label(str(spec.get("label", "")))
	)
	return card

func _zone_for_lane(lane: StringName) -> Zone:
	match lane:
		&"in_progress":
			return in_progress_zone
		&"done":
			return done_zone
		_:
			return backlog_zone

func _refresh_lane_counts() -> void:
	backlog_count_label.text = _count_text(backlog_zone)
	in_progress_count_label.text = "%d / %d" % [in_progress_zone.get_item_count(), WIP_LIMIT]
	done_count_label.text = _count_text(done_zone)

func _refresh_teaching_copy() -> void:
	teaching_label.text = "Scene: 3 CardZone nodes in showcase.tscn. Config: 2 local ZoneConfig resources. Rule: WorkflowWipLimitPolicy only on In Progress. Controller: this file just seeds tasks, resets the board, updates counts, and surfaces rejection copy."

func _count_text(zone: Zone) -> String:
	var count = zone.get_item_count()
	return "%d task%s" % [count, "" if count == 1 else "s"]

func _task_title(item) -> String:
	if item is ZoneCard:
		var card := item as ZoneCard
		if card.data != null and card.data.title != "":
			return card.data.title
	if item is Node:
		return (item as Node).name
	return "Task"

func _accent_for_label(label: String) -> Color:
	return ACCENT_BY_LABEL.get(label, WorkflowTaskCardScript.DEFAULT_ACCENT)

func _set_status(message: String) -> void:
	status_label.text = message
