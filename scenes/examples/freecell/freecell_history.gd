extends RefCounted

const FreeCellCardFactoryScript = preload("res://scenes/examples/freecell/freecell_card_factory.gd")
const FreeCellStateModelScript = preload("res://scenes/examples/freecell/freecell_state_model.gd")

var _history_limit: int = 256
var _history_states: Array[Dictionary] = []
var _history_signatures: Array[String] = []
var _checkpoint_pending: bool = false
var _undo_animation_active: bool = false

func _init(history_limit: int = 256) -> void:
	_history_limit = history_limit

func can_undo() -> bool:
	return _history_states.size() > 1

func is_undo_animation_active() -> bool:
	return _undo_animation_active

func schedule_checkpoint() -> bool:
	if _checkpoint_pending:
		return false
	_checkpoint_pending = true
	return true

func cancel_pending_checkpoint() -> void:
	_checkpoint_pending = false

func reset_to_snapshot(snapshot: Dictionary) -> void:
	var resolved_snapshot = snapshot.duplicate(true)
	_history_states = [resolved_snapshot]
	_history_signatures = [_state_signature(resolved_snapshot)]
	_checkpoint_pending = false

func commit_checkpoint(snapshot: Dictionary) -> bool:
	_checkpoint_pending = false
	var resolved_snapshot = snapshot.duplicate(true)
	var signature = _state_signature(resolved_snapshot)
	if not _history_signatures.is_empty() and _history_signatures[_history_signatures.size() - 1] == signature:
		return false
	_history_states.append(resolved_snapshot)
	_history_signatures.append(signature)
	if _history_states.size() > _history_limit:
		_history_states.pop_front()
		_history_signatures.pop_front()
	return true

func undo_snapshot() -> Dictionary:
	_checkpoint_pending = false
	if not can_undo():
		return {}
	_history_states.pop_back()
	_history_signatures.pop_back()
	return _history_states[_history_states.size() - 1].duplicate(true)

func restore_state(
	state: Dictionary,
	all_zones: Array[Zone],
	free_cell_zones: Array[Zone],
	foundation_zones: Array[Zone],
	tableau_zones: Array[Zone],
	zone_for_item: Callable,
	move_card_for_restore: Callable,
	reorder_items: Callable,
	clear_selection_all: Callable,
	hide_select_overlay: Callable,
	current_deal_number: int,
	animation_duration: float
) -> Dictionary:
	var normalized_state = FreeCellStateModelScript.normalize_state(state, current_deal_number)
	var should_animate = animation_duration > 0.0 and DisplayServer.get_name() != "headless"
	if should_animate:
		_undo_animation_active = true
	var restored = _restore_state_with_existing_cards(
		normalized_state,
		all_zones,
		free_cell_zones,
		foundation_zones,
		tableau_zones,
		zone_for_item,
		move_card_for_restore,
		reorder_items,
		clear_selection_all,
		hide_select_overlay
	)
	if not restored:
		_undo_animation_active = false
	return {
		"restored": restored,
		"should_animate": should_animate,
		"deal_number": int(normalized_state.get("deal_number", current_deal_number))
	}

func finish_undo_animation() -> void:
	_undo_animation_active = false

func _state_signature(state: Dictionary) -> String:
	var normalized_state = FreeCellStateModelScript.normalize_state(state, 1)
	var parts: Array[String] = ["deal=%d" % int(normalized_state.get("deal_number", 0))]
	for tableau in normalized_state.get("tableaus", []):
		parts.append("T:" + _join_codes(tableau))
	for cell in normalized_state.get("free_cells", []):
		parts.append("C:" + str(cell))
	for foundation in normalized_state.get("foundation_slots", []):
		parts.append("F:" + _join_codes(foundation))
	return "|".join(parts)

func _join_codes(values: Array) -> String:
	var codes: Array[String] = []
	for value in values:
		codes.append(str(value))
	return ",".join(PackedStringArray(codes))

func _restore_state_with_existing_cards(
	state: Dictionary,
	all_zones: Array[Zone],
	free_cell_zones: Array[Zone],
	foundation_zones: Array[Zone],
	tableau_zones: Array[Zone],
	zone_for_item: Callable,
	move_card_for_restore: Callable,
	reorder_items: Callable,
	clear_selection_all: Callable,
	hide_select_overlay: Callable
) -> bool:
	var card_lookup = FreeCellCardFactoryScript.card_lookup_by_code(all_zones)
	var zone_plan = FreeCellStateModelScript.build_zone_plan(state, free_cell_zones, foundation_zones, tableau_zones)
	if card_lookup.is_empty() or zone_plan.is_empty():
		return false
	if hide_select_overlay.is_valid():
		hide_select_overlay.call()
	if clear_selection_all.is_valid():
		clear_selection_all.call()
	for entry in zone_plan:
		var zone = entry["zone"] as Zone
		var codes: Array = entry["codes"]
		if zone == null:
			return false
		for target_index in range(codes.size()):
			var code = str(codes[target_index])
			if not card_lookup.has(code):
				return false
			var card = card_lookup[code] as ZoneItemControl
			var current_zone = zone_for_item.call(card) as Zone
			if current_zone == null:
				return false
			if current_zone == zone:
				continue
			if not move_card_for_restore.is_valid() or not move_card_for_restore.call(card, current_zone, zone, target_index):
				return false
	for entry in zone_plan:
		var zone = entry["zone"] as Zone
		var desired_items: Array[ZoneItemControl] = []
		for code in entry["codes"]:
			var resolved = card_lookup.get(str(code), null)
			if resolved is not ZoneItemControl:
				return false
			desired_items.append(resolved as ZoneItemControl)
		if desired_items.size() != zone.get_item_count():
			return false
		if desired_items.is_empty():
			zone.refresh()
			continue
		if not reorder_items.is_valid() or not reorder_items.call(zone, desired_items, ZonePlacementTarget.linear(0)):
			return false
	return true
