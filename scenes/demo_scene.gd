extends Control

const CardScene = preload("res://addons/nascentsoul/card/zone_card.tscn")

@onready var table: Control = $Table

@onready var deck_zone: Zone = $Table/DeckContainer/DeckZone
@onready var hand_zone: Zone = $Table/HandContainer/HandZone
@onready var discard_zone: Zone = $Table/DiscardContainer/DiscardZone

@onready var draw_button: Button = $UI/DrawButton
@onready var discard_button: Button = $UI/DiscardButton

func _ready() -> void:
	for i in range(20):
		var new_card = CardScene.instantiate() as ZoneCard
		new_card.name = "Card_" + str(i + 1)
		new_card.z_index = 1
		if deck_zone.add_item(new_card):
			table.add_child(new_card)
		else:
			print("未能加入卡牌：", new_card.name)


func _on_draw_button_pressed() -> void:
	if deck_zone.managed_items.is_empty():
		print("空卡组！")
		return
	
	var top_card = deck_zone.managed_items.back()
	var success = deck_zone.transfer_item_to(top_card, hand_zone)
	if not success:
		print("无法抽卡！")


func _on_discard_button_pressed() -> void:
	if hand_zone.selected_items.is_empty():
		print("没有选中的手牌！")
		return
	
	for card_to_discard in hand_zone.selected_items:
		hand_zone.transfer_item_to(card_to_discard, discard_zone)


func _on_hand_zone_item_dropped(item: Control, zone) -> void:
	var mouse_pos = get_global_mouse_position()

	if discard_zone.container.get_global_rect().has_point(mouse_pos):
		var drop_index = discard_zone.get_drop_index_at_global_pos(mouse_pos)
		print("通过拖拽弃牌: %s, 插入到索引: %d" % [item.name, drop_index])
		hand_zone.transfer_item_to(item, discard_zone, drop_index)
	elif zone == hand_zone and hand_zone.container.get_global_rect().has_point(mouse_pos):
		var drop_index = hand_zone.get_drop_index_at_global_pos(mouse_pos)
		hand_zone.reorder_item(item, drop_index)
	else:
		print("无效拖拽。")
