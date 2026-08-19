extends CanvasLayer

@export var open_button_path: NodePath
@export var scroll_step := 140.0

@onready var _controls_root := %ControlsScreen as Control
@onready var _back_button := %ControlsBackButton as Button
@onready var _gamepad_nav_button := %GamepadNavButton as Button
@onready var _pair_nav_button := %PairNavButton as Button
@onready var _scroll_container := %ControlsScreen/Margin/Center as ScrollContainer

var _open_button: Button
var _title_tween: Tween
var _button_tween: Tween

var _keyboard_pair := 0
var _gamepad_pair := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_controls_root.visible = false
	_apply_arcade_text_style()

	_back_button.pressed.connect(close)
	_back_button.mouse_entered.connect(_animate_back_button_hover.bind(true))
	_back_button.mouse_exited.connect(_animate_back_button_hover.bind(false))
	_gamepad_nav_button.pressed.connect(_toggle_controls_page)
	_pair_nav_button.pressed.connect(_toggle_pair)

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
			JoyButton.JOY_BUTTON_DPAD_LEFT, JoyButton.JOY_BUTTON_LEFT_SHOULDER:
				get_viewport().set_input_as_handled()
				_navigate_controls_page(-1)
			JoyButton.JOY_BUTTON_DPAD_RIGHT, JoyButton.JOY_BUTTON_RIGHT_SHOULDER:
				get_viewport().set_input_as_handled()
				_navigate_controls_page(1)
			JoyButton.JOY_BUTTON_DPAD_UP:
				get_viewport().set_input_as_handled()
				_scroll_by(-1.0)
			JoyButton.JOY_BUTTON_DPAD_DOWN:
				get_viewport().set_input_as_handled()
				_scroll_by(1.0)
			JoyButton.JOY_BUTTON_A:
				get_viewport().set_input_as_handled()
				_toggle_pair()
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
	_keyboard_pair = 0
	_gamepad_pair = 0
	_update_subtitle_for_player_count()
	_show_keyboard_page()
	if _scroll_container != null:
		_scroll_container.scroll_vertical = 0
		_back_button.grab_focus()
	call_deferred("_play_open_animation")


func _update_subtitle_for_player_count() -> void:
	var player_count := MatchSettings.get_player_count()
	var subtitle := _controls_root.get_node_or_null("Margin/Center/Panel/Padding/Content/Subtitle") as Label
	if subtitle == null:
		return
	match player_count:
		2:
			subtitle.text = "JUGADOR 1  •  JUGADOR 2"
		3:
			subtitle.text = "JUGADOR 1  •  JUGADOR 2  •  JUGADOR 3"
		4:
			subtitle.text = "JUGADOR 1  •  JUGADOR 2  •  JUGADOR 3  •  JUGADOR 4"


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
	if direction > 0:
		if not showing_gamepad:
			if _keyboard_pair == 0:
				_keyboard_pair = 1
				_update_keyboard_pair()
			else:
				_gamepad_pair = 0
				_show_gamepad_page()
		elif _gamepad_pair == 0:
			_gamepad_pair = 1
			_update_gamepad_pair()
		else:
			_keyboard_pair = 0
			_show_keyboard_page()
	else:
		if showing_gamepad:
			if _gamepad_pair == 1:
				_gamepad_pair = 0
				_update_gamepad_pair()
			else:
				_keyboard_pair = 1
				_show_keyboard_page()
		elif _keyboard_pair == 1:
			_keyboard_pair = 0
			_update_keyboard_pair()
		else:
			_gamepad_pair = 1
			_show_gamepad_page()
	_reset_scroll()


func _show_keyboard_page() -> void:
	_set_keyboard_content_visible(true)
	_set_gamepad_content_visible(false)
	_apply_keyboard_visual_style()
	_gamepad_nav_button.text = "CONTROLES CON MANDO  →"
	_gamepad_nav_button.grab_focus()
	_update_keyboard_pair()
	_reset_scroll()


func _show_gamepad_page() -> void:
	_set_keyboard_content_visible(false)
	_set_gamepad_content_visible(true)
	_gamepad_nav_button.text = "←  CONTROLES DE TECLADO"
	_gamepad_nav_button.grab_focus()
	_update_gamepad_pair()
	_reset_scroll()


func _set_keyboard_content_visible(is_visible: bool) -> void:
	for node_name in ["Title", "KeyboardSubtitle", "Subtitle", "Players"]:
		_get_content_node(node_name).visible = is_visible


func _set_gamepad_content_visible(is_visible: bool) -> void:
	for node_name in ["MandosTitle", "MandosSubtitle", "Mandos"]:
		var node := _get_content_node(node_name)
		node.visible = is_visible
		if node is Label and is_visible:
			(node as Label).visible_ratio = 1.0


func _toggle_pair() -> void:
	if _get_content_node("Mandos").visible:
		_gamepad_pair = 1 - _gamepad_pair
		_update_gamepad_pair()
	else:
		_keyboard_pair = 1 - _keyboard_pair
		_update_keyboard_pair()
	_reset_scroll()


func _update_keyboard_pair() -> void:
	var players := _get_content_node("Players")
	for child in players.get_children():
		if child is Control:
			child.visible = false

	if _keyboard_pair == 0:
		var p1 := players.get_node_or_null("PlayerOne") as Control
		var p2 := players.get_node_or_null("PlayerTwo") as Control
		if p1 != null:
			p1.visible = true
		if p2 != null:
			p2.visible = true
		_pair_nav_button.text = "JUGADORES 3 Y 4  →"
	else:
		var p3 := players.get_node_or_null("PlayerThree") as Control
		var p4 := players.get_node_or_null("PlayerFour") as Control
		if p3 != null:
			p3.visible = true
		if p4 != null:
			p4.visible = true
		_pair_nav_button.text = "←  JUGADORES 1 Y 2"


func _update_gamepad_pair() -> void:
	var mandos := _get_content_node("Mandos")
	var subtitle := _get_content_node("MandosSubtitle") as Label
	for child in mandos.get_children():
		if child is Control:
			child.visible = false

	if _gamepad_pair == 0:
		var m1 := mandos.get_node_or_null("MandoOne") as Control
		var m2 := mandos.get_node_or_null("MandoTwo") as Control
		if m1 != null:
			m1.visible = true
		if m2 != null:
			m2.visible = true
		_pair_nav_button.text = "JUGADORES 3 Y 4  →"
		if subtitle != null:
			subtitle.text = "P1 = MANDO 1   •   P2 = MANDO 2"
	else:
		var m3 := mandos.get_node_or_null("MandoThree") as Control
		var m4 := mandos.get_node_or_null("MandoFour") as Control
		if m3 != null:
			m3.visible = true
		if m4 != null:
			m4.visible = true
		_pair_nav_button.text = "←  JUGADORES 1 Y 2"
		if subtitle != null:
			subtitle.text = "P3 = MANDO 3   •   P4 = MANDO 4"


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


func _apply_keyboard_visual_style() -> void:
	var title := _get_content_node("Title") as Label
	if title != null:
		title.add_theme_color_override("font_color", Color(1, 0.72, 0.08, 1))
		title.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.01, 1))
		title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		title.add_theme_constant_override("outline_size", 9)
		title.add_theme_constant_override("shadow_offset_y", 7)

	var keyboard_subtitle := _get_content_node("KeyboardSubtitle") as Label
	if keyboard_subtitle != null:
		keyboard_subtitle.add_theme_color_override("font_color", Color(0.96, 0.97, 1, 1))
		keyboard_subtitle.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1))
		keyboard_subtitle.add_theme_constant_override("outline_size", 5)

	_replace_move_key_with_cluster(
		"Margin/Center/Panel/Padding/Content/Players/PlayerOne/Padding/Content/Bindings/Move/Key",
		["W", "A", "S", "D"]
	)
	_replace_move_key_with_cluster(
		"Margin/Center/Panel/Padding/Content/Players/PlayerTwo/Padding/Content/Bindings/Move/Key",
		["←", "↑", "↓", "→"]
	)
	_apply_bottom_button_styles()


func _replace_move_key_with_cluster(key_path: String, key_labels: Array[String]) -> void:
	var original_key := _controls_root.get_node_or_null(NodePath(key_path)) as PanelContainer
	if original_key == null:
		return

	var key_style := original_key.get_theme_stylebox("panel")
	var parent := original_key.get_parent()
	var child_index := original_key.get_index()
	var key_cluster := HBoxContainer.new()
	key_cluster.name = "KeyCluster"
	key_cluster.custom_minimum_size = Vector2(190, 44)
	key_cluster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_cluster.add_theme_constant_override("separation", 6)

	for key_label_text in key_labels:
		var key_panel := PanelContainer.new()
		key_panel.custom_minimum_size = Vector2(43, 44)
		key_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_panel.add_theme_stylebox_override("panel", key_style)
		var key_label := Label.new()
		key_label.text = key_label_text
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key_label.add_theme_font_override("font", _controls_root.get_theme_font("font"))
		key_label.add_theme_font_size_override("font_size", 24)
		key_label.add_theme_color_override("font_color", Color(0.98, 0.98, 1, 1))
		key_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		key_label.add_theme_constant_override("outline_size", 3)
		key_panel.add_child(key_label)
		key_cluster.add_child(key_panel)

	parent.remove_child(original_key)
	parent.add_child(key_cluster)
	parent.move_child(key_cluster, child_index)
	original_key.queue_free()


func _apply_bottom_button_styles() -> void:
	_apply_button_style(_back_button, Color(1, 0.64, 0.04, 0.96), Color(1, 0.9, 0.35, 1), Color(0.08, 0.05, 0.01, 1))
	_apply_button_style(_gamepad_nav_button, Color(0.04, 0.32, 0.7, 0.94), Color(0.3, 0.78, 1, 1), Color(1, 1, 1, 1))
	_apply_button_style(_pair_nav_button, Color(0.32, 0.12, 0.56, 0.94), Color(0.75, 0.48, 1, 1), Color(1, 1, 1, 1))


func _apply_button_style(button: Button, background: Color, border: Color, text_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = background
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 5
	normal.border_color = border
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_left = 18
	normal.corner_radius_bottom_right = 18
	normal.shadow_color = Color(0, 0, 0, 0.65)
	normal.shadow_size = 7
	normal.shadow_offset = Vector2(0, 4)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", text_color.darkened(0.15))
	button.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.02, 1))
	button.add_theme_constant_override("outline_size", 4)


func _apply_arcade_text_style() -> void:
	var fight_font := _controls_root.get_theme_font("font")
	for label in _controls_root.find_children("*", "Label", true, false):
		var text_label := label as Label
		if text_label == null:
			continue
		if fight_font != null:
			text_label.add_theme_font_override("font", fight_font)
		text_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1))
		text_label.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.07, 0.95))
		text_label.add_theme_constant_override("outline_size", 3)
		text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		text_label.add_theme_constant_override("shadow_offset_x", 2)
		text_label.add_theme_constant_override("shadow_offset_y", 3)

	# Las teclas priorizan legibilidad: texto sencillo, sin contorno ni sombra.
	for key_text in _controls_root.find_children("Text", "Label", true, false):
		var key_label := key_text as Label
		if key_label == null:
			continue
		key_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1, 1))
		key_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
		key_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
		key_label.add_theme_constant_override("outline_size", 0)
		key_label.add_theme_constant_override("shadow_offset_x", 0)
		key_label.add_theme_constant_override("shadow_offset_y", 0)

	var card_headers := [
		{"path": "Margin/Center/Panel/Padding/Content/Players/PlayerOne/Padding/Content/Header", "color": Color(1, 0.32, 0.64, 1)},
		{"path": "Margin/Center/Panel/Padding/Content/Players/PlayerTwo/Padding/Content/Header", "color": Color(0.2, 0.72, 1, 1)},
		{"path": "Margin/Center/Panel/Padding/Content/Players/PlayerThree/Padding/Content/Header", "color": Color(0.32, 0.92, 0.55, 1)},
		{"path": "Margin/Center/Panel/Padding/Content/Players/PlayerFour/Padding/Content/Header", "color": Color(1, 0.78, 0.22, 1)},
		{"path": "Margin/Center/Panel/Padding/Content/Mandos/MandoOne/Padding/Content/Header", "color": Color(1, 0.32, 0.64, 1)},
		{"path": "Margin/Center/Panel/Padding/Content/Mandos/MandoTwo/Padding/Content/Header", "color": Color(0.2, 0.72, 1, 1)},
		{"path": "Margin/Center/Panel/Padding/Content/Mandos/MandoThree/Padding/Content/Header", "color": Color(0.32, 0.92, 0.55, 1)},
		{"path": "Margin/Center/Panel/Padding/Content/Mandos/MandoFour/Padding/Content/Header", "color": Color(1, 0.78, 0.22, 1)},
	]
	for header_data in card_headers:
		var card_header := _controls_root.get_node_or_null(NodePath(header_data["path"])) as Label
		if card_header != null:
			card_header.add_theme_color_override("font_color", header_data["color"])
			card_header.add_theme_color_override("font_outline_color", Color(0.01, 0.01, 0.02, 1))
			card_header.add_theme_constant_override("outline_size", 4)

	for header_path in [
		"Margin/Center/Panel/Padding/Content/Title",
		"Margin/Center/Panel/Padding/Content/MandosTitle",
	]:
		var header := _controls_root.get_node_or_null(header_path) as Label
		if header != null:
			header.add_theme_color_override("font_color", Color(0.94, 0.96, 1, 1))
			header.add_theme_color_override("font_outline_color", Color(0.12, 0.14, 0.18, 1))
			header.add_theme_constant_override("outline_size", 5)
			header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
			header.add_theme_constant_override("shadow_offset_x", 4)
			header.add_theme_constant_override("shadow_offset_y", 5)

	if fight_font != null:
		_back_button.add_theme_font_override("font", fight_font)
		_gamepad_nav_button.add_theme_font_override("font", fight_font)
		_pair_nav_button.add_theme_font_override("font", fight_font)
	_back_button.add_theme_color_override("font_color", Color(0.94, 0.96, 1, 1))
	_back_button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	_back_button.add_theme_color_override("font_pressed_color", Color(0.78, 0.82, 0.9, 1))
	_back_button.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08, 1))
	_back_button.add_theme_constant_override("outline_size", 4)
	_back_button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	_back_button.add_theme_constant_override("shadow_offset_y", 3)
	_gamepad_nav_button.add_theme_color_override("font_color", Color(0.94, 0.96, 1, 1))
	_gamepad_nav_button.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08, 1))
	_gamepad_nav_button.add_theme_constant_override("outline_size", 2)
	_pair_nav_button.add_theme_color_override("font_color", Color(0.94, 0.96, 1, 1))
	_pair_nav_button.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.08, 1))
	_pair_nav_button.add_theme_constant_override("outline_size", 2)
