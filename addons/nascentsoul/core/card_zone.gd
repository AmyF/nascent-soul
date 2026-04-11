@tool
class_name CardZone extends Zone

func _ready() -> void:
	if config == null:
		config = _build_default_card_config()
	super._ready()

func _build_default_card_config() -> ZoneConfig:
	return ZoneConfig.make_card_defaults()
