extends PanelContainer

@export var panel_color := Color(0.025, 0.045, 0.09, 0.94)
@export var border_color := Color(0.2, 0.65, 1.0, 1.0)
@export var accent_color := Color(0.55, 0.9, 1.0, 1.0)
@export_range(8.0, 28.0, 1.0) var corner_cut := 16.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var width := size.x
	var height := size.y
	if width <= 0.0 or height <= 0.0:
		return

	var cut := minf(corner_cut, minf(width, height) * 0.22)
	var points := PackedVector2Array([
		Vector2(0.0, cut),
		Vector2(cut, 0.0),
		Vector2(width - cut * 1.5, 0.0),
		Vector2(width, cut * 1.5),
		Vector2(width, height - cut),
		Vector2(width - cut, height),
		Vector2(cut * 1.5, height),
		Vector2(0.0, height - cut * 1.5),
	])

	var shadow_points := PackedVector2Array()
	for point in points:
		shadow_points.append(point + Vector2(0.0, 5.0))
	draw_colored_polygon(shadow_points, Color(0.0, 0.0, 0.0, 0.52))
	draw_colored_polygon(points, panel_color)

	var closed_points := points.duplicate()
	closed_points.append(points[0])
	draw_polyline(closed_points, Color(border_color, 0.18), 8.0, true)
	draw_polyline(closed_points, border_color, 2.5, true)
	draw_line(points[1] + Vector2(8.0, 0.0), points[2] - Vector2(8.0, 0.0), accent_color, 3.0, true)
	draw_line(points[6] - Vector2(8.0, 0.0), points[5] + Vector2(8.0, 0.0), Color(accent_color, 0.35), 1.5, true)
