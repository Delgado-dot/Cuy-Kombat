class_name ScenarioManager
extends Node

const ARENA_SCENES := {
	&"volcanica": preload("res://scenes/arenas/ArenaBase.tscn"),
	&"mitad_del_mundo": preload("res://scenes/arenas/ArenaMitadDelMundo.tscn"),
	&"quito": preload("res://scenes/arenas/ArenaQuito.tscn"),
}

@export var game_manager_path: NodePath
@export var spawn_manager_path: NodePath
@export var scenario_select_path: NodePath
@export var arena_path: NodePath
@export var objects_spawner_path: NodePath

var _game_manager: Node
var _spawn_manager: Node
var _scenario_select: Node
var _objects_spawner: Node
var _switching := false


func _ready() -> void:
	_game_manager = get_node_or_null(game_manager_path)
	_spawn_manager = get_node_or_null(spawn_manager_path)
	_scenario_select = get_node_or_null(scenario_select_path)
	_objects_spawner = get_node_or_null(objects_spawner_path)

	if _scenario_select != null:
		if not _scenario_select.has_signal("scenario_confirmed"):
			push_error("ScenarioManager: ScenarioSelectUI no expone scenario_confirmed.")
			return
		if not _scenario_select.is_connected("scenario_confirmed", _on_scenario_confirmed):
			_scenario_select.connect("scenario_confirmed", _on_scenario_confirmed)

	# main.tscn es gameplay puro: sin selector embebido se arranca la partida
	# con el escenario elegido en ScreenFlow (o el volcánico por defecto).
	if _scenario_select == null:
		await get_tree().process_frame
		_start_match(ScreenFlow.selected_scenario)


func _on_scenario_confirmed(scenario_id: StringName) -> void:
	_start_match(scenario_id)


func _start_match(scenario_id: StringName) -> void:
	if _switching:
		return
	if _game_manager == null or _game_manager.get("match_state") != GameManager.MatchState.WAITING:
		push_error("ScenarioManager: solo se puede elegir escenario desde WAITING.")
		return

	var arena_scene := ARENA_SCENES.get(scenario_id) as PackedScene
	if arena_scene == null:
		push_error("ScenarioManager: escenario desconocido: %s" % scenario_id)
		return

	var current_arena := get_node_or_null(arena_path) as Node3D
	if current_arena == null:
		push_error("ScenarioManager: no se encontró la arena activa Main/Arena.")
		return
	if _spawn_manager == null or not _spawn_manager.has_method("colocar_jugadores"):
		push_error("ScenarioManager: SpawnManager no está disponible.")
		return
	if _game_manager == null or not _game_manager.has_method("iniciar_partida"):
		push_error("ScenarioManager: GameManager no puede iniciar la partida.")
		return

	_switching = true
	_free_spawned_objects()

	var parent := current_arena.get_parent()
	var arena_transform := current_arena.transform
	var arena_name := current_arena.name
	var arena_index := current_arena.get_index()
	var arena_exited := current_arena.tree_exited

	current_arena.queue_free()
	await arena_exited

	var new_arena := arena_scene.instantiate() as Node3D
	new_arena.name = arena_name
	new_arena.transform = arena_transform
	parent.add_child(new_arena)
	parent.move_child(new_arena, mini(arena_index, parent.get_child_count() - 1))

	await get_tree().physics_frame
	await get_tree().process_frame

	if _scenario_select != null and _scenario_select.has_method("hide_selector"):
		_scenario_select.call("hide_selector")

	_reconnect_players_to_central_hole()
	_spawn_manager.call("colocar_jugadores")

	if _objects_spawner != null and _objects_spawner.has_method("_spawn_objects"):
		_objects_spawner.call("_spawn_objects")

	MusicManager.play_arena_music()
	_game_manager.iniciar_partida()
	_switching = false


func _free_spawned_objects() -> void:
	if _objects_spawner == null:
		return
	for obj in _objects_spawner.get_children():
		if obj is Node:
			obj.queue_free()


func _reconnect_players_to_central_hole() -> void:
	if _game_manager == null:
		return
	var player_paths := _game_manager.get("player_paths") as Array
	for player_path in player_paths:
		var player := get_node_or_null(player_path) as Node
		if player != null and player.has_method("_connect_death_zone"):
			player.call("_connect_death_zone")


func start_next_round() -> void:
	if _switching:
		return
	var next_arena := _pick_next_arena(ScreenFlow.selected_scenario)
	ScreenFlow.selected_scenario = next_arena
	get_tree().reload_current_scene()


func _pick_next_arena(current: StringName) -> StringName:
	var candidates: Array[StringName] = []
	for arena_id in ARENA_SCENES:
		if arena_id != current:
			candidates.append(arena_id)
	if candidates.is_empty():
		return current
	candidates.shuffle()
	return candidates[0]
