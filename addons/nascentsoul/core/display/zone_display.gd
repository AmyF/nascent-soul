# ZoneDisplay.gd
class_name ZoneDisplay
extends Resource

## ZoneDisplay 是显示逻辑的【基类】。
## 它在 Zone 的更新流程中扮演双重角色：
## 1. 【筛选】: 从排好序的对象列表中，决定哪些对象最终是可见的。
## 2. 【应用状态】: 管理可见对象的视觉外观，特别是提供实现通用“悬停效果”的配置数据。
##
## [重要] 这个基类不知道如何操作一个未知的 Control 节点（例如，如何翻面或高亮）。
## 具体的视觉效果必须通过【继承】此类，并在子类的 apply_display_state 方法中实现。


#=============================================================================
# 1. 导出属性 (Inspector配置)
#=============================================================================

## Zone 中最多同时显示的对象数量。例如，用于实现“只显示墓地顶端的5张牌”。
## -1 表示全部显示。
@export var max_visible_items: int = -1

## 当鼠标悬停时，是否启用通用的放大、上移等变换效果。
@export var enable_enlarge_on_hover: bool = true

## [悬停效果] 应用的缩放乘数。例如 Vector2(1.5, 1.5) 表示放大到1.5倍。
@export var hover_scale_multiplier: Vector2 = Vector2(1.2, 1.2)

## [悬停效果] 应用的像素位移。例如 Vector2(0, -50) 表示向上移动50像素。
@export var hover_offset: Vector2 = Vector2(0, -30)

## [悬停效果] 增加的Z轴层级，以确保悬停对象显示在最上层。
@export var hover_z_index_increment: int = 10


#=============================================================================
# 2. 生命周期方法 (Lifecycle Method)
#=============================================================================

## 当Zone准备就绪时，会调用此方法来初始化资源。
func _setup(zone: Zone):
	pass


#=============================================================================
# 3. 公共方法 (由Zone调用)
#=============================================================================

## [可重写]
## 筛选出最终应该被显示的 Control 对象。
## 基类会根据 max_visible_items 属性进行筛选。
func filter_visible_items(items: Array[Control]) -> Array[Control]:
	if max_visible_items >= 0 and items.size() > max_visible_items:
		# 返回从索引0开始的、长度为max_visible_items的子数组
		return items.slice(0, max_visible_items)
	
	# 如果不限制数量，则返回原始数组
	return items


## [必须在子类中重写]
## 为单个 Control 对象应用其【非变换类】的视觉状态（如材质、颜色、子节点可见性等）。
## 这个方法是实现游戏特定视觉逻辑的核心。
func apply_display_state(item: Control, state_info: Dictionary):
	# 基类实现为空，等待子类重写。
	# state_info 字典会包含类似 {"is_hovered": bool, "is_selected": bool} 的动态信息。
	pass


## [可重写]
## 获取当一个对象处于或离开【悬停状态】时，其变换属性需要做出的“增量调整”。
## Zone 会将这个结果与 ZoneLayout 的计算结果合并，来实现悬停放大等效果。
func get_hover_transform_adjustment(item: Control, is_hovered: bool) -> Dictionary:
	if enable_enlarge_on_hover and is_hovered:
		return {
			"scale": hover_scale_multiplier,
			"offset": hover_offset,
			"z_index": hover_z_index_increment
		}
	else:
		# 返回默认/零值
		return {
			"scale": Vector2.ONE,
			"offset": Vector2.ZERO,
			"z_index": 0
		}
