extends Node3D

@onready var log_rigid: RigidBody3D = $Log
@onready var shape_holder: CollisionShape3D = $Log/CollisionShape3D
@onready var model: Node3D = $Log/TroncoModel


func _ready() -> void:
	print("[LOG TEST] === Tronco fisico (independiente de interaction ===")
	print("[LOG TEST] Es RigidBody3D: %s" % (log_rigid is RigidBody3D))
	print("[LOG TEST] No es InteractableObject (no grabbable/throwable): %s" % (not log_rigid is InteractableObject))
	print("[LOG TEST] No esta en grupo interactable_objects: %s" % (not log_rigid.is_in_group("interactable_objects")))
	print("[LOG TEST] Sin protocolo Kevin: can_be_grabbed=%s, throw=%s" % [
		not log_rigid.has_method("can_be_grabbed"),
		not log_rigid.has_method("throw"),
	])

	if shape_holder.shape is CylinderShape3D:
		var cyl := shape_holder.shape as CylinderShape3D
		print("[LOG TEST] Colision horizontal (radio=%.2f, longitud=%.2f): %s" % [
			cyl.radius,
			cyl.height,
			abs(shape_holder.transform.basis.y.y) < 0.001,
		])

	if model != null:
		var basis_y: Vector3 = model.transform.basis.y
		var scale_y: float = absf(basis_y.x)
		print("[LOG TEST] Modelo reducido (scale medio ~%.2f): %s" % [
			scale_y,
			scale_y <= 0.8,
		])
