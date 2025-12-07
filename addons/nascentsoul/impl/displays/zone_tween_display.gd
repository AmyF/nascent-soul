class_name ZoneTweenDisplay extends ZoneDisplay

@export var duration: float = 0.2
@export var trans_type: Tween.TransitionType = Tween.TRANS_CUBIC

# 缓存正在运行的 Tween 和目标状态
var _active_tweens: Dictionary = {} # { Control: Tween }
var _target_cache: Dictionary = {} # { Control: Dictionary }

func apply(items: Array[Control], transforms: Dictionary, ghost_instance: Control = null):
	# 清理无效缓存
	var invalid = []
	for k in _active_tweens:
		if not is_instance_valid(k): invalid.append(k)
	for k in invalid:
		_active_tweens.erase(k)
		_target_cache.erase(k)
	
	for item in items:
		if item not in transforms: continue
		var data = transforms[item]
		
		# 1. Ghost 瞬移
		if item == ghost_instance:
			if item in _active_tweens:
				_active_tweens[item].kill()
				_active_tweens.erase(item)
			
			item.position = data.pos
			item.rotation = data.rot
			item.scale = data.scale
			item.z_index = data.z_index
			continue
		
		# 2. 检查目标是否变化 (防止动画打断)
		if _is_target_same(item, data):
			continue
		
		# 3. 创建新 Tween
		if item in _active_tweens:
			_active_tweens[item].kill()
		
		var tween = item.create_tween()
		tween.set_parallel(true)
		tween.set_trans(trans_type)
		
		tween.tween_property(item, "position", data.pos, duration)
		tween.tween_property(item, "rotation", data.rot, duration)
		tween.tween_property(item, "scale", data.scale, duration)
		item.z_index = data.z_index
		
		_active_tweens[item] = tween
		_target_cache[item] = data.duplicate()
		
		tween.finished.connect(func():
			if _active_tweens.get(item) == tween:
				_active_tweens.erase(item)
		)

func _is_target_same(item: Control, new_data: Dictionary) -> bool:
	if not _target_cache.has(item): return false
	if not _active_tweens.has(item): return false
	if not _active_tweens[item].is_valid(): return false
	
	var old = _target_cache[item]
	if old.pos.distance_squared_to(new_data.pos) > 0.1: return false
	if abs(old.rot - new_data.rot) > 0.001: return false
	if old.scale.distance_squared_to(new_data.scale) > 0.001: return false
	
	return true
