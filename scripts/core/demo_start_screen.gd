extends Node3D

@export var game_manager_path: NodePath
@export var start_screen_path: NodePath
@export var winner_screen_path: NodePath

@onready var _game_manager := get_node_or_null(game_manager_path) as GameManager
@onready var _start_screen := get_node_or_null(start_screen_path) as CanvasLayer
@onready var _winner_screen := get_node_or_null(winner_screen_path) as CanvasLayer

var _match_finished := false

func _ready() -> void:
	if _start_screen != null:
		_start_screen.visible = true
	if _winner_screen != null:
		_winner_screen.visible = false

	if _game_manager == null:
		push_error("DemoStartScreen: no se encontró GameManager.")
		return

	if not _game_manager.match_started.is_connected(_on_match_started):
		_game_manager.match_started.connect(_on_match_started)
	if not _game_manager.match_finished.is_connected(_on_match_finished):
		_game_manager.match_finished.connect(_on_match_finished)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if not _match_finished and event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_start_match()
	elif _match_finished and event.keycode == KEY_R:
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()

func _start_match() -> void:
	if _game_manager != null:
		_game_manager.iniciar_partida()

func _on_match_started() -> void:
	if _start_screen != null:
		_start_screen.visible = false

func _on_match_finished(winner: Node) -> void:
	_match_finished = true

	if _winner_screen == null or _game_manager == null:
		return
	if _winner_screen.has_method("show_winner"):
		_winner_screen.show_winner(_game_manager.get_player_number(winner))
