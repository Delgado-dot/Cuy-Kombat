extends SceneTree

var log_file: FileAccess
var skeleton: Skeleton3D
var head_idx := -1
var neck_idx := -1
var samples: Array = []
var idle_samples: Array = []

func log_line(msg: String) -> void:
	log_file.store_line(msg)
	log_file.flush()

func _init() -> void:
	var log_path: String = OS.get_environment("TEMP") + "/probe_run.log"
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	log_line("PROBE RUN START")
	call_deferred("_run")

func _run() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.position = Vector3(0, -0.5, 0)
	var floor_collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	floor_collider.shape = box
	floor_body.add_child(floor_collider)
	root.add_child(floor_body)

	var scene: PackedScene = load("res://entities/player/player.tscn")
	var player := scene.instantiate()
	player.position = Vector3(0, 1.0, 0)
	root.add_child(player)
	log_line("player added")

	skeleton = player.get_node("Visual/CuyModel/Armature/Skeleton3D") as Skeleton3D
	log_line("skeleton=" + str(skeleton.get_path()))
	for i in range(skeleton.get_bone_count()):
		log_line("  bone " + str(i) + " = " + skeleton.get_bone_name(i))

	head_idx = skeleton.find_bone("Cabesa")
	neck_idx = skeleton.find_bone("Cuello")
	log_line("head=" + str(head_idx) + " neck=" + str(neck_idx))

	await physics_frame
	await physics_frame
	await physics_frame
	log_line("settled, pressing W")

	var ev_press := InputEventKey.new()
	ev_press.physical_keycode = KEY_W
	ev_press.pressed = true
	Input.parse_input_event(ev_press)

	for i in range(180):
		await physics_frame
	log_line("running; sampling 180 frames")
	for i in range(180):
		await physics_frame
		var head_gpose: Transform3D = skeleton.get_bone_global_pose(head_idx)
		var nose := head_gpose.basis.z
		var head_euler := skeleton.get_bone_pose_rotation(head_idx).get_euler()
		samples.append(Vector3(nose.y, head_euler.x, head_euler.z))

	var total := Vector3.ZERO
	var nose_ys: Array = []
	for s in samples:
		total += s
		nose_ys.append(snappedf(s.x, 0.001))
	var avg := total / samples.size()
	log_line("RUN head nose.y avg=" + str(snappedf(avg.x, 0.0001)) + " eulerX avg=" + str(snappedf(avg.y, 0.0001)) + " eulerZ avg=" + str(snappedf(avg.z, 0.0001)))
	log_line("RUN nose.y samples=" + str(nose_ys))

	var ev_release := InputEventKey.new()
	ev_release.physical_keycode = KEY_W
	ev_release.pressed = false
	Input.parse_input_event(ev_release)
	log_line("W released")

	for i in range(60):
		await physics_frame
	log_line("idle; sampling 120 frames")
	for i in range(120):
		await physics_frame
		var head_gpose2: Transform3D = skeleton.get_bone_global_pose(head_idx)
		var nose2 := head_gpose2.basis.z
		var head_euler2 := skeleton.get_bone_pose_rotation(head_idx).get_euler()
		idle_samples.append(Vector3(nose2.y, head_euler2.x, head_euler2.z))

	var total2 := Vector3.ZERO
	var nose_ys2: Array = []
	for s in idle_samples:
		total2 += s
		nose_ys2.append(snappedf(s.x, 0.001))
	var avg2 := total2 / idle_samples.size()
	log_line("IDLE head nose.y avg=" + str(snappedf(avg2.x, 0.0001)) + " eulerX avg=" + str(snappedf(avg2.y, 0.0001)) + " eulerZ avg=" + str(snappedf(avg2.z, 0.0001)))
	log_line("IDLE nose.y samples=" + str(nose_ys2))
	log_line("PROBE RUN DONE")
	quit()
