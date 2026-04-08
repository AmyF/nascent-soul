extends Control

@onready var tab_container: TabContainer = $RootMargin/RootVBox/TabContainer
@onready var intro_label: Label = $RootMargin/RootVBox/IntroLabel

func _ready() -> void:
	intro_label.text = "Use the tabs below to explore transfer flows, layout recipes, permission policies, and a copy-friendly starter board. In the editor, the plugin menu also includes shortcuts for the hub, the recipe scene, and the README."
	tab_container.set_tab_title(0, "Transfer Playground")
	tab_container.set_tab_title(1, "Layout Gallery")
	tab_container.set_tab_title(2, "Permission Lab")
	tab_container.set_tab_title(3, "Zone Recipes")
	if DisplayServer.get_name() == "headless":
		get_tree().create_timer(0.5).timeout.connect(get_tree().quit)
