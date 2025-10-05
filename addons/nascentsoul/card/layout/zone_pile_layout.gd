# ZonePileLayout.gd
class_name ZonePileLayout
extends ZoneLayout

## ZonePileLayout 将所有对象堆叠在一起，形成一个“牌堆”或“牌库”的视觉效果。
## 它通过微小的偏移来暗示牌堆的数量，并可以将牌堆精确地放置在容器的九个标准位置。


#=============================================================================
# 1. 枚举 (Enums)
#=============================================================================

## 定义牌堆在容器内的对齐位置
enum PileAlignment { 
	TOP_LEFT, TOP_CENTER, TOP_RIGHT, 
	CENTER_LEFT, CENTER, CENTER_RIGHT, 
	BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT 
}


#=============================================================================
# 2. 导出属性 (Inspector配置)
#=============================================================================

## 整个牌堆在 Zone 容器内的对齐位置。
@export var pile_alignment: PileAlignment = PileAlignment.CENTER

## 牌堆中每下一个对象相对于上一个对象的像素偏移量。
@export var offset_per_item: Vector2 = Vector2(0, -1)

## 限制偏移效果应用的对象数量。-1表示不限制。
@export var max_visible_offset: int = 10

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
	
	# --- 步骤 1: 计算牌堆的“基准位置” ---
	# 我们以第一个对象的大小为参考来计算对齐
	var reference_size = item_size
	var base_pos := Vector2()
	
	# 计算水平位置
	match pile_alignment:
		PileAlignment.TOP_LEFT, PileAlignment.CENTER_LEFT, PileAlignment.BOTTOM_LEFT:
			base_pos.x = 0
		PileAlignment.TOP_CENTER, PileAlignment.CENTER, PileAlignment.BOTTOM_CENTER:
			base_pos.x = (zone_rect.size.x - reference_size.x) / 2.0
		PileAlignment.TOP_RIGHT, PileAlignment.CENTER_RIGHT, PileAlignment.BOTTOM_RIGHT:
			base_pos.x = zone_rect.size.x - reference_size.x

	# 计算垂直位置
	match pile_alignment:
		PileAlignment.TOP_LEFT, PileAlignment.TOP_CENTER, PileAlignment.TOP_RIGHT:
			base_pos.y = 0
		PileAlignment.CENTER_LEFT, PileAlignment.CENTER, PileAlignment.CENTER_RIGHT:
			base_pos.y = (zone_rect.size.y - reference_size.y) / 2.0
		PileAlignment.BOTTOM_LEFT, PileAlignment.BOTTOM_CENTER, PileAlignment.BOTTOM_RIGHT:
			base_pos.y = zone_rect.size.y - reference_size.y

	# --- 步骤 2: 遍历并计算每个对象的最终位置 ---
	for i in range(items.size()):
		var item = items[i]
		
		var offset_index = i
		if max_visible_offset >= 0:
			offset_index = min(i, max_visible_offset)
			
		var item_pos = base_pos + offset_per_item * offset_index
		
		transforms[item] = {
			"position": item_pos,
			"rotation_degrees": 0.0,
			"scale": Vector2.ONE,
			"z_index": i # 确保后来的牌在上面
		}
		
	return transforms


## 根据给定的全局坐标，计算出一个最合适插入新对象的索引位置。
func get_drop_index_at_position(position: Vector2, items: Array[Control], zone_rect: Rect2) -> int:
	# 对于“牌堆”，新对象总是被添加到最上层。
	return items.size()
