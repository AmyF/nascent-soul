@tool
class_name BattlefieldZone extends Zone

func _ready() -> void:
	if space_model == null:
		space_model = ZoneSquareGridSpaceModel.new()
	if layout_policy == null:
		layout_policy = ZoneBattlefieldLayout.new()
	super._ready()

func place_item_at(item: Control, target: ZonePlacementTarget) -> bool:
	return add_item(item, target)

func move_item_to_target(item: Control, target_zone: Zone, target: ZonePlacementTarget) -> bool:
	return move_item_to(item, target_zone, target)

func get_item_cell(item: Control) -> ZonePlacementTarget:
	return get_item_target(item)
