@tool
class_name ZoneCardDisplay extends ZoneTweenDisplay

@export var hovered_scale: float = 1.08
@export var selected_scale: float = 1.04
@export var hovered_lift: float = 18.0
@export var selected_lift: float = 8.0

func apply(zone: Node, runtime, placements: Array[ZonePlacement]) -> void:
	var adjusted: Array[ZonePlacement] = []
	for managed_item in runtime.get_items():
		if managed_item != null and managed_item.has_method("set_hovered_visual"):
			managed_item.call("set_hovered_visual", false)
		if managed_item != null and managed_item.has_method("set_selected_visual"):
			managed_item.call("set_selected_visual", false)
	for placement in placements:
		var item = placement.item
		var adjusted_placement = ZonePlacement.new(item, placement.position, placement.rotation, placement.scale, placement.z_index, placement.instant)
		var is_hovered = runtime.selection_state.hovered_item == item
		var is_selected = runtime.selection_state.is_selected(item)
		if item != null and item.has_method("set_hovered_visual"):
			item.call("set_hovered_visual", is_hovered)
		if item != null and item.has_method("set_selected_visual"):
			item.call("set_selected_visual", is_selected)
		if not adjusted_placement.instant:
			if is_hovered:
				adjusted_placement.scale *= hovered_scale
				adjusted_placement.position += Vector2(0, -hovered_lift)
				adjusted_placement.z_index += 100
			elif is_selected:
				adjusted_placement.scale *= selected_scale
				adjusted_placement.position += Vector2(0, -selected_lift)
				adjusted_placement.z_index += 60
		adjusted.append(adjusted_placement)
	super.apply(zone, runtime, adjusted)
