extends RefCounted

# Internal helper that keeps editor-only warning rules out of Zone.gd's public
# surface.

static func build(zone: Zone, context: ZoneContext, is_expected_direct_child: Callable) -> PackedStringArray:
	var warnings := PackedStringArray()
	if zone == null or context == null:
		return warnings
	var resolved_space = context.get_space_model()
	var resolved_layout = context.get_layout_policy()
	var resolved_display = context.get_display_style()
	if zone is CardZone and not _is_linear_space_model(resolved_space):
		warnings.append("CardZone expects ZoneLinearSpaceModel semantics. Use a linear card-zone preset, or switch this node to BattlefieldZone if it should target a board.")
	if zone is BattlefieldZone and not _is_battlefield_space_model(resolved_space):
		warnings.append("BattlefieldZone expects a square or hex grid space model. Use a battlefield preset, or switch this node to CardZone/Zone if the items should stay in a linear lane.")
	if resolved_layout is ZoneBattlefieldLayout and not _is_battlefield_space_model(resolved_space):
		warnings.append("ZoneBattlefieldLayout expects ZoneSquareGridSpaceModel or ZoneHexGridSpaceModel. Pair battlefield layouts with a board-style space model.")
	if _is_linear_layout(resolved_layout) and _is_battlefield_space_model(resolved_space):
		warnings.append("Hand, pile, and row layouts expect ZoneLinearSpaceModel. Pair linear card layouts with CardZone or a linear Zone config instead of a battlefield grid.")
	if zone.clip_contents and (resolved_layout is ZoneHandLayout or resolved_layout is ZonePileLayout or resolved_display is ZoneCardDisplay):
		warnings.append("Zone clips its children. Hover lift, drag previews, and pile overlap may be cut off.")
	if zone.size != Vector2.ZERO:
		if resolved_layout is ZoneHandLayout and (resolved_layout as ZoneHandLayout).would_escape_container(zone.size):
			warnings.append("The current hand layout values push cards outside the zone. Reduce arch settings or use a taller zone.")
		if resolved_layout is ZonePileLayout and (resolved_layout as ZonePileLayout).would_escape_container(zone.size):
			warnings.append("The current pile layout values push cards outside the zone. Reduce overlap or increase the zone size.")
	for child in zone.get_children():
		if is_expected_direct_child.is_valid() and is_expected_direct_child.call(child):
			continue
		if child is Control:
			warnings.append("Direct child '%s' is not managed. Put zone items under ItemsRoot instead of attaching them directly to Zone." % child.name)
			break
	return warnings

static func _is_linear_layout(layout: ZoneLayoutPolicy) -> bool:
	return layout is ZoneHBoxLayout or layout is ZoneHandLayout or layout is ZonePileLayout

static func _is_linear_space_model(space_model: ZoneSpaceModel) -> bool:
	return space_model is ZoneLinearSpaceModel

static func _is_battlefield_space_model(space_model: ZoneSpaceModel) -> bool:
	return space_model is ZoneSquareGridSpaceModel or space_model is ZoneHexGridSpaceModel
