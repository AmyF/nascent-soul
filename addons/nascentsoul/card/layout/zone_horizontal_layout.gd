# HorizontalLayout.gd
class_name ZoneHorizontalLayout
extends ZoneLayout

## HorizontalLayout 是一个具体的布局实现。
## 它将一组对象在一个水平线上进行排列，并提供了丰富的对齐和分布选项。


#=============================================================================
# 1. 枚举 (Enums)
#=============================================================================

## 垂直方向上的对齐方式
enum VAlignment { TOP, CENTER, BOTTOM }
## 水平方向上的分布方式
enum Distribution { PACK_START, PACK_CENTER, PACK_END, JUSTIFY }


#=============================================================================
# 2. 导出属性 (Inspector配置)
#=============================================================================

## 对象之间的间距（像素）。
@export var spacing: float = 10.0
## 垂直方向上的对齐方式。
@export var vertical_alignment: VAlignment = VAlignment.CENTER
## 水平方向上的分布方式。
@export var distribution: Distribution = Distribution.PACK_CENTER
## 牌的标准大小（用于计算对齐）。实际对象可以有不同大小。
@export var item_size: Vector2 = Vector2(100, 150)

#=============================================================================
# 3. 核心方法 (重写基类方法)
#=============================================================================

## 计算所有对象的目标变换。
func calculate_transforms(items: Array[Control], zone_rect: Rect2) -> Dictionary:
	var transforms := {}
	if items.is_empty():
		return transforms

	# --- 步骤 1: 计算总宽度和有效间距 ---
	var total_items_width: float = items.size() * item_size.x

	var total_width: float = total_items_width + spacing * (items.size() - 1)
	var current_spacing: float = spacing

	# --- 步骤 2: 根据分布方式，计算起始X坐标和实际间距 ---
	var current_x: float
	match distribution:
		Distribution.PACK_START:
			current_x = zone_rect.position.x
		Distribution.PACK_CENTER:
			current_x = zone_rect.position.x + (zone_rect.size.x - total_width) / 2.0
		Distribution.PACK_END:
			current_x = zone_rect.position.x + zone_rect.size.x - total_width
		Distribution.JUSTIFY:
			current_x = zone_rect.position.x
			if items.size() > 1:
				current_spacing = (zone_rect.size.x - total_items_width) / (items.size() - 1)
			else: # 如果只有一个对象，Justify表现为居中
				current_x = zone_rect.position.x + (zone_rect.size.x - total_items_width) / 2.0

	# --- 步骤 3: 遍历并计算每个对象的最终变换 ---
	for i in range(items.size()):
		var item = items[i]
		var item_scaled_size = item.size * item.scale

		var item_y: float
		match vertical_alignment:
			VAlignment.TOP:
				item_y = zone_rect.position.y
			VAlignment.CENTER:
				item_y = zone_rect.position.y + (zone_rect.size.y - item_scaled_size.y) / 2.0
			VAlignment.BOTTOM:
				item_y = zone_rect.position.y + zone_rect.size.y - item_scaled_size.y
		
		transforms[item] = {
			"position": Vector2(current_x, item_y),
			"rotation_degrees": 0.0,
			"scale": Vector2.ONE, # 可以之后扩展为统一缩放
			"z_index": i
		}
		
		# 更新下一个对象的起始x坐标
		current_x += item_scaled_size.x + current_spacing
		
	return transforms


## 根据给定的全局坐标，计算出一个最合适插入新对象的索引位置。
func get_drop_index_at_position(position: Vector2, items: Array[Control], zone_rect: Rect2) -> int:
	if items.is_empty():
		return 0

	# 调用 calculate_transforms 来获取所有对象在理想布局下的位置
	var transforms = calculate_transforms(items, zone_rect)

	# 遍历所有对象，找到第一个中心点在鼠标右侧的对象
	for i in range(items.size()):
		var item = items[i]
		var item_transform = transforms[item]
		var item_pos = item_transform["position"]
		var item_scaled_size = item.size * item_transform["scale"]
		
		# 计算对象在布局中的中心X坐标
		var item_center_x = item_pos.x + item_scaled_size.x / 2.0
		
		if position.x < item_center_x:
			return i

	# 如果鼠标位置在所有对象的右侧，则返回最后一个索引
	return items.size()
