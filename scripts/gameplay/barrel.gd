extends BreakableBox

class_name Barrel

## Emitida una única vez cuando el barrel explota al romperse.
signal exploded()

## Radio en metros desde el centro del barrel que recibe el efecto de la explosión.
@export var explosion_radius := 6.0
## Fuerza horizontal máxima del knockback (aplicada en el centro de la explosión).
## 18.0 aumentada un 10%: 18.0 × 1.10 = 19.8.
@export var explosion_force := 19.8
## Fuerza vertical máxima del knockback (aplicada en el centro de la explosión).
@export var explosion_up_force := 7.0
## Duración del estado de knockback aplicado a los jugadores.
@export var explosion_duration := 0.45
## Escena de VFX provisional instanciada al explotar. Solo visual. Si es null,
## la explosión física continúa funcionando igual.
@export var explosion_vfx_scene: PackedScene
## Cantidad de fragmentos del barril lanzados al explotar. La escena de
## fragmentos se hereda de BreakableBox (debris_fragment_scene).
@export var barrel_debris_count := 5

## Sonido de explosión (punto de conexión; si es null no se reproduce nada).
@export var explosion_sfx: AudioStream

var _did_explode := false
var _last_spawned_vfx: Node3D


func _ready() -> void:
	super._ready()
	sleeping = true
	_strip_embedded_model_physics()


## Al romperse, el barril explota. NO usa el feedback de ruptura de la caja
## (virutas de madera): usa su propio sistema de explosión. La limpieza física
## (freeze, colisiones, grupo) es la misma.
func _break() -> void:
	if is_broken():
		return

	_is_broken = true
	_destroy_body()
	print("[BARREL] EXPLODING")
	_explode()
	queue_free()


## Un barril lanzado que golpea directamente a un jugador explota en el acto.
## Reutiliza el flujo normal de ruptura (impact_detected → _break → _explode):
## el jugador recibe el golpe del proyectil y luego el efecto de área de la
## explosión. El lanzador ya quedó excluido del impacto del proyectil y también
## se excluye del área de la explosión.
func _on_projectile_hit_player(player: CharacterBody3D) -> void:
	if _is_broken:
		return
	var intensity := maxf(_projectile_speed, linear_velocity.length())
	_handle_impact(player, intensity, global_position)


## Al romperse, lanza a todos los jugadores dentro del radio, con fuerza que
## disminuye desde el centro hasta el límite del radio. Reutiliza el sistema de
## knockback existente del Player (apply_knockback). Se ejecuta una sola vez.
func _explode() -> void:
	if _did_explode:
		return
	_did_explode = true

	var center := global_position
	exploded.emit()
	_spawn_explosion_vfx(center)
	_spawn_barrel_debris(center)
	ObjectVFX.play_sfx(self, explosion_sfx, center)

	for player in _find_all_players():
		if not is_instance_valid(player):
			continue

		# El lanzador del barril no recibe el área de la explosión de su propio
		# objeto (también está excluido del impacto directo del proyectil).
		if _last_thrower != null and is_instance_valid(_last_thrower) \
				and player == _last_thrower:
			continue

		var distance := player.global_position.distance_to(center)
		if distance > explosion_radius:
			continue

		var direction := player.global_position - center
		direction.y = 0.0
		if direction.length_squared() < 0.0001:
			direction = -player.global_transform.basis.z

		var falloff := 1.0 - clampf(distance / explosion_radius, 0.0, 1.0)
		player.apply_knockback(
			direction.normalized(),
			explosion_force * falloff,
			explosion_up_force * falloff,
			false,
			explosion_duration
		)


## Instancia el VFX provisional en la posición global de la explosión.
## Puramente visual: no aplica física, no hace knockback y no detecta jugadores.
## Cualquier fallo en el VFX no afecta a la lógica física de la explosión.
func _spawn_explosion_vfx(center: Vector3) -> void:
	if explosion_vfx_scene == null:
		return

	var vfx := explosion_vfx_scene.instantiate() as Node3D
	if vfx == null:
		return

	get_tree().current_scene.add_child(vfx)
	vfx.global_position = center
	_last_spawned_vfx = vfx


## Restos físicos del barril expulsados radialmente por la explosión.
## Puramente visual: los fragmentos no tienen lógica de combate ni knockback.
func _spawn_barrel_debris(center: Vector3) -> void:
	if debris_fragment_scene == null:
		return

	ObjectVFX.spawn_debris(
		self,
		debris_fragment_scene,
		center,
		barrel_debris_count,
		4.5,
		8.5,
		5.0,
		0.14,
		Color(0.26, 0.22, 0.2, 1.0),
		0.45,
		0.6
	)


## Recorre el árbol de la escena y devuelve todos los jugadores (CharacterBody3D
## con el protocolo de knockback del Player de Kevin).
func _find_all_players() -> Array[CharacterBody3D]:
	var players: Array[CharacterBody3D] = []
	var stack: Array[Node] = [get_tree().current_scene]

	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CharacterBody3D and node.has_method("apply_knockback"):
			players.append(node as CharacterBody3D)
		for child in node.get_children():
			stack.append(child)

	return players


## Some imported .glb assets auto-generate their own physics bodies
## (StaticBody3D/RigidBody3D/Area3D) nested inside the model hierarchy.
## Those are independent from this RigidBody3D and are NOT affected by
## `freeze`, so they can move/collide on their own and drag the visual
## mesh with them. This removes any such embedded physics nodes,
## leaving only the intended CollisionShape3D on the Barrel itself.
func _strip_embedded_model_physics() -> void:
	var model := get_node_or_null("BarrilModel")
	if model == null:
		return
	_strip_physics_recursive(model)


func _strip_physics_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionObject3D:
			push_warning("[Barrel] Removing embedded physics node from imported model: %s" % child.get_path())
			child.queue_free()
		else:
			_strip_physics_recursive(child)
