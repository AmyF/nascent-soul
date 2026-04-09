class_name ZoneTransferDecision extends RefCounted

enum TransferMode {
	DIRECT_PLACE,
	SPAWN_PIECE
}

var allowed: bool = true
var reason: String = ""
var resolved_target: ZonePlacementTarget = null
var transfer_mode: TransferMode = TransferMode.DIRECT_PLACE
var spawn_scene: PackedScene = null
var metadata: Dictionary = {}

var target_index: int:
	get:
		if resolved_target == null or not resolved_target.is_linear():
			return -1
		return resolved_target.slot
	set(value):
		if value < 0:
			resolved_target = ZonePlacementTarget.invalid()
			return
		var existing_global = resolved_target.global_position if resolved_target != null else Vector2.ZERO
		var existing_local = resolved_target.local_position if resolved_target != null else Vector2.ZERO
		resolved_target = ZonePlacementTarget.linear(value, existing_global, existing_local)

func _init(
	p_allowed: bool = true,
	p_reason: String = "",
	p_resolved_target: ZonePlacementTarget = null,
	p_transfer_mode: TransferMode = TransferMode.DIRECT_PLACE,
	p_spawn_scene: PackedScene = null,
	p_metadata: Dictionary = {}
) -> void:
	allowed = p_allowed
	reason = p_reason
	resolved_target = p_resolved_target.duplicate_target() if p_resolved_target != null else ZonePlacementTarget.invalid()
	transfer_mode = p_transfer_mode
	spawn_scene = p_spawn_scene
	metadata = p_metadata.duplicate(true)

func duplicate_decision() -> ZoneTransferDecision:
	return ZoneTransferDecision.new(allowed, reason, resolved_target, transfer_mode, spawn_scene, metadata)
