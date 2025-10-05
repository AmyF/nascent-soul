# ZoneArcLayout.gd
class_name ZoneArcLayout
extends ZoneLayout

## ZoneArcLayout v4: 一个“弹性”的、响应式的弧形布局模块。
##
## 核心行为：
## 1. 当卡牌较少时，它们会以固定的重叠/间距展开，手牌总宽度会随卡牌数量增加而变宽。
## 2. 当手牌的总宽度达到Zone容器的最大宽度时，它将不再变宽。
## 3. 继续增加卡牌，将导致卡牌之间的重叠度增加（间距缩小），以将所有卡牌容纳在容器宽度内。


#=============================================================================
# 1. 导出属性 (Inspector配置)
#=============================================================================

@export_group("Arc Shape", "arc_")
## [弧形] 弧形最高点相对于布局【最终宽度】的比例。0=直线, 0.1=轻微弧度。
@export_range(0.0, 1.0, 0.01) var arc_height_factor: float = 0.1

@export_group("Arc Origin", "arc_center_")
## [弧心基准] 使用归一化坐标来描述手牌“基线”的中心点。
@export var arc_center_anchor: Vector2 = Vector2(0.5, 0.5)
## [弧心基准] 在锚点位置基础上，再额外施加的一个像素级偏移，用于微调。
@export var arc_center_margin: Vector2 = Vector2.ZERO

@export_group("Item Transform", "item_")
## [对象] 在“展开阶段”中，相邻卡牌之间的理想重叠像素值。
## 负数表示间距。
@export var item_overlap: float = -5.0
## [对象] 对象本身是否要跟随弧形的切线进行旋转。
@export var item_rotate: bool = true
## [对象] 卡牌自身的旋转和定位枢轴点，使用归一化坐标。
@export var card_pivot_anchor: Vector2 = Vector2(0.5, 1.0)
## 牌的标准大小（用于计算对齐）。实际对象可以有不同大小。
@export var item_size: Vector2 = Vector2(100, 150)


#=============================================================================
# 2. 核心方法 (重写基类方法)
#=============================================================================

func calculate_transforms(items: Array[Control], zone_rect: Rect2) -> Dictionary:
	var transforms := {}
	if items.is_empty():
		return transforms

	var item_count = items.size()
	var container_width = zone_rect.size.x
	var item_width = item_size.x

	# --- 步骤 1: 计算手牌的“自然宽度”和“有效宽度” ---
	var natural_width = item_width * item_count - item_overlap * (item_count - 1)
	var effective_width = min(natural_width, container_width)
	
	# --- 步骤 2: 根据当前阶段（展开/压缩），计算卡牌间的有效水平步长 ---
	var x_step: float
	if item_count > 1:
		# 如果处于压缩阶段，x_step会变小；否则，它等于卡牌宽度-理想重叠
		x_step = (effective_width - item_width) / (item_count - 1)
	else:
		x_step = 0

	# --- 步骤 3: 根据有效宽度和高度系数，反向计算出圆的几何参数 ---
	var arc_height = effective_width * arc_height_factor
	var radius: float
	var arc_center_y_offset: float # 圆心相对于手牌基线的Y偏移
	
	# 防止除以零，当弧高为0时，退化为水平直线布局
	if arc_height < 0.01:
		radius = 0
		arc_center_y_offset = 0
	else:
		var half_width = effective_width / 2.0
		radius = (half_width * half_width + arc_height * arc_height) / (2.0 * arc_height)
		arc_center_y_offset = radius - arc_height
	
	# --- 步骤 4: 计算手牌基线和圆心位置 ---
	var chord_center_pos = (zone_rect.size * arc_center_anchor) + arc_center_margin
	var arc_center_pos = chord_center_pos + Vector2(0, arc_center_y_offset)

	# --- 步骤 5: 遍历并计算每个对象的变换 ---
	var start_x = (container_width - effective_width) / 2.0
	var center_index = (item_count - 1) / 2.0

	for i in range(item_count):
		var item = items[i]
		var pivot_offset = item.size * card_pivot_anchor
		
		# --- 计算位置 ---
		var chord_x = start_x + i * x_step
		var x_from_center = chord_x - container_width / 2.0 + (item_width - x_step) / 2.0

		var item_pivot_pos: Vector2
		var current_angle_rad: float
		
		if radius > 0: # 弧形布局
			var y_on_circle = sqrt(max(0, radius * radius - x_from_center * x_from_center))
			item_pivot_pos = Vector2(
				chord_center_pos.x + x_from_center,
				arc_center_pos.y - y_on_circle
			)
			current_angle_rad = asin(x_from_center / radius)
		else: # 直线布局
			item_pivot_pos = Vector2(chord_center_pos.x + x_from_center, chord_center_pos.y)
			current_angle_rad = 0.0
		
		# --- 计算旋转和Z轴 ---
		var item_rotation = rad_to_deg(current_angle_rad) if item_rotate else 0.0
		var distance_from_center = abs(i - center_index)
		var z_index = item_count - int(distance_from_center * 2)

		# --- 组合最终变换数据 ---
		transforms[item] = {
			"position": item_pivot_pos,
			"rotation_degrees": item_rotation,
			"scale": Vector2.ONE,
			"z_index": z_index,
			"pivot_offset": pivot_offset
		}
		
	return transforms


func get_drop_index_at_position(position: Vector2, items: Array[Control], zone_rect: Rect2) -> int:
	if items.is_empty():
		return 0

	var item_count = items.size()
	var container_width = zone_rect.size.x
	var item_width = items[0].size.x * items[0].scale.x

	# --- 复现 calculate_transforms 中的宽度和步长计算 ---
	var natural_width = item_width * item_count - item_overlap * (item_count - 1)
	var effective_width = min(natural_width, container_width)
	
	var x_step: float = (effective_width - item_width) / (item_count - 1) if item_count > 1 else 0
	var start_x = (container_width - effective_width) / 2.0

	# --- 找到鼠标X坐标对应的插入索引 ---
	var local_mouse_x = position.x
	
	# 检查是否在所有牌的最左边
	if local_mouse_x < start_x + x_step / 2.0:
		return 0

	# 检查是否在所有牌的最右边
	if local_mouse_x > start_x + (item_count - 1) * x_step + item_width - x_step / 2.0:
		return item_count
	
	# 在中间位置
	var index = int((local_mouse_x - start_x + x_step / 2.0) / x_step)
	return clamp(index, 0, item_count)