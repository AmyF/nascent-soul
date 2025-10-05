# ZoneHorizontalLayout.gd
class_name ZoneHorizontalLayout
extends ZoneLayout

## HorizontalLayout (弹性版): 一个响应式的、支持动态压缩的横向布局模块。
##
## 核心行为：
## 1. 当内容较少时，以固定间距展开，并根据分布模式对齐。
## 2. 当内容总宽度试图超过容器宽度时，自动减小间距以将所有内容约束在容器内。


#=============================================================================
# 1. 枚举 (Enums)
#=============================================================================

## 垂直方向上的对齐方式
enum VAlignment { TOP, CENTER, BOTTOM }
## 水平方向上的分布方式
enum Distribution { PACK_START, PACK_CENTER, PACK_END }


#=============================================================================
# 2. 导出属性 (Inspector配置)
#=============================================================================

@export_group("Layout")
## 对象之间的间距（像素）。
@export var spacing: float = 10.0
## 垂直方向上的对齐方式。
@export var vertical_alignment: VAlignment = VAlignment.CENTER
## 水平方向上的分布方式。
@export var distribution: Distribution = Distribution.PACK_CENTER

@export_group("Item Sizing")
## 用于布局计算的统一对象尺寸。此布局将忽略对象自身的size。
@export var item_size: Vector2 = Vector2(120, 180)

#=============================================================================
# 3. 核心方法 (重写基类方法)
#=============================================================================

## 计算所有对象的目标变换。
func calculate_transforms(items: Array[Control], zone_rect: Rect2, ghost_index: int = -1, dragged_item: Control = null) -> Dictionary:
	var transforms := {}
	var phantom_list: Array = []
	var ghost_placeholder: Control = null

	if enable_ghost_slot_feedback and ghost_index > -1:
		phantom_list = items.duplicate()
		if dragged_item in phantom_list: phantom_list.erase(dragged_item)
		ghost_placeholder = Control.new(); ghost_placeholder.size = item_size

		var safe_ghost_index = clamp(ghost_index, 0, phantom_list.size())
		phantom_list.insert(safe_ghost_index, ghost_placeholder)
	else:
		phantom_list = items

	if phantom_list.is_empty():
		return transforms

	var item_count = phantom_list.size()
	var container_width = zone_rect.size.x
	
	var natural_width = item_size.x * item_count + spacing * (item_count - 1)
	var effective_width = min(natural_width, container_width)
	
	var effective_spacing: float
	if natural_width > container_width and item_count > 1:
		effective_spacing = (container_width - (item_size.x * item_count)) / (item_count - 1)
	else:
		effective_spacing = spacing

	var current_x: float
	match distribution:
		Distribution.PACK_START:
			current_x = 0
		Distribution.PACK_CENTER:
			current_x = (container_width - effective_width) / 2.0
		Distribution.PACK_END:
			current_x = container_width - effective_width

	for i in range(item_count):
		var p_item = phantom_list[i]
		
		if p_item == ghost_placeholder:
			current_x += item_size.x + effective_spacing
			continue

		var item_y: float
		match vertical_alignment:
			VAlignment.TOP:
				item_y = 0
			VAlignment.CENTER:
				item_y = (zone_rect.size.y - item_size.y) / 2.0
			VAlignment.BOTTOM:
				item_y = zone_rect.size.y - item_size.y
		
		var item_scale = Vector2.ONE
		if p_item.size.x > 0 and p_item.size.y > 0:
			item_scale = item_size / p_item.size

		transforms[p_item] = {
			"position": Vector2(current_x, item_y),
			"rotation_degrees": 0.0,
			"scale": item_scale,
			"z_index": i
		}
		
		current_x += item_size.x + effective_spacing
		
	if is_instance_valid(ghost_placeholder):
		ghost_placeholder.queue_free()
		
	return transforms


func get_drop_index_at_position(position: Vector2, items: Array[Control], zone_rect: Rect2) -> int:
	if items.is_empty():
		return 0

	var item_count = items.size()
	var container_width = zone_rect.size.x
	
	var natural_width = item_size.x * item_count + spacing * (item_count - 1)
	var effective_width = min(natural_width, container_width)

	var effective_spacing: float
	if natural_width > container_width and item_count > 1:
		effective_spacing = (container_width - (item_size.x * item_count)) / (item_count - 1)
	else:
		effective_spacing = spacing

	var start_x: float
	match distribution:
		Distribution.PACK_START: start_x = 0
		Distribution.PACK_CENTER: start_x = (container_width - effective_width) / 2.0
		Distribution.PACK_END: start_x = container_width - effective_width

	var slot_width = item_size.x + effective_spacing
	var local_mouse_x = position.x

	if local_mouse_x < start_x + slot_width / 2.0:
		return 0
	
	# FIX: 使用 effective_width 替换不存在的 total_width，并简化逻辑
	if local_mouse_x > start_x + effective_width - slot_width / 2.0:
		return item_count
	
	var relative_x = local_mouse_x - start_x
	var index = int(relative_x / slot_width + 0.5)
	
	return clamp(index, 0, item_count)
