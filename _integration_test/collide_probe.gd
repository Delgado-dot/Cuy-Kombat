extends Node

const PLAYER_SCENE := "res://entities/player/player.tscn"

var _p1: Node
var _p2: Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var fcs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(30, 0.4, 30)
	fcs.shape = shape
	floor_body.add_child(fcs)
	floor_body.position = Vector3(0, -0.2, 0)
	add_child(floor_body)

	_p1 = _spawn("P1", Vector3(6.5, 1, 0), -PI / 2, "wasd")
	_p2 = _spawn("P2", Vector3(7.5, 1, 0), PI / 2, "arrows")
	await _ticks(3)

	await _head_on()
	await _side_by_side()
	get_tree().quit(0)


func _head_on() -> void:
	_reset_player(_p1, Vector3(6.5, 1, 0), -PI / 2)
	_reset_player(_p2, Vector3(7.5, 1, 0), PI / 2)
	await _ticks(3)
	_press(KEY_D)
	_press(KEY_LEFT)
	var min_dist := INF
	var gap_at_min := -INF
	for i in 120:
		await get_tree().physics_frame
		var d: float = _p1.global_position.distance_to(_p2.global_position)
		if i % 20 == 0:
			print("HEAD-ON t%d d=%.2f p1=(%.2f,%.2f,%.2f) p2=(%.2f,%.2f,%.2f) gap=%.2f" % [
				i, d, _p1.global_position.x, _p1.global_position.y, _p1.global_position.z,
				_p2.global_position.x, _p2.global_position.y, _p2.global_position.z,
				_visual_gap(_p1, _p2)])
		if d < min_dist:
			min_dist = d
			gap_at_min = _visual_gap(_p1, _p2)
	_release_key(KEY_D)
	_release_key(KEY_LEFT)
	print("COLLIDE head-on: min_center_dist=%.3f visual_gap_at_min=%.3f" % [min_dist, gap_at_min])
	var ok := min_dist > 1.0 and gap_at_min > -0.05
	print("HEAD-ON RESULT: %s" % ("PASS" if ok else "FAIL"))


func _side_by_side() -> void:
	_reset_player(_p1, Vector3(6.5, 1, 0), 0.0)
	_reset_player(_p2, Vector3(7.5, 1, 0), 0.0)
	await _ticks(3)
	_press(KEY_D)
	_press(KEY_LEFT)
	var min_dist := INF
	var gap_at_min := -INF
	for i in 120:
		await get_tree().physics_frame
		var d: float = _p1.global_position.distance_to(_p2.global_position)
		if i % 20 == 0:
			print("SIDE t%d d=%.2f p1=(%.2f,%.2f,%.2f) p2=(%.2f,%.2f,%.2f) gap=%.2f" % [
				i, d, _p1.global_position.x, _p1.global_position.y, _p1.global_position.z,
				_p2.global_position.x, _p2.global_position.y, _p2.global_position.z,
				_visual_gap(_p1, _p2)])
		if d < min_dist:
			min_dist = d
			gap_at_min = _visual_gap(_p1, _p2)
	_release_key(KEY_D)
	_release_key(KEY_LEFT)
	print("COLLIDE side: min_center_dist=%.3f visual_gap_at_min=%.3f" % [min_dist, gap_at_min])
	var ok := min_dist > 1.0 and gap_at_min > -0.05
	print("SIDE RESULT: %s" % ("PASS" if ok else "FAIL"))


func _spawn(name: String, pos: Vector3, rot_y: float, scheme: String) -> Node:
	var ps: PackedScene = load(PLAYER_SCENE)
	var p := ps.instantiate()
	p.name = name
	p.control_scheme = scheme
	p.position = pos
	p.rotation.y = rot_y
	add_child(p)
	return p


func _visual_gap(a: Node, b: Node) -> float:
	var axis: Vector3 = (b.global_position - a.global_position).normalized()
	var d: float = (b.global_position - a.global_position).dot(axis)
	var ea := _max_extent_toward(a, axis)
	var eb := _max_extent_toward(b, -axis)
	return d - ea - eb


func _max_extent_toward(node: Node, axis: Vector3) -> float:
	var cuy := node.get_node_or_null("Visual/CuyModel")
	var m := -INF
	for mesh in _find_meshes(cuy):
		var g: AABB = (mesh as MeshInstance3D).global_transform * (mesh as MeshInstance3D).mesh.get_aabb()
		for i in 8:
			var corner: Vector3 = g.get_endpoint(i)
			var v: float = (corner - node.global_position).dot(axis)
			m = maxf(m, v)
	return m if m != -INF else 0.0


func _find_meshes(node: Node) -> Array:
	var out: Array = []
	if node == null:
		return out
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_find_meshes(child))
	return out


func _reset_player(p: Node, pos: Vector3, rot_y: float) -> void:
	p.velocity = Vector3.ZERO
	p.set("_horizontal_velocity", Vector3.ZERO)
	p.set("_external_push", Vector3.ZERO)
	p.set("_knockback_time_left", 0.0)
	p.set("_knockout_pending", false)
	p.set("_stun_pending", false)
	p.set("_stun_time_left", 0.0)
	p.set("_grabbed_target", null)
	p.set("_grabbed_by", null)
	p.set("_knocked_time_left", 0.0)
	p.set("_recovering", false)
	p.set("_recovery_time", 0.0)
	p.set("_knockout_hits", 0)
	p.set("_tackle_cooldown_left", 0.0)
	p.set("_tackle_time_left", 0.0)
	p.set("_punch_cooldown_left", 0.0)
	p.set("_punch_active_left", 0.0)
	p.set("_charge_time", 0.0)
	p.set("_punch_key_was_down", false)
	p.collision_layer = 1
	p.collision_mask = 1
	p.visible = true
	var cs := p.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs != null:
		cs.disabled = false
	p.global_position = pos
	p.rotation.y = rot_y


func _ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _press(key: Key) -> void:
	_send_key(key, true)


func _release_key(key: Key) -> void:
	_send_key(key, false)


func _send_key(key: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = pressed
	Input.parse_input_event(ev)
