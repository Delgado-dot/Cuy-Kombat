extends CanvasLayer

const ROUNDS_OPTIONS: Array[int] = [3, 5, 7]

@onready var _root := %UI as Control
@onready var _round_3_button := %Round3Button as Button
@onready var _round_5_button := %Round5Button as Button
@onready var _round_7_button := %Round7Button as Button
@onready var _rounds_summary_label := %RoundsSummaryLabel as Label
@onready var _play_button := %PlayButton as Button
@onready var _back_button := %BackButton as Button

var _selected_max_rounds := MatchSettings.DEFAULT_MAX_ROUNDS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = true

	_round_3_button.pressed.connect(_on_round_pressed.bind(3))
	_round_5_button.pressed.connect(_on_round_pressed.bind(5))
	_round_7_button.pressed.connect(_on_round_pressed.bind(7))
	_round_3_button.focus_entered.connect(_on_round_focused.bind(3))
	_round_5_button.focus_entered.connect(_on_round_focused.bind(5))
	_round_7_button.focus_entered.connect(_on_round_focused.bind(7))
	_play_button.pressed.connect(_on_play_pressed)
	_back_button.pressed.connect(_on_back_pressed)

	_apply_selection(MatchSettings.max_rounds, false)
	MusicManager.play_menu_music()
	_play_button.grab_focus()


func _input(event: InputEvent) -> void:
	if not _root.visible:
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _on_round_pressed(max_rounds: int) -> void:
	_apply_selection(max_rounds)


func _on_round_focused(max_rounds: int) -> void:
	_apply_selection(max_rounds)


func _apply_selection(max_rounds: int, _emit_change: bool = true) -> void:
	if max_rounds not in ROUNDS_OPTIONS:
		return
	_selected_max_rounds = max_rounds
	_round_3_button.button_pressed = max_rounds == 3
	_round_5_button.button_pressed = max_rounds == 5
	_round_7_button.button_pressed = max_rounds == 7
	_rounds_summary_label.text = "RONDAS DE LA PARTIDA: %d" % max_rounds


func _on_play_pressed() -> void:
	if not MatchSettings.set_max_rounds(_selected_max_rounds):
		return
	RoundManager.reset()
	ScreenFlow.go_to_scenario_select()


func _on_back_pressed() -> void:
	ScreenFlow.go_to_main_menu()
