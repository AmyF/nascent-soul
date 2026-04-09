@tool
class_name ZoneTransferRule extends Resource

@export var source_zone_name: String = ""
@export var source_item_script: Script
@export var required_item_meta_key: String = ""
@export var required_item_meta_value: String = ""
@export var target_kind: ZonePlacementTarget.TargetKind = ZonePlacementTarget.TargetKind.NONE
@export var transfer_mode: ZoneTransferDecision.TransferMode = ZoneTransferDecision.TransferMode.DIRECT_PLACE
@export var spawn_scene: PackedScene
@export var reject_reason: String = ""
@export var allowed: bool = true

func matches(request: ZoneTransferRequest) -> bool:
	if request == null:
		return false
	if source_zone_name != "":
		var source_zone = request.source_zone as Zone
		if source_zone == null or source_zone.name != source_zone_name:
			return false
	if target_kind != ZonePlacementTarget.TargetKind.NONE:
		if request.placement_target == null or request.placement_target.kind != target_kind:
			return false
	if request.items.is_empty():
		return false
	for item in request.items:
		if not _matches_item(item):
			return false
	return true

func build_decision(request: ZoneTransferRequest) -> ZoneTransferDecision:
	var target = request.placement_target.duplicate_target() if request.placement_target != null else ZonePlacementTarget.invalid()
	return ZoneTransferDecision.new(allowed, reject_reason if not allowed else "", target, transfer_mode, spawn_scene)

func _matches_item(item: Control) -> bool:
	if not is_instance_valid(item):
		return false
	if source_item_script != null and item.get_script() != source_item_script:
		return false
	if required_item_meta_key != "":
		if not item.has_meta(required_item_meta_key):
			return false
		if required_item_meta_value != "" and str(item.get_meta(required_item_meta_key)) != required_item_meta_value:
			return false
	return true
