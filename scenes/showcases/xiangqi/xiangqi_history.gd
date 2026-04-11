extends RefCounted

const XiangqiStateModelScript = preload("res://scenes/showcases/xiangqi/xiangqi_state_model.gd")

var _history_limit: int = 256
var _history_states: Array = []
var _history_signatures: Array[String] = []
var _history_transitions: Array = []
var _undo_animation_active: bool = false
var _state_model = XiangqiStateModelScript.new()

func _init(history_limit: int = 256) -> void:
	_history_limit = history_limit

func can_undo() -> bool:
	return _history_states.size() > 1

func is_undo_animation_active() -> bool:
	return _undo_animation_active

func reset_to_snapshot(snapshot: Dictionary) -> void:
	var resolved_snapshot = _state_model.normalize_state(snapshot)
	_history_states = [resolved_snapshot.duplicate(true)]
	_history_signatures = [_state_model.state_signature(resolved_snapshot)]
	_history_transitions = [{}]

func commit_checkpoint(snapshot: Dictionary, transition: Dictionary = {}) -> bool:
	var resolved_snapshot = _state_model.normalize_state(snapshot)
	var signature = _state_model.state_signature(resolved_snapshot)
	if not _history_signatures.is_empty() and _history_signatures[_history_signatures.size() - 1] == signature:
		return false
	_history_states.append(resolved_snapshot.duplicate(true))
	_history_signatures.append(signature)
	_history_transitions.append(transition.duplicate(true))
	if _history_states.size() > _history_limit:
		_history_states.pop_front()
		_history_signatures.pop_front()
		_history_transitions.pop_front()
	return true

func pop_undo() -> Dictionary:
	if not can_undo():
		return {}
	var transition = _history_transitions.pop_back() if not _history_transitions.is_empty() else {}
	_history_states.pop_back()
	_history_signatures.pop_back()
	return {
		"snapshot": _history_states[_history_states.size() - 1].duplicate(true),
		"transition": transition.duplicate(true) if transition is Dictionary else {}
	}

func mark_undo_animation_started() -> void:
	_undo_animation_active = true

func finish_undo_animation() -> void:
	_undo_animation_active = false
