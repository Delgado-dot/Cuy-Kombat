extends Node3D

@onready var log_rigid: RigidBody3D = $Log
@onready var shape_holder: CollisionShape3D = $Log/CollisionShape3D
@onready var model: Node3D = $Log/TroncoModel


func _ready() -> void:
	print("[LOG TEST] === Tronco horizontal (independiente de interaccion) ===")
	print("[LOG TEST] Es RigidBody3D: %s" % (log_rigid is RigidBody3D))
	print("[LOG TEST] No es InteractableObject (no grabbable/throwable): %s" % (not log_rigid is InteractableObject))
	print("[LOG TEST] No esta en grupo interactable_objects: %s" % (not log_rigid.is_in_group("interactable_objects")))
	print("[LOG TEST] Sin protocolo Kevin: can_be_grabbed=%s, throw=%s" % [
		not log_rigid.has_method("can_be_grabbed"),
		not log_rigid.has_method("throw"),
	])

	var model_map: Dictionary = _model_extents()
	var model_horizontal := bool(model_map.get("horizontal", false))
	var model_size := model_map.get("size", Vector3.ZERO) as Vector3
	print("[LOG TEST] Modelo horizontal (eje largo en X/Z): %s (size=%s)" % [model_horizontal, model_size])

	var collision_horizontal := false
	var collision_covers := false
	if shape_holder.shape is CylinderShape3D:
		var cyl := shape_holder.shape as CylinderShape3D
		var axis: Vector3 = shape_holder.transform.basis * Vector3.UP
		collision_horizontal = absf(axis.normalized().y) < 0.1
		var col_length := cyl.height
		var col_radius := cyl.radius
		var trunk_length := model_size.x
		var trunk_radius := maxf(model_size.y, model_size.z) * 0.5
		collision_covers = col_length >= trunk_length * 0.95 and col_radius >= trunk_radius * 0.95
		print("[LOG TEST] Colision horizontal (eje en X/Z): %s | longitud=%.2f radio=%.2f" % [
			collision_horizontal,
			col_length,
			col_radius,
		])
		print("[LOG TEST] Colision cubre el tronco: %s (tronco longitud=%.2f radio=%.2f)" % [
			collision_covers,
			trunk_length,
			trunk_radius,
		])

	var checks := {
		"es_rigid_body": log_rigid is RigidBody3D,
		"no_interactable": not log_rigid is InteractableObject,
		"no_grupo_interactable": not log_rigid.is_in_group("interactable_objects"),
		"no_agarrable": not log_rigid.has_method("can_be_grabbed"),
		"no_lanzable": not log_rigid.has_method("throw"),
		"modelo_horizontal": model_horizontal,
		"colision_horizontal": collision_horizontal,
		"colision_cubre_tronco": collision_covers,
	}

	var all_ok := true
	for key in checks:
		print("[LOG TEST] %-28s -> %s" % [key, checks[key]])
		if not checks[key]:
			all_ok = false

	print("[LOG TEST] RESULTADO: ", ("PASS" if all_ok else "FAIL"))
	get_tree().quit(0 if all_ok else 1)


## Calcula la extensión del modelo en su espacio local (sin la transformación
## del nodo Log, para no depender de su posición en el test).
func _model_extents() -> Dictionary:
	var aabb := _node_aabb(model, Transform3D())
	var size := aabb.size
	# Modelo horizontal: el eje largo (X o Z) debe dominar sobre el radio (Y).
	var longest := maxf(maxf(size.x, size.y), size.z)
	var horizontal := (size.x >= size.y * 2.0 and absf(size.x - longest) < 0.01) \
		or (size.z >= size.y * 2.0 and absf(size.z - longest) < 0.01)
	return {"size": size, "horizontal": horizontal}


func _node_aabb(node: Node, parent: Transform3D) -> AABB:
	var local := Transform3D()
	if node is Node3D:
		local = (node as Node3D).transform
	var world := parent * local

	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			return world * mi.get_aabb()

	var ret := AABB()
	for child in node.get_children():
		var child_aabb := _node_aabb(child, world)
		if ret.size == Vector3.ZERO:
			ret = child_aabb
		else:
			ret = ret.merge(child_aabb)
	return ret