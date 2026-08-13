extends Node

## Sistema central de mutaciones.
## Se registra como autoload ("MutationManager") en project.godot para poder
## ser consultado desde cualquier sistema (player, spawner, UI, etc.).
##
## Responsabilidades:
## - Saber qué mutaciones están activas.
## - Activarlas / desactivarlas.
## - Consultar si una mutación está activa.
## - Aplicar sus efectos vía get_stat_multiplier().
## - Quitarlas al terminar la partida (clear()).
##
## Las mutaciones son temporales: se activan antes de la partida y se limpian
## al terminar, de modo que la siguiente partida comienza sin modificaciones.

signal mutations_changed

const MUTATION_SCRIPTS := {
	&"super_speed": preload("res://scripts/systems/mutations/super_speed.gd"),
	&"powerful_hits": preload("res://scripts/systems/mutations/powerful_hits.gd"),
	&"low_gravity": preload("res://scripts/systems/mutations/low_gravity.gd"),
	&"fast_recovery": preload("res://scripts/systems/mutations/fast_recovery.gd"),
	&"slow_recovery": preload("res://scripts/systems/mutations/slow_recovery.gd"),
	&"slippery_floor": preload("res://scripts/systems/mutations/slippery_floor.gd"),
	&"inclined_arena": preload("res://scripts/systems/mutations/inclined_arena.gd"),
	&"giant_cuy": preload("res://scripts/systems/mutations/giant_cuy.gd"),
}

const MUTATION_IDS: Array[StringName] = [
	&"super_speed",
	&"powerful_hits",
	&"low_gravity",
	&"fast_recovery",
	&"slow_recovery",
	&"slippery_floor",
	&"inclined_arena",
	&"giant_cuy",
]

var _active: Dictionary = {}

func is_active(id: StringName) -> bool:
	return _active.has(id)

func activate(id: StringName) -> bool:
	if _active.has(id):
		return true

	var script: Script = MUTATION_SCRIPTS.get(id)
	if script == null:
		push_error("MutationManager: mutación desconocida '%s'." % id)
		return false

	_active[id] = script.new()
	mutations_changed.emit()
	return true

func deactivate(id: StringName) -> bool:
	if not _active.erase(id):
		return false
	mutations_changed.emit()
	return true

func clear() -> void:
	if _active.is_empty():
		return
	_active.clear()
	mutations_changed.emit()

## Reemplaza todas las mutaciones activas por la lista indicada.
func set_active(ids: Array[StringName]) -> void:
	_active.clear()
	for id in ids:
		var script: Script = MUTATION_SCRIPTS.get(id)
		if script != null:
			_active[id] = script.new()
	mutations_changed.emit()

func get_active_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in _active.keys():
		result.append(id)
	return result

func get_active_count() -> int:
	return _active.size()

func get_all_mutation_ids() -> Array[StringName]:
	return MUTATION_IDS.duplicate()

## Metadatos (id, display_name, description) para futuras pantallas de menú.
func get_mutation_meta(id: StringName) -> Dictionary:
	var script: Script = MUTATION_SCRIPTS.get(id)
	if script == null:
		return {}
	var mutation: Mutation = script.new()
	return {
		"id": mutation.get_id(),
		"display_name": mutation.get_display_name(),
		"description": mutation.get_description(),
	}

## Punto de consulta de los sistemas del juego.
## Multiplica los multiplicadores de todas las mutaciones activas para una
## estadística. Devuelve 1.0 cuando ninguna mutación la modifica.
func get_stat_multiplier(player: Node, stat: StringName) -> float:
	var multiplier := 1.0
	for mutation in _active.values():
		multiplier *= (mutation as Mutation).get_stat_multiplier(player, stat)
	return multiplier

## Suma las velocidades de deslizamiento (arena inclinada) de las mutaciones
## activas. Devuelve Vector3.ZERO cuando ninguna empuja al jugador.
func get_slide_direction(player: Node) -> Vector3:
	var result := Vector3.ZERO
	for mutation in _active.values():
		result += (mutation as Mutation).get_slide_direction(player)
	return result

## Multiplica los multiplicadores de escala (tamaño) de las mutaciones
## activas. Devuelve 1.0 cuando ninguna mutación modifica el tamaño.
func get_scale_multiplier(player: Node) -> float:
	var multiplier := 1.0
	for mutation in _active.values():
		multiplier *= (mutation as Mutation).get_scale_multiplier(player)
	return multiplier
