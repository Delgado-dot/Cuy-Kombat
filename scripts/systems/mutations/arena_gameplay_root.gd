class_name ArenaGameplayRoot
extends Node3D

## Agrupa en runtime las piezas jugables de cualquier escenario y aplica la
## inclinacion solicitada por las mutaciones sin afectar camara, UI ni fondo.

@export var gameplay_node_paths: Array[NodePath] = []
@export_range(0.5, 1.0, 0.05) var activation_duration := 0.75

var _game_manager: Node
var _round_active := false
var _dynamic_tilt_active := false
var _tilt_angle := 0.0
var _tilt_speed := 0.0
var _tilt_phase := 0.0
var _tilt_weight := 0.0


func _ready() -> void:
	# La arena cargada tiene escala no uniforme en main.tscn. Al volver esta
	# raiz top-level, la rotacion se compone sin deformar piso ni colisiones.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	top_level = true
	rotation = Vector3.ZERO
	set_physics_process(false)

	if not MutationManager.mutations_changed.is_connected(_refresh_mutation_state):
		MutationManager.mutations_changed.connect(_refresh_mutation_state)

	call_deferred("_setup_gameplay_root")


func _exit_tree() -> void:
	_stop_dynamic_tilt()


func _setup_gameplay_root() -> void:
	_reparent_gameplay_nodes()
	_connect_game_manager()
	_refresh_mutation_state()


func _reparent_gameplay_nodes() -> void:
	for node_path in gameplay_node_paths:
		var gameplay_node := get_node_or_null(node_path) as Node3D
		if gameplay_node == null:
			push_error("ArenaGameplayRoot: no se encontro el nodo jugable %s." % node_path)
			continue
		gameplay_node.reparent(self, true)


func _connect_game_manager() -> void:
	var arena := get_parent()
	var main := arena.get_parent() if arena != null else null
	_game_manager = main.get_node_or_null("GameManager") if main != null else null

	if _game_manager == null:
		push_error("ArenaGameplayRoot: no se encontro GameManager.")
		return

	if not _game_manager.match_started.is_connected(_on_match_started):
		_game_manager.match_started.connect(_on_match_started)
	if not _game_manager.match_finished.is_connected(_on_match_finished):
		_game_manager.match_finished.connect(_on_match_finished)

	_round_active = _game_manager.get("match_state") == GameManager.MatchState.PLAYING


func _refresh_mutation_state() -> void:
	_tilt_angle = MutationManager.get_arena_tilt_angle()
	_tilt_speed = MutationManager.get_arena_tilt_speed()
	var should_move := _round_active and _tilt_angle > 0.0 and _tilt_speed > 0.0

	if not should_move:
		_stop_dynamic_tilt()
		return

	if _dynamic_tilt_active:
		return

	_dynamic_tilt_active = true
	_tilt_phase = 0.0
	_tilt_weight = 0.0
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _dynamic_tilt_active:
		return

	_tilt_weight = move_toward(_tilt_weight, 1.0, delta / activation_duration)
	_tilt_phase = fposmod(_tilt_phase + _tilt_speed * delta, TAU)
	rotation = Vector3(
		cos(_tilt_phase) * _tilt_angle * _tilt_weight,
		0.0,
		sin(_tilt_phase) * _tilt_angle * _tilt_weight
	)


func _stop_dynamic_tilt() -> void:
	_dynamic_tilt_active = false
	_tilt_phase = 0.0
	_tilt_weight = 0.0
	set_physics_process(false)
	rotation = Vector3.ZERO


func _on_match_started() -> void:
	_round_active = true
	_refresh_mutation_state()


func _on_match_finished(_winner: Node) -> void:
	_round_active = false
	_stop_dynamic_tilt()
