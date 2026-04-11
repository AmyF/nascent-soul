extends "res://scenes/tests/shared/test_harness.gd"

const MAIN_MENU_SCENE = preload("res://scenes/main_menu.tscn")
const DEMO_SCENE = preload("res://scenes/demo.tscn")
const FREECELL_SCENE = preload("res://scenes/examples/freecell.tscn")
const XIANGQI_SCENE = preload("res://scenes/examples/xiangqi.tscn")

func _get_demo_hub_content_host(scene: Control) -> Control:
	return scene.get_node_or_null("RootMargin/RootHBox/ContentColumn/ContentPanel/ContentHost") as Control if scene != null else null

func _get_demo_hub_current_content(scene: Control) -> Control:
	var content_host = _get_demo_hub_content_host(scene)
	if content_host == null or content_host.get_child_count() == 0:
		return null
	return content_host.get_child(0) as Control
