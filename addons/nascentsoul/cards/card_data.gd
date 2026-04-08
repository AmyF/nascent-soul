@tool
class_name CardData extends Resource

@export var id: String = ""
@export var title: String = ""
@export var cost: int = 0
@export var tags: PackedStringArray = []
@export var front_texture: Texture2D
@export var back_texture: Texture2D
@export var custom_data: Dictionary = {}
