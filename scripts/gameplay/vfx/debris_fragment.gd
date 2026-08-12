extends RigidBody3D

## Fragmento físico reutilizable para rupturas (caja → madera, barril → metal).
## Vive unos segundos y se elimina solo. No tiene lógica de combate ni interactúa
## con el sistema de objetos/knockback: es puro feedback visual con física.

const DEFAULT_LIFETIME := 2.5

var _lifetime := DEFAULT_LIFETIME


func _ready() -> void:
	can_sleep = true
	_apply_material()
	get_tree().create_timer(_lifetime).timeout.connect(queue_free)


## Configura tamaño (metros) y apariencia antes/después de entrar al árbol.
func setup(size: float, color: Color, metallic := 0.0, roughness := 0.9) -> void:
	var shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape != null and shape.shape is BoxShape3D:
		var box: BoxShape3D = (shape.shape as BoxShape3D).duplicate()
		box.size = Vector3(size, size, size)
		shape.shape = box

	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh != null:
		var base := mesh.mesh
		if base is BoxMesh:
			var box_mesh: BoxMesh = (base as BoxMesh).duplicate()
			box_mesh.size = Vector3(size, size * 1.1, size * 0.9)
			mesh.mesh = box_mesh

	var mat := _build_material(color, metallic, roughness)
	if mesh != null:
		mesh.material_override = mat


func _build_material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	return mat


func _apply_material() -> void:
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null or mesh.material_override != null:
		return
	mesh.material_override = _build_material(Color(0.62, 0.38, 0.18, 1.0), 0.0, 0.9)


func _physics_process(_delta: float) -> void:
	if global_position.y < -40.0:
		queue_free()
