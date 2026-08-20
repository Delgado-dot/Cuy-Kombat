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

@onready var _mutation_list := %MutationList as GridContainer
@onready var _status_label := %MutationStatusLabel as Label
@onready var _random_button := %MutationRandomButton as Button
@onready var _back_button := %MutationBackButton as Button
@onready var _confirm_button := %MutationConfirmButton as Button
@onready var _list_scroll := %ListScroll as ScrollContainer

var _checkboxes: Dictionary = {}

# --- Rolling animation state ---
var _is_animating := false
var _card_panels: Array[PanelContainer] = []
var _card_desc_labels: Array[Label] = []
var _card_original_styles: Array[StyleBoxFlat] = []
var _card_ids: Array[StringName] = []
var _original_status_text := ""
var _animation_tween: Tween = null
var _selected_card_indices: Array[int] = []

const ROLL_TOTAL_DURATION := 2.5
const ROLL_TOTAL_STEPS := 26
const POP_SCALE := Vector2(1.08, 1.08)
const POP_DURATION := 0.35

const MUTATION_IMAGES := {
	&"super_speed": "res://assets/imagenes/Mutaciones/super_speed.png",
	&"powerful_hits": "res://assets/imagenes/Mutaciones/powerful_hits.png",
	&"low_gravity": "res://assets/imagenes/Mutaciones/Guayakill.jpg",
	&"fast_recovery": "res://assets/imagenes/Mutaciones/MitadMundo.jpeg",
	&"slow_recovery": "res://assets/imagenes/Mutaciones/Panecillo.jpeg",
	&"slippery_floor": "res://assets/imagenes/Mutaciones/Plaza.jpg",
	&"inclined_arena": "res://assets/imagenes/Mutaciones/PlazaGrande.jpeg",
	&"giant_cuy": "res://assets/imagenes/Mutaciones/Quilotoa.jpg",
}


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
	if _is_animating:
		get_viewport().set_input_as_handled()
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
	_card_ids.clear()
	_card_panels.clear()
	_card_desc_labels.clear()
	_card_original_styles.clear()
	for id in MutationManager.get_all_mutation_ids():
		var meta: Dictionary = MutationManager.get_mutation_meta(id)
		var card := _create_row(id, meta)
		_mutation_list.add_child(card)
		_card_ids.append(id)
		_card_panels.append(card)


func _create_row(id: StringName, meta: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 104)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var base_style := _create_row_style()
	panel.add_theme_stylebox_override("panel", base_style)
	_card_original_styles.append(base_style)

	var image_path: String = MUTATION_IMAGES.get(id, "")
	if not image_path.is_empty() and ResourceLoader.exists(image_path):
		var texture := load(image_path) as Texture2D
		if texture != null:
			var bg_texture := TextureRect.new()
			bg_texture.texture = texture
			bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(bg_texture)

			var overlay := ColorRect.new()
			overlay.color = Color(0.0, 0.0, 0.0, 0.3)
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(overlay)

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
	_card_desc_labels.append(desc)

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


# ===========================================================================
#  ROLLING ANIMATION
# ===========================================================================

func _on_random_pressed() -> void:
	if _is_animating:
		return
	# 1) Disable buttons during animation
	_random_button.disabled = true
	_confirm_button.disabled = true
	# 2) Run selection logic (unchanged)
	for check in _checkboxes.values():
		check.set_pressed_no_signal(false)
	var ids := MutationManager.get_all_mutation_ids()
	ids.shuffle()
	var picked_ids: Array[StringName] = []
	for id in ids.slice(0, mini(2, ids.size())):
		(_checkboxes[id] as CheckBox).set_pressed_no_signal(true)
		picked_ids.append(id)
	_refresh_status()
	# 3) Map picked ids → panel indices
	_selected_card_indices.clear()
	for picked_id in picked_ids:
		for i in _card_ids.size():
			if _card_ids[i] == picked_id:
				_selected_card_indices.append(i)
				break
	# 4) Start rolling animation
	_start_rolling_animation()


func _start_rolling_animation() -> void:
	_is_animating = true
	_original_status_text = _status_label.text

	# Dim all checkboxes during the roll
	for i in _card_panels.size():
		(_checkboxes[_card_ids[i]] as CheckBox).visible = false
		_card_desc_labels[i].text = ""

	# Reset all cards to base style
	_reset_all_card_styles()

	# Kill previous tween if any
	if _animation_tween and _animation_tween.is_valid():
		_animation_tween.kill()

	var step := 0.0
	var current_highlighted := -1

	_animation_tween = create_tween()
	_animation_tween.tween_method(
		_animate_roll_step.bind(
			# Capture locals for the callback
			{"current": current_highlighted, "step": step}
		),
		0.0, 1.0, ROLL_TOTAL_DURATION
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_animation_tween.tween_callback(_on_rolling_animation_finished)


## Called every tween frame. `progress` goes 0→1.
## `ctx` is a Dictionary mutated across frames to track highlighted card.
func _animate_roll_step(progress: float, ctx: Dictionary) -> void:
	var eased_progress: float = ease(progress, -4.0)
	var raw_step: float = eased_progress * ROLL_TOTAL_STEPS
	var card_index: int = int(raw_step) % _card_panels.size()

	if card_index != ctx["current"]:
		# Remove highlight from previous card
		if ctx["current"] >= 0 and ctx["current"] < _card_panels.size():
			_apply_base_style(ctx["current"])
		# Highlight new card
		_apply_rolling_highlight(card_index)
		_scroll_to_card(card_index)
		ctx["current"] = card_index
	ctx["step"] = raw_step


func _on_rolling_animation_finished() -> void:
	_is_animating = false
	_animation_tween = null

	# Reset all cards first
	_reset_all_card_styles()

	# Apply final selected state to winning cards
	for idx in _selected_card_indices:
		_apply_selected_style(idx)
		_scroll_to_card(idx)

	# Show checkboxes and descriptions for selected cards
	for idx in _selected_card_indices:
		(_checkboxes[_card_ids[idx]] as CheckBox).visible = true
		(_checkboxes[_card_ids[idx]] as CheckBox).button_pressed = true
		_card_desc_labels[idx].text = _get_mutation_description(_card_ids[idx])

	# Status label
	_status_label.text = "¡MUTACIÓN SELECCIONADA!"

	# Pop + highlight animation on selected cards
	_animate_pop_selection()

	# Re-enable buttons after a brief pause
	await get_tree().create_timer(1.4).timeout
	_random_button.disabled = false
	_confirm_button.disabled = false
	_confirm_button.grab_focus()


# --- Style helpers ---

func _apply_rolling_highlight(card_index: int) -> void:
	if card_index < 0 or card_index >= _card_panels.size():
		return
	var panel := _card_panels[card_index]
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color(0.04, 0.06, 0.12, 0.95)
	highlight_style.border_color = Color(1.0, 0.85, 0.2, 0.95)
	highlight_style.set_border_width_all(3)
	highlight_style.set_corner_radius_all(12)
	highlight_style.shadow_color = Color(1.0, 0.7, 0.05, 0.35)
	highlight_style.shadow_size = 8
	highlight_style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", highlight_style)
	panel.modulate = Color(1.05, 1.05, 1.0)


func _apply_selected_style(card_index: int) -> void:
	if card_index < 0 or card_index >= _card_panels.size():
		return
	var panel := _card_panels[card_index]
	var sel_style := StyleBoxFlat.new()
	sel_style.bg_color = Color(0.18, 0.08, 0.01, 0.96)
	sel_style.border_color = Color(1.0, 0.69, 0.015, 1.0)
	sel_style.set_border_width_all(4)
	sel_style.set_corner_radius_all(12)
	sel_style.shadow_color = Color(1.0, 0.5, 0.0, 0.6)
	sel_style.shadow_size = 12
	sel_style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", sel_style)


func _apply_base_style(card_index: int) -> void:
	if card_index < 0 or card_index >= _card_panels.size():
		return
	var panel := _card_panels[card_index]
	panel.add_theme_stylebox_override("panel", _card_original_styles[card_index])
	panel.modulate = Color.WHITE


func _reset_all_card_styles() -> void:
	for i in _card_panels.size():
		_apply_base_style(i)


# --- Pop / scale animation ---

func _animate_pop_selection() -> void:
	for idx in _selected_card_indices:
		var panel := _card_panels[idx]
		panel.pivot_offset = panel.custom_minimum_size / 2.0

		# Scale pop: scale up → bounce back
		var pop_tween := create_tween()
		pop_tween.tween_property(panel, "scale", POP_SCALE, 0.12).set_ease(
			Tween.EASE_OUT
		).set_trans(Tween.TRANS_BACK)
		pop_tween.tween_property(panel, "scale", Vector2.ONE, POP_DURATION).set_ease(
			Tween.EASE_OUT
		).set_trans(Tween.TRANS_ELASTIC)

		# Subtle golden glow pulse (modulate)
		var glow_tween := create_tween()
		glow_tween.tween_property(
			panel, "modulate", Color(1.15, 1.05, 0.75), 0.15
		)
		glow_tween.tween_property(panel, "modulate", Color.WHITE, 0.35).set_ease(
			Tween.EASE_OUT
		).set_trans(Tween.TRANS_SINE)
		glow_tween.tween_property(
			panel, "modulate", Color(1.08, 1.0, 0.85), 0.2
		)
		glow_tween.tween_property(panel, "modulate", Color.WHITE, 0.3).set_ease(
			Tween.EASE_OUT
		).set_trans(Tween.TRANS_SINE)


# --- Scroll helper ---

func _scroll_to_card(card_index: int) -> void:
	if card_index < 0 or card_index >= _card_panels.size():
		return
	var card := _card_panels[card_index]
	var card_rect := card.get_global_rect()
	var scroll_rect := _list_scroll.get_global_rect()
	if card_rect.position.y < scroll_rect.position.y or card_rect.end.y > scroll_rect.end.y:
		var target := int(card.position.y - _list_scroll.size.y * 0.35)
		target = clampi(target, 0, _list_scroll.get_v_scroll_bar().max_value)
		_list_scroll.scroll_vertical = target


# --- Utility ---

func _get_mutation_description(id: StringName) -> String:
	var meta: Dictionary = MutationManager.get_mutation_meta(id)
	return meta.get("description", "")


func _on_confirm_pressed() -> void:
	if _is_animating:
		return
	var ids: Array[StringName] = []
	for id in _checkboxes:
		if _checkboxes[id].button_pressed:
			ids.append(id)
	MutationManager.set_active(ids)
	confirmed.emit()


func _on_back_pressed() -> void:
	if _is_animating:
		return
	back_requested.emit()
