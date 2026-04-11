extends RefCounted

const ExampleZoneSupport = preload("res://scenes/examples/shared/example_zone_support.gd")
const FreeCellCardScript = preload("res://scenes/examples/freecell/freecell_card.gd")
const FreeCellZonePolicyScript = preload("res://scenes/examples/freecell/freecell_zone_policy.gd")

var _tableau_zones: Array[Zone] = []
var _free_cell_zones: Array[Zone] = []
var _foundation_zones: Array[Zone] = []
var _zone_info: Dictionary = {}

func build(
	free_cells_row: Control,
	foundations_row: Control,
	tableau_row: Control,
	policy_controller: Object,
	bind_zone_events: Callable
) -> void:
	if not _tableau_zones.is_empty():
		return
	_free_cell_zones = _collect_scene_zones(free_cells_row, &"freecell", policy_controller, bind_zone_events)
	_foundation_zones = _collect_scene_zones(foundations_row, &"foundation", policy_controller, bind_zone_events)
	_tableau_zones = _collect_scene_zones(tableau_row, &"tableau", policy_controller, bind_zone_events)

func clear_policy_controllers() -> void:
	for policy in _collect_zone_policies():
		policy.controller = null

func get_zone_info() -> Dictionary:
	return _zone_info

func tableau_zones_ref() -> Array[Zone]:
	return _tableau_zones

func free_cell_zones_ref() -> Array[Zone]:
	return _free_cell_zones

func foundation_zones_ref() -> Array[Zone]:
	return _foundation_zones

func get_tableau_zones() -> Array[Zone]:
	return _tableau_zones.duplicate()

func get_free_cell_zones() -> Array[Zone]:
	return _free_cell_zones.duplicate()

func get_foundation_zones() -> Array[Zone]:
	return _foundation_zones.duplicate()

func all_zones_ref() -> Array[Zone]:
	var zones: Array[Zone] = []
	zones.append_array(_free_cell_zones)
	zones.append_array(_foundation_zones)
	zones.append_array(_tableau_zones)
	return zones

func get_card_by_code(code: String) -> Control:
	for zone in all_zones_ref():
		for item in zone.get_items():
			if item is FreeCellCardScript and (item as FreeCellCardScript).code == code:
				return item
	return null

func role_of(zone: Zone) -> StringName:
	return StringName(_zone_info.get(zone, {}).get("role", &""))

func display_name(zone: Zone) -> String:
	if zone == null:
		return "Unknown"
	var info = _zone_info.get(zone, {})
	var role = StringName(info.get("role", &""))
	var index = int(info.get("index", 0)) + 1
	match role:
		&"freecell":
			return "Free Cell %d" % index
		&"foundation":
			return "Foundation %d" % index
		&"tableau":
			return "Tableau %d" % index
		_:
			return zone.name

func clear_all_cards() -> void:
	for zone in all_zones_ref():
		zone.clear_selection()
		for item in zone.get_items():
			if zone.remove_item(item):
				item.queue_free()

func clear_selection_all() -> void:
	for zone in all_zones_ref():
		zone.clear_selection()

func _collect_scene_zones(row: Control, role: StringName, policy_controller: Object, bind_zone_events: Callable) -> Array[Zone]:
	var zones: Array[Zone] = []
	for index in range(row.get_child_count()):
		var lane = row.get_child(index)
		if lane is not Node:
			continue
		var zone = (lane as Node).get_node_or_null("ZoneHost") as Zone
		if zone == null:
			continue
		var policy = ExampleZoneSupport.get_zone_transfer_policy(zone)
		if policy is FreeCellZonePolicyScript:
			(policy as FreeCellZonePolicyScript).controller = policy_controller
		_zone_info[zone] = {
			"role": role,
			"index": index
		}
		if bind_zone_events.is_valid():
			bind_zone_events.call(zone)
		zones.append(zone)
	return zones

func _collect_zone_policies() -> Array:
	var policies: Array = []
	for zone in all_zones_ref():
		var policy = ExampleZoneSupport.get_zone_transfer_policy(zone)
		if policy != null and policy not in policies:
			policies.append(policy)
	return policies
