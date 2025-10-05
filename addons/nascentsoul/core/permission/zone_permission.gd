# ZonePermission.gd
class_name ZonePermission
extends Resource

## ZonePermission 是权限逻辑的基类。
## 它的核心职责是作为一个“守卫”，判断一个 ManagedObject 是否被允许进入某个 Zone。
## 这个基类提供了一些通用的权限规则（如数量限制、分组限制），
## 开发者可以直接使用，也可以按需继承它以实现更复杂的游戏规则。


#=============================================================================
# 1. 导出属性 (Inspector配置)
#=============================================================================

## Zone 中允许存在的最大对象数量。-1 表示没有限制。
@export var max_items: int = -1
## 允许进入的对象必须属于的Godot节点分组 (Groups)。如果数组为空，则不进行分组检查。
@export var allowed_groups: Array[StringName]
## 不允许进入的对象所属的Godot节点分组。
@export var denied_groups: Array[StringName]


#=============================================================================
# 2. 生命周期方法 (Lifecycle Method)
#=============================================================================

## 当Zone准备就绪时，会调用此方法来初始化资源。
## 对于ZonePermission，此方法为空，但为保持API一致性而存在。
func _setup(zone: Zone):
	pass


#=============================================================================
# 3. 公共方法 (由Zone调用)
#=============================================================================

## 判断一个对象是否可以直接被添加到目标Zone。
## 子类可以重写此方法以添加更复杂的规则。
func can_add(item: Control, target_zone: Zone) -> bool:
	# 规则1: 检查数量上限
	if max_items >= 0 and target_zone.managed_items.size() >= max_items:
		return false
		
	# 规则2: 检查是否属于被拒绝的分组
	for group in denied_groups:
		if item.is_in_group(group):
			return false
			
	# 规则3: 检查是否属于允许的分组（如果列表不为空）
	if not allowed_groups.is_empty():
		var is_allowed = false
		for group in allowed_groups:
			if item.is_in_group(group):
				is_allowed = true
				break # 只要满足一个即可
		if not is_allowed:
			return false

	# 所有检查都通过
	return true


## 判断一个对象是否可以从一个Zone转移到目标Zone。
## 默认实现会直接调用 can_add()。
## 子类可以重写此方法以实现更复杂的转移规则 (例如：“卡牌只能从'牌库'转移到'手牌区'”)。
func can_transfer_in(item: Control, from_zone: Zone, target_zone: Zone) -> bool:
	# 默认情况下，转移规则和添加规则相同。
	# 注意：这里的 from_zone 参数是为了让子类可以利用来源信息。
	return can_add(item, target_zone)
