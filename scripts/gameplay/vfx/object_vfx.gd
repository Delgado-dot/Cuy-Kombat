class_name ObjectVFX
extends RefCounted

## Utilidades compartidas de VFX para los objetos interactuables (Rock, Caja,
## Barril). Solo instancian escenas visuales temporales y reproducen sonidos;
## NO tocan física, knockback ni la arquitectura de objetos.

## Instancia una escena VFX en `position` (mundo) como hijo de la escena actual.
## La escena VFX es responsable de limpiarse sola (one_shot + queue_free).
## Devuelve el nodo instanciado o null si la escena es null/inválida.
static func spawn_vfx(node: Node, scene: PackedScene, position: Vector3) -> Node3D:
	if scene == null or node == null:
		return null

	var vfx := scene.instantiate() as Node3D
	if vfx == null:
		return null

	var tree := node.get_tree()
	if tree == null or tree.current_scene == null:
		vfx.free()
		return null

	tree.current_scene.add_child(vfx)
	vfx.global_position = position
	return vfx


## Adjunta una escena VFX (p. ej. un trail) como hijo del objeto físico para que
## lo siga mientras vuela. Devuelve el nodo o null.
static func attach_vfx(object: Node3D, scene: PackedScene) -> Node3D:
	if scene == null or object == null:
		return null

	var vfx := scene.instantiate() as Node3D
	if vfx == null:
		return null

	object.add_child(vfx)
	vfx.global_position = object.global_position
	return vfx


## Reproduce un sonido 3D breve en `position` si hay un AudioStream configurado.
## No hace nada (y no crea nodos) si el stream es null: así los puntos de audio
## quedan preparados sin depender de assets externos. El player se limpia solo.
static func play_sfx(node: Node, stream: AudioStream, position: Vector3, volume_db := 0.0) -> void:
	if stream == null or node == null:
		return

	var tree := node.get_tree()
	if tree == null or tree.current_scene == null:
		return

	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.max_distance = 60.0
	player.unit_size = 8.0

	tree.current_scene.add_child(player)
	player.global_position = position
	player.finished.connect(player.queue_free)
	player.play()


## Instancia `count` fragmentos físicos (DebrisFragment) en `position` con
## direcciones aleatorias. Puramente visual; los fragmentos se limpian solos.
static func spawn_debris(node: Node, scene: PackedScene, position: Vector3, count: int, \
		min_speed: float, max_speed: float, up_force: float, size: float, \
		color: Color, metallic := 0.0, roughness := 0.9) -> void:
	if scene == null or node == null or count <= 0:
		return

	var tree := node.get_tree()
	if tree == null or tree.current_scene == null:
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in count:
		var frag := scene.instantiate() as RigidBody3D
		if frag == null:
			continue

		tree.current_scene.add_child(frag)
		frag.global_position = position \
			+ Vector3(rng.randf_range(-0.15, 0.15), 0.25, rng.randf_range(-0.15, 0.15))

		if frag.has_method("setup"):
			frag.setup(size, color, metallic, roughness)

		var angle := rng.randf() * TAU
		var speed := rng.randf_range(min_speed, max_speed)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		frag.apply_impulse(direction * speed + Vector3.UP * (up_force + rng.randf_range(0.0, 1.5)))
		frag.apply_torque_impulse(Vector3(
			rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)
		) * 0.6)
