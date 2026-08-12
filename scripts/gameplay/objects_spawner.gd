extends Node3D

## Spawner minimo del modulo Objetos e Interaccion.
## Instancia un conjunto aleatorio de objetos (Barrel/BreakableBox/Rock)
## dentro de la arena, encima del suelo detectado por raycast, evitando
## spawn/posiciones de jugadores y solapamiento entre objetos.
## No modifica arenas ni SpawnManager. No aplica impulsos ni freeze.

const OBJECT_SCENES: Array[PackedScene] = [
	preload("res://scenes/gameplay/barrel.tscn"),
	preload("res://scenes/gameplay/breakable_box.tscn"),
	preload("res://scenes/gameplay/rock.tscn"),
]

## Maximo de objetos por arena.
@export var max_objects := 8
@export var min_objects := 4
## Radio minimo/maximo (mundo) alrededor de spawn_center donde se generan.
@export_range(0.0, 60.0) var min_spawn_radius := 8.0
@export_range(0.0, 60.0) var max_spawn_radius := 16.0
@export var spawn_center := Vector3.ZERO
## Distancia horizontal minima entre objetos generados.
@export var min_separation := 2.2
## Distancia minima a los nodos a evitar (spawn de jugadores, etc).
@export var avoid_distance := 3.5
@export var avoid_node_paths: Array[NodePath] = []
## Altura desde la que se lanza el raycast al suelo.
@export var ray_origin_height := 30.0
@export var ray_length := 40.0
## -1 = semilla aleatoria en cada corrida.
@export var seed_value := -1

var _rng := RandomNumberGenerator.new()
var _spawned: Array[Node3D] = []


func _ready() -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_spawn_objects()
	print(get_debug_summary())


func _spawn_objects() -> void:
	var count := _rng.randi_range(min_objects, max_objects)
	var avoidance: Array[Node3D] = []
	for node_path in avoid_node_paths:
		var node := get_node_or_null(node_path)
		if node is Node3D:
			avoidance.append(node as Node3D)

	var placed: Array[Vector3] = []

	for i in count:
		var obj: Node3D = null
		var obj_pos := Vector3.ZERO

		for attempt in 50:
			var angle := _rng.randf() * TAU
			var radius := _rng.randf_range(min_spawn_radius, max_spawn_radius)
			var probe := spawn_center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

			if _too_near_avoidance(probe, avoidance):
				continue
			if _too_near_placed(probe, placed):
				continue

			var floor_hit: Variant = _raycast_floor(probe, avoidance)
			if floor_hit == null:
				continue

			var scene := OBJECT_SCENES[_rng.randi_range(0, OBJECT_SCENES.size() - 1)]
			obj = scene.instantiate() as Node3D
			add_child(obj)
			obj.global_position = floor_hit + Vector3(0.0, _ground_offset(obj), 0.0)
			obj.global_rotation = Vector3.ZERO
			obj_pos = probe
			placed.append(obj_pos)
			_spawned.append(obj)
			break

		if obj == null:
			push_warning("[ObjectsSpawner] No se encontro posicion valida para el objeto %d/%d" % [i + 1, count])


## Raycast vertical hacia abajo para encontrar la superficie del suelo.
## Devuelve el punto del impacto (Vector3) o null si no hay suelo.
func _raycast_floor(probe: Vector3, avoidance: Array[Node3D]) -> Variant:
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.new()
	params.from = probe + Vector3(0.0, ray_origin_height, 0.0)
	params.to = probe + Vector3(0.0, -ray_length, 0.0)
	params.collide_with_areas = false
	params.collide_with_bodies = true

	var exclude: Array[RID] = []
	for node in avoidance:
		if node is PhysicsBody3D:
			exclude.append((node as PhysicsBody3D).get_rid())
	params.exclude = exclude

	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return null

	var collider: Object = hit["collider"]
	if collider is StaticBody3D or collider is CSGShape3D:
		return hit["position"] as Vector3
	# Volvió a golpear algo que no es suelo (jugador/objeto): repetir sin el punto.
	return null


func _too_near_avoidance(pos: Vector3, avoidance: Array[Node3D]) -> bool:
	for node in avoidance:
		var target := pos
		if node is Node3D:
			target = (node as Node3D).global_position
		if pos.distance_to(target) < avoid_distance:
			return true
	return false


func _too_near_placed(pos: Vector3, placed: Array[Vector3]) -> bool:
	for other in placed:
		if pos.distance_to(other) < min_separation:
			return true
	return false


## Devuelve la altura a la que debe colocarse el centro del objeto para que su
## base quede apoyada en el suelo (punto del impacto del raycast).
func _ground_offset(obj: Node3D) -> float:
	var col := obj.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null or col.shape == null:
		return 0.6

	var basis := col.transform.basis
	match col.shape.get_class():
		"BoxShape3D":
			return _max_corner_y(basis, (col.shape as BoxShape3D).size * 0.5)
		"SphereShape3D":
			return (col.shape as SphereShape3D).radius
		"CylinderShape3D":
			var axis := (basis * Vector3.UP).normalized()
			if absf(axis.y) > 0.85:
				return (col.shape as CylinderShape3D).height * 0.5
			return (col.shape as CylinderShape3D).radius
		"CapsuleShape3D":
			var cap_axis := (basis * Vector3.UP).normalized()
			if absf(cap_axis.y) > 0.85:
				return (col.shape as CapsuleShape3D).height * 0.5
			return (col.shape as CapsuleShape3D).radius
	return 0.6


func _max_corner_y(basis: Basis, half: Vector3) -> float:
	var max_y := absf((basis * Vector3(half.x, half.y, half.z)).y)
	max_y = maxf(max_y, absf((basis * Vector3(-half.x, half.y, half.z)).y))
	max_y = maxf(max_y, absf((basis * Vector3(half.x, -half.y, half.z)).y))
	max_y = maxf(max_y, absf((basis * Vector3(-half.x, -half.y, half.z)).y))
	max_y = maxf(max_y, absf((basis * Vector3(half.x, half.y, -half.z)).y))
	max_y = maxf(max_y, absf((basis * Vector3(-half.x, half.y, -half.z)).y))
	max_y = maxf(max_y, absf((basis * Vector3(half.x, -half.y, -half.z)).y))
	max_y = maxf(max_y, absf((basis * Vector3(-half.x, -half.y, -half.z)).y))
	return max_y


func get_debug_summary() -> String:
	var lines: Array[String] = []
	lines.append("[ObjectsSpawner] %d/%d objetos generados (max %d)" % [_spawned.size(), _spawned.size(), max_objects])
	for obj in _spawned:
		lines.append("  - %s tipo=%s en %s | collision=%s" % [
			obj.name, obj.get_script().get_global_name() if obj.get_script() != null else "?", obj.global_position, _has_collision(obj)])
	return "\n".join(lines)


func _has_collision(obj: Node3D) -> bool:
	return obj.get_node_or_null("CollisionShape3D") != null