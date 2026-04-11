class_name ExampleItemSupport extends RefCounted

const CARD_SIZE := Vector2(120, 180)
const PIECE_SIZE := Vector2(92, 92)

static var _front_texture: Texture2D = null
static var _back_texture: Texture2D = null

static func make_card(title: String, cost: int, tags, face_up: bool = true, highlighted: bool = false) -> ZoneCard:
	var normalized_tags := _normalize_tags(tags)
	var data := CardData.new()
	data.id = title.to_lower().replace(" ", "_")
	data.title = title
	data.cost = cost
	data.tags = PackedStringArray(normalized_tags)
	data.front_texture = _load_front_texture()
	data.back_texture = _load_back_texture()
	data.custom_data = {
		"cost": cost,
		"tags": normalized_tags
	}
	var card := ZoneCard.new()
	card.name = title
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	card.data = data
	card.face_up = face_up
	card.highlighted = highlighted
	card.zone_item_metadata = {
		"example_cost": cost,
		"example_tags": normalized_tags,
		"example_primary_tag": normalized_tags[0] if not normalized_tags.is_empty() else "card"
	}
	card.set_meta("example_cost", cost)
	card.set_meta("example_tags", normalized_tags)
	card.set_meta("example_primary_tag", normalized_tags[0] if not normalized_tags.is_empty() else "card")
	return card

static func add_cards_from_specs(zone: Zone, specs: Array, face_up: bool = true, highlighted: bool = false) -> void:
	for spec in specs:
		if spec == null:
			continue
		var title := ""
		var cost := 0
		var tags = []
		if spec is Dictionary:
			title = str(spec.get("title", ""))
			cost = int(spec.get("cost", 0))
			tags = spec.get("tags", [])
		else:
			title = str(spec.get("title"))
			cost = int(spec.get("cost"))
			tags = spec.get("tags")
		zone.add_item(make_card(title, cost, tags, face_up, highlighted))

static func make_piece(title: String, team: String, attack: int, defense: int) -> ZonePiece:
	var data := PieceData.new()
	data.id = title.to_lower().replace(" ", "_")
	data.title = title
	data.team = team
	data.attack = attack
	data.defense = defense
	data.texture = _load_front_texture()
	var piece := ZonePiece.new()
	piece.name = title
	piece.custom_minimum_size = PIECE_SIZE
	piece.size = piece.custom_minimum_size
	piece.data = data
	piece.zone_item_metadata = {
		"target_team": team,
		"piece_team": team,
		"piece_attack": attack,
		"piece_defense": defense
	}
	return piece

static func clear_card_texture_cache() -> void:
	_front_texture = null
	_back_texture = null

static func _load_front_texture() -> Texture2D:
	if _front_texture == null:
		_front_texture = load("res://assets/card/card_front.png")
	return _front_texture

static func _load_back_texture() -> Texture2D:
	if _back_texture == null:
		_back_texture = load("res://assets/card/card_back.png")
	return _back_texture

static func _normalize_tags(tags) -> Array[String]:
	var normalized: Array[String] = []
	if tags is PackedStringArray:
		normalized.assign(tags)
		return normalized
	if tags is Array:
		for tag in tags:
			normalized.append(str(tag))
	return normalized
