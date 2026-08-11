extends SceneTree

var log_file: FileAccess
var skeleton: Skeleton3D
var head_idx := -1
var neck_idx := -1
var spine0_idx := -1
var spine1_idx := -1
var root_idx := -1

func log_line(msg: String) -> void:
	log_file.store_line(msg)
	log_file.flush()

func _init() -> void:
	var log_path: String = OS.get_environment("TEMP") + "/probe_chain.log"
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	log_line("PROBE CHAIN START")
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

	skeleton = player.get_node("Visual/CuyModel/Armature/Skeleton3D") as Skeleton3D
	head_idx = skeleton.find_bone("Cabesa")
	neck_idx = skeleton.find_bone("Cuello")
	spine0_idx = skeleton.find_bone("ColumnaBaj")
	spine1_idx = skeleton.find_bone("Caolumna1")
	root_idx = skeleton.find_bone("rincipal")
	log_line("head=" + str(head_idx) + " neck=" + str(neck_idx) + " spine0=" + str(spine0_idx) + " spine1=" + str(spine1_idx) + " root=" + str(root_idx))

	await physics_frame
	await physics_frame
	await physics_frame

	var ev_press := InputEventKey.new()
	ev_press.physical_keycode = KEY_W
	ev_press.pressed = true
	Input.parse_input_event(ev_press)

	for i in range(180):
		await physics_frame
	log_line("--- RUN: nose.y (basis.z.y) por hueso y euler local ---")
	for i in range(24):
		await physics_frame
		var line := "f" + str(i)
		for b in [root_idx, spine0_idx, spine1_idx, neck_idx, head_idx]:
			var gpose: Transform3D = skeleton.get_bone_global_pose(b)
			var euler: Vector3 = skeleton.get_bone_pose_rotation(b).get_euler()
			line += " | " + skeleton.get_bone_name(b) + " nose.y=" + str(snappedf(gpose.basis.z.y, 0.001)) + " eulerX=" + str(snappedf(euler.x, 0.001))
		log_line(line)

	var ev_release := InputEventKey.new()
	ev_release.physical_keycode = KEY_W
	ev_release.pressed = false
	Input.parse_input_event(ev_release)

	for i in range(60):
		await physics_frame
	log_line("--- IDLE: nose.y (basis.z.y) por hueso y euler local ---")
	for i in range(24):
		await physics_frame
		var line := "f" + str(i)
		for b in [root_idx, spine0_idx, spine1_idx, neck_idx, head_idx]:
			var gpose: Transform3D = skeleton.get_bone_global_pose(b)
			var euler: Vector3 = skeleton.get_bone_pose_rotation(b).get_euler()
			line += " | " + skeleton.get_bone_name(b) + " nose.y=" + str(snappedf(gpose.basis.z.y, 0.001)) + " eulerX=" + str(snappedf(euler.x, 0.001))
		log_line(line)

	log_line("PROBE CHAIN DONE")
	quit()
