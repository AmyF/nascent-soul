@tool
class_name CardZone extends Zone

func _ready() -> void:
	if config == null:
		config = _build_default_card_config()
	super._ready()

func _build_default_card_config() -> ZoneConfig:
	var resolved := ZoneConfig.new()
	resolved.space_model = ZoneLinearSpaceModel.new()
	var layout := ZoneHandLayout.new()
	layout.arch_angle_deg = 38.0
	layout.arch_height = 26.0
	layout.card_spacing_angle = 5.5
	resolved.layout_policy = layout
	resolved.display_style = ZoneCardDisplay.new()
	resolved.interaction = ZoneInteraction.new()
	resolved.sort_policy = ZoneManualSort.new()
	resolved.transfer_policy = ZoneAllowAllTransferPolicy.new()
	resolved.drag_visual_factory = ZoneConfigurableDragVisualFactory.new()
	resolved.targeting_style = ZoneArrowTargetingStyle.new()
	resolved.targeting_policy = ZoneTargetAllowAllPolicy.new()
	return resolved
