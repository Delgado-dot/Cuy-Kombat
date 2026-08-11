extends Node3D

const ELIMINATED_MESSAGE_DURATION := 1.5
const ARENA_SCENES := {
	&"volcanica": preload("res://scenes/arenas/ArenaBase.tscn"),
	&"mitad_del_mundo": preload("res://scenes/arenas/ArenaMitadDelMundo.tscn"),
	&"quito": preload("res://scenes/arenas/ArenaQuito.tscn"),
}

@export var game_manager_path: NodePath
@export var start_screen_path: NodePath
@export var winner_screen_path: NodePath
@export var winner_label_path: NodePath

@onready var _game_manager := get_node_or_null(game_manager_path)
@onready var _start_screen := get_node_or_null(start_screen_path) as CanvasLayer
@onready var _winner_screen := get_node_or_null(winner_screen_path) as CanvasLayer
@onready var _winner_label := get_node_or_null(winner_label_path) as Label
@onready var _spawn_manager := get_node_or_null("SpawnManager")
@onready var _player_one := get_node_or_null("Player1") as Node3D
@onready var _player_two := get_node_or_null("Player2") as Node3D

var _arena_switch_in_progress := false

func _ready() -> void:
	if _start_screen != null:
		_start_screen.visible = true
		if _start_screen.has_method("show_main_menu"):
			_start_screen.call("show_main_menu")
		if _start_screen.has_signal("scenario_confirmed"):
			if not _start_screen.is_connected("scenario_confirmed", _on_scenario_confirmed):
				_start_screen.connect("scenario_confirmed", _on_scenario_confirmed)
		else:
			push_error("DemoStartScreen: la UI no expone scenario_confirmed.")
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


func _on_scenario_confirmed(scenario_id: StringName) -> void:
	if _arena_switch_in_progress:
		return

	var arena_scene := ARENA_SCENES.get(scenario_id) as PackedScene
	if arena_scene == null:
		push_error("DemoStartScreen: escenario desconocido: %s" % scenario_id)
		return

	var new_arena := arena_scene.instantiate() as Node3D
	if not _is_valid_arena(new_arena):
		if new_arena != null:
			new_arena.free()
		push_error("DemoStartScreen: la arena seleccionada no tiene los SpawnPoints requeridos.")
		return

	var current_arena := get_node_or_null("Arena") as Node3D
	if current_arena == null:
		new_arena.free()
		push_error("DemoStartScreen: no se encontró la arena activa Main/Arena.")
		return
	if _spawn_manager == null or not _spawn_manager.has_method("colocar_jugadores"):
		new_arena.free()
		push_error("DemoStartScreen: SpawnManager no está disponible.")
		return
	if _game_manager == null or not _game_manager.has_method("iniciar_partida"):
		new_arena.free()
		push_error("DemoStartScreen: GameManager no puede iniciar la partida.")
		return
	if int(_game_manager.get("match_state")) != GameManager.MatchState.WAITING:
		new_arena.free()
		push_error("DemoStartScreen: solo se puede elegir arena desde WAITING.")
		return

	_arena_switch_in_progress = true
	var arena_transform := current_arena.transform
	var arena_index := current_arena.get_index()
	var arena_exited := current_arena.tree_exited
	current_arena.queue_free()
	await arena_exited

	new_arena.name = "Arena"
	new_arena.transform = arena_transform
	add_child(new_arena)
	move_child(new_arena, mini(arena_index, get_child_count() - 1))
	await get_tree().process_frame

	_spawn_manager.call("colocar_jugadores")
	_reconnect_players_to_central_hole()
	_game_manager.call("iniciar_partida")
	_arena_switch_in_progress = false


func _is_valid_arena(arena: Node3D) -> bool:
	if arena == null:
		return false
	return (
		arena.get_node_or_null("PuntosDeAparicion/SpawnJugador1") is Marker3D
		and arena.get_node_or_null("PuntosDeAparicion/SpawnJugador2") is Marker3D
		and arena.get_node_or_null("PuntosDeAparicion/SpawnJugador3") is Marker3D
		and arena.get_node_or_null("PuntosDeAparicion/SpawnJugador4") is Marker3D
		and arena.find_child("AgujeroCentral", true, false) is Area3D
	)


func _reconnect_players_to_central_hole() -> void:
	for player in [_player_one, _player_two]:
		if player != null and player.has_method("_connect_death_zone"):
			player.call("_connect_death_zone")

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
