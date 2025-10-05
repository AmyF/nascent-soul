# ZoneLayout.gd
class_name ZoneLayout
extends Resource

## ZoneLayout 是布局逻辑的【抽象基类】。
## 它的唯一职责是定义所有布局子类都必须实现的“契约”（核心方法）。
##
## [重要] 这个基类不包含任何布局属性（如padding），也不执行任何有意义的布局。
## 你必须创建一个继承自此类的新脚本，并在其中定义所需的属性和布局逻辑。

#=============================================================================
# 1. 导出属性 (Inspector配置)
#=============================================================================

@export_group("Feedback")
## 是否启用“拖拽空位”的视觉反馈效果。
@export var enable_ghost_slot_feedback: bool = true

#=============================================================================
# 2. 生命周期方法 (Lifecycle Method)
#=============================================================================

## 当Zone准备就绪时，会调用此方法来初始化资源。
func _setup(zone: Zone):
	pass


#=============================================================================
# 3. 公共方法 (由Zone调用)
#=============================================================================

## [必须在子类中重写]
## 接收需要布局的对象数组和可用的布局区域，然后返回一个描述每个对象目标变换的字典。
func calculate_transforms(items: Array[Control], zone_rect: Rect2, ghost_index: int = -1, dragged_item: Control = null) -> Dictionary:
	var transforms := {}
	
	# 基类实现：一个安全的默认行为，将所有对象放在容器的左上角，使用默认变换。
	for i in range(items.size()):
		var item = items[i]
		transforms[item] = {
			"position": zone_rect.position,
			"rotation_degrees": 0.0,
			"scale": Vector2.ONE,
			"z_index": i 
		}
		
	return transforms


## [必须在子类中重写]
## 根据给定的全局坐标，计算出一个最合适插入新对象的索引位置。
func get_drop_index_at_position(position: Vector2, items: Array[Control], zone_rect: Rect2) -> int:
	# 基类实现：一个安全的默认行为，总是建议将对象放在列表的末尾。
	return items.size()
