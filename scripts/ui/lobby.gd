extends CanvasLayer

const CHARACTERS := MatchSettings.CHARACTER_PRESETS
const LOBBY_MODEL_SCALE_FACTOR := Vector3(0.80, 0.80, 0.80)

# Control tracking para 2 jugadores activos (preparado dinámicamente para 4)
var _player_count := 2
var _selected_character_idx := [0, 1, 2, 3]
var _player_ready := [false, false, false, false]

var _p1_axis_neutral := true
var _p2_axis_neutral := true

@onready var _p1_name_label := %P1NameLabel as Label
@onready var _p2_name_label := %P2NameLabel as Label
@onready var _p1_prev_btn := %P1PrevButton as Button
@onready var _p1_next_btn := %P1NextButton as Button
@onready var _p2_prev_btn := %P2PrevButton as Button
@onready var _p2_next_btn := %P2NextButton as Button
@onready var _p1_pivot := %P1CuyPivot as Node3D
@onready var _p2_pivot := %P2CuyPivot as Node3D
@onready var _p1_ready_label := %P1ReadyLabel as Label
@onready var _p2_ready_label := %P2ReadyLabel as Label
@onready var _p1_ready_btn := %P1ReadyButton as Button
@onready var _p2_ready_btn := %P2ReadyButton as Button

@onready var _selection_section := %SelectionSection as Control
# Removed unused _p1_card reference
@onready var _rounds_selector := %RoundsSelector as Control
@onready var _round_3_button := %Round3Button as Button
@onready var _round_5_button := %Round5Button as Button
@onready var _round_7_button := %Round7Button as Button
@onready var _rounds_summary_label := %RoundsSummaryLabel as Label
@onready var _play_button := %PlayButton as Button
@onready var _back_button := %BackButton as Button

var _selected_max_rounds := MatchSettings.DEFAULT_MAX_ROUNDS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rounds_selector.visible = false
	_selection_section.visible = true

# Removed invalid stylebox override (was loading non-existent resource)

	_selected_character_idx[0] = MatchSettings.player_characters[0]
	_selected_character_idx[1] = MatchSettings.player_characters[1]

	_setup_connections()
	_update_player_display(1)
	_update_player_display(2)
	_apply_round_selection(MatchSettings.max_rounds, false)

	MusicManager.play_menu_music()


func _process(delta: float) -> void:
	if _p1_pivot != null and is_instance_valid(_p1_pivot):
		_p1_pivot.rotation.y += delta * 1.25
	if _p2_pivot != null and is_instance_valid(_p2_pivot):
		_p2_pivot.rotation.y += delta * 1.25


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
		return

	if _rounds_selector.visible:
		return

	# P1 Selección de Personaje (WASD / A / D / Joypad 0)
	if not _player_ready[0]:
		var p1_dir := 0
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_A:
				p1_dir = -1
			elif event.keycode == KEY_D:
				p1_dir = 1
		elif event is InputEventJoypadButton and event.device == 0 and event.pressed:
			if event.button_index == JOY_BUTTON_DPAD_LEFT:
				p1_dir = -1
			elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
				p1_dir = 1
		elif event is InputEventJoypadMotion and event.device == 0:
			if event.axis == JOY_AXIS_LEFT_X:
				if event.axis_value < -0.5 and _p1_axis_neutral:
					p1_dir = -1
					_p1_axis_neutral = false
				elif event.axis_value > 0.5 and _p1_axis_neutral:
					p1_dir = 1
					_p1_axis_neutral = false
				elif absf(event.axis_value) < 0.2:
					_p1_axis_neutral = true

		if p1_dir != 0:
			get_viewport().set_input_as_handled()
			_cycle_character(1, p1_dir)
			return

	# P2 Selección de Personaje (Flechas / Left / Right / Joypad 1)
	if not _player_ready[1]:
		var p2_dir := 0
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_LEFT:
				p2_dir = -1
			elif event.keycode == KEY_RIGHT:
				p2_dir = 1
		elif event is InputEventJoypadButton and event.device == 1 and event.pressed:
			if event.button_index == JOY_BUTTON_DPAD_LEFT:
				p2_dir = -1
			elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
				p2_dir = 1
		elif event is InputEventJoypadMotion and event.device == 1:
			if event.axis == JOY_AXIS_LEFT_X:
				if event.axis_value < -0.5 and _p2_axis_neutral:
					p2_dir = -1
					_p2_axis_neutral = false
				elif event.axis_value > 0.5 and _p2_axis_neutral:
					p2_dir = 1
					_p2_axis_neutral = false
				elif absf(event.axis_value) < 0.2:
					_p2_axis_neutral = true

		if p2_dir != 0:
			get_viewport().set_input_as_handled()
			_cycle_character(2, p2_dir)
			return

	# Alternar estado READY por jugador
	if event.is_action_pressed("grab_p1") or (event is InputEventKey and event.pressed and event.keycode == KEY_G):
		get_viewport().set_input_as_handled()
		_toggle_ready(1)
		return
	elif event.is_action_pressed("grab_p2") or (event is InputEventKey and event.pressed and event.keycode == KEY_K):
		get_viewport().set_input_as_handled()
		_toggle_ready(2)
		return


func _setup_connections() -> void:
	_p1_prev_btn.pressed.connect(_cycle_character.bind(1, -1))
	_p1_next_btn.pressed.connect(_cycle_character.bind(1, 1))
	_p2_prev_btn.pressed.connect(_cycle_character.bind(2, -1))
	_p2_next_btn.pressed.connect(_cycle_character.bind(2, 1))

	_p1_ready_btn.pressed.connect(_toggle_ready.bind(1))
	_p2_ready_btn.pressed.connect(_toggle_ready.bind(2))

	_round_3_button.pressed.connect(_on_round_pressed.bind(3))
	_round_5_button.pressed.connect(_on_round_pressed.bind(5))
	_round_7_button.pressed.connect(_on_round_pressed.bind(7))

	_play_button.pressed.connect(_on_play_pressed)
	_back_button.pressed.connect(_on_back_pressed)


func _cycle_character(player_num: int, dir: int) -> void:
	var p_idx := player_num - 1
	if _player_ready[p_idx]:
		return
	_selected_character_idx[p_idx] = posmod(_selected_character_idx[p_idx] + dir, CHARACTERS.size())
	MatchSettings.set_player_character(player_num, _selected_character_idx[p_idx])
	_update_player_display(player_num)


func _update_player_display(player_num: int) -> void:
	var p_idx := player_num - 1
	var char_info: Dictionary = CHARACTERS[_selected_character_idx[p_idx]]
	var pivot: Node3D = _p1_pivot if player_num == 1 else _p2_pivot
	var name_label: Label = _p1_name_label if player_num == 1 else _p2_name_label

	name_label.text = String(char_info["name"])

	if pivot != null:
		for child in pivot.get_children():
			child.queue_free()
		var scene_path := String(char_info["scene_path"])
		if ResourceLoader.exists(scene_path):
			var packed := load(scene_path) as PackedScene
			if packed != null:
				var model_instance := packed.instantiate() as Node3D
				# Duplicate to ensure fully independent resources
				var model := model_instance.duplicate() as Node3D
				var scale_vec: Vector3 = (char_info.get("scale", Vector3.ONE) as Vector3) * LOBBY_MODEL_SCALE_FACTOR
				var offset_vec: Vector3 = char_info.get("offset", Vector3.ZERO) as Vector3
				model.transform = Transform3D(Basis().scaled(scale_vec), offset_vec)
				pivot.add_child(model)

	_update_ready_ui(player_num)


func _toggle_ready(player_num: int) -> void:
	var p_idx := player_num - 1
	_player_ready[p_idx] = not _player_ready[p_idx]
	_update_ready_ui(player_num)
	_check_all_ready()


func _update_ready_ui(player_num: int) -> void:
	var p_idx := player_num - 1
	var is_ready: bool = _player_ready[p_idx]
	var is_p1 := player_num == 1

	var ready_label: Label = _p1_ready_label if is_p1 else _p2_ready_label
	var ready_btn: Button = _p1_ready_btn if is_p1 else _p2_ready_btn
	var prev_btn: Button = _p1_prev_btn if is_p1 else _p2_prev_btn
	var next_btn: Button = _p1_next_btn if is_p1 else _p2_next_btn

	prev_btn.disabled = is_ready
	next_btn.disabled = is_ready

	if is_ready:
		ready_label.text = "LISTO"
		ready_label.add_theme_color_override("font_color", Color(0.02, 0.02, 0.05, 0.0))
		ready_btn.text = "LISTO (CANCELAR)"
	else:
		ready_label.text = "NO LISTO"
		ready_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
		ready_btn.text = "CONFIRMAR (LISTO)"


func _check_all_ready() -> void:
	var all_ready := true
	for i in range(_player_count):
		if not _player_ready[i]:
			all_ready = false
			break

	if all_ready:
		_selection_section.visible = false
		_rounds_selector.visible = true
		_round_3_button.grab_focus()
	else:
		_rounds_selector.visible = false
		_selection_section.visible = true


func _on_round_pressed(max_rounds: int) -> void:
	_apply_round_selection(max_rounds)


func _apply_round_selection(max_rounds: int, _emit_change: bool = true) -> void:
	_selected_max_rounds = max_rounds
	MatchSettings.set_max_rounds(max_rounds)
	_round_3_button.button_pressed = (max_rounds == 3)
	_round_5_button.button_pressed = (max_rounds == 5)
	_round_7_button.button_pressed = (max_rounds == 7)
	_rounds_summary_label.text = "RONDAS DE LA PARTIDA: %d" % max_rounds


func _on_play_pressed() -> void:
	MatchSettings.set_max_rounds(_selected_max_rounds)
	RoundManager.reset()
	ScreenFlow.go_to_mutation_select()


func _on_back_pressed() -> void:
	if _rounds_selector.visible:
		_player_ready[0] = false
		_player_ready[1] = false
		_update_ready_ui(1)
		_update_ready_ui(2)
		_rounds_selector.visible = false
		_selection_section.visible = true
		return

	ScreenFlow.go_to_main_menu()
