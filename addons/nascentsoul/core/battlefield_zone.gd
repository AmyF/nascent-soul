@tool
class_name BattlefieldZone extends Zone

func _ready() -> void:
	if config == null:
		config = _build_default_battlefield_config()
	super._ready()

func _build_default_battlefield_config() -> ZoneConfig:
	return ZoneConfig.make_battlefield_defaults()
