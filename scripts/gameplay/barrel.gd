extends BreakableBox

class_name Barrel

func _ready() -> void:
	super._ready()
	sleeping = true
	_strip_embedded_model_physics()


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
