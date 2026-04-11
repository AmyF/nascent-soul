extends "res://addons/nascentsoul/resources/zone_item_spawn_factory.gd"
class_name ZoneCardToPieceSpawnFactory

const ZonePieceScript = preload("res://addons/nascentsoul/pieces/zone_piece.gd")

func create_spawned_item(
	source_item,
	_context,
	_decision,
	_placement_target
):
	if source_item == null:
		return null
	var piece := ZonePieceScript.new()
	var source_data = source_item.data
	piece.name = "%sPiece" % (source_data.title if source_data != null and source_data.title != "" else source_item.name)
	piece.custom_minimum_size = Vector2(92, 92)
	piece.size = piece.custom_minimum_size
	var piece_data := PieceData.new()
	if source_data != null:
		piece_data.id = source_data.id
		piece_data.title = source_data.title
		piece_data.texture = source_data.front_texture
		piece_data.attack = source_data.cost
		piece_data.defense = max(1, source_data.tags.size())
		piece_data.custom_data = source_data.custom_data.duplicate(true)
		piece.data = piece_data
	return piece

func configure_spawned_item(
	source_item,
	spawned_item,
	context,
	placement_target
) -> void:
	if spawned_item != null and spawned_item.has_method("configure_from_transfer_source"):
		spawned_item.configure_from_transfer_source(source_item, context, placement_target)
