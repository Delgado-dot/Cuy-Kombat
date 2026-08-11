extends Node3D

const ELIMINATED_MESSAGE_DURATION := 1.5

@export var game_manager_path: NodePath
@export var start_screen_path: NodePath
@export var winner_screen_path: NodePath
@export var winner_label_path: NodePath

@onready var _game_manager := get_node_or_null(game_manager_path)
@onready var _start_screen := get_node_or_null(start_screen_path) as CanvasLayer
@onready var _winner_screen := get_node_or_null(winner_screen_path) as CanvasLayer
@onready var _winner_label := get_node_or_null(winner_label_path) as Label

func _ready() -> void:
	if _start_screen != null:
		_start_screen.visible = true
		if _start_screen.has_method("show_main_menu"):
			_start_screen.call("show_main_menu")
	if _winner_screen != null:
		_winner_screen.visible = false

	if _game_manager == null:
		push_error("DemoStartScreen: no se encontró GameManager.")
		return
	if not _game_manager.has_signal("match_started") or not _game_manager.has_signal("match_finished"):
		push_error("DemoStartScreen: GameManager no expone las señales esperadas.")
		return

	_game_manager.connect("match_started", _on_match_started)
	_game_manager.connect("match_finished", _on_match_finished)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return

	if (
		_game_manager != null
		and _game_manager.has_method("iniciar_partida")
		and _can_start_from_keyboard()
		and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)
	):
		get_viewport().set_input_as_handled()
		_game_manager.iniciar_partida()
		return

	if (
		_winner_screen != null
		and _winner_screen.visible
		and event.keycode == KEY_R
	):
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()

func _on_match_started() -> void:
	if _start_screen != null and not _start_screen.has_method("show_gameplay"):
		_start_screen.visible = false


func _can_start_from_keyboard() -> bool:
	if _start_screen == null:
		return true
	if _start_screen.has_method("can_start_match_from_keyboard"):
		return bool(_start_screen.call("can_start_match_from_keyboard"))
	return _start_screen.visible

func _on_match_finished(winner: Node) -> void:
	var winner_number: int = _game_manager.get_player_number(winner)

	await get_tree().create_timer(ELIMINATED_MESSAGE_DURATION, false).timeout
	if _start_screen != null and _start_screen.has_method("hide_eliminated_message"):
		_start_screen.call("hide_eliminated_message")

	if _winner_screen != null and _winner_screen.has_method("show_winner"):
		_winner_screen.call("show_winner", winner_number)
		return

	if _winner_label != null:
		_winner_label.text = "PLAYER %d GANO\nPresiona R para reiniciar" % winner_number
	if _winner_screen != null:
		_winner_screen.visible = true
