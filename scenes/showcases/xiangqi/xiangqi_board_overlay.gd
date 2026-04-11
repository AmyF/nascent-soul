extends Control

@export var columns: int = 9
@export var rows: int = 10
@export var cell_size: Vector2 = Vector2(72, 72)
@export var cell_spacing: Vector2 = Vector2.ZERO
@export var padding: Vector2 = Vector2(20, 20)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var board_color = Color(0.18, 0.12, 0.08, 0.96)
	var line_color = Color(0.36, 0.24, 0.15, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.91, 0.80, 0.60, 1.0), true)
	draw_rect(Rect2(Vector2.ZERO, size), board_color, false, 3.0)

	var column_centers: Array[float] = []
	var row_centers: Array[float] = []
	for column in range(columns):
		column_centers.append(_cell_center_x(column))
	for row in range(rows):
		row_centers.append(_cell_center_y(row))

	var left = column_centers[0]
	var right = column_centers[columns - 1]
	for row in range(rows):
		draw_line(Vector2(left, row_centers[row]), Vector2(right, row_centers[row]), line_color, 2.0)

	for column in range(columns):
		var x = column_centers[column]
		if column == 0 or column == columns - 1:
			draw_line(Vector2(x, row_centers[0]), Vector2(x, row_centers[rows - 1]), line_color, 2.0)
			continue
		draw_line(Vector2(x, row_centers[0]), Vector2(x, row_centers[4]), line_color, 2.0)
		draw_line(Vector2(x, row_centers[5]), Vector2(x, row_centers[rows - 1]), line_color, 2.0)

	_draw_palace(line_color)

func _draw_palace(line_color: Color) -> void:
	var top_left = Vector2(_cell_center_x(3), _cell_center_y(0))
	var top_right = Vector2(_cell_center_x(5), _cell_center_y(0))
	var top_bottom_left = Vector2(_cell_center_x(3), _cell_center_y(2))
	var top_bottom_right = Vector2(_cell_center_x(5), _cell_center_y(2))
	draw_line(top_left, top_bottom_right, line_color, 2.0)
	draw_line(top_right, top_bottom_left, line_color, 2.0)

	var bottom_left = Vector2(_cell_center_x(3), _cell_center_y(7))
	var bottom_right = Vector2(_cell_center_x(5), _cell_center_y(7))
	var bottom_top_left = Vector2(_cell_center_x(3), _cell_center_y(9))
	var bottom_top_right = Vector2(_cell_center_x(5), _cell_center_y(9))
	draw_line(bottom_left, bottom_top_right, line_color, 2.0)
	draw_line(bottom_right, bottom_top_left, line_color, 2.0)

func _cell_center_x(column: int) -> float:
	return padding.x + column * (cell_size.x + cell_spacing.x) + cell_size.x * 0.5

func _cell_center_y(row: int) -> float:
	return padding.y + row * (cell_size.y + cell_spacing.y) + cell_size.y * 0.5
