@tool
class_name TargetingSpellCard extends ZoneCard

const ZonePieceScript = preload("res://addons/nascentsoul/pieces/zone_piece.gd")
const ZoneTargetRuleTablePolicyScript = preload("res://addons/nascentsoul/impl/targeting/zone_target_rule_table_policy.gd")
const ZoneTargetRuleScript = preload("res://addons/nascentsoul/impl/targeting/zone_target_rule.gd")

const CARD_SIZE := Vector2(120, 180)
const FRONT_TEXTURE := preload("res://assets/card/card_front.png")
const BACK_TEXTURE := preload("res://assets/card/card_back.png")

@export var spell_name: String = "Meteor"
@export var enemy_meta_key: String = "target_team"
@export var enemy_meta_value: String = "enemy"
@export var ally_meta_value: String = "ally"
@export var ally_reject_reason: String = "This spell only targets enemies."

func create_zone_targeting_intent(_source_zone: Zone, _entry_mode: StringName) -> ZoneTargetingIntent:
	var intent := ZoneTargetingIntent.new()
	intent.allowed_candidate_kinds = PackedInt32Array([ZoneTargetCandidate.CandidateKind.ITEM])
	intent.policy = _make_targeting_policy()
	intent.metadata = {
		"spell_name": _resolve_spell_name()
	}
	return intent

static func create_demo_card(title: String, cost: int, tags: Array = ["spell"]) -> TargetingSpellCard:
	var card := TargetingSpellCard.new()
	var normalized_tags := PackedStringArray()
	for tag in tags:
		normalized_tags.append(str(tag))
	var data := CardData.new()
	data.id = title.to_lower().replace(" ", "_")
	data.title = title
	data.cost = cost
	data.tags = normalized_tags
	data.front_texture = FRONT_TEXTURE
	data.back_texture = BACK_TEXTURE
	data.custom_data = {
		"cost": cost,
		"tags": normalized_tags
	}
	card.name = title
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	card.data = data
	card.face_up = true
	card.spell_name = title
	card.set_meta("example_cost", cost)
	card.set_meta("example_tags", normalized_tags)
	card.set_meta("example_primary_tag", normalized_tags[0] if not normalized_tags.is_empty() else "spell")
	return card

func _make_targeting_policy() -> ZoneTargetingPolicy:
	var reject_allies := ZoneTargetRuleScript.new()
	reject_allies.target_candidate_kind = ZoneTargetCandidate.CandidateKind.ITEM
	reject_allies.target_item_script = ZonePieceScript
	reject_allies.required_candidate_meta_key = enemy_meta_key
	reject_allies.required_candidate_meta_value = ally_meta_value
	reject_allies.allowed = false
	reject_allies.reject_reason = ally_reject_reason

	var allow_enemies := ZoneTargetRuleScript.new()
	allow_enemies.target_candidate_kind = ZoneTargetCandidate.CandidateKind.ITEM
	allow_enemies.target_item_script = ZonePieceScript
	allow_enemies.required_candidate_meta_key = enemy_meta_key
	allow_enemies.required_candidate_meta_value = enemy_meta_value

	var rule_table := ZoneTargetRuleTablePolicyScript.new()
	var rules: Array[ZoneTargetRule] = [reject_allies, allow_enemies]
	rule_table.rules = rules
	return rule_table

func _resolve_spell_name() -> String:
	if spell_name != "":
		return spell_name
	if data != null and data.title != "":
		return data.title
	return name
