class_name ZoneDragContext

static var is_dragging: bool = false
static var dragging_items: Array[Control] = []
static var source_zone: Node = null
static var hover_zone: Node = null
static var drag_offset: Vector2 = Vector2.ZERO
static var cursor_proxy: Control = null

static func clear():
	is_dragging = false
	dragging_items.clear()
	source_zone = null
	hover_zone = null
	if is_instance_valid(cursor_proxy):
		cursor_proxy.queue_free()
	cursor_proxy = null
