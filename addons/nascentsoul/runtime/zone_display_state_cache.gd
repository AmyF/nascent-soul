class_name ZoneDisplayStateCache extends RefCounted

var _states: Dictionary = {}

func cleanup() -> void:
	clear(true)

func get_state(style: Resource) -> Dictionary:
	if style == null:
		return {}
	var key = style.get_instance_id()
	if not _states.has(key):
		_states[key] = {
			"active_tweens": {},
			"target_cache": {}
		}
	return _states[key]

func clear(kill_active_tweens: bool = false) -> void:
	if kill_active_tweens:
		for state in _states.values():
			var active_tweens: Dictionary = state.get("active_tweens", {})
			for item in active_tweens.keys():
				var tween = active_tweens[item]
				if tween != null:
					tween.kill()
	_states.clear()

func prune() -> void:
	for state in _states.values():
		var active_tweens: Dictionary = state.get("active_tweens", {})
		var target_cache: Dictionary = state.get("target_cache", {})
		var stale_items: Array = []
		for item in active_tweens.keys():
			var tween = active_tweens[item]
			if not is_instance_valid(item) or tween == null or not tween.is_valid() or not tween.is_running():
				stale_items.append(item)
		for item in target_cache.keys():
			if not is_instance_valid(item) and item not in stale_items:
				stale_items.append(item)
		for item in stale_items:
			active_tweens.erase(item)
			if not is_instance_valid(item):
				target_cache.erase(item)
