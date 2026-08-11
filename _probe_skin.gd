extends SceneTree

var player: Node3D
var sk: Skeleton3D

func _initialize() -> void:
	player = (load("res://entities/player/player.tscn") as PackedScene).instantiate()
	root.add_child(player)

func _process(_delta: float) -> bool:
	if player == null:
		return false
	sk = player.find_child("Skeleton3D", true, false) as Skeleton3D
	print("== BONES ==")
	for i in sk.get_bone_count():
		print("  idx=", i, " name=", sk.get_bone_name(i))
	print("== MESH INSTANCES ==")
	var found := false
	for mi in sk.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		found = true
		var arrays := mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		print("Mesh ", mi.get_path(), " surf0 verts=", verts.size())
		var dominance := {}
		var arm_verts := {}
		for vi in verts.size():
			var bi := bones[vi * 4]
			var bw := weights[vi * 4]
			for k in 4:
				if weights[vi * 4 + k] > bw:
					bw = weights[vi * 4 + k]
					bi = bones[vi * 4 + k]
			var bname := sk.get_bone_name(bi) if bi >= 0 and bi < sk.get_bone_count() else "none"
			dominance[bname] = dominance.get(bname, 0) + 1
			var v := verts[vi]
			if bname in ["HombroIzq", "ManoIzq", "HombroDer", "ManoDer"]:
				if not arm_verts.has(bname):
					arm_verts[bname] = []
				arm_verts[bname].append(v)
		print("  peso dominante por hueso (vtx count): ", dominance)
		for bname in arm_verts:
			var arr: Array = arm_verts[bname]
			var minp := Vector3.INF
			var maxp := -Vector3.INF
			for v in arr:
				minp = minp.min(v)
				maxp = maxp.max(v)
			print("  vtx dominantes ", bname, ": n=", arr.size(), " bbox min=", minp, " max=", maxp)
	quit()
	return false
