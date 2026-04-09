class_name ZoneItemVisualState extends RefCounted

var hovered: bool = false
var selected: bool = false
var target_candidate_active: bool = false
var target_candidate_allowed: bool = false

func _init(
	p_hovered: bool = false,
	p_selected: bool = false,
	p_target_candidate_active: bool = false,
	p_target_candidate_allowed: bool = false
) -> void:
	hovered = p_hovered
	selected = p_selected
	target_candidate_active = p_target_candidate_active
	target_candidate_allowed = p_target_candidate_allowed

func duplicate_state():
	return get_script().new(hovered, selected, target_candidate_active, target_candidate_allowed)

func matches(other: ZoneItemVisualState) -> bool:
	if other == null:
		return false
	return hovered == other.hovered \
		and selected == other.selected \
		and target_candidate_active == other.target_candidate_active \
		and target_candidate_allowed == other.target_candidate_allowed
