class_name GameManager
extends Node

signal match_started
signal combat_started
signal player_eliminated(player: Node)
signal match_finished(winner: Node)

enum MatchState {
	WAITING,
	COUNTDOWN,
	PLAYING,
	FINISHED,
}

@export var player_paths: Array[NodePath] = []
@export var death_zone_path: NodePath

var match_state := MatchState.WAITING
var _players: Array[Node] = []

@onready var _death_zone := get_node_or_null(death_zone_path) as Area3D


func _ready() -> void:
	_register_players()
	_set_players_input(false)

	if _death_zone == null:
		push_error("GameManager: no se encontró DeathZone.")
	elif not _death_zone.body_entered.is_connected(_on_death_zone_body_entered):
		_death_zone.body_entered.connect(_on_death_zone_body_entered)


func iniciar_partida() -> void:
	if match_state != MatchState.WAITING:
		return

	match_state = MatchState.COUNTDOWN
	_set_players_input(false)
	match_started.emit()


func comenzar_combate() -> void:
	if match_state != MatchState.COUNTDOWN:
		return

	match_state = MatchState.PLAYING
	_set_players_input(true)
	combat_started.emit()


func jugador_eliminado(player: Node) -> void:
	if match_state != MatchState.PLAYING:
		return

	var winner := _find_remaining_player(player)

	if winner == null:
		push_error("GameManager: no se pudo determinar al jugador ganador.")
		return

	player_eliminated.emit(player)
	finalizar_partida(winner)


func finalizar_partida(winner: Node) -> void:
	if match_state != MatchState.PLAYING:
		return

	match_state = MatchState.FINISHED
	_set_players_input(false)
	match_finished.emit(winner)


func get_player_number(player: Node) -> int:
	return _players.find(player) + 1


func _register_players() -> void:
	_players.clear()

	for player_path in player_paths:
		var player := get_node_or_null(player_path)

		if player == null:
			push_error("GameManager: no se encontró un jugador en %s." % player_path)
			continue
		if not player.has_signal("eliminated"):
			push_error("GameManager: %s no tiene la señal eliminated." % player.name)
			continue

		_players.append(player)
		player.eliminated.connect(jugador_eliminado)


func _set_players_input(enabled: bool) -> void:
	for player in _players:
		player.set("input_enabled", enabled)


func _find_remaining_player(eliminated_player: Node) -> Node:
	for player in _players:
		if player != eliminated_player:
			return player

	return null


func _on_death_zone_body_entered(body: Node3D) -> void:
	if match_state != MatchState.PLAYING:
		return
	if body != null and body.has_method("eliminate"):
		body.eliminate()
