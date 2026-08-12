extends CanvasLayer

const PLAYER_ONE_COLOR := Color(1.0, 0.38, 0.69, 1.0)
const PLAYER_TWO_COLOR := Color(0.36, 0.78, 1.0, 1.0)

@export var game_manager_path: NodePath

@onready var _winner_label := %WinnerLabel as Label
@onready var _confetti := %Confetti as CPUParticles2D
@onready var _next_round_button := %NextRoundButton as Button
@onready var _main_menu_button := %MainMenuButton as Button

var _game_manager: Node
var _winner_shown := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_next_round_button.disabled = true
	_next_round_button.tooltip_text = "Disponible cuando exista un reinicio seguro de ronda."
	_main_menu_button.pressed.connect(_return_to_main_menu)
	_update_confetti_area()

	_game_manager = get_node_or_null(game_manager_path)
	_connect_game_manager()


func show_winner(player_number: int) -> void:
	if _winner_shown:
		return

	_winner_shown = true
	_winner_label.text = "Jugador %d ganó" % player_number
	_winner_label.add_theme_color_override(
		"font_color",
		PLAYER_ONE_COLOR if player_number == 1 else PLAYER_TWO_COLOR
	)
	visible = true
	_update_confetti_area()
	_confetti.restart()
	_confetti.emitting = true
	_main_menu_button.grab_focus()


func _update_confetti_area() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_confetti.position = Vector2(viewport_size.x * 0.5, 40.0)
	_confetti.emission_rect_extents.x = viewport_size.x * 0.48


func _connect_game_manager() -> void:
	if _game_manager == null:
		push_error("WinnerScreen: no se encontró GameManager.")
		return
	if not _game_manager.has_signal("match_finished"):
		push_error("WinnerScreen: GameManager no expone la señal match_finished.")
		return

	if not _game_manager.match_finished.is_connected(_on_match_finished):
		_game_manager.match_finished.connect(_on_match_finished)


func _on_match_finished(winner: Node) -> void:
	var player_number := 0
	if _game_manager != null and _game_manager.has_method("get_player_number"):
		player_number = _game_manager.get_player_number(winner)
	show_winner(player_number)


func _return_to_main_menu() -> void:
	get_tree().paused = false
	ScreenFlow.go_to_main_menu()
