@tool
extends "res://addons/nascentsoul/pieces/zone_piece.gd"

const PIECE_SIZE := Vector2(92, 92)
const DEFAULT_TEXTURE := preload("res://assets/card/card_front.png")

var _example_piece_id: String = ""
var _example_piece_title: String = ""
var _example_piece_team: String = ""
var _example_piece_attack: int = 0
var _example_piece_defense: int = 0
var _example_piece_texture: Texture2D = DEFAULT_TEXTURE
var _example_extra_custom_data: Dictionary = {}
var _example_extra_metadata: Dictionary = {}

@export var piece_id: String = "":
	get:
		return _example_piece_id
	set(value):
		_example_piece_id = value
		_apply_example_state()

@export var piece_title: String = "":
	get:
		return _example_piece_title
	set(value):
		_example_piece_title = value
		_apply_example_state()

@export var piece_team: String = "":
	get:
		return _example_piece_team
	set(value):
		_example_piece_team = value
		_apply_example_state()

@export var piece_attack: int = 0:
	get:
		return _example_piece_attack
	set(value):
		_example_piece_attack = value
		_apply_example_state()

@export var piece_defense: int = 0:
	get:
		return _example_piece_defense
	set(value):
		_example_piece_defense = value
		_apply_example_state()

@export var piece_texture: Texture2D = DEFAULT_TEXTURE:
	get:
		return _example_piece_texture
	set(value):
		_example_piece_texture = value
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
		custom_minimum_size = PIECE_SIZE
	if size == Vector2.ZERO:
		size = custom_minimum_size
	_apply_example_state()
	super._ready()

func _apply_example_state() -> void:
	var normalized_title = _example_piece_title.strip_edges()
	var normalized_id = _example_piece_id.strip_edges()
	if normalized_id == "" and normalized_title != "":
		normalized_id = normalized_title.to_lower().replace(" ", "_")
	var next_data := PieceData.new()
	next_data.id = normalized_id
	next_data.title = normalized_title
	next_data.team = _example_piece_team
	next_data.attack = _example_piece_attack
	next_data.defense = _example_piece_defense
	next_data.texture = _example_piece_texture if _example_piece_texture != null else DEFAULT_TEXTURE
	var custom_data := {}
	for key in _example_extra_custom_data.keys():
		custom_data[key] = _example_extra_custom_data[key]
	next_data.custom_data = custom_data
	data = next_data
	if normalized_title != "":
		name = normalized_title
	var metadata := {
		"target_team": _example_piece_team,
		"piece_team": _example_piece_team,
		"piece_attack": _example_piece_attack,
		"piece_defense": _example_piece_defense
	}
	for key in _example_extra_metadata.keys():
		metadata[key] = _example_extra_metadata[key]
	set_zone_item_metadata(metadata)
	set_meta("target_team", _example_piece_team)
	set_meta("piece_team", _example_piece_team)
	set_meta("piece_attack", _example_piece_attack)
	set_meta("piece_defense", _example_piece_defense)
	for key in _example_extra_metadata.keys():
		set_meta(str(key), _example_extra_metadata[key])
