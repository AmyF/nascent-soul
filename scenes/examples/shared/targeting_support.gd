class_name TargetingSupport extends RefCounted

const ExampleSupport = preload("res://scenes/examples/shared/example_support.gd")
const TargetingSpellCardScript = preload("res://scenes/examples/shared/targeting_spell_card.gd")
const ZoneTargetRuleTablePolicyScript = preload("res://addons/nascentsoul/impl/targeting/zone_target_rule_table_policy.gd")
const ZoneTargetRuleScript = preload("res://addons/nascentsoul/impl/targeting/zone_target_rule.gd")

static func make_spell_card(title: String, cost: int = 2, tags: Array = ["spell", "target"]) -> TargetingSpellCard:
	return TargetingSpellCardScript.create_demo_card(title, cost, tags)

static func make_target_piece(title: String, team: String, attack: int, defense: int) -> ZonePiece:
	var piece = ExampleSupport.make_piece(title, team, attack, defense)
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
	allow_piece.target_item_script = preload("res://addons/nascentsoul/pieces/zone_piece.gd")
	var policy := ZoneTargetRuleTablePolicyScript.new()
	var rules: Array[ZoneTargetRule] = [allow_piece]
	policy.rules = rules
	var intent := ZoneTargetingIntent.new()
	intent.allowed_candidate_kinds = PackedInt32Array([ZoneTargetCandidate.CandidateKind.ITEM])
	intent.policy = policy
	intent.metadata = {"spell_name": spell_name}
	return intent
