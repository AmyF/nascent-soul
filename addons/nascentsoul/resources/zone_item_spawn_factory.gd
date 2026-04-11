class_name ZoneItemSpawnFactory extends Resource

# Public item-level factory hook for transfer-driven spawning.

func create_spawned_item(
	_source_item,
	_context,
	_decision,
	_placement_target
):
	return null

func configure_spawned_item(
	_source_item,
	_spawned_item,
	_context,
	_placement_target
) -> void:
	pass
