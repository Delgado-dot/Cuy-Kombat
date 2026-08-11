extends CanvasLayer

@export var game_manager_path: NodePath
@export var winner_screen_path: NodePath
@export var controls_screen_path: NodePath

@onready var _menu_root := %MainMenu as Control
@onready var _play_button := %PlayButton as Button
@onready var _controls_button := %ControlsButton as Button
@onready var _options_button := %MainOptionsButton as Button
@onready var _quit_button := %QuitButton as Button
@onready var _options_message := %OptionsMessage as Label

var _game_manager: Node
var _winner_screen: CanvasLayer
var _controls_screen: CanvasLayer
var _controls_root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_game_manager = get_node_or_null(game_manager_path)
	_winner_screen = get_node_or_null(winner_screen_path) as CanvasLayer
	_controls_screen = get_node_or_null(controls_screen_path) as CanvasLayer

	if _controls_screen != null:
		_controls_root = _controls_screen.get_node_or_null("ControlsScreen") as Control
		if _controls_root != null:
			_controls_root.visibility_changed.connect(_on_controls_visibility_changed)

	_menu_root.visible = true
	_options_message.visible = false
	_play_button.grab_focus()

	_connect_buttons()
	_connect_game_manager()


func _unhandled_input(event: InputEvent) -> void:
	if not _menu_root.visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_on_play_pressed()


func _connect_buttons() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_controls_button.pressed.connect(_on_controls_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _connect_game_manager() -> void:
	if _game_manager == null:
		push_error("MainMenu: no se encontró GameManager.")
		return
	if not _game_manager.has_signal("match_started") or not _game_manager.has_signal("match_finished"):
		push_error("MainMenu: GameManager no expone las señales esperadas.")
		return

	if not _game_manager.match_started.is_connected(_on_match_started):
		_game_manager.match_started.connect(_on_match_started)
	if not _game_manager.match_finished.is_connected(_on_match_finished):
		_game_manager.match_finished.connect(_on_match_finished)


func _on_play_pressed() -> void:
	if _game_manager != null and _game_manager.has_method("iniciar_partida"):
		_game_manager.iniciar_partida()


func _on_controls_pressed() -> void:
	_menu_root.visible = false
	if _controls_screen != null and _controls_screen.has_method("open"):
		_controls_screen.open()


func _on_options_pressed() -> void:
	_options_message.text = "OPCIONES PRÓXIMAMENTE"
	_options_message.visible = true
	_play_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_controls_visibility_changed() -> void:
	if _controls_root != null and not _controls_root.visible:
		_menu_root.visible = true
		_play_button.grab_focus()


func _on_match_started() -> void:
	_menu_root.visible = false


func _on_match_finished(winner: Node) -> void:
	_options_message.visible = false
	if _winner_screen != null and _winner_screen.has_method("show_winner"):
		if _game_manager != null and _game_manager.has_method("get_player_number"):
			_winner_screen.show_winner(_game_manager.get_player_number(winner))
