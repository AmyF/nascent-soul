@tool
class_name ZoneConfig extends Resource

@export_group("Policies")
@export var space_model: ZoneSpaceModel
@export var layout_policy: ZoneLayoutPolicy
@export var display_style: ZoneDisplayStyle
@export var interaction: ZoneInteraction
@export var sort_policy: ZoneSortPolicy
@export var transfer_policy: ZoneTransferPolicy
@export var targeting_style: ZoneTargetingStyle
@export var targeting_policy: ZoneTargetingPolicy

@export_group("Drag Visuals")
@export var drag_visual_factory: ZoneDragVisualFactory

func duplicate_config():
	var duplicated = get_script().new()
	duplicated.space_model = space_model
	duplicated.layout_policy = layout_policy
	duplicated.display_style = display_style
	duplicated.interaction = interaction
	duplicated.sort_policy = sort_policy
	duplicated.transfer_policy = transfer_policy
	duplicated.targeting_style = targeting_style
	duplicated.targeting_policy = targeting_policy
	duplicated.drag_visual_factory = drag_visual_factory
	return duplicated
