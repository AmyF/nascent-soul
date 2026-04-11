@tool
extends "res://addons/nascentsoul/cards/zone_card.gd"

const CARD_SIZE := Vector2(120, 180)
const DEFAULT_FRONT_TEXTURE := preload("res://assets/card/card_front.png")
const DEFAULT_BACK_TEXTURE := preload("res://assets/card/card_back.png")

var _example_card_id: String = ""
var _example_card_title: String = ""
var _example_card_cost: int = 0
var _example_card_tags: PackedStringArray = PackedStringArray()
var _example_front_texture: Texture2D = DEFAULT_FRONT_TEXTURE
var _example_back_texture: Texture2D = DEFAULT_BACK_TEXTURE
var _example_extra_custom_data: Dictionary = {}
var _example_extra_metadata: Dictionary = {}

@export var card_id: String = "":
	get:
		return _example_card_id
	set(value):
		_example_card_id = value
		_apply_example_state()

@export var card_title: String = "":
	get:
		return _example_card_title
	set(value):
		_example_card_title = value
		_apply_example_state()

@export var card_cost: int = 0:
	get:
		return _example_card_cost
	set(value):
		_example_card_cost = value
		_apply_example_state()

@export var card_tags: PackedStringArray = PackedStringArray():
	get:
		return _example_card_tags
	set(value):
		_example_card_tags = value
		_apply_example_state()

@export var front_texture: Texture2D = DEFAULT_FRONT_TEXTURE:
	get:
		return _example_front_texture
	set(value):
		_example_front_texture = value
		_apply_example_state()

@export var back_texture: Texture2D = DEFAULT_BACK_TEXTURE:
	get:
		return _example_back_texture
	set(value):
		_example_back_texture = value
		_apply_example_state()

@export var extra_custom_data: Dictionary = {}:
	get:
		return _example_extra_custom_data
	set(value):
		_example_extra_custom_data = value
		_apply_example_state()

@export var extra_metadata: Dictionary = {}:
	get:
		return _example_extra_metadata
	set(value):
		_example_extra_metadata = value
		_apply_example_state()

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = CARD_SIZE
	if size == Vector2.ZERO:
		size = custom_minimum_size
	_apply_example_state()
	super._ready()

func _apply_example_state() -> void:
	var normalized_title = _example_card_title.strip_edges()
	var normalized_id = _example_card_id.strip_edges()
	if normalized_id == "" and normalized_title != "":
		normalized_id = normalized_title.to_lower().replace(" ", "_")
	var next_data := CardData.new()
	next_data.id = normalized_id
	next_data.title = normalized_title
	next_data.cost = _example_card_cost
	next_data.tags = _example_card_tags.duplicate()
	next_data.front_texture = _example_front_texture if _example_front_texture != null else DEFAULT_FRONT_TEXTURE
	next_data.back_texture = _example_back_texture if _example_back_texture != null else DEFAULT_BACK_TEXTURE
	var custom_data := {
		"cost": _example_card_cost,
		"tags": _example_card_tags.duplicate()
	}
	for key in _example_extra_custom_data.keys():
		custom_data[key] = _example_extra_custom_data[key]
	next_data.custom_data = custom_data
	data = next_data
	if normalized_title != "":
		name = normalized_title
	var metadata := {
		"example_cost": _example_card_cost,
		"example_tags": _example_card_tags.duplicate(),
		"example_primary_tag": _example_card_tags[0] if not _example_card_tags.is_empty() else "card"
	}
	for key in _example_extra_metadata.keys():
		metadata[key] = _example_extra_metadata[key]
	set_zone_item_metadata(metadata)
	set_meta("example_cost", _example_card_cost)
	set_meta("example_tags", _example_card_tags.duplicate())
	set_meta("example_primary_tag", metadata["example_primary_tag"])
	for key in _example_extra_metadata.keys():
		set_meta(str(key), _example_extra_metadata[key])
