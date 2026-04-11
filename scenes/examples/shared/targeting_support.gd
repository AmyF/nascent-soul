class_name TargetingSupport extends RefCounted

const ExampleItemSupport = preload("res://scenes/examples/shared/example_item_support.gd")
const ZonePieceScript = preload("res://addons/nascentsoul/pieces/zone_piece.gd")
const ZoneTargetRuleTablePolicyScript = preload("res://addons/nascentsoul/impl/targeting/zone_target_rule_table_policy.gd")
const ZoneTargetRuleScript = preload("res://addons/nascentsoul/impl/targeting/zone_target_rule.gd")
const CLASSIC_ARROW_STYLE = preload("res://addons/nascentsoul/presets/targeting/classic_arrow_targeting_style.tres")
const ARCANE_BOLT_STYLE = preload("res://addons/nascentsoul/presets/targeting/arcane_bolt_targeting_style.tres")
const STRIKE_VECTOR_STYLE = preload("res://addons/nascentsoul/presets/targeting/strike_vector_targeting_style.tres")
const TACTICAL_BEAM_STYLE = preload("res://addons/nascentsoul/presets/targeting/tactical_beam_targeting_style.tres")

static func builtin_targeting_style_ids() -> Array:
	return [&"classic", &"arcane", &"strike", &"tactical"]

static func builtin_targeting_style_label(style_id: StringName) -> String:
	match style_id:
		&"arcane":
			return "Arcane Bolt"
		&"strike":
			return "Strike Vector"
		&"tactical":
			return "Tactical Beam"
		_:
			return "Classic Arrow"

static func builtin_targeting_style(index_or_id) -> ZoneTargetingStyle:
	var style_id = _coerce_builtin_style_id(index_or_id)
	var resource: Resource = CLASSIC_ARROW_STYLE
	match style_id:
		&"arcane":
			resource = ARCANE_BOLT_STYLE
		&"strike":
			resource = STRIKE_VECTOR_STYLE
		&"tactical":
			resource = TACTICAL_BEAM_STYLE
		_:
			resource = CLASSIC_ARROW_STYLE
	return resource.duplicate(true) as ZoneTargetingStyle

static func _coerce_builtin_style_id(index_or_id) -> StringName:
	if index_or_id is int:
		var ids = builtin_targeting_style_ids()
		var index = clampi(index_or_id, 0, ids.size() - 1)
		return ids[index]
	if index_or_id is StringName:
		return index_or_id
	if index_or_id is String:
		return StringName(index_or_id)
	return &"classic"

static func make_spell_card(title: String, cost: int = 2, tags: Array = ["spell", "target"]) -> ZoneCard:
	var card = ExampleItemSupport.make_card(title, cost, tags, true)
	card.zone_targeting_intent_override = _make_enemy_spell_intent(title)
	return card

static func make_target_piece(title: String, team: String, attack: int, defense: int) -> ZonePiece:
	var piece = ExampleItemSupport.make_piece(title, team, attack, defense)
	var metadata = piece.get_zone_item_metadata()
	metadata["target_team"] = team
	piece.set_zone_item_metadata(metadata)
	piece.set_meta("target_team", team)
	return piece

static func make_square_placement_intent(ability_name: String) -> ZoneTargetingIntent:
	var allow_square := ZoneTargetRuleScript.new()
	allow_square.target_candidate_kind = ZoneTargetCandidate.CandidateKind.PLACEMENT
	allow_square.placement_target_kind = ZonePlacementTarget.TargetKind.SQUARE
	var policy := ZoneTargetRuleTablePolicyScript.new()
	var rules: Array[ZoneTargetRule] = [allow_square]
	policy.rules = rules
	var intent := ZoneTargetingIntent.new()
	intent.allowed_candidate_kinds = PackedInt32Array([ZoneTargetCandidate.CandidateKind.PLACEMENT])
	intent.policy = policy
	intent.metadata = {"ability_name": ability_name}
	return intent

static func make_piece_item_intent(spell_name: String = "Arc") -> ZoneTargetingIntent:
	var allow_piece := ZoneTargetRuleScript.new()
	allow_piece.target_candidate_kind = ZoneTargetCandidate.CandidateKind.ITEM
	allow_piece.target_item_script = ZonePieceScript
	var policy := ZoneTargetRuleTablePolicyScript.new()
	var rules: Array[ZoneTargetRule] = [allow_piece]
	policy.rules = rules
	var intent := ZoneTargetingIntent.new()
	intent.allowed_candidate_kinds = PackedInt32Array([ZoneTargetCandidate.CandidateKind.ITEM])
	intent.policy = policy
	intent.metadata = {"spell_name": spell_name}
	return intent

static func _make_enemy_spell_intent(spell_name: String) -> ZoneTargetingIntent:
	var reject_allies := ZoneTargetRuleScript.new()
	reject_allies.target_candidate_kind = ZoneTargetCandidate.CandidateKind.ITEM
	reject_allies.target_item_script = ZonePieceScript
	reject_allies.required_candidate_meta_key = "target_team"
	reject_allies.required_candidate_meta_value = "ally"
	reject_allies.allowed = false
	reject_allies.reject_reason = "This spell only targets enemies."
	var allow_enemies := ZoneTargetRuleScript.new()
	allow_enemies.target_candidate_kind = ZoneTargetCandidate.CandidateKind.ITEM
	allow_enemies.target_item_script = ZonePieceScript
	allow_enemies.required_candidate_meta_key = "target_team"
	allow_enemies.required_candidate_meta_value = "enemy"
	var policy := ZoneTargetRuleTablePolicyScript.new()
	var rules: Array[ZoneTargetRule] = [reject_allies, allow_enemies]
	policy.rules = rules
	var intent := ZoneTargetingIntent.new()
	intent.allowed_candidate_kinds = PackedInt32Array([ZoneTargetCandidate.CandidateKind.ITEM])
	intent.policy = policy
	intent.metadata = {"spell_name": spell_name}
	return intent
