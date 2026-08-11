extends Node

const MAIN_SCENE := "res://main.tscn"

const STATE_NORMAL := 0
const STATE_GRABBING := 4
const STATE_GRABBED := 5
const STATE_KNOCKED := 6

var _main: Node
var _gm: Node
var _p1: Node
var _p2: Node
var _main_menu: Node
var _results: Array = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _setup()

	var ext := _model_extents(_p1)
	var front := -ext.position.z
	var back := ext.position.z + ext.size.z
	print("MODEL_AABB local: pos=%s size=%s" % [str(ext.position), str(ext.size)])
	print("MODEL front=%.2f back=%.2f depth=%.2f" % [front, back, front + back])

	await _grab_cycle(1)
	await _grab_cycle(2)
	await _knocked_grab_check()
	_print_report()
	var fails := 0
	for r in _results:
		if not r.ok:
			fails += 1
	print("GRAB_PROBE RESULT: fails=%d" % fails)
	get_tree().quit(1 if fails > 0 else 0)


func _setup() -> void:
	var packed: PackedScene = load(MAIN_SCENE)
	_main = packed.instantiate()
	add_child(_main)
	await _ticks(10)
	_gm = _main.get_node("GameManager")
	_p1 = _main.get_node("Player1")
	_p2 = _main.get_node("Player2")
	_main_menu = _main.get_node("MainMenu")
	_main_menu._play_button.pressed.emit()
	await _ticks(10)


func _grab_cycle(cycle: int) -> void:
	var grabber: Node = _p1 if cycle == 1 else _p2
	var victim: Node = _p2 if cycle == 1 else _p1
	var action: StringName = &"grab_p1" if cycle == 1 else &"grab_p2"

	_reset_player(_p1, Vector3(0, 1, 8.7), PI)
	_reset_player(_p2, Vector3(0, 1, 9.7), 0.0)
	await _ticks(3)
	_action_press(action, true)

	var grabbing := false
	var grabbed := false
	for i in 30:
		await get_tree().physics_frame
		if int(grabber.get("_state")) == STATE_GRABBING:
			grabbing = true
		if int(victim.get("_state")) == STATE_GRABBED:
			grabbed = true
	_result("G%d agarre iniciado" % cycle, grabbing and grabbed,
		"grabber=%d victim=%d" % [int(grabber.get("_state")), int(victim.get("_state"))])

	for i in 80:
		await get_tree().physics_frame

	var dist: float = grabber.global_position.distance_to(victim.global_position)
	var gap: float = _visual_gap(grabber, victim)
	var yaw_diff: float = absf(wrapf(victim.rotation.y - (grabber.rotation.y + PI), -PI, PI))
	_result("G%d separacion entre origenes" % cycle, dist > 1.2 and dist < 2.6, "dist=%.2f" % dist)
	_result("G%d modelos no se atraviesan (hueco > 0)" % cycle, gap > 0.0, "gap=%.2f" % gap)
	_result("G%d orientacion estable (frente a frente)" % cycle, yaw_diff < 0.1, "yaw_diff=%.2f rad" % yaw_diff)

	_action_press(action, false)
	await _ticks(10)


func _knocked_grab_check() -> void:
	_p2.set("knockout_hits", 4)
	_reset_player(_p1, Vector3(0, 1, 8.7), PI)
	_reset_player(_p2, Vector3(0, 1, 9.7), 0.0)
	await _ticks(3)
	while float(_p1.get("_punch_cooldown_left")) > 0.0:
		await get_tree().physics_frame
	_press(KEY_F)
	for j in 12:
		await get_tree().physics_frame
	_release(KEY_F)
	var knocked := false
	for i in 60:
		await get_tree().physics_frame
		if int(_p2.get("_state")) == STATE_KNOCKED:
			knocked = true
			break
	_result("K P2 queda KNOCKED", knocked, "state=%d" % int(_p2.get("_state")))

	_action_press("grab_p1", true)
	await _ticks(10)
	var grabbed := int(_p1.get("_state")) == STATE_GRABBING or int(_p2.get("_state")) == STATE_GRABBED
	_result("K NO agarra a jugador KNOCKED", not grabbed,
		"p1=%d p2=%d" % [int(_p1.get("_state")), int(_p2.get("_state"))])
	_action_press("grab_p1", false)
	await _ticks(5)


func _model_extents(player: Node) -> AABB:
	var cuy := player.get_node_or_null("Visual/CuyModel")
	var aabb: AABB
	var first := true
	for m in _find_meshes(cuy):
		var g: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).mesh.get_aabb()
		if first:
			aabb = g
			first = false
		else:
			aabb = aabb.merge(g)
	return player.global_transform.affine_inverse() * aabb


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


func _result(name: String, ok: bool, detail: String = "") -> void:
	var status := "PASS" if ok else "FAIL"
	var line := "[%s] %s" % [status, name]
	if detail != "":
		line += "  (" + detail + ")"
	print(line)
	_results.append({"name": name, "ok": ok, "detail": detail})


func _print_report() -> void:
	var fails := 0
	for r in _results:
		if not r.ok:
			fails += 1
	print("")
	print("TOTAL=%d PASS=%d FAIL=%d" % [_results.size(), _results.size() - fails, fails])


func _ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _press(key: Key) -> void:
	_send_key(key, true)


func _release(key: Key) -> void:
	_send_key(key, false)


func _send_key(key: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _action_press(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _reset_player(p: Node, pos: Vector3, rot_y: float) -> void:
	p.velocity = Vector3.ZERO
	p.set("_state", STATE_NORMAL)
	p.set("_horizontal_velocity", Vector3.ZERO)
	p.set("_external_push", Vector3.ZERO)
	p.set("_knockback_time_left", 0.0)
	p.set("_knockout_pending", false)
	p.set("_stun_pending", false)
	p.set("_stun_time_left", 0.0)
	p.set("_grabbed_target", null)
	p.set("_grabbed_by", null)
	p.set("_knocked_time_left", 0.0)
	p.set("_knocked_timer_paused", false)
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
	p.set_physics_process(true)
	var cs := p.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs != null:
		cs.disabled = false
	p.global_position = pos
	p.rotation.y = rot_y
