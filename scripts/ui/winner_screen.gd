extends CanvasLayer

const PLAYER_ONE_COLOR := Color(1.0, 0.38, 0.69, 1.0)
const PLAYER_TWO_COLOR := Color(0.36, 0.78, 1.0, 1.0)
const WINNER_MODEL_SCALE_FACTOR := 0.62
const WINNER_MODEL_VERTICAL_OFFSET := 0.65

@export var game_manager_path: NodePath
@export var scenario_manager_path: NodePath
@export var next_round_delay := 3.0

@onready var _winner_label := %WinnerLabel as Label
@onready var _confetti := %Confetti as GPUParticles2D
@onready var _next_round_button := %NextRoundButton as Button
@onready var _main_menu_button := %MainMenuButton as Button
@onready var _transition_title := %TransitionTitle as Label
@onready var _countdown_label := %CountdownLabel as Label
@onready var _next_round_timer := %NextRoundTimer as Timer
@onready var _winner_glow := %WinnerGlow as Polygon2D
@onready var _winner_light := %WinnerLight as OmniLight3D
@onready var _winner_cuy_pivot := %WinnerCuyPivot as Node3D

var _game_manager: Node
var _scenario_manager: Node
var _winner_shown := false
var _round_transition_started := false
var _next_round_started := false
var _presentation_tween: Tween
var _winner_animation_player: AnimationPlayer
var _winner_celebration_name := StringName()
var _winner_skeletons: Array[Skeleton3D] = []
var _winner_bone_base_rotations := {}
var _winner_celebration_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_next_round_button.pressed.connect(_start_next_round)
	_main_menu_button.pressed.connect(_return_to_main_menu)
	_next_round_timer.timeout.connect(_start_next_round)
	_update_confetti_area()

	_game_manager = get_node_or_null(game_manager_path)
	_scenario_manager = get_node_or_null(scenario_manager_path)
	_connect_game_manager()


func _process(delta: float) -> void:
	if _round_transition_started and not _next_round_started and not _next_round_timer.is_stopped():
		_countdown_label.text = str(maxi(1, ceili(_next_round_timer.time_left)))

	if visible and _winner_celebration_name == StringName() and not _winner_skeletons.is_empty():
		_winner_celebration_time += delta
		_apply_procedural_winner_celebration()


func _connect_game_manager() -> void:
	if _game_manager == null:
		push_error("WinnerScreen: no se encontró GameManager en '%s'." % game_manager_path)
		return
	if not _game_manager.has_signal("match_finished"):
		push_error("WinnerScreen: GameManager no expone la señal match_finished.")
		return
	if not _game_manager.match_finished.is_connected(_on_match_finished):
		_game_manager.match_finished.connect(_on_match_finished)


func _on_match_finished(winner: Node) -> void:
	var player_number := get_player_number(winner)
	RoundManager.register_win(player_number)
	show_winner(player_number)


func get_player_number(node: Node) -> int:
	if node == null:
		return 1
	if node.is_in_group("player_1"):
		return 1
	if node.is_in_group("player_2"):
		return 2
	if _game_manager != null and _game_manager.has_method("get_player_number"):
		return _game_manager.get_player_number(node)
	return 1


func show_winner(player_number: int) -> void:
	if _winner_shown:
		return

	_winner_shown = true
	_apply_winner_character_model(player_number)

	var champion := RoundManager.reached_goal(player_number)
	var winner_label_text := "¡P%d CAMPEÓN!" if champion else "¡P%d GANA LA RONDA!"
	_winner_label.text = winner_label_text % player_number
	var winner_color := PLAYER_ONE_COLOR if player_number == 1 else PLAYER_TWO_COLOR
	_winner_label.add_theme_color_override(
		"font_color",
		winner_color
	)
	_winner_glow.color = Color(winner_color.r, winner_color.g, winner_color.b, 0.16)
	_winner_light.light_color = winner_color.lightened(0.18)
	visible = true
	_play_winner_presentation()
	_update_confetti_area()
	_confetti.restart()
	_confetti.emitting = true

	if champion:
		_transition_title.text = "PARTIDA FINALIZADA"
		_countdown_label.text = ""
	else:
		_start_round_countdown()


func _start_round_countdown() -> void:
	if _round_transition_started or _next_round_started:
		return
	_round_transition_started = true
	_transition_title.text = "SIGUIENTE RONDA"
	_next_round_timer.start(maxf(next_round_delay, 0.1))
	_countdown_label.text = str(maxi(1, ceili(_next_round_timer.time_left)))


func _apply_winner_character_model(player_number: int) -> void:
	var preset: Dictionary = MatchSettings.get_player_character(player_number)
	if preset.is_empty() or not preset.has("scene_path"):
		return

	var scene_path := String(preset["scene_path"])
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return

	var model_scene := load(scene_path) as PackedScene
	if model_scene == null:
		return

	for child in _winner_cuy_pivot.get_children():
		child.queue_free()

	var model := model_scene.instantiate() as Node3D
	if model != null:
		var scale_vec := (preset.get("scale", Vector3.ONE) as Vector3) * WINNER_MODEL_SCALE_FACTOR
		var offset_vec := (preset.get("offset", Vector3.ZERO) as Vector3) + Vector3.UP * WINNER_MODEL_VERTICAL_OFFSET
		model.transform = Transform3D(Basis().scaled(scale_vec), offset_vec)
		model.rotation.y = PI
		_winner_cuy_pivot.add_child(model)
		_prepare_winner_celebration(model)


func _prepare_winner_celebration(model: Node3D) -> void:
	_winner_animation_player = null
	_winner_celebration_name = StringName()
	_winner_skeletons.clear()
	_winner_bone_base_rotations.clear()
	_winner_celebration_time = 0.0

	for skeleton_node in model.find_children("*", "Skeleton3D", true, false):
		var skeleton := skeleton_node as Skeleton3D
		if skeleton == null:
			continue
		_winner_skeletons.append(skeleton)
		var base_rotations := {}
		for bone_index in skeleton.get_bone_count():
			base_rotations[bone_index] = skeleton.get_bone_pose_rotation(bone_index)
		_winner_bone_base_rotations[skeleton.get_instance_id()] = base_rotations

	var animation_players := model.find_children("*", "AnimationPlayer", true, false)
	if animation_players.is_empty():
		return

	_winner_animation_player = animation_players[0] as AnimationPlayer
	if _winner_animation_player == null:
		return

	for animation_name in [&"victory", &"Victory", &"dance", &"Dance"]:
		if _winner_animation_player.has_animation(animation_name):
			_winner_celebration_name = animation_name
			_winner_animation_player.play(_winner_celebration_name)
			if not _winner_animation_player.animation_finished.is_connected(_repeat_winner_celebration):
				_winner_animation_player.animation_finished.connect(_repeat_winner_celebration)
			return


func _apply_procedural_winner_celebration() -> void:
	var body_sway := sin(_winner_celebration_time * 4.6) * 0.09
	var head_tilt := sin(_winner_celebration_time * 6.2) * 0.14
	var arm_wave := 0.55 + sin(_winner_celebration_time * 6.2) * 0.2
	var leg_kick := sin(_winner_celebration_time * 4.6) * 0.1

	for skeleton in _winner_skeletons:
		if not is_instance_valid(skeleton):
			continue
		var base_rotations: Dictionary = _winner_bone_base_rotations.get(skeleton.get_instance_id(), {})
		for bone_index in skeleton.get_bone_count():
			if not base_rotations.has(bone_index):
				continue

			var bone_name := skeleton.get_bone_name(bone_index).to_lower()
			var base_rotation: Quaternion = base_rotations[bone_index]
			if "head" in bone_name or "cabeza" in bone_name:
				skeleton.set_bone_pose_rotation(bone_index, base_rotation * Quaternion(Vector3.FORWARD, head_tilt))
			elif "chest" in bone_name or "spine" in bone_name or "torso" in bone_name or "body" in bone_name:
				skeleton.set_bone_pose_rotation(bone_index, base_rotation * Quaternion(Vector3.FORWARD, body_sway))
			elif "arm" in bone_name or "brazo" in bone_name or "forearm" in bone_name or "hand" in bone_name or "mano" in bone_name:
				var arm_side := -1.0 if "_l" in bone_name or "left" in bone_name or "izq" in bone_name else 1.0
				skeleton.set_bone_pose_rotation(bone_index, base_rotation * Quaternion(Vector3.FORWARD, arm_side * arm_wave))
			elif "leg" in bone_name or "pierna" in bone_name or "pata" in bone_name:
				var leg_side := -1.0 if "_l" in bone_name or "left" in bone_name or "izq" in bone_name else 1.0
				skeleton.set_bone_pose_rotation(bone_index, base_rotation * Quaternion(Vector3.RIGHT, leg_side * leg_kick))
			elif "ear" in bone_name or "oreja" in bone_name:
				skeleton.set_bone_pose_rotation(bone_index, base_rotation * Quaternion(Vector3.FORWARD, head_tilt * 0.7))


func _restore_winner_bone_poses() -> void:
	for skeleton in _winner_skeletons:
		if not is_instance_valid(skeleton):
			continue
		var base_rotations: Dictionary = _winner_bone_base_rotations.get(skeleton.get_instance_id(), {})
		for bone_index in base_rotations:
			skeleton.set_bone_pose_rotation(bone_index, base_rotations[bone_index])


func _repeat_winner_celebration(animation_name: StringName) -> void:
	if visible and _winner_animation_player != null and animation_name == _winner_celebration_name:
		_winner_animation_player.play(_winner_celebration_name)


func _play_winner_presentation() -> void:
	if _presentation_tween != null and _presentation_tween.is_valid():
		_presentation_tween.kill()

	_winner_cuy_pivot.scale = Vector3(0.82, 0.82, 0.82)
	_winner_cuy_pivot.position = Vector3.ZERO
	_winner_cuy_pivot.rotation = Vector3.ZERO
	_presentation_tween = create_tween().set_parallel()
	_presentation_tween.tween_property(
		_winner_cuy_pivot,
		"scale",
		Vector3.ONE,
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_confetti_area() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_confetti.position = Vector2(viewport_size.x * 0.5, 40.0)

	var particles_material := _confetti.process_material as ParticleProcessMaterial
	if particles_material != null:
		particles_material.emission_box_extents.x = viewport_size.x * 0.48


func _return_to_main_menu() -> void:
	_restore_winner_bone_poses()
	get_tree().paused = false
	ScreenFlow.go_to_main_menu()


func _start_next_round() -> void:
	if _next_round_started:
		return
	if _scenario_manager == null or not _scenario_manager.has_method("start_next_round"):
		push_error("WinnerScreen: no se encontró ScenarioManager para la siguiente ronda.")
		return
	_next_round_started = true
	_round_transition_started = false
	_next_round_timer.stop()
	_restore_winner_bone_poses()
	_scenario_manager.call("start_next_round")
