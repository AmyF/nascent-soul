extends Control

const ExampleZoneSupport = preload("res://scenes/examples/shared/example_zone_support.gd")
const FreeCellCardFactoryScript = preload("res://scenes/examples/freecell/freecell_card_factory.gd")
const FreeCellCardScript = preload("res://scenes/examples/freecell/freecell_card.gd")
const FreeCellHistoryScript = preload("res://scenes/examples/freecell/freecell_history.gd")
const FreeCellMoveRulesScript = preload("res://scenes/examples/freecell/freecell_move_rules.gd")
const FreeCellRulesScript = preload("res://scenes/examples/freecell/freecell_rules.gd")
const FreeCellStateModelScript = preload("res://scenes/examples/freecell/freecell_state_model.gd")
const FreeCellZoneRegistryScript = preload("res://scenes/examples/freecell/freecell_zone_registry.gd")
const ZoneDragStartDecisionScript = preload("res://addons/nascentsoul/model/zone_drag_start_decision.gd")

const GAME_MENU_NEW := 1
const GAME_MENU_SELECT := 2
const GAME_MENU_RESTART := 3
const GAME_MENU_UNDO := 4
const HELP_MENU_RULES := 11
const HELP_MENU_ABOUT := 12
const HISTORY_LIMIT := 256
const UNDO_ANIMATION_PADDING := 0.08

const NORMAL_STATUS_COLOR := Color(0.10, 0.10, 0.10, 1.0)
const REJECT_STATUS_COLOR := Color(0.72, 0.09, 0.12, 1.0)
const WIN_STATUS_COLOR := Color(0.20, 0.42, 0.12, 1.0)
const DEAL_MAX := FreeCellRulesScript.DEAL_MAX

@onready var root_vbox: VBoxContainer = $RootMargin/RootVBox
@onready var title_bar: PanelContainer = $RootMargin/RootVBox/TitleBar
@onready var window_title_label: Label = $RootMargin/RootVBox/TitleBar/TitleBarRow/WindowTitleLabel
@onready var toolbar: PanelContainer = $RootMargin/RootVBox/Toolbar
@onready var game_menu_button: MenuButton = $RootMargin/RootVBox/Toolbar/ToolbarRow/GameMenuButton
@onready var new_game_button: Button = $RootMargin/RootVBox/Toolbar/ToolbarRow/NewGameButton
@onready var undo_button: Button = $RootMargin/RootVBox/Toolbar/ToolbarRow/UndoButton
@onready var help_menu_button: MenuButton = $RootMargin/RootVBox/Toolbar/ToolbarRow/HelpMenuButton
@onready var deal_label: Label = $RootMargin/RootVBox/Toolbar/ToolbarRow/SeedLabel
@onready var top_row: HBoxContainer = $RootMargin/RootVBox/TopRow
@onready var free_cells_slots_row: HBoxContainer = $RootMargin/RootVBox/TopRow/FreeCellsSlotsRow
@onready var foundations_slots_row: HBoxContainer = $RootMargin/RootVBox/TopRow/FoundationsSlotsRow
@onready var tableau_scroll: ScrollContainer = $RootMargin/RootVBox/TableauScroll
@onready var tableau_row: HBoxContainer = $RootMargin/RootVBox/TableauScroll/TableauRow
@onready var victory_label: Label = $RootMargin/RootVBox/VictoryLabel
@onready var status_bar: PanelContainer = $RootMargin/RootVBox/StatusBar
@onready var status_label: Label = $RootMargin/RootVBox/StatusBar/StatusLabel
@onready var select_game_overlay: Control = $SelectGameOverlay
@onready var select_game_spin_box: SpinBox = $SelectGameOverlay/DialogPanel/DialogVBox/SelectGameSpinBox
@onready var select_game_ok_button: Button = $SelectGameOverlay/DialogPanel/DialogVBox/ButtonRow/SelectGameOkButton
@onready var select_game_cancel_button: Button = $SelectGameOverlay/DialogPanel/DialogVBox/ButtonRow/SelectGameCancelButton

var _rng := RandomNumberGenerator.new()
var _last_deal_number: int = 1
var _game_won: bool = false
var _history = FreeCellHistoryScript.new(HISTORY_LIMIT)
var _move_rules = FreeCellMoveRulesScript.new()
var _zones = FreeCellZoneRegistryScript.new()

func _ready() -> void:
	_zones.build(free_cells_slots_row, foundations_slots_row, tableau_row, self, Callable(self, "_bind_zone_events"))
	_move_rules.attach(_zones.get_zone_info(), _zones.free_cell_zones_ref(), _zones.foundation_zones_ref(), _zones.tableau_zones_ref())
	_wire_controls()
	resized.connect(_queue_layout_refresh)
	visibility_changed.connect(_queue_layout_refresh)
	_queue_layout_refresh()
	start_new_game()

func _exit_tree() -> void:
	_zones.clear_policy_controllers()

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if _history.is_undo_animation_active():
		get_viewport().set_input_as_handled()
		return
	if select_game_overlay.visible:
		if key_event.keycode == KEY_ESCAPE:
			_hide_select_game_overlay()
			get_viewport().set_input_as_handled()
			return
		if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
			_on_select_game_confirmed()
			get_viewport().set_input_as_handled()
			return
	if key_event.keycode == KEY_F2:
		start_new_game()
		get_viewport().set_input_as_handled()
		return
	if key_event.ctrl_pressed and key_event.keycode == KEY_Z:
		if undo_last_move():
			get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_F5:
		start_new_game(_last_deal_number)
		get_viewport().set_input_as_handled()
		return
	if key_event.ctrl_pressed and key_event.keycode == KEY_G:
		_show_select_game_overlay()
		get_viewport().set_input_as_handled()

func start_new_game(deal_number: int = -1) -> void:
	_last_deal_number = deal_number if deal_number > 0 else _random_deal_number()
	_apply_state(_build_deal_state(_last_deal_number), true)
	_set_status("Classic FreeCell ready. Drag cards or double-click to send exposed cards home.")

func load_debug_state(state: Dictionary) -> void:
	_apply_state(state, true)
	if not _game_won:
		_set_status("Loaded a FreeCell position for debugging.")

func get_tableau_zones() -> Array[Zone]:
	return _zones.get_tableau_zones()

func get_free_cell_zones() -> Array[Zone]:
	return _zones.get_free_cell_zones()

func get_foundation_zones() -> Array[Zone]:
	return _zones.get_foundation_zones()

func get_card_by_code(code: String) -> Control:
	return _zones.get_card_by_code(code)

func has_won() -> bool:
	return _game_won

func can_undo() -> bool:
	return _history.can_undo()

func foundation_total() -> int:
	var count := 0
	for zone in _zones.foundation_zones_ref():
		count += zone.get_item_count()
	return count

func try_move_cards(items: Array[ZoneItemControl], target_zone: Zone) -> bool:
	if _history.is_undo_animation_active():
		return false
	if items.is_empty() or target_zone == null:
		return false
	var source_zone = _move_rules.zone_for_item(items[0])
	if source_zone == null:
		return false
	return ExampleZoneSupport.transfer_items(source_zone, items, target_zone, ZonePlacementTarget.linear(target_zone.get_item_count()))

func try_auto_foundation(card: Control) -> bool:
	if _history.is_undo_animation_active():
		return false
	if card is not FreeCellCardScript:
		return false
	var freecell_card := card as FreeCellCardScript
	var source_zone = _move_rules.zone_for_item(freecell_card)
	if source_zone == null:
		return false
	var source_role = _zones.role_of(source_zone)
	if source_role == &"foundation":
		return false
	if not _move_rules.is_exposed_card(freecell_card):
		return false
	if not _move_rules.can_auto_foundation(freecell_card):
		return false
	return _move_card_to_foundation(freecell_card)

func undo_last_move() -> bool:
	if _history.is_undo_animation_active():
		_set_status("The undo animation is still playing.", REJECT_STATUS_COLOR)
		return false
	if not can_undo():
		_update_undo_button_state()
		_set_status("There is no move to undo.", REJECT_STATUS_COLOR)
		return false
	var snapshot = _history.undo_snapshot()
	if snapshot.is_empty():
		_update_undo_button_state()
		_set_status("There is no move to undo.", REJECT_STATUS_COLOR)
		return false
	if _restore_state_from_history(snapshot):
		_set_status("Undoing the last move...")
	else:
		_set_status("Undid the last move.")
	return true

func evaluate_freecell_transfer(zone_role: StringName, _zone_index: int, _context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision:
	if _history.is_undo_animation_active():
		return ZoneTransferDecision.new(false, "Finish the undo animation before making another move.", ZonePlacementTarget.invalid())
	return _move_rules.evaluate_transfer(zone_role, request)

func evaluate_freecell_drag_start(zone_role: StringName, _zone_index: int, context: ZoneContext, anchor_item: ZoneItemControl, _selected_items: Array[ZoneItemControl]):
	if _history.is_undo_animation_active():
		return ZoneDragStartDecisionScript.new(false, "Finish the undo animation before dragging again.", [anchor_item] if is_instance_valid(anchor_item) else [])
	return _move_rules.evaluate_drag_start(zone_role, context, anchor_item)

func _wire_controls() -> void:
	select_game_overlay.visible = false
	select_game_spin_box.min_value = 1
	select_game_spin_box.max_value = DEAL_MAX
	select_game_spin_box.step = 1
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	undo_button.pressed.connect(_on_undo_button_pressed)
	select_game_ok_button.pressed.connect(_on_select_game_confirmed)
	select_game_cancel_button.pressed.connect(_hide_select_game_overlay)

	var game_popup = game_menu_button.get_popup()
	game_popup.clear()
	game_popup.add_item("New Game\tF2", GAME_MENU_NEW)
	game_popup.add_item("Undo\tCtrl+Z", GAME_MENU_UNDO)
	game_popup.add_item("Select Game...\tCtrl+G", GAME_MENU_SELECT)
	game_popup.add_item("Restart This Game\tF5", GAME_MENU_RESTART)
	game_popup.id_pressed.connect(_on_game_menu_id_pressed)

	var help_popup = help_menu_button.get_popup()
	help_popup.clear()
	help_popup.add_item("How to Play", HELP_MENU_RULES)
	help_popup.add_item("About This Showcase", HELP_MENU_ABOUT)
	help_popup.id_pressed.connect(_on_help_menu_id_pressed)
	_update_undo_button_state()

func _bind_zone_events(zone: Zone) -> void:
	zone.item_transferred.connect(_on_item_transferred.bind(zone))
	zone.drop_rejected.connect(_on_drop_rejected.bind(zone))
	zone.drag_start_rejected.connect(_on_drag_start_rejected.bind(zone))
	zone.item_double_clicked.connect(_on_item_double_clicked.bind(zone))
	zone.item_right_clicked.connect(_on_item_right_clicked.bind(zone))
	zone.item_clicked.connect(_on_zone_item_clicked.bind(zone))

func _all_zones() -> Array[Zone]:
	return _zones.all_zones_ref()

func _make_card_from_code(code: String) -> Control:
	return FreeCellCardFactoryScript.make_card_from_code(code)

func _on_zone_item_clicked(item: Control, zone: Zone) -> void:
	if _history.is_undo_animation_active():
		return
	if zone == null or item == null:
		return
	var role = _zones.role_of(zone)
	if role == &"tableau":
		_select_movable_tail(zone, item)
		return
	_select_single_card(zone, item)

func _on_item_double_clicked(item: Control, _zone: Zone) -> void:
	if _history.is_undo_animation_active():
		return
	if try_auto_foundation(item):
		return
	_set_status("%s cannot move to the foundations yet." % _card_label(item), REJECT_STATUS_COLOR)

func _on_item_right_clicked(item: Control, _zone: Zone) -> void:
	if _history.is_undo_animation_active():
		return
	if try_auto_foundation(item):
		return
	_set_status("%s stays where it is." % _card_label(item), REJECT_STATUS_COLOR)

func _on_item_transferred(item: Control, source_zone: Zone, target_zone: Zone, _target, emitter_zone: Zone) -> void:
	if emitter_zone != target_zone:
		return
	_schedule_history_checkpoint()
	_refresh_chrome()
	_update_victory_state()
	if _game_won:
		return
	_set_status("%s moved from %s to %s." % [_card_label(item), _zone_display_name(source_zone), _zone_display_name(target_zone)])

func _on_drop_rejected(items: Array, _source_zone: Zone, _target_zone: Zone, reason: String, _emitter_zone: Zone) -> void:
	if items.is_empty():
		_set_status(reason, REJECT_STATUS_COLOR)
		return
	_set_status("%s: %s" % [_card_label(items[0]), reason], REJECT_STATUS_COLOR)

func _on_drag_start_rejected(items: Array, _source_zone: Zone, reason: String, _emitter_zone: Zone) -> void:
	if items.is_empty():
		_set_status(reason, REJECT_STATUS_COLOR)
		return
	_set_status("%s: %s" % [_card_label(items[0]), reason], REJECT_STATUS_COLOR)

func _on_game_menu_id_pressed(id: int) -> void:
	match id:
		GAME_MENU_NEW:
			start_new_game()
		GAME_MENU_UNDO:
			undo_last_move()
		GAME_MENU_SELECT:
			_show_select_game_overlay()
		GAME_MENU_RESTART:
			start_new_game(_last_deal_number)

func _on_help_menu_id_pressed(id: int) -> void:
	match id:
		HELP_MENU_RULES:
			_set_status("Build down by alternating color. Build the foundations up from Ace to King in suit.")
		HELP_MENU_ABOUT:
			_set_status("Windows XP style FreeCell showcase built on NascentSoul card zones.")

func _on_new_game_button_pressed() -> void:
	start_new_game()

func _on_undo_button_pressed() -> void:
	undo_last_move()

func _on_select_game_confirmed() -> void:
	var next_deal = int(select_game_spin_box.value)
	_hide_select_game_overlay()
	start_new_game(next_deal)

func _show_select_game_overlay() -> void:
	select_game_spin_box.value = _last_deal_number
	select_game_overlay.visible = true
	select_game_spin_box.grab_focus()

func _hide_select_game_overlay() -> void:
	select_game_overlay.visible = false

func _select_single_card(zone: Zone, card: Control) -> void:
	if zone == null or card == null:
		return
	_zones.clear_selection_all()
	zone.select_item(card)

func _select_movable_tail(zone: Zone, card: Control) -> void:
	if zone == null or card == null:
		return
	var cards = _move_rules.typed_cards(zone.get_items())
	var index = _move_rules.find_card_index(cards, card)
	if index == -1:
		return
	var tail = cards.slice(index, cards.size())
	if tail.is_empty():
		return
	if tail.size() > 1 and not _move_rules.is_descending_alternating_run(tail):
		_zones.clear_selection_all()
		_set_status("Only exposed descending alternating runs can move together.", REJECT_STATUS_COLOR)
		return
	if tail.size() == 1 and index != cards.size() - 1:
		_zones.clear_selection_all()
		_set_status("Only the exposed top card can move from this tableau.", REJECT_STATUS_COLOR)
		return
	_zones.clear_selection_all()
	zone.select_item(tail[0], false)
	for tail_index in range(1, tail.size()):
		zone.select_item(tail[tail_index], true)

func _clear_selection_all() -> void:
	_zones.clear_selection_all()

func _refresh_chrome() -> void:
	window_title_label.text = "FreeCell Game #%d" % _last_deal_number
	deal_label.text = "Game #%d" % _last_deal_number
	_update_undo_button_state()

func _random_deal_number() -> int:
	_rng.seed = int(Time.get_unix_time_from_system()) ^ int(Time.get_ticks_usec())
	return _rng.randi_range(1, DEAL_MAX)

func _move_card_to_foundation(card: FreeCellCardScript) -> bool:
	if not is_instance_valid(card):
		return false
	var source_zone = _move_rules.zone_for_item(card)
	if source_zone == null:
		return false
	var target_zone = _move_rules.foundation_zone_for_card(card)
	if target_zone == null:
		return false
	return ExampleZoneSupport.move_item(source_zone, card, target_zone, ZonePlacementTarget.linear(target_zone.get_item_count()))

func _build_deal_state(deal_number: int) -> Dictionary:
	return FreeCellStateModelScript.build_deal_state(deal_number)

func _apply_state(state: Dictionary, reset_history: bool) -> void:
	var normalized_state = FreeCellStateModelScript.normalize_state(state, _last_deal_number)
	_history.cancel_pending_checkpoint()
	_game_won = false
	victory_label.visible = false
	_hide_select_game_overlay()
	_zones.clear_all_cards()
	_last_deal_number = int(normalized_state.get("deal_number", _last_deal_number))
	var tableau_zones = _zones.tableau_zones_ref()
	var free_cell_zones = _zones.free_cell_zones_ref()
	var foundation_zones = _zones.foundation_zones_ref()
	var tableaus: Array = normalized_state.get("tableaus", [])
	for index in range(min(tableaus.size(), tableau_zones.size())):
		for code in tableaus[index]:
			tableau_zones[index].add_item(_make_card_from_code(str(code)))
	var free_cells: Array = normalized_state.get("free_cells", [])
	for index in range(min(free_cells.size(), free_cell_zones.size())):
		var code = str(free_cells[index])
		if code != "":
			free_cell_zones[index].add_item(_make_card_from_code(code))
	var foundation_slots: Array = normalized_state.get("foundation_slots", [])
	for index in range(min(foundation_slots.size(), foundation_zones.size())):
		for code in foundation_slots[index]:
			foundation_zones[index].add_item(_make_card_from_code(str(code)))
	_refresh_chrome()
	_update_victory_state()
	for zone in _all_zones():
		zone.refresh()
	if reset_history:
		_reset_history_to_current_state()

func _serialize_state() -> Dictionary:
	return FreeCellStateModelScript.serialize_state(_last_deal_number, _zones.tableau_zones_ref(), _zones.free_cell_zones_ref(), _zones.foundation_zones_ref())

func _reset_history_to_current_state() -> void:
	_history.reset_to_snapshot(_serialize_state())
	_update_undo_button_state()

func _schedule_history_checkpoint() -> void:
	if not _history.schedule_checkpoint():
		return
	call_deferred("_commit_history_checkpoint")

func _commit_history_checkpoint() -> void:
	_history.commit_checkpoint(_serialize_state())
	_update_undo_button_state()

func _update_undo_button_state() -> void:
	if is_instance_valid(new_game_button):
		new_game_button.disabled = _history.is_undo_animation_active()
	if is_instance_valid(game_menu_button):
		game_menu_button.disabled = _history.is_undo_animation_active()
	if is_instance_valid(help_menu_button):
		help_menu_button.disabled = _history.is_undo_animation_active()
	if not is_instance_valid(undo_button):
		return
	undo_button.disabled = _history.is_undo_animation_active() or not can_undo()

func _restore_state_from_history(state: Dictionary) -> bool:
	var outcome = _history.restore_state(
		state,
		_all_zones(),
		_zones.free_cell_zones_ref(),
		_zones.foundation_zones_ref(),
		_zones.tableau_zones_ref(),
		Callable(_move_rules, "zone_for_item"),
		Callable(self, "_move_card_for_restore"),
		Callable(ExampleZoneSupport, "reorder_items"),
		Callable(self, "_clear_selection_all"),
		Callable(self, "_hide_select_game_overlay"),
		_last_deal_number,
		_freecell_animation_duration()
	)
	if not outcome.get("restored", false):
		_apply_state(state, false)
		return false
	_last_deal_number = int(outcome.get("deal_number", _last_deal_number))
	_refresh_chrome()
	_update_victory_state()
	for zone in _all_zones():
		zone.refresh()
	if not outcome.get("should_animate", false):
		_history.finish_undo_animation()
		_update_undo_button_state()
		return false
	var timer = get_tree().create_timer(_freecell_animation_duration() + UNDO_ANIMATION_PADDING)
	timer.timeout.connect(_finish_undo_animation, CONNECT_ONE_SHOT)
	return true

func _move_card_for_restore(card: ZoneItemControl, source_zone: Zone, target_zone: Zone, target_index: int) -> bool:
	if card == null or source_zone == null or target_zone == null:
		return false
	var snapshots = source_zone._runtime_capture_transfer_snapshots([card], null, card)
	if not source_zone.remove_item(card):
		return false
	target_zone._runtime_set_transfer_handoff(card, snapshots.get(card, {}))
	return target_zone.add_item(card, ZonePlacementTarget.linear(target_index))

func _freecell_animation_duration() -> float:
	for zone in _all_zones():
		var display_style = ExampleZoneSupport.get_zone_display_style(zone)
		if display_style is ZoneTweenDisplay:
			return max(0.0, (display_style as ZoneTweenDisplay).duration)
	return 0.0

func _finish_undo_animation() -> void:
	_history.finish_undo_animation()
	_update_undo_button_state()
	if not _game_won:
		_set_status("Undid the last move.")

func _update_victory_state() -> void:
	_game_won = foundation_total() == 52
	victory_label.visible = _game_won
	if _game_won:
		victory_label.text = "You won."
		_set_status("Every card reached the foundations. Press F2 for a new game.", WIN_STATUS_COLOR)

func _card_label(item: Control) -> String:
	if item is FreeCellCardScript:
		return (item as FreeCellCardScript).display_name()
	return item.name if item != null else "Card"

func _zone_display_name(zone: Zone) -> String:
	return _zones.display_name(zone)

func _set_status(message: String, font_color: Color = NORMAL_STATUS_COLOR) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", font_color)

func _queue_layout_refresh() -> void:
	call_deferred("_apply_responsive_layout")

func _apply_responsive_layout() -> void:
	tableau_row.custom_minimum_size = Vector2(_tableau_content_width(), 0.0)
	var reserved_height = _control_height(title_bar) + _control_height(toolbar) + _control_height(top_row) + _control_height(status_bar) + (_control_height(victory_label) if victory_label.visible else 0.0) + 28.0
	var available_height = clamp(size.y - reserved_height, 260.0, 520.0)
	tableau_scroll.custom_minimum_size = Vector2(0.0, available_height)
	for zone in _all_zones():
		zone.refresh()

func _tableau_content_width() -> float:
	var total_width := 0.0
	var child_controls := 0
	for child in tableau_row.get_children():
		if child is not Control:
			continue
		child_controls += 1
		var control := child as Control
		total_width += max(control.custom_minimum_size.x, control.get_combined_minimum_size().x)
	if child_controls <= 1:
		return total_width
	var spacing = float(tableau_row.get_theme_constant("separation"))
	return total_width + spacing * float(child_controls - 1)

func _control_height(control: Control) -> float:
	if control == null:
		return 0.0
	return control.size.y if control.size.y > 0.0 else control.get_combined_minimum_size().y
