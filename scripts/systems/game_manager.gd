class_name GameManager
extends Node

signal match_started
signal match_finished(winner: Node)
signal match_intro_updated(text: String)

enum MatchState {
	WAITING,
	PLAYING,
	FINISHED,
}

@export var player_paths: Array[NodePath] = []
@export var death_zone_path: NodePath

var match_state := MatchState.WAITING
var _players: Array[Node] = []
var _eliminated_players: Array[Node] = []
var _intro_running := false

@onready var _death_zone := get_node_or_null(death_zone_path) as Area3D


func _ready() -> void:
	_register_players()
	_set_players_input(false)

	if _death_zone == null:
		push_error("GameManager: no se encontró DeathZone.")
	elif not _death_zone.body_entered.is_connected(_on_death_zone_body_entered):
		_death_zone.body_entered.connect(_on_death_zone_body_entered)


func iniciar_partida() -> void:
	if match_state != MatchState.WAITING or _intro_running:
		return

	_intro_running = true
	_set_players_input(false)
	_play_match_intro()


func _play_match_intro() -> void:
	for text in ["3", "2", "1"]:
		match_intro_updated.emit(text)
		await get_tree().create_timer(1.0).timeout

	match_intro_updated.emit("¡PELEA!")
	await get_tree().create_timer(0.8).timeout

	match_state = MatchState.PLAYING
	_set_players_input(true)
	match_started.emit()
	_intro_running = false


func jugador_eliminado(player: Node) -> void:
	if match_state != MatchState.PLAYING:
		return
	if player in _eliminated_players:
		return

	_eliminated_players.append(player)

	var winner := _find_remaining_player()

	if winner == null:
		push_error("GameManager: no se pudo determinar al jugador ganador.")
		return

	finalizar_partida(winner)


func finalizar_partida(winner: Node) -> void:
	if match_state != MatchState.PLAYING:
		return

	match_state = MatchState.FINISHED
	_set_players_input(false)
	match_finished.emit(winner)


func finalizar_partida_por_tiempo() -> void:
	if match_state != MatchState.PLAYING:
		return

	match_state = MatchState.FINISHED
	_set_players_input(false)
	match_finished.emit(_player_leading_by_health())


func get_player_number(player: Node) -> int:
	return _players.find(player) + 1


func _player_leading_by_health() -> Node:
	var best: Node = _players[0] if not _players.is_empty() else null
	var best_health := -1.0

	for player in _players:
		var health := _get_player_health(player)
		if health > best_health:
			best_health = health
			best = player

	return best


func _get_player_health(player: Node) -> float:
	if player == null or not is_instance_valid(player):
		return 0.0

	var threshold := float(player.get("knockout_threshold"))
	if threshold <= 0.0:
		return 1.0

	var hits := float(player.get("knockout_hits"))
	return clampf(1.0 - hits / threshold, 0.0, 1.0)


func _register_players() -> void:
	_players.clear()
	_eliminated_players.clear()

	var active_count := MatchSettings.get_player_count()
	var count := mini(player_paths.size(), active_count)

	for i in range(count):
		var player_path := player_paths[i]
		var player := get_node_or_null(player_path)

		if player == null:
			push_error("GameManager: no se encontró un jugador en %s." % player_path)
			continue
		if not player.has_signal("eliminated"):
			push_error("GameManager: %s no tiene la señal eliminated." % player.name)
			continue

		player.visible = true
		player.set("input_enabled", false)
		_players.append(player)
		player.eliminated.connect(jugador_eliminado)

	for i in range(count, player_paths.size()):
		var extra := get_node_or_null(player_paths[i])
		if extra != null:
			extra.visible = false
			extra.set("input_enabled", false)


func _set_players_input(enabled: bool) -> void:
	for player in _players:
		player.set("input_enabled", enabled)


func _find_remaining_player() -> Node:
	var remaining: Node = null

	for player in _players:
		if player in _eliminated_players:
			continue
		if remaining != null:
			return null
		remaining = player

	return remaining


func _on_death_zone_body_entered(body: Node3D) -> void:
	if match_state != MatchState.PLAYING:
		return
	if body != null and body.has_method("eliminate"):
		body.eliminate()
