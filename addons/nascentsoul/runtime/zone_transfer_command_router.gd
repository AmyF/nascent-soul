class_name ZoneTransferCommandRouter extends RefCounted

const ZoneRuntimePortScript = preload("res://addons/nascentsoul/runtime/zone_runtime_port.gd")

var transfer_service = null
var context: ZoneContext = null
var zone = null
var store: ZoneStore = null

func _init(p_transfer_service, p_context: ZoneContext, p_store: ZoneStore) -> void:
	transfer_service = p_transfer_service
	context = p_context
	zone = context.zone
	store = p_store

func cleanup() -> void:
	store = null
	zone = null
	context = null
	transfer_service = null

func perform_transfer(command: ZoneTransferCommand) -> bool:
	if command == null:
		return false
	match command.kind:
		ZoneTransferCommand.CommandKind.INSERT:
			if command.target_zone != null and command.target_zone != zone:
				return command.target_zone.perform_transfer(command)
			var item = command.primary_item()
			return transfer_service.add_item(item, command.placement_target)
		ZoneTransferCommand.CommandKind.REORDER:
			var owning_zone = command.source_zone if command.source_zone != null else zone
			if owning_zone != zone:
				return owning_zone.perform_transfer(command)
			return transfer_service._reorder_items(command.items, transfer_service.resolve_transfer_target(command.items, command.placement_target))
		_:
			var source_zone = command.source_zone if command.source_zone != null else zone
			if source_zone != zone:
				return source_zone.perform_transfer(command)
			var target_zone = command.target_zone if command.target_zone != null else zone
			if target_zone == zone:
				return transfer_service._reorder_items(command.items, transfer_service.resolve_transfer_target(command.items, command.placement_target))
			return transfer_command_items(target_zone, command.items, command.placement_target, command.global_position)

func transfer_command_items(target_zone: Zone, items: Array[ZoneItemControl], placement_target: ZonePlacementTarget, global_position = null) -> bool:
	if target_zone == null or items.is_empty():
		return false
	var moving_items: Array[ZoneItemControl] = []
	for item in store.items:
		if item in items and is_instance_valid(item):
			moving_items.append(item)
	if moving_items.is_empty():
		return false
	var request_position = global_position if global_position != null else context.resolve_programmatic_transfer_global_position(moving_items)
	var target_context = ZoneRuntimePortScript.resolve_context(target_zone)
	var target_transfer = ZoneRuntimePortScript.resolve_transfer_service(target_zone)
	if target_context == null or target_transfer == null:
		return false
	var requested_target = target_transfer.resolve_transfer_target(moving_items, placement_target)
	var request = transfer_service.make_transfer_request(target_zone, zone, moving_items, requested_target, request_position)
	var decision = target_transfer.resolve_drop_decision(request)
	if not decision.allowed:
		target_transfer.emit_drop_rejected_items(moving_items, zone, decision.reason)
		return false
	return transfer_service._transfer_items_to(target_zone, moving_items, decision.resolved_target, request.global_position, zone, decision)
