extends CanvasLayer

@export var open_button_path: NodePath
@export var scroll_step := 140.0

@onready var _controls_root := %ControlsScreen as Control
@onready var _back_button := %ControlsBackButton as Button
@onready var _gamepad_nav_button := %GamepadNavButton as Button
@onready var _scroll_container := %ControlsScreen/Margin/Center as ScrollContainer

var _open_button: Button
var _title_tween: Tween
var _button_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_controls_root.visible = false
	_apply_arcade_text_style()

	_back_button.pressed.connect(close)
	_back_button.mouse_entered.connect(_animate_back_button_hover.bind(true))
	_back_button.mouse_exited.connect(_animate_back_button_hover.bind(false))
	_gamepad_nav_button.pressed.connect(_toggle_controls_page)

	_open_button = get_node_or_null(open_button_path) as Button if not open_button_path.is_empty() else null
	if _open_button != null:
		_open_button.pressed.connect(open)


func _input(event: InputEvent) -> void:
	if not _controls_root.visible:
		return

	if event.is_action_pressed("ui_cancel"):
		if event is InputEventKey and event.echo:
			return
		get_viewport().set_input_as_handled()
		close()

	if event is InputEventJoypadMotion:
		if event.axis == JoyAxis.JOY_AXIS_RIGHT_Y:
			get_viewport().set_input_as_handled()
			_scroll_by(event.axis_value)
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JoyButton.JOY_BUTTON_DPAD_LEFT:
				get_viewport().set_input_as_handled()
				_navigate_controls_page(-1)
			JoyButton.JOY_BUTTON_DPAD_RIGHT:
				get_viewport().set_input_as_handled()
				_navigate_controls_page(1)
			JoyButton.JOY_BUTTON_DPAD_UP, JoyButton.JOY_BUTTON_LEFT_SHOULDER:
				get_viewport().set_input_as_handled()
				_scroll_by(-1.0)
			JoyButton.JOY_BUTTON_DPAD_DOWN, JoyButton.JOY_BUTTON_RIGHT_SHOULDER:
				get_viewport().set_input_as_handled()
				_scroll_by(1.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT:
				get_viewport().set_input_as_handled()
				_navigate_controls_page(-1)
			KEY_RIGHT:
				get_viewport().set_input_as_handled()
				_navigate_controls_page(1)
			KEY_UP, KEY_PAGEUP:
				get_viewport().set_input_as_handled()
				_scroll_by(-1.0)
			KEY_DOWN, KEY_PAGEDOWN:
				get_viewport().set_input_as_handled()
				_scroll_by(1.0)


func _scroll_by(direction: float) -> void:
	if _scroll_container == null:
		return
	var max_scroll := _scroll_container.get_v_scroll_bar().max_value
	_scroll_container.scroll_vertical = clampi(
		_scroll_container.scroll_vertical + int(scroll_step * direction),
		0,
		int(max_scroll)
	)


func open(_from_screen: Node = null) -> void:
	_controls_root.visible = true
	_show_keyboard_page()
	if _scroll_container != null:
		_scroll_container.scroll_vertical = 0
		_back_button.grab_focus()
	call_deferred("_play_open_animation")


func close() -> void:
	_controls_root.visible = false


func _toggle_controls_page() -> void:
	var showing_gamepad := _get_content_node("Mandos").visible
	if showing_gamepad:
		_show_keyboard_page()
	else:
		_show_gamepad_page()


func _navigate_controls_page(direction: int) -> void:
	var showing_gamepad := _get_content_node("Mandos").visible
	if direction > 0 and not showing_gamepad:
		_show_gamepad_page()
	elif direction < 0 and showing_gamepad:
		_show_keyboard_page()


func _show_keyboard_page() -> void:
	_set_keyboard_content_visible(true)
	_set_gamepad_content_visible(false)
	_gamepad_nav_button.text = "CONTROLES CON MANDO  →"
	_gamepad_nav_button.grab_focus()
	_reset_scroll()


func _show_gamepad_page() -> void:
	_set_keyboard_content_visible(false)
	_set_gamepad_content_visible(true)
	_gamepad_nav_button.text = "←  CONTROLES DE TECLADO"
	_gamepad_nav_button.grab_focus()
	_reset_scroll()


func _set_keyboard_content_visible(is_visible: bool) -> void:
	for node_name in ["Title", "Subtitle", "Players"]:
		_get_content_node(node_name).visible = is_visible


func _set_gamepad_content_visible(is_visible: bool) -> void:
	for node_name in ["MandosTitle", "MandosSubtitle", "Mandos"]:
		var node := _get_content_node(node_name)
		node.visible = is_visible
		if node is Label and is_visible:
			(node as Label).visible_ratio = 1.0


func _get_content_node(node_name: String) -> Control:
	return _controls_root.get_node("Margin/Center/Panel/Padding/Content/%s" % node_name) as Control


func _reset_scroll() -> void:
	if _scroll_container != null:
		_scroll_container.scroll_vertical = 0


func _play_open_animation() -> void:
	if _title_tween != null and _title_tween.is_valid():
		_title_tween.kill()

	var titles: Array[Label] = [
		_controls_root.get_node_or_null("Margin/Center/Panel/Padding/Content/Title") as Label,
		_controls_root.get_node_or_null("Margin/Center/Panel/Padding/Content/MandosTitle") as Label,
	]
	_title_tween = create_tween()
	_title_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for title in titles:
		if title == null:
			continue
		title.visible_ratio = 0.0
		_title_tween.tween_property(title, "visible_ratio", 1.0, 0.55)

	var cards: Array[Control] = [
		_controls_root.get_node_or_null("Margin/Center/Panel/Padding/Content/Players/PlayerOne") as Control,
		_controls_root.get_node_or_null("Margin/Center/Panel/Padding/Content/Players/PlayerTwo") as Control,
		_controls_root.get_node_or_null("Margin/Center/Panel/Padding/Content/Mandos/MandoOne") as Control,
		_controls_root.get_node_or_null("Margin/Center/Panel/Padding/Content/Mandos/MandoTwo") as Control,
	]
	for card_index in cards.size():
		var card := cards[card_index]
		if card == null:
			continue
		card.pivot_offset = card.size * 0.5
		card.scale = Vector2(0.93, 0.93)
		card.modulate.a = 0.0
		var card_tween := create_tween()
		card_tween.set_parallel(true)
		card_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tween.tween_property(card, "scale", Vector2.ONE, 0.42)
		card_tween.tween_property(card, "modulate:a", 1.0, 0.25)
		_animate_key_buttons(card, 0.14 + card_index * 0.05)

	_back_button.pivot_offset = _back_button.size * 0.5
	_back_button.scale = Vector2(0.94, 0.94)
	var entrance_tween := create_tween()
	entrance_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(_back_button, "scale", Vector2.ONE, 0.36)


func _animate_key_buttons(card: Control, start_delay: float) -> void:
	var key_buttons := card.find_children("Key", "PanelContainer", true, false)
	for index in key_buttons.size():
		var key_button := key_buttons[index] as Control
		if key_button == null:
			continue
		key_button.pivot_offset = key_button.size * 0.5
		key_button.scale = Vector2(0.82, 0.82)
		key_button.modulate.a = 0.0
		var key_tween := create_tween()
		key_tween.tween_interval(start_delay + index * 0.045)
		key_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		key_tween.tween_property(key_button, "scale", Vector2.ONE, 0.24)
		key_tween.parallel().tween_property(key_button, "modulate:a", 1.0, 0.16)


func _animate_back_button_hover(is_hovered: bool) -> void:
	if _button_tween != null and _button_tween.is_valid():
		_button_tween.kill()
	_button_tween = create_tween()
	_button_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_button_tween.tween_property(
		_back_button,
		"scale",
		Vector2(1.035, 1.035) if is_hovered else Vector2.ONE,
		0.16
	)


func _apply_arcade_text_style() -> void:
	var fight_font := _controls_root.get_theme_font("font")
	for label in _controls_root.find_children("*", "Label", true, false):
		var text_label := label as Label
		if text_label == null:
			continue
		if fight_font != null:
			text_label.add_theme_font_override("font", fight_font)
		text_label.add_theme_color_override("font_outline_color", Color(0.025, 0.02, 0.08, 0.95))
		text_label.add_theme_constant_override("outline_size", 3)
		text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		text_label.add_theme_constant_override("shadow_offset_x", 2)
		text_label.add_theme_constant_override("shadow_offset_y", 3)

	# Las teclas priorizan legibilidad: texto sencillo, sin contorno ni sombra.
	for key_text in _controls_root.find_children("Text", "Label", true, false):
		var key_label := key_text as Label
		if key_label == null:
			continue
		key_label.add_theme_color_override("font_color", Color(0.015, 0.06, 0.12, 1))
		key_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
		key_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		key_label.add_theme_constant_override("outline_size", 0)
		key_label.add_theme_constant_override("shadow_offset_x", 0)
		key_label.add_theme_constant_override("shadow_offset_y", 0)

	for header_path in [
		"Margin/Center/Panel/Padding/Content/Title",
		"Margin/Center/Panel/Padding/Content/MandosTitle",
	]:
		var header := _controls_root.get_node_or_null(header_path) as Label
		if header != null:
			header.add_theme_color_override("font_color", Color(0.9, 0.06, 0.035, 1))
			header.add_theme_color_override("font_outline_color", Color(1, 0.72, 0.2, 1))
			header.add_theme_constant_override("outline_size", 5)
			header.add_theme_color_override("font_shadow_color", Color(0.12, 0.005, 0.005, 1))
			header.add_theme_constant_override("shadow_offset_x", 4)
			header.add_theme_constant_override("shadow_offset_y", 5)

	if fight_font != null:
		_back_button.add_theme_font_override("font", fight_font)
		_gamepad_nav_button.add_theme_font_override("font", fight_font)
	_back_button.add_theme_color_override("font_color", Color(1, 0.88, 0.48, 1))
	_back_button.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.7, 1))
	_back_button.add_theme_color_override("font_pressed_color", Color(1, 0.78, 0.32, 1))
	_back_button.add_theme_color_override("font_outline_color", Color(0.42, 0.025, 0.005, 1))
	_back_button.add_theme_constant_override("outline_size", 4)
	_back_button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	_back_button.add_theme_constant_override("shadow_offset_y", 3)
	_gamepad_nav_button.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.06, 1))
	_gamepad_nav_button.add_theme_constant_override("outline_size", 2)
