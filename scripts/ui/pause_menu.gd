extends CanvasLayer

@export var game_manager_path: NodePath

@onready var _pause_menu := %PauseMenu as Control
@onready var _resume_button := %ResumeButton as Button
@onready var _restart_button := %RestartButton as Button
@onready var _pause_options_button := %PauseOptionsButton as Button
@onready var _pause_main_menu_button := %PauseMainMenuButton as Button

var _game_manager: Node
var _match_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_menu.visible = false
	_game_manager = get_node_or_null(game_manager_path)

	_resume_button.pressed.connect(_resume_match)
	_restart_button.pressed.connect(_restart_round)
	_pause_main_menu_button.pressed.connect(_exit_to_main_menu)

	_pause_options_button.disabled = true
	_pause_options_button.tooltip_text = "Disponible en una fase futura."

	_connect_game_manager()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if event is InputEventKey and event.echo:
		return
	if not _match_active:
		return

	get_viewport().set_input_as_handled()
	if get_tree().paused:
		_resume_match()
	else:
		_pause_match()


func _pause_match() -> void:
	_pause_menu.visible = true
	get_tree().paused = true
	_resume_button.grab_focus()


func _resume_match() -> void:
	_pause_menu.visible = false
	get_tree().paused = false


func _restart_round() -> void:
	get_tree().paused = false
	ScreenFlow.reload_for_next_round()


func _exit_to_main_menu() -> void:
	_match_active = false
	_pause_menu.visible = false
	get_tree().paused = false
	ScreenFlow.go_to_main_menu()


func _connect_game_manager() -> void:
	if _game_manager == null:
		push_error("PauseMenu: no se encontró GameManager.")
		return
	if not _game_manager.has_signal("match_started") or not _game_manager.has_signal("match_finished"):
		push_error("PauseMenu: GameManager no expone las señales esperadas.")
		return

	if not _game_manager.match_started.is_connected(_on_match_started):
		_game_manager.match_started.connect(_on_match_started)
	if not _game_manager.match_finished.is_connected(_on_match_finished):
		_game_manager.match_finished.connect(_on_match_finished)


func _on_match_started() -> void:
	_match_active = true
	get_tree().paused = false
	_pause_menu.visible = false


func _on_match_finished(_winner: Node) -> void:
	_match_active = false
	_pause_menu.visible = false
	get_tree().paused = false
