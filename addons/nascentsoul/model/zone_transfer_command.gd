class_name ZoneTransferCommand extends RefCounted

# Public command contract for programmatic inserts, reorders, and transfers.

enum CommandKind {
	INSERT,
	TRANSFER,
	REORDER
}

var kind: CommandKind = CommandKind.TRANSFER
var source_zone = null
var target_zone = null
var items: Array[ZoneItemControl] = []
var placement_target: ZonePlacementTarget = null
var global_position = null

func _init(
	p_kind: CommandKind = CommandKind.TRANSFER,
	p_source_zone = null,
	p_target_zone = null,
	p_items: Array[ZoneItemControl] = [],
	p_placement_target: ZonePlacementTarget = null,
	p_global_position = null
) -> void:
	kind = p_kind
	source_zone = p_source_zone
	target_zone = p_target_zone
	items = p_items.duplicate()
	placement_target = p_placement_target.duplicate_target() if p_placement_target != null else null
	global_position = p_global_position

static func insert_into(target, item, placement_target: ZonePlacementTarget = null):
	var items: Array[ZoneItemControl] = []
	if is_instance_valid(item):
		items.append(item)
	return load("res://addons/nascentsoul/model/zone_transfer_command.gd").new(CommandKind.INSERT, null, target, items, placement_target)

static func transfer_between(
	source,
	target,
	p_items: Array[ZoneItemControl],
	placement_target: ZonePlacementTarget = null,
	p_global_position = null
):
	return load("res://addons/nascentsoul/model/zone_transfer_command.gd").new(CommandKind.TRANSFER, source, target, p_items, placement_target, p_global_position)

static func reorder_within(zone, p_items: Array[ZoneItemControl], placement_target: ZonePlacementTarget = null):
	return load("res://addons/nascentsoul/model/zone_transfer_command.gd").new(CommandKind.REORDER, zone, zone, p_items, placement_target)

func duplicate_command():
	return get_script().new(kind, source_zone, target_zone, items, placement_target, global_position)

func primary_item() -> ZoneItemControl:
	return items[0] if not items.is_empty() else null
