extends Control

# --- 内部类：模拟卡牌 ---
# 在实际项目中，这应该是一个独立的 Card.tscn
class DemoCard extends ColorRect:
	func _init(lbl_text: String, size_vec: Vector2):
		custom_minimum_size = size_vec
		size = size_vec
		color = Color(randf(), randf(), randf()) # 随机颜色
		
		var label = Label.new()
		label.text = lbl_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(label)
		
		# --- 关键：设置 Ghost 占位符 ---
		# 这里我们在代码中动态生成一个 PackedScene 作为 Ghost
		# 实际项目中，你应该 preload("res://GhostCard.tscn")
		var ghost_root = ColorRect.new()
		ghost_root.color = Color(1, 1, 1, 0.2) # 半透明白色
		ghost_root.custom_minimum_size = size_vec
		ghost_root.mouse_filter = Control.MOUSE_FILTER_IGNORE # 必须忽略鼠标
		
		var packed_ghost = PackedScene.new()
		packed_ghost.pack(ghost_root)
		
		set_meta("zone_ghost_scene", packed_ghost)

@onready var board_panel: Panel = $BoardPanel
@onready var hand_panel: Panel = $HandPanel

func _ready():
	var hand_zone = _create_zone(hand_panel, "HandZone")
	# 配置手牌布局
	var hand_layout = ZoneHandLayout.new()
	hand_layout.arch_angle_deg = 40
	hand_layout.arch_height = 30
	hand_layout.center_offset_y = 400 # 圆心在屏幕下方更远
	hand_zone.layout = hand_layout
	
	var board_zone = _create_zone(board_panel, "BoardZone")
	# 配置垂直布局
	var board_layout = ZoneVBoxLayout.new()
	board_layout.item_spacing = 15
	board_layout.padding_top = 20
	board_zone.layout = board_layout
	
	# 3. 添加卡牌到手牌区
	for i in range(5):
		var card = DemoCard.new("Card " + str(i+1), Vector2(100, 150))
		hand_panel.add_child(card)

# --- 辅助函数：快速创建 Zone ---
func _create_zone(container: Control, zone_name: String) -> Zone:
	var zone = Zone.new()
	zone.name = zone_name
	# 链接容器
	zone.container = container
	container.add_child(zone) # Zone 作为 Container 的子节点 (也可以是兄弟节点)
	
	# 配置通用模块
	zone.display = ZoneTweenDisplay.new()
	zone.interaction = ZoneCardInteraction.new()
	zone.sort = ZoneManualSort.new()
	zone.permission = ZoneAllowAllPermission.new()
	
	return zone
