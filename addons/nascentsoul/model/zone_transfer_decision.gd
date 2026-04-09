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
