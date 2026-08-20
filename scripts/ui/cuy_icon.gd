extends Control

var tint := Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		tint = value
		queue_redraw()


func _draw() -> void:
	var size := custom_minimum_size
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	var cx := w * 0.5
	var cy := h * 0.5
	var dark := Color(0.02, 0.02, 0.035, 1.0)

	_draw_ellipse(Vector2(cx - w * 0.30, cy - h * 0.34), w * 0.15, h * 0.17, tint.darkened(0.18))
	_draw_ellipse(Vector2(cx + w * 0.30, cy - h * 0.34), w * 0.15, h * 0.17, tint.darkened(0.18))

	_draw_ellipse(Vector2(cx, cy - h * 0.02), w * 0.40, h * 0.36, tint)

	var eye_r := maxf(w * 0.045, 1.5)
	draw_circle(Vector2(cx - w * 0.14, cy - h * 0.02), eye_r, dark)
	draw_circle(Vector2(cx + w * 0.14, cy - h * 0.02), eye_r, dark)

	var eye_glint := maxf(w * 0.015, 0.8)
	draw_circle(Vector2(cx - w * 0.16, cy - h * 0.05), eye_glint, Color.WHITE)
	draw_circle(Vector2(cx + w * 0.12, cy - h * 0.05), eye_glint, Color.WHITE)

	_draw_ellipse(Vector2(cx, cy + h * 0.16), w * 0.075, h * 0.045, Color(1.0, 0.45, 0.55, 1.0))

	draw_rect(Rect2(cx - w * 0.035, cy + h * 0.20, w * 0.032, h * 0.07), Color.WHITE)
	draw_rect(Rect2(cx + w * 0.005, cy + h * 0.20, w * 0.032, h * 0.07), Color.WHITE)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(rx, ry))
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
