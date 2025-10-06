# ZoneCardDisplay.gd
class_name ZoneCardDisplay
extends ZoneDisplay

## ZoneCardDisplay 是一个专门用于处理 ZoneCard 节点的显示逻辑模块。
## 它将 Zone 传递过来的通用状态（如 is_hovered, is_selected）
## 翻译成 ZoneCard 能够理解的具体指令（如 set_highlight, set_face_up）。


#=============================================================================
# 1. 导出属性 (Inspector配置)
#=============================================================================

## 控制该区域的卡牌是否默认显示为背面。
@export var show_as_backside: bool = false
## 控制鼠标悬停时是否高亮卡牌。
@export var highlight_on_hover: bool = true
## 控制卡牌被选中时是否高亮。
@export var highlight_on_select: bool = true
## 当鼠标悬停在一张背面的牌上时，是否临时将其翻开以供预览。
@export var face_up_on_hover: bool = false


#=============================================================================
# 2. 核心方法 (重写基类方法)
#=============================================================================

## 为单个 Control 对象应用其最终的视觉状态。
## 这是连接通用框架与具体游戏对象的桥梁。
func apply_display_state(item: Control, state_info: Dictionary):
	# 步骤 1: 安全地将 Control 转换为 ZoneCard 类型。
	# 如果传入的 item 不是 ZoneCard，则忽略，以保证健壮性。
	var card = item as ZoneCard
	if not card:
		return

	# 步骤 2: 从 state_info 中获取动态状态信息。
	# 使用 .get() 并提供默认值，以防万一 key 不存在。
	var is_hovered: bool = state_info.get("is_hovered", false)
	var is_selected: bool = state_info.get("is_selected", false)
	
	# 步骤 3: 组合高亮逻辑。
	# 当“悬停时高亮”或“选中时高亮”的条件满足时，就应该高亮。
	var should_highlight = false
	if highlight_on_hover and is_hovered:
		should_highlight = true
	if highlight_on_select and is_selected:
		should_highlight = true
	
	card.set_highlight(should_highlight)
	
	# 步骤 4: 组合翻面逻辑。
	# 默认的翻面状态由 show_as_backside 决定。
	var should_be_face_up = not show_as_backside
	# 如果“悬停时翻开”功能启用，并且鼠标正悬停在上面，则覆盖默认状态。
	if face_up_on_hover and is_hovered:
		should_be_face_up = true
		
	card.set_face_up(should_be_face_up)
