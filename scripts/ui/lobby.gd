extends CanvasLayer

const CHARACTERS := MatchSettings.CHARACTER_PRESETS
const LOBBY_MODEL_SCALE_FACTOR := Vector3(0.5, 0.5, 0.5)

var _player_count := 4
var _selected_character_idx := [0, 1, 2, 3]
var _player_ready := [false, false, false, false]

var _axis_neutral := [true, true, true, true]

@onready var _p1_name_label := %P1NameLabel as Label
@onready var _p2_name_label := %P2NameLabel as Label
@onready var _p3_name_label := %P3NameLabel as Label
@onready var _p4_name_label := %P4NameLabel as Label
@onready var _p1_prev_btn := %P1PrevButton as Button
@onready var _p1_next_btn := %P1NextButton as Button
@onready var _p2_prev_btn := %P2PrevButton as Button
@onready var _p2_next_btn := %P2NextButton as Button
@onready var _p3_prev_btn := %P3PrevButton as Button
@onready var _p3_next_btn := %P3NextButton as Button
@onready var _p4_prev_btn := %P4PrevButton as Button
@onready var _p4_next_btn := %P4NextButton as Button
@onready var _p1_pivot := %P1CuyPivot as Node3D
@onready var _p2_pivot := %P2CuyPivot as Node3D
@onready var _p3_pivot := %P3CuyPivot as Node3D
@onready var _p4_pivot := %P4CuyPivot as Node3D
@onready var _p1_ready_label := %P1ReadyLabel as Label
@onready var _p2_ready_label := %P2ReadyLabel as Label
@onready var _p3_ready_label := %P3ReadyLabel as Label
@onready var _p4_ready_label := %P4ReadyLabel as Label
@onready var _p1_ready_btn := %P1ReadyButton as Button
@onready var _p2_ready_btn := %P2ReadyButton as Button
@onready var _p3_ready_btn := %P3ReadyButton as Button
@onready var _p4_ready_btn := %P4ReadyButton as Button

@onready var _selection_section := %SelectionSection as Control
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

	MatchSettings.detect_and_assign_joypads()

	for i in range(4):
		_selected_character_idx[i] = MatchSettings.player_characters[i]

	_setup_connections()
	for i in range(1, 5):
		_update_player_display(i)
	_apply_round_selection(MatchSettings.max_rounds, false)

	MusicManager.play_menu_music()


func _process(delta: float) -> void:
	if _p1_pivot != null and is_instance_valid(_p1_pivot):
		_p1_pivot.rotation.y += delta * 1.25
	if _p2_pivot != null and is_instance_valid(_p2_pivot):
		_p2_pivot.rotation.y += delta * 1.25
	if _p3_pivot != null and is_instance_valid(_p3_pivot):
		_p3_pivot.rotation.y += delta * 1.25
	if _p4_pivot != null and is_instance_valid(_p4_pivot):
		_p4_pivot.rotation.y += delta * 1.25


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_on_back_pressed()
		return

	if _rounds_selector.visible:
		return

	for player_num in range(1, 5):
		if _handle_player_cycling(event, player_num):
			return
		if _handle_player_ready(event, player_num):
			return


func _handle_player_cycling(event: InputEvent, player_num: int) -> bool:
	var p_idx := player_num - 1
	if _player_ready[p_idx]:
		return false

	var dir := 0
	var device := MatchSettings.get_player_joypad_device(player_num)

	if event is InputEventKey and event.pressed:
		dir = _get_keyboard_cycling_dir(player_num, event.keycode)
	elif device >= 0:
		if event is InputEventJoypadButton and event.device == device and event.pressed:
			if event.button_index == JOY_BUTTON_DPAD_LEFT:
				dir = -1
			elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
				dir = 1
		elif event is InputEventJoypadMotion and event.device == device:
			if event.axis == JOY_AXIS_LEFT_X:
				if event.axis_value < -0.5 and _axis_neutral[p_idx]:
					dir = -1
					_axis_neutral[p_idx] = false
				elif event.axis_value > 0.5 and _axis_neutral[p_idx]:
					dir = 1
					_axis_neutral[p_idx] = false
				elif absf(event.axis_value) < 0.2:
					_axis_neutral[p_idx] = true

	if dir != 0:
		get_viewport().set_input_as_handled()
		_cycle_character(player_num, dir)
		return true
	return false


func _get_keyboard_cycling_dir(player_num: int, keycode: Key) -> int:
	match player_num:
		1:
			if keycode == KEY_A:
				return -1
			elif keycode == KEY_D:
				return 1
		2:
			if keycode == KEY_LEFT:
				return -1
			elif keycode == KEY_RIGHT:
				return 1
		3:
			if keycode == KEY_J:
				return -1
			elif keycode == KEY_L:
				return 1
		4:
			if keycode == KEY_KP_4:
				return -1
			elif keycode == KEY_KP_6:
				return 1
	return 0


func _handle_player_ready(event: InputEvent, player_num: int) -> bool:
	if event is InputEventKey and event.pressed:
		if _get_keyboard_ready_key(player_num) == event.keycode:
			get_viewport().set_input_as_handled()
			_toggle_ready(player_num)
			return true

	var device := MatchSettings.get_player_joypad_device(player_num)
	if device >= 0 and event is InputEventJoypadButton and event.device == device and event.pressed \
			and event.button_index == JOY_BUTTON_Y:
		get_viewport().set_input_as_handled()
		_toggle_ready(player_num)
		return true
	return false


func _get_keyboard_ready_key(player_num: int) -> Key:
	match player_num:
		1: return KEY_G
		2: return KEY_K
		3: return KEY_N
		4: return KEY_KP_1
	return KEY_G


func _setup_connections() -> void:
	_p1_prev_btn.pressed.connect(_cycle_character.bind(1, -1))
	_p1_next_btn.pressed.connect(_cycle_character.bind(1, 1))
	_p2_prev_btn.pressed.connect(_cycle_character.bind(2, -1))
	_p2_next_btn.pressed.connect(_cycle_character.bind(2, 1))
	_p3_prev_btn.pressed.connect(_cycle_character.bind(3, -1))
	_p3_next_btn.pressed.connect(_cycle_character.bind(3, 1))
	_p4_prev_btn.pressed.connect(_cycle_character.bind(4, -1))
	_p4_next_btn.pressed.connect(_cycle_character.bind(4, 1))

	_p1_ready_btn.pressed.connect(_toggle_ready.bind(1))
	_p2_ready_btn.pressed.connect(_toggle_ready.bind(2))
	_p3_ready_btn.pressed.connect(_toggle_ready.bind(3))
	_p4_ready_btn.pressed.connect(_toggle_ready.bind(4))

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
	var name_label: Label = _get_name_label(player_num)
	var pivot: Node3D = _get_pivot(player_num)

	name_label.text = String(char_info["name"])

	if pivot != null:
		for child in pivot.get_children():
			child.queue_free()
		var scene_path := String(char_info["scene_path"])
		if ResourceLoader.exists(scene_path):
			var packed := load(scene_path) as PackedScene
			if packed != null:
				var model := packed.instantiate() as Node3D
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
	var ready_label: Label = _get_ready_label(player_num)
	var ready_btn: Button = _get_ready_btn(player_num)
	var prev_btn: Button = _get_prev_btn(player_num)
	var next_btn: Button = _get_next_btn(player_num)

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
	var all_ready := true
	for i in range(_player_count):
		if not _player_ready[i]:
			all_ready = false
			break
	if not all_ready:
		return
	MatchSettings.set_player_count(_player_count)
	MatchSettings.set_max_rounds(_selected_max_rounds)
	RoundManager.reset()
	ScreenFlow.go_to_mutation_select()


func _on_back_pressed() -> void:
	if _rounds_selector.visible:
		for i in range(_player_count):
			_player_ready[i] = false
			_update_ready_ui(i + 1)
		_rounds_selector.visible = false
		_selection_section.visible = true
		return

	ScreenFlow.go_to_main_menu()


func _get_name_label(player_num: int) -> Label:
	match player_num:
		1: return _p1_name_label
		2: return _p2_name_label
		3: return _p3_name_label
		4: return _p4_name_label
	return _p1_name_label


func _get_pivot(player_num: int) -> Node3D:
	match player_num:
		1: return _p1_pivot
		2: return _p2_pivot
		3: return _p3_pivot
		4: return _p4_pivot
	return _p1_pivot


func _get_ready_label(player_num: int) -> Label:
	match player_num:
		1: return _p1_ready_label
		2: return _p2_ready_label
		3: return _p3_ready_label
		4: return _p4_ready_label
	return _p1_ready_label


func _get_ready_btn(player_num: int) -> Button:
	match player_num:
		1: return _p1_ready_btn
		2: return _p2_ready_btn
		3: return _p3_ready_btn
		4: return _p4_ready_btn
	return _p1_ready_btn


func _get_prev_btn(player_num: int) -> Button:
	match player_num:
		1: return _p1_prev_btn
		2: return _p2_prev_btn
		3: return _p3_prev_btn
		4: return _p4_prev_btn
	return _p1_prev_btn


func _get_next_btn(player_num: int) -> Button:
	match player_num:
		1: return _p1_next_btn
		2: return _p2_next_btn
		3: return _p3_next_btn
		4: return _p4_next_btn
	return _p1_next_btn
