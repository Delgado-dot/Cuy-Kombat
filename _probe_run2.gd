extends SceneTree

var log_file: FileAccess
var player: Node3D
var skeleton: Skeleton3D
var head_idx := -1
var spine_idx := -1

func log_line(msg: String) -> void:
	log_file.store_line(msg)
	log_file.flush()

func _init() -> void:
	var log_path: String = OS.get_environment("TEMP") + "/probe_run2.log"
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	log_line("PROBE RUN2 v3 START")
	call_deferred("_run")

func press_key(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)

func release_key(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = false
	Input.parse_input_event(ev)

func sample(tag: String, i: int) -> void:
	var hm: bool = player.get("_head_moving")
	var spine_euler: Vector3 = skeleton.get_bone_pose_rotation(spine_idx).get_euler()
	var head_gpose: Transform3D = skeleton.get_bone_global_pose(head_idx)
	var nose := head_gpose.basis.z
	log_line(tag + " f=" + str(i) + " hm=" + str(hm) + " spineX=" + str(snappedf(spine_euler.x, 0.001)) + " nose.y=" + str(snappedf(nose.y, 0.001)) + " vel=" + str(snappedf(player.velocity.length(), 0.01)) + " anim=" + str(player.get("_current_cuy_anim")) + " butt=" + str(snappedf(player.get("_headbutt_k"), 0.001)))

func _run() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(0, -0.5, 0)
	var floor_collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	floor_collider.shape = box
	floor_body.add_child(floor_collider)
	root.add_child(floor_body)

	var scene: PackedScene = load("res://entities/player/player.tscn")
	player = scene.instantiate()
	player.position = Vector3(0, 1.0, 0)
	root.add_child(player)
	await physics_frame
	await physics_frame

	skeleton = player.get_node("Visual/CuyModel/Armature/Skeleton3D")
	head_idx = skeleton.find_bone("Cabesa")
	spine_idx = skeleton.find_bone("Caolumna1")
	log_line("idx head=" + str(head_idx) + " spine=" + str(spine_idx))

	press_key(KEY_W)
	log_line("W pressed; accelerating")
	for i in range(200):
		await physics_frame
	log_line("--- RUN samples ---")
	for i in range(10):
		await physics_frame
		sample("RUN", i)

	press_key(KEY_F)
	log_line("--- RUN + HEADBUTT samples ---")
	for i in range(18):
		await physics_frame
		sample("BUTT", i)

	release_key(KEY_F)
	release_key(KEY_W)
	log_line("W,F released; decelerating to idle")
	for i in range(150):
		await physics_frame
	log_line("--- IDLE samples ---")
	for i in range(10):
		await physics_frame
		sample("IDLE", i)

	log_line("PROBE RUN2 v3 DONE")
	quit()
