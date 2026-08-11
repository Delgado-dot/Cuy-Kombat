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
	var mi := sk.find_child("node_0", true, false) as MeshInstance3D
	var mesh: Mesh = mi.mesh
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var hz_i := sk.find_bone("HombroIzq")
	var hz_d := sk.find_bone("HombroDer")
	var ma_i := sk.find_bone("ManoIzq")
	var ma_d := sk.find_bone("ManoDer")
	var s_g_i: Transform3D = _global_rest(hz_i)
	var m_g_i: Transform3D = _global_rest(ma_i)
	var s_g_d: Transform3D = _global_rest(hz_d)
	var m_g_d: Transform3D = _global_rest(ma_d)
	var arm_axis_i: Vector3 = (m_g_i.origin - s_g_i.origin).normalized()
	var arm_axis_d: Vector3 = (m_g_d.origin - s_g_d.origin).normalized()
	var counts := {"ManoIzq_tubo": 0, "ManoIzq_fuera_tubo": 0, "ManoDer_tubo": 0, "ManoDer_fuera_tubo": 0, "maxw_manoizq": 0.0, "maxw_manoder": 0.0}
	var spread_manoizq := []
	var spread_manoder := []
	for vi in verts.size():
		var bi := -1
		var bw := -1.0
		for k in 4:
			if weights[vi * 4 + k] > bw:
				bw = weights[vi * 4 + k]
				bi = bones[vi * 4 + k]
		if bw < 0.9:
			continue
		var v := verts[vi]
		if bi == ma_i:
			counts.maxw_manoizq = maxf(counts.maxw_manoizq, bw)
			var proj := (v - s_g_i.origin).dot(arm_axis_i)
			var perp := (v - s_g_i.origin) - arm_axis_i * proj
			if proj > -0.1 and proj < 0.55 and perp.length() < 0.18:
				counts.ManoIzq_tubo += 1
				spread_manoizq.append(v)
			else:
				counts.ManoIzq_fuera_tubo += 1
		elif bi == ma_d:
			counts.maxw_manoder = maxf(counts.maxw_manoder, bw)
			var proj := (v - s_g_d.origin).dot(arm_axis_d)
			var perp := (v - s_g_d.origin) - arm_axis_d * proj
			if proj > -0.1 and proj < 0.55 and perp.length() < 0.18:
				counts.ManoDer_tubo += 1
				spread_manoder.append(v)
			else:
				counts.ManoDer_fuera_tubo += 1
	print("vtx con peso>=0.9 -> ", counts)
	for tag in [["ManoIzq", spread_manoizq], ["ManoDer", spread_manoder]]:
		var arr: Array = tag[1]
		if arr.is_empty():
			continue
		var minp := Vector3.INF
		var maxp := -Vector3.INF
		for v in arr:
			minp = minp.min(v)
			maxp = maxp.max(v)
		var cx := Vector3.ZERO
		for v in arr:
			cx += v
		cx /= arr.size()
		print(tag[0], " tubo: n=", arr.size(), " bbox=", minp, " -> ", maxp, " centro=", cx)
	quit()
	return false

func _global_rest(idx: int) -> Transform3D:
	if idx < 0:
		return Transform3D.IDENTITY
	return _global_rest(sk.get_bone_parent(idx)) * sk.get_bone_rest(idx)
