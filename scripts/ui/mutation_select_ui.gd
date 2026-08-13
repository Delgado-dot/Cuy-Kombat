class_name MutationSelectUI
extends Control

## Pantalla de selección de mutaciones entre el Lobby y la selección de escenario.
## Las reglas elegidas se aplican al confirmar (MutationManager.set_active) y se
## limpian al salir hacia el Lobby o el menú principal (MutationManager.clear()).
## El listado se construye en código a partir de MutationManager, así que no hace
## falta tocar esta pantalla al añadir/quitar mutaciones.

signal confirmed
signal back_requested

@export var scroll_step := 140.0

@onready var _mutation_list := %MutationList as VBoxContainer
@onready var _status_label := %MutationStatusLabel as Label
@onready var _random_button := %MutationRandomButton as Button
@onready var _back_button := %MutationBackButton as Button
@onready var _confirm_button := %MutationConfirmButton as Button
@onready var _list_scroll := %ListScroll as ScrollContainer

var _checkboxes: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_rows()
	_random_button.pressed.connect(_on_random_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_refresh_status()
	ScreenFlow.register_mutation_select(self)
	_confirm_button.grab_focus()
	MusicManager.play_menu_music()


func _exit_tree() -> void:
	ScreenFlow.unregister_mutation_select(self)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
		return

	# Scroll libre con mando (el D-pad mueve el foco y ListScroll lo sigue).
	if event is InputEventJoypadMotion:
		if event.axis == JoyAxis.JOY_AXIS_RIGHT_Y:
			get_viewport().set_input_as_handled()
			_scroll_by(event.axis_value)
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JoyButton.JOY_BUTTON_LEFT_SHOULDER:
				get_viewport().set_input_as_handled()
				_scroll_by(-1.0)
			JoyButton.JOY_BUTTON_RIGHT_SHOULDER:
				get_viewport().set_input_as_handled()
				_scroll_by(1.0)
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_PAGEUP:
				get_viewport().set_input_as_handled()
				_scroll_by(-1.0)
			KEY_PAGEDOWN:
				get_viewport().set_input_as_handled()
				_scroll_by(1.0)


func _scroll_by(direction: float) -> void:
	var max_scroll := _list_scroll.get_v_scroll_bar().max_value
	_list_scroll.scroll_vertical = clampi(
		_list_scroll.scroll_vertical + int(scroll_step * direction),
		0,
		int(max_scroll)
	)


func _build_rows() -> void:
	for id in MutationManager.get_all_mutation_ids():
		var meta: Dictionary = MutationManager.get_mutation_meta(id)
		_mutation_list.add_child(_create_row(id, meta))


func _create_row(id: StringName, meta: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _create_row_style())

	var content := MarginContainer.new()
	content.add_theme_constant_override("margin_left", 16)
	content.add_theme_constant_override("margin_top", 10)
	content.add_theme_constant_override("margin_right", 16)
	content.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(content)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	content.add_child(box)

	var check := CheckBox.new()
	check.text = meta.get("display_name", str(id))
	check.add_theme_font_size_override("font_size", 20)
	check.add_theme_color_override("font_color", Color(0.94, 0.96, 1))
	check.add_theme_color_override("font_hover_color", Color(1, 0.84, 0.2))
	check.add_theme_color_override("font_pressed_color", Color(1, 0.84, 0.2))
	check.toggled.connect(_refresh_status)
	box.add_child(check)
	_checkboxes[id] = check

	var desc := Label.new()
	desc.text = meta.get("description", "")
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.8, 0.83, 0.9))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)

	return panel


func _create_row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.035, 0.08, 0.92)
	style.border_color = Color(0.28, 0.5, 0.8, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style


func _refresh_status(_toggled: bool = false) -> void:
	var count := 0
	for check in _checkboxes.values():
		if check.button_pressed:
			count += 1
	_status_label.text = "%d MUTACIÓN(ES) ACTIVA(S)" % count


## Desmarca todo y marca 2 mutaciones al azar.
func _on_random_pressed() -> void:
	for check in _checkboxes.values():
		check.set_pressed_no_signal(false)
	var ids := MutationManager.get_all_mutation_ids()
	ids.shuffle()
	for id in ids.slice(0, mini(2, ids.size())):
		(_checkboxes[id] as CheckBox).set_pressed_no_signal(true)
	_refresh_status()


func _on_confirm_pressed() -> void:
	var ids: Array[StringName] = []
	for id in _checkboxes:
		if _checkboxes[id].button_pressed:
			ids.append(id)
	MutationManager.set_active(ids)
	confirmed.emit()


func _on_back_pressed() -> void:
	back_requested.emit()
