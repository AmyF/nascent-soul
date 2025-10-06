# ZoneArcLayout.gd
class_name ZoneArcLayout
extends ZoneLayout

## ZoneArcLayout: 一个“弹性”的、响应式的弧形布局模块。
##
## 核心行为：
## 1. 当卡牌较少时，它们会以固定的重叠/间距展开，手牌总宽度会随卡牌数量增加而变宽。
## 2. 当手牌的总宽度达到Zone容器的最大宽度时，它将不再变宽。
## 3. 继续增加卡牌，将导致卡牌之间的重叠度增加（间距缩小），以将所有卡牌容纳在容器宽度内。
## 它使用统一的 item_size 进行计算，以确保布局的稳定和可预测性。


#=============================================================================
# 1. 导出属性 (Inspector配置)
#=============================================================================

@export_group("Arc Shape", "arc_")
## [弧形] 弧形最高点相对于布局【最终宽度】的比例。0=直线, 0.1=轻微弧度。
@export_range(0.0, 1.0, 0.01) var arc_height_factor: float = 0.15

@export_group("Arc Origin", "arc_center_")
## [弧心基准] 使用归一化坐标来描述手牌“基线”的中心点。
@export var arc_center_anchor: Vector2 = Vector2(0.5, 0.5)
## [弧心基准] 在锚点位置基础上，再额外施加的一个像素级偏移，用于微调。
@export var arc_center_margin: Vector2 = Vector2.ZERO

@export_group("Item Transform", "item_")
## [对象] 用于布局计算的统一对象尺寸。
@export var item_size: Vector2 = Vector2(100, 150)
## [对象] 在“展开阶段”中，相邻卡牌之间的理想重叠像素值。负数表示间距。
@export var item_overlap: float = 10.0
## [对象] 对象本身是否要跟随弧形的切线进行旋转。
@export var item_rotate: bool = true
## [对象] 卡牌自身的旋转和定位枢轴点，使用归一化坐标。
@export var card_pivot_anchor: Vector2 = Vector2(0.5, 1.0)

#=============================================================================
# 2. 核心方法 (重写基类方法)
#=============================================================================

func calculate_transforms(items: Array[Control], zone_rect: Rect2, ghost_index: int = -1, dragged_item: Control = null) -> Dictionary:
	var transforms := {}
	var phantom_list: Array = []
	var ghost_placeholder: Control = null

	# --- 步骤 1: 构建幻影列表 ---
	if enable_ghost_slot_feedback and ghost_index > -1:
		phantom_list = items.duplicate()
		if dragged_item in phantom_list:
			phantom_list.erase(dragged_item)
		ghost_placeholder = Control.new()
		ghost_placeholder.size = item_size
		
		var safe_ghost_index = clamp(ghost_index, 0, phantom_list.size())
		phantom_list.insert(safe_ghost_index, ghost_placeholder)
	else:
		phantom_list = items

	if phantom_list.is_empty():
		return transforms

	var item_count = phantom_list.size()
	
	# --- 步骤 2: 计算“弹性”宽度和水平步长 ---
	var container_width = zone_rect.size.x
	var natural_width = item_size.x * item_count - item_overlap * (item_count - 1)
	var effective_width = min(natural_width, container_width)
	
	var x_step: float = (effective_width - item_size.x) / (item_count - 1) if item_count > 1 else 0

	# --- 步骤 3: 根据有效宽度和高度，反向计算圆的几何参数 ---
	var arc_height = effective_width * arc_height_factor
	var radius: float
	var arc_center_y_offset: float
	
	if arc_height < 0.01: # 退化为直线
		radius = 0
		arc_center_y_offset = 0
	else:
		var half_width = effective_width / 2.0
		radius = (half_width * half_width + arc_height * arc_height) / (2.0 * arc_height)
		arc_center_y_offset = radius - arc_height
	
	# --- 步骤 4: 计算手牌基线和圆心位置 ---
	var chord_center_pos = (zone_rect.size * arc_center_anchor) + arc_center_margin
	var arc_center_pos = chord_center_pos + Vector2(0, arc_center_y_offset)

	# --- 步骤 5: 遍历幻影列表，为原始对象生成变换信息 ---
	var start_x = (container_width - effective_width) / 2.0
	var center_index = (item_count - 1) / 2.0

	for i in range(item_count):
		var p_item = phantom_list[i]
		
		if p_item == ghost_placeholder:
			continue

		var pivot_offset = item_size * card_pivot_anchor
		var chord_x = start_x + i * x_step
		var x_from_center = chord_x - container_width / 2.0 + (item_size.x - x_step) / 2.0
		
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

		var item_rotation = rad_to_deg(current_angle_rad) if item_rotate else 0.0
		var distance_from_center = abs(i - center_index)
		var z_index = i

		var item_scale = Vector2.ONE
		if p_item.size.x > 0 and p_item.size.y > 0:
			item_scale = item_size / p_item.size

		transforms[p_item] = {
			"position": item_pivot_pos,
			"rotation_degrees": item_rotation,
			"scale": item_scale,
			"z_index": z_index,
			"pivot_offset": pivot_offset
		}
		
	if is_instance_valid(ghost_placeholder):
		ghost_placeholder.queue_free()
		
	return transforms


func get_drop_index_at_position(position: Vector2, items: Array[Control], zone_rect: Rect2) -> int:
	if items.is_empty():
		return 0

	var item_count = items.size()
	var container_width = zone_rect.size.x
	
	var natural_width = item_size.x * item_count - item_overlap * (item_count - 1)
	var effective_width = min(natural_width, container_width)
	
	var x_step: float = (effective_width - item_size.x) / (item_count - 1) if item_count > 1 else 0
	var start_x = (container_width - effective_width) / 2.0
	
	var local_mouse_x = position.x
	
	# 检查是否在第一个卡牌之前
	if local_mouse_x < start_x + x_step / 2.0:
		return 0
	
	# 检查是否在最后一个卡牌之后
	if local_mouse_x > start_x + (item_count - 1) * x_step + x_step / 2.0:
		return item_count
	
	# 计算最接近的插入位置
	var index = roundi((local_mouse_x - start_x) / x_step)
	
	return clamp(index, 0, item_count)
