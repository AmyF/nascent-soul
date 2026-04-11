extends "res://scenes/tests/shared/test_harness.gd"

const MAIN_MENU_SCENE = preload("res://scenes/main_menu.tscn")
const DEMO_SCENE = preload("res://scenes/demo.tscn")
const TRANSFER_SCENE = preload("res://scenes/examples/transfer_playground.tscn")
const POLICY_SCENE = preload("res://scenes/examples/policy_lab.tscn")
const LAYOUT_SCENE = preload("res://scenes/examples/layout_gallery.tscn")
const RECIPES_SCENE = preload("res://scenes/examples/zone_recipes.tscn")
const BATTLEFIELD_SQUARE_SCENE = preload("res://scenes/examples/battlefield_square_lab.tscn")
const BATTLEFIELD_HEX_SCENE = preload("res://scenes/examples/battlefield_hex_lab.tscn")
const BATTLEFIELD_MODES_SCENE = preload("res://scenes/examples/battlefield_transfer_modes.tscn")
const TARGETING_SCENE = preload("res://scenes/examples/targeting_lab.tscn")
const FREECELL_SCENE = preload("res://scenes/examples/freecell.tscn")
const XIANGQI_SCENE = preload("res://scenes/examples/xiangqi.tscn")

func _check_card_zone_sample_data(zone: Zone, expected_specs: Array, label: String, require_order: bool = true) -> void:
	_check(zone != null, "%s should expose its serialized card zone" % label)
	if zone == null:
		return
	var items := _get_zone_sample_items(zone)
	_check(items.size() == expected_specs.size(), "%s should keep %d serialized sample cards" % [label, expected_specs.size()])
	if require_order:
		for index in range(min(items.size(), expected_specs.size())):
			_check_card_sample(items[index] as ZoneCard, expected_specs[index], "%s card %d" % [label, index + 1])
		return
	for expected in expected_specs:
		var expected_title := str(expected.get("title", ""))
		var matched := _find_item_by_title(zone, expected_title) as ZoneCard
		_check(matched != null, "%s should keep sample card %s" % [label, expected_title])
		if matched != null:
			_check_card_sample(matched, expected, "%s sample %s" % [label, expected_title])

func _check_card_sample(card: ZoneCard, expected: Dictionary, label: String) -> void:
	_check(card != null, "%s should stay a ZoneCard" % label)
	if card == null:
		return
	_check(card.data != null, "%s should keep serialized CardData" % label)
	if card.data == null:
		return
	var expected_title := str(expected.get("title", ""))
	var expected_cost := int(expected.get("cost", 0))
	var expected_tags: Array = expected.get("tags", [])
	_check(card.data.title == expected_title, "%s should preserve title %s" % [label, expected_title])
	_check(card.name == expected_title, "%s should keep node name aligned with title %s" % [label, expected_title])
	_check(card.data.cost == expected_cost, "%s should preserve cost %d" % [label, expected_cost])
	_check(card.data.custom_data.get("cost") == expected_cost, "%s should preserve serialized custom cost data" % label)
	_check(card.data.tags.size() == expected_tags.size(), "%s should preserve all serialized tags" % label)
	for tag in expected_tags:
		_check(card.data.tags.has(str(tag)), "%s should preserve tag %s" % [label, str(tag)])
	var metadata = card.get_zone_item_metadata()
	var metadata_tags := _to_packed_string_array(metadata.get("example_tags", PackedStringArray()))
	_check(metadata.get("example_cost") == expected_cost, "%s should preserve example_cost metadata" % label)
	_check(metadata_tags.size() == expected_tags.size(), "%s should preserve example_tags metadata" % label)
	for tag in expected_tags:
		_check(metadata_tags.has(str(tag)), "%s should preserve example tag metadata %s" % [label, str(tag)])
	if not expected_tags.is_empty():
		_check(metadata.get("example_primary_tag") == str(expected_tags[0]), "%s should preserve example_primary_tag metadata" % label)

func _check_piece_zone_sample_data(zone: Zone, expected_specs: Array, label: String, require_order: bool = true) -> void:
	_check(zone != null, "%s should expose its serialized piece zone" % label)
	if zone == null:
		return
	var items := _get_zone_sample_items(zone)
	_check(items.size() == expected_specs.size(), "%s should keep %d serialized sample pieces" % [label, expected_specs.size()])
	if require_order:
		for index in range(min(items.size(), expected_specs.size())):
			_check_piece_sample(items[index] as ZonePiece, expected_specs[index], "%s piece %d" % [label, index + 1])
		return
	for expected in expected_specs:
		var expected_title := str(expected.get("title", ""))
		var matched := _find_item_by_title(zone, expected_title) as ZonePiece
		_check(matched != null, "%s should keep sample piece %s" % [label, expected_title])
		if matched != null:
			_check_piece_sample(matched, expected, "%s sample %s" % [label, expected_title])

func _check_piece_sample(piece: ZonePiece, expected: Dictionary, label: String) -> void:
	_check(piece != null, "%s should stay a ZonePiece" % label)
	if piece == null:
		return
	_check(piece.data != null, "%s should keep serialized PieceData" % label)
	if piece.data == null:
		return
	var expected_title := str(expected.get("title", ""))
	var expected_team := str(expected.get("team", ""))
	var expected_attack := int(expected.get("attack", 0))
	var expected_defense := int(expected.get("defense", 0))
	_check(piece.data.title == expected_title, "%s should preserve title %s" % [label, expected_title])
	_check(piece.name == expected_title, "%s should keep node name aligned with title %s" % [label, expected_title])
	_check(piece.data.team == expected_team, "%s should preserve team %s" % [label, expected_team])
	_check(piece.data.attack == expected_attack, "%s should preserve attack %d" % [label, expected_attack])
	_check(piece.data.defense == expected_defense, "%s should preserve defense %d" % [label, expected_defense])
	var metadata = piece.get_zone_item_metadata()
	_check(metadata.get("target_team") == expected_team, "%s should preserve target_team metadata" % label)
	_check(metadata.get("piece_team") == expected_team, "%s should preserve piece_team metadata" % label)
	_check(metadata.get("piece_attack") == expected_attack, "%s should preserve piece_attack metadata" % label)
	_check(metadata.get("piece_defense") == expected_defense, "%s should preserve piece_defense metadata" % label)
	if expected.has("square"):
		_check(metadata.get("demo_square") == expected["square"], "%s should preserve demo_square metadata" % label)

func _check_targeting_intent_override(item: ZoneItemControl, metadata_key: String, metadata_value, candidate_kind: int, label: String) -> void:
	_check(item != null and item.zone_targeting_intent_override != null, "%s should serialize a targeting intent override" % label)
	if item == null or item.zone_targeting_intent_override == null:
		return
	var intent = item.zone_targeting_intent_override
	_check(intent.policy != null, "%s should keep a targeting policy on the override" % label)
	_check(intent.metadata.get(metadata_key) == metadata_value, "%s should preserve targeting metadata %s" % [label, metadata_key])
	_check(intent.allowed_candidate_kinds.has(candidate_kind), "%s should preserve allowed candidate kind %d" % [label, candidate_kind])

func _find_item_by_title(zone: Zone, title: String) -> ZoneItemControl:
	if zone == null:
		return null
	for item in _get_zone_sample_items(zone):
		if item == null:
			continue
		if item.name == title:
			return item
		if item is ZoneCard and (item as ZoneCard).data != null and (item as ZoneCard).data.title == title:
			return item
		if item is ZonePiece and (item as ZonePiece).data != null and (item as ZonePiece).data.title == title:
			return item
	return null

func _get_zone_sample_items(zone: Zone) -> Array[ZoneItemControl]:
	var items: Array[ZoneItemControl] = []
	if zone == null:
		return items
	for item in zone.get_items():
		if item != null:
			items.append(item)
	if not items.is_empty():
		return items
	var items_root := zone.get_node_or_null("ItemsRoot")
	if items_root == null:
		return items
	for child in items_root.get_children():
		if child is ZoneItemControl:
			items.append(child as ZoneItemControl)
	return items

func _to_packed_string_array(value) -> PackedStringArray:
	if value is PackedStringArray:
		return value
	if value is Array:
		return PackedStringArray(value)
	return PackedStringArray()

func _get_demo_hub_content_host(scene: Control) -> Control:
	return scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentPanel/ContentHost") as Control if scene != null else null

func _get_demo_hub_current_content(scene: Control) -> Control:
	var content_host = _get_demo_hub_content_host(scene)
	if content_host == null or content_host.get_child_count() == 0:
		return null
	return content_host.get_child(0) as Control

func _assert_demo_hub_transfer_layout(content_host: Control, content: Control, label: String) -> void:
	var visible_rect = content_host.get_global_rect()
	var top_row = content.get_node_or_null("RootMargin/RootVBox/TopRow") as Control
	var hand_label = content.get_node_or_null("RootMargin/RootVBox/HandLabel") as Control
	var hand_zone = content.get_node_or_null("RootMargin/RootVBox/HandZone") as Zone
	var board_zone = content.get_node_or_null("RootMargin/RootVBox/TopRow/BoardColumn/BoardZone") as Zone
	_check(top_row != null and hand_label != null and top_row.get_global_rect().end.y <= hand_label.get_global_rect().position.y + 1.0, "%s should keep the play row above the hand lane" % label)
	_check(hand_zone != null and _rect_inside(visible_rect, hand_zone.get_global_rect(), 4.0), "%s should keep the hand lane inside the visible host" % label)
	_check(board_zone != null and _rect_inside(visible_rect, board_zone.get_global_rect(), 4.0), "%s should keep the board lane inside the visible host" % label)

func _assert_scene_nodes_inside_host(host: Control, scene: Control, node_paths: Array[String], label: String) -> void:
	var visible_rect = host.get_global_rect()
	for node_path in node_paths:
		var control = scene.get_node_or_null(node_path) as Control
		_check(control != null, "%s should expose %s" % [label, node_path])
		if control != null:
			_check(_rect_inside(visible_rect, control.get_global_rect(), 4.0), "%s should keep %s inside the embedded host" % [label, node_path])
