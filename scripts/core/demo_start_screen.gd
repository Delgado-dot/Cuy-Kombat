extends Node3D

@export var player_paths: Array[NodePath] = []
@export var start_screen_path: NodePath
@export var winner_screen_path: NodePath
@export var winner_label_path: NodePath
@export var death_zone_path: NodePath

@onready var _start_screen := get_node_or_null(start_screen_path) as CanvasLayer
@onready var _winner_screen := get_node_or_null(winner_screen_path) as CanvasLayer
@onready var _winner_label := get_node_or_null(winner_label_path) as Label
@onready var _death_zone := get_node_or_null(death_zone_path) as Area3D

var _match_started := false
var _match_finished := false

func _ready() -> void:
	_connect_players()
	_set_players_input(false)

	if _start_screen != null:
		_start_screen.visible = true
	if _winner_screen != null:
		_winner_screen.visible = false
	if _death_zone != null:
		_death_zone.body_entered.connect(_on_death_zone_body_entered)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if not _match_started and event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_start_match()
	elif _match_finished and event.keycode == KEY_R:
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()

func _start_match() -> void:
	_match_started = true

	if _start_screen != null:
		_start_screen.visible = false

	_set_players_input(true)

func _set_players_input(enabled: bool) -> void:
	for player_path in player_paths:
		var player := get_node_or_null(player_path)

		if player != null:
			player.set("input_enabled", enabled)

func _connect_players() -> void:
	for player_path in player_paths:
		var player := get_node_or_null(player_path)

		if player == null:
			continue
		if player.has_signal("eliminated"):
			player.eliminated.connect(_on_player_eliminated)

func _on_death_zone_body_entered(body: Node3D) -> void:
	if body != null and body.has_method("eliminate"):
		body.eliminate()

func _on_player_eliminated(player: Node) -> void:
	if _match_finished:
		return

	_match_finished = true
	_set_players_input(false)
	_show_winner_for(player)

func _show_winner_for(eliminated_player: Node) -> void:
	var winner_index := 0

	for index in range(player_paths.size()):
		var player := get_node_or_null(player_paths[index])

		if player != null and player != eliminated_player:
			winner_index = index + 1
			break

	if _winner_label != null:
		_winner_label.text = "PLAYER %d GANO\nPresiona R para reiniciar" % winner_index
	if _winner_screen != null:
		_winner_screen.visible = true
