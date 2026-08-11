extends SceneTree

var log_file: FileAccess

func log_line(msg: String) -> void:
	log_file.store_line(msg)
	log_file.flush()

func _init() -> void:
	var log_path: String = OS.get_environment("TEMP") + "/probe_tracks.log"
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	var glb: PackedScene = load("res://assets/models/CuyAnimado.glb")
	var model := glb.instantiate()
	root.add_child(model)
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		log_line("NO AP")
		quit()
		return

	for anim_name in ["Idle", "Run", "Jump"]:
		var anim: Animation = ap.get_animation(anim_name)
		if anim == null:
			log_line("NO ANIM " + anim_name)
			continue
		log_line("=== " + anim_name + " len=" + str(anim.length))
		for i in anim.get_track_count():
			var path := anim.track_get_path(i)
			var name_str := path.get_concatenated_names()
			var sub_str := path.get_concatenated_subnames()
			var ttype: int = anim.track_get_type(i)
			var kc: int = anim.track_get_key_count(i)
			var first: Variant = anim.track_get_key_value(i, 0) if kc > 0 else null
			var last: Variant = anim.track_get_key_value(i, kc - 1) if kc > 0 else null
			log_line("  track " + name_str + " : " + sub_str + " type=" + str(ttype) + " keys=" + str(kc) + " first=" + str(first) + " last=" + str(last))
	quit()
