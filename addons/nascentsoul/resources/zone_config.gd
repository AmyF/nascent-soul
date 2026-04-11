@tool
class_name ZoneConfig extends Resource

# Public behavior bundle for a zone. Compose policies, layouts, styles, and
# factories here instead of depending on runtime internals directly.

const CONFIG_FIELDS := [
	"space_model",
	"layout_policy",
	"display_style",
	"interaction",
	"sort_policy",
	"transfer_policy",
	"targeting_style",
	"targeting_policy",
	"drag_visual_factory"
]

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

static func make_card_defaults() -> ZoneConfig:
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

static func make_battlefield_defaults(space_model_override: ZoneSpaceModel = null) -> ZoneConfig:
	var resolved := ZoneConfig.new()
	resolved.space_model = space_model_override if space_model_override != null else ZoneSquareGridSpaceModel.new()
	resolved.layout_policy = ZoneBattlefieldLayout.new()
	resolved.display_style = ZoneCardDisplay.new()
	resolved.interaction = ZoneInteraction.new()
	resolved.transfer_policy = ZoneOccupancyTransferPolicy.new()
	resolved.drag_visual_factory = ZoneConfigurableDragVisualFactory.new()
	resolved.targeting_style = ZoneArrowTargetingStyle.new()
	resolved.targeting_policy = ZoneTargetAllowAllPolicy.new()
	return resolved

func duplicate_config() -> ZoneConfig:
	var duplicated = get_script().new()
	duplicated.copy_from(self)
	return duplicated

func copy_from(other: ZoneConfig, only_missing: bool = false) -> ZoneConfig:
	if other == null:
		return self
	for field_name in CONFIG_FIELDS:
		if only_missing and get(field_name) != null:
			continue
		set(field_name, other.get(field_name))
	return self

func filled_from(fallback: ZoneConfig) -> ZoneConfig:
	var duplicated = duplicate_config()
	duplicated.copy_from(fallback, true)
	return duplicated

func with_overrides(overrides: Dictionary) -> ZoneConfig:
	var duplicated = duplicate_config()
	duplicated.apply_overrides(overrides)
	return duplicated

func apply_overrides(overrides: Dictionary) -> ZoneConfig:
	for raw_key in overrides.keys():
		var field_name := str(raw_key)
		if not CONFIG_FIELDS.has(field_name):
			push_error("ZoneConfig override '%s' is not supported." % field_name)
			continue
		set(field_name, overrides[raw_key])
	return self
