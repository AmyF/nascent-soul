@tool
class_name BattlefieldZone extends Zone

func _ready() -> void:
	if config == null:
		config = _build_default_battlefield_config()
	super._ready()

func _build_default_battlefield_config() -> ZoneConfig:
	var resolved := ZoneConfig.new()
	var space := ZoneSquareGridSpaceModel.new()
	resolved.space_model = space
	resolved.layout_policy = ZoneBattlefieldLayout.new()
	resolved.display_style = ZoneCardDisplay.new()
	resolved.interaction = ZoneInteraction.new()
	resolved.transfer_policy = ZoneOccupancyTransferPolicy.new()
	resolved.drag_visual_factory = ZoneConfigurableDragVisualFactory.new()
	resolved.targeting_style = ZoneArrowTargetingStyle.new()
	resolved.targeting_policy = ZoneTargetAllowAllPolicy.new()
	return resolved
