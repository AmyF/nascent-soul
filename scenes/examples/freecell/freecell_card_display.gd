extends ZoneTweenDisplay

@export var selected_scale: float = 1.01
@export var selected_lift: float = 1.0

func apply(context: ZoneContext, placements: Array[ZonePlacement]) -> void:
	var adjusted: Array[ZonePlacement] = []
	for managed_item in context.get_items():
		if not is_instance_valid(managed_item):
			continue
		var cleared_state = managed_item.get_zone_visual_state()
		cleared_state.hovered = false
		cleared_state.selected = false
		managed_item.apply_zone_visual_state(cleared_state)
	for placement in placements:
		var item = placement.item
		if item != null and not is_instance_valid(item):
			continue
		var adjusted_placement = ZonePlacement.new(item, placement.position, placement.rotation, placement.scale, placement.z_index, placement.instant)
		var selection_state = context.selection_state
		var is_hovered = selection_state != null and selection_state.hovered_item == item
		var is_selected = selection_state != null and item is ZoneItemControl and selection_state.is_selected(item as ZoneItemControl)
		if item is ZoneItemControl:
			var visual_state = (item as ZoneItemControl).get_zone_visual_state()
			visual_state.hovered = is_hovered
			visual_state.selected = is_selected
			(item as ZoneItemControl).apply_zone_visual_state(visual_state)
		if not adjusted_placement.instant and is_selected:
			adjusted_placement.scale *= selected_scale
			adjusted_placement.position += Vector2(0, -selected_lift)
			adjusted_placement.z_index += 60
		adjusted.append(adjusted_placement)
	super.apply(context, adjusted)
