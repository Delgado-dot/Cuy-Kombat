extends CanvasLayer

signal scenario_confirmed(scenario_id: StringName)

const COUNTDOWN_STEPS := ["3", "2", "1"]
const COUNTDOWN_STEP_DURATION := 0.85
const FIGHT_MESSAGE_DURATION := 0.65
const ROUND_DURATION_SECONDS := 105
const PLAYER_ONE_COLOR := Color(1.0, 0.38, 0.69, 1.0)
const PLAYER_TWO_COLOR := Color(0.36, 0.78, 1.0, 1.0)

@export var game_manager_path: NodePath

@onready var _main_menu := %MainMenu as Control
@onready var _controls_screen := %ControlsScreen as Control
@onready var _options_screen := %OptionsScreen as Control
@onready var _scenario_select_ui := $ScenarioSelectUI as Control
@onready var _pause_menu := %PauseMenu as Control
@onready var _gameplay_hud := %GameplayHUD as Control
@onready var _round_timer := %RoundTimer as Timer
@onready var _round_timer_label := %RoundTimerLabel as Label
@onready var _countdown_overlay := %CountdownOverlay as Control
@onready var _countdown_label := %CountdownLabel as Label
@onready var _eliminated_overlay := %EliminatedOverlay as Control
@onready var _eliminated_player_label := %EliminatedPlayerLabel as Label
@onready var _play_button := %PlayButton as Button
@onready var _controls_button := %ControlsButton as Button
@onready var _main_options_button := %MainOptionsButton as Button
@onready var _quit_button := %QuitButton as Button
@onready var _controls_back_button := %ControlsBackButton as Button
@onready var _options_back_button := %OptionsBackButton as Button
@onready var _resume_button := %ResumeButton as Button
@onready var _restart_button := %RestartButton as Button
@onready var _pause_options_button := %PauseOptionsButton as Button
@onready var _pause_main_menu_button := %PauseMainMenuButton as Button

var _game_manager: Node
var _match_active := false
var _options_opened_from_pause := false
var _countdown_running := false
var _round_seconds_remaining := ROUND_DURATION_SECONDS


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game_manager = get_node_or_null(game_manager_path)
	_connect_buttons()
	_connect_game_manager()
	_round_timer.timeout.connect(_on_round_timer_timeout)
	show_main_menu()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return

	if _controls_screen.visible:
		get_viewport().set_input_as_handled()
		_show_main_menu_panel()
		return

	if _scenario_select_ui.visible:
		get_viewport().set_input_as_handled()
		_on_scenario_back_requested()
		return

	if _options_screen.visible:
		get_viewport().set_input_as_handled()
		_on_options_back_pressed()
		return

	if not _match_active:
		return

	get_viewport().set_input_as_handled()
	if get_tree().paused:
		_resume_match()
	else:
		_pause_match()


func show_main_menu() -> void:
	_match_active = false
	_countdown_running = false
	_options_opened_from_pause = false
	get_tree().paused = false
	_main_menu.visible = true
	_controls_screen.visible = false
	_options_screen.visible = false
	_scenario_select_ui.call("hide_selector")
	_pause_menu.visible = false
	_gameplay_hud.visible = false
	_countdown_overlay.visible = false
	_eliminated_overlay.visible = false
	_stop_round_timer()
	_play_button.grab_focus()


func show_gameplay() -> void:
	_main_menu.visible = false
	_controls_screen.visible = false
	_options_screen.visible = false
	_scenario_select_ui.call("hide_selector")
	_pause_menu.visible = false


func hide_eliminated_message() -> void:
	_eliminated_overlay.visible = false


func can_start_match_from_keyboard() -> bool:
	# El botón JUGAR enfocado procesa ENTER y abre el selector sin saltárselo.
	return false


func _connect_buttons() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_controls_button.pressed.connect(_on_controls_pressed)
	_main_options_button.pressed.connect(_on_main_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_controls_back_button.pressed.connect(_show_main_menu_panel)
	_options_back_button.pressed.connect(_on_options_back_pressed)
	_resume_button.pressed.connect(_resume_match)
	_restart_button.pressed.connect(_restart_round)
	_pause_options_button.pressed.connect(_on_pause_options_pressed)
	_scenario_select_ui.connect("scenario_confirmed", _on_scenario_confirmed)
	_scenario_select_ui.connect("back_requested", _on_scenario_back_requested)

	_pause_main_menu_button.disabled = true
	_pause_main_menu_button.tooltip_text = "Disponible cuando exista un retorno seguro al menú."


func _connect_game_manager() -> void:
	if _game_manager == null:
		push_error("GameUI: no se encontró GameManager.")
		return
	if (
		not _game_manager.has_signal("match_started")
		or not _game_manager.has_signal("combat_started")
		or not _game_manager.has_signal("player_eliminated")
		or not _game_manager.has_signal("match_finished")
	):
		push_error("GameUI: GameManager no expone las señales esperadas.")
		return

	if not _game_manager.is_connected("match_started", _on_match_started):
		_game_manager.connect("match_started", _on_match_started)
	if not _game_manager.is_connected("combat_started", _on_combat_started):
		_game_manager.connect("combat_started", _on_combat_started)
	if not _game_manager.is_connected("player_eliminated", _on_player_eliminated):
		_game_manager.connect("player_eliminated", _on_player_eliminated)
	if not _game_manager.is_connected("match_finished", _on_match_finished):
		_game_manager.connect("match_finished", _on_match_finished)


func _on_play_pressed() -> void:
	show_scenario_selector()


func show_scenario_selector() -> void:
	_main_menu.visible = false
	_controls_screen.visible = false
	_options_screen.visible = false
	_scenario_select_ui.call("show_selector")


func _on_scenario_back_requested() -> void:
	_scenario_select_ui.call("hide_selector")
	_show_main_menu_panel()


func _on_scenario_confirmed(scenario_id: StringName) -> void:
	scenario_confirmed.emit(scenario_id)


func _on_controls_pressed() -> void:
	_main_menu.visible = false
	_controls_screen.visible = true
	_controls_back_button.grab_focus()


func _show_main_menu_panel() -> void:
	_controls_screen.visible = false
	_options_screen.visible = false
	_scenario_select_ui.call("hide_selector")
	_main_menu.visible = true
	_play_button.grab_focus()


func _on_main_options_pressed() -> void:
	_options_opened_from_pause = false
	_main_menu.visible = false
	_options_screen.visible = true
	_options_back_button.grab_focus()


func _on_pause_options_pressed() -> void:
	_options_opened_from_pause = true
	_pause_menu.visible = false
	_options_screen.visible = true
	_options_back_button.grab_focus()


func _on_options_back_pressed() -> void:
	_options_screen.visible = false
	if _options_opened_from_pause:
		_pause_menu.visible = true
		_resume_button.grab_focus()
	else:
		_main_menu.visible = true
		_play_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _pause_match() -> void:
	_pause_menu.visible = true
	get_tree().paused = true
	_resume_button.grab_focus()


func _resume_match() -> void:
	_pause_menu.visible = false
	_options_screen.visible = false
	get_tree().paused = false


func _restart_round() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_match_started() -> void:
	_match_active = false
	get_tree().paused = false
	show_gameplay()
	_gameplay_hud.visible = false
	_eliminated_overlay.visible = false
	await _run_countdown()


func _run_countdown() -> void:
	if _countdown_running:
		return

	_countdown_running = true
	_countdown_overlay.visible = true

	for step in COUNTDOWN_STEPS:
		_countdown_label.text = step
		await get_tree().create_timer(COUNTDOWN_STEP_DURATION, false).timeout

	_countdown_label.text = "¡PELEA!"
	await get_tree().create_timer(FIGHT_MESSAGE_DURATION, false).timeout
	_countdown_overlay.visible = false
	_countdown_running = false

	if _game_manager != null and _game_manager.has_method("comenzar_combate"):
		_game_manager.comenzar_combate()
	else:
		push_error("GameUI: GameManager no puede comenzar el combate.")


func _on_combat_started() -> void:
	_match_active = true
	_gameplay_hud.visible = true
	_start_round_timer()


func _on_player_eliminated(player: Node) -> void:
	_match_active = false
	_gameplay_hud.visible = false
	_stop_round_timer()

	var player_number: int = _game_manager.get_player_number(player)
	_eliminated_player_label.text = "P%d" % player_number
	_eliminated_player_label.add_theme_color_override(
		"font_color",
		PLAYER_ONE_COLOR if player_number == 1 else PLAYER_TWO_COLOR
	)
	_eliminated_overlay.visible = true


func _on_match_finished(_winner: Node) -> void:
	_match_active = false
	_countdown_running = false
	_countdown_overlay.visible = false
	_gameplay_hud.visible = false
	_stop_round_timer()
	_pause_menu.visible = false
	_options_screen.visible = false
	get_tree().paused = false


func _start_round_timer() -> void:
	_round_seconds_remaining = ROUND_DURATION_SECONDS
	_update_round_timer_label()
	_round_timer.start()


func _stop_round_timer() -> void:
	_round_timer.stop()


func _on_round_timer_timeout() -> void:
	if _round_seconds_remaining <= 0:
		_round_timer.stop()
		return

	_round_seconds_remaining -= 1
	_update_round_timer_label()

	if _round_seconds_remaining == 0:
		_round_timer.stop()


func _update_round_timer_label() -> void:
	var minutes := floori(float(_round_seconds_remaining) / 60.0)
	var seconds := _round_seconds_remaining % 60
	_round_timer_label.text = "%02d:%02d" % [minutes, seconds]
