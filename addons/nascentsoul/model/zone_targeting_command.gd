class_name ZoneTargetingCommand extends RefCounted

var source_zone = null
var source_item = null
var intent: ZoneTargetingIntent = null
var entry_mode: StringName = &"explicit"
var pointer_global_position: Vector2 = Vector2.ZERO

func _init(
	p_source_zone = null,
	p_source_item = null,
	p_intent: ZoneTargetingIntent = null,
	p_entry_mode: StringName = &"explicit",
	p_pointer_global_position: Vector2 = Vector2.ZERO
) -> void:
	source_zone = p_source_zone
	source_item = p_source_item
	intent = p_intent
	entry_mode = p_entry_mode
	pointer_global_position = p_pointer_global_position

static func explicit_for_item(
	source_zone,
	source_item,
	intent: ZoneTargetingIntent = null,
	pointer_global_position: Vector2 = Vector2.ZERO
):
	return load("res://addons/nascentsoul/model/zone_targeting_command.gd").new(source_zone, source_item, intent, &"explicit", pointer_global_position)

static func drag_for_item(
	source_zone,
	source_item,
	intent: ZoneTargetingIntent = null,
	pointer_global_position: Vector2 = Vector2.ZERO
):
	return load("res://addons/nascentsoul/model/zone_targeting_command.gd").new(source_zone, source_item, intent, &"drag", pointer_global_position)

func duplicate_command():
	return get_script().new(source_zone, source_item, intent, entry_mode, pointer_global_position)
