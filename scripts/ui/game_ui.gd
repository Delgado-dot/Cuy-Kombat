extends CanvasLayer

@export var game_manager_path: NodePath

@onready var _main_menu := %MainMenu as Control
@onready var _controls_screen := %ControlsScreen as Control
@onready var _options_screen := %OptionsScreen as Control
@onready var _pause_menu := %PauseMenu as Control
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game_manager = get_node_or_null(game_manager_path)
	_connect_buttons()
	_connect_game_manager()
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
	_options_opened_from_pause = false
	get_tree().paused = false
	_main_menu.visible = true
	_controls_screen.visible = false
	_options_screen.visible = false
	_pause_menu.visible = false
	_play_button.grab_focus()


func show_gameplay() -> void:
	_main_menu.visible = false
	_controls_screen.visible = false
	_options_screen.visible = false
	_pause_menu.visible = false


func can_start_match_from_keyboard() -> bool:
	return _main_menu.visible and not get_tree().paused


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

	_pause_main_menu_button.disabled = true
	_pause_main_menu_button.tooltip_text = "Disponible cuando exista un retorno seguro al menú."


func _connect_game_manager() -> void:
	if _game_manager == null:
		push_error("GameUI: no se encontró GameManager.")
		return
	if not _game_manager.has_signal("match_started") or not _game_manager.has_signal("match_finished"):
		push_error("GameUI: GameManager no expone las señales esperadas.")
		return

	if not _game_manager.is_connected("match_started", _on_match_started):
		_game_manager.connect("match_started", _on_match_started)
	if not _game_manager.is_connected("match_finished", _on_match_finished):
		_game_manager.connect("match_finished", _on_match_finished)


func _on_play_pressed() -> void:
	if _game_manager != null and _game_manager.has_method("iniciar_partida"):
		_game_manager.iniciar_partida()


func _on_controls_pressed() -> void:
	_main_menu.visible = false
	_controls_screen.visible = true
	_controls_back_button.grab_focus()


func _show_main_menu_panel() -> void:
	_controls_screen.visible = false
	_options_screen.visible = false
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
	_match_active = true
	get_tree().paused = false
	show_gameplay()


func _on_match_finished(_winner: Node) -> void:
	_match_active = false
	_pause_menu.visible = false
	_options_screen.visible = false
	get_tree().paused = false
