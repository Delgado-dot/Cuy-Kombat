extends SceneTree

var log_file: FileAccess

func log_line(msg: String) -> void:
	log_file.store_line(msg)
	log_file.flush()

func _init() -> void:
	var log_path: String = OS.get_environment("TEMP") + "/probe_anim.log"
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	log_line("PROBE START")
	var glb: PackedScene = load("res://assets/models/CuyAnimado.glb")
	log_line("GLB loaded")
	var model := glb.instantiate()
	root.add_child(model)
	log_line("model added")
	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	log_line("skeleton=" + str(skeleton != null) + " animplayer=" + str(ap != null))
	if skeleton == null or ap == null:
		log_line("MISSING NODES")
		quit()
		return

	var head_idx := skeleton.find_bone("Cabesa")
	var neck_idx := skeleton.find_bone("Cuello")
	log_line("bones: head=" + str(head_idx) + " neck=" + str(neck_idx))

	var head_rest := skeleton.get_bone_global_rest(head_idx)
	log_line("head rest basis z=" + str(head_rest.basis.z) + " fwdGlobal=" + str(head_rest.basis * Vector3(0, 0, -1)))

	for anim_name in ["Idle", "Run", "Jump"]:
		var anim: Animation = ap.get_animation(anim_name)
		if anim == null:
			log_line("NO ANIM: " + anim_name)
			continue
		log_line("=== " + anim_name + " len=" + str(anim.length) + " loops=" + str(anim.loop_mode))
		for i in anim.get_track_count():
			var path := anim.track_get_path(i)
			var name_str := path.get_concatenated_names()
			var sub_str := path.get_concatenated_subnames()
			if sub_str.contains("Cabesa") or sub_str.contains("Cuello"):
				var ttype: int = anim.track_get_type(i)
				var vals := ""
				for j in anim.track_get_key_count(i):
					var t := anim.track_get_key_time(i, j)
					var v: Variant = anim.track_get_key_value(i, j)
					vals += "[" + str(snappedf(t, 0.001)) + ":" + str(v) + "] "
				log_line("  track " + name_str + " : " + sub_str + " type=" + str(ttype) + " keys=" + vals)

		for t in [0.0, 0.1, 0.2, 0.3, 0.4, 0.5]:
			ap.play(anim_name)
			ap.advance(t)
			skeleton.force_update_all_bone_transforms()
			var pose_q: Quaternion = skeleton.get_bone_pose_rotation(head_idx)
			var gpose: Transform3D = skeleton.get_bone_global_pose(head_idx)
			var gforward := -(gpose.basis.z)
			var lforward := (pose_q * Vector3(0, 0, -1))
			var euler := pose_q.get_euler()
			log_line("  t=" + str(t) + " localFwd=" + str(lforward) + " globalFwd=" + str(gforward) + " euler=" + str(euler) + " globalFwd.y=" + str(snappedf(gforward.y, 0.001)))

	log_line("PROBE DONE")
	quit()
