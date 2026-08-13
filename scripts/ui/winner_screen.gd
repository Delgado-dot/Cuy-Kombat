extends CanvasLayer

const PLAYER_ONE_COLOR := Color(1.0, 0.38, 0.69, 1.0)
const PLAYER_TWO_COLOR := Color(0.36, 0.78, 1.0, 1.0)

@export var game_manager_path: NodePath
@export var scenario_manager_path: NodePath

@onready var _winner_label := %WinnerLabel as Label
@onready var _confetti := %Confetti as GPUParticles2D
@onready var _next_round_button := %NextRoundButton as Button
@onready var _main_menu_button := %MainMenuButton as Button
@onready var _winner_glow := %WinnerGlow as Polygon2D
@onready var _winner_light := %WinnerLight as OmniLight3D
@onready var _winner_cuy_pivot := %WinnerCuyPivot as Node3D

var _game_manager: Node
var _scenario_manager: Node
var _winner_shown := false
var _presentation_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_next_round_button.pressed.connect(_start_next_round)
	_main_menu_button.pressed.connect(_return_to_main_menu)
	_update_confetti_area()

	_game_manager = get_node_or_null(game_manager_path)
	_scenario_manager = get_node_or_null(scenario_manager_path)
	_connect_game_manager()


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
		_next_round_button.disabled = true
		_next_round_button.text = "CAMPEÓN"
		_next_round_button.tooltip_text = "El match ha terminado."
		_main_menu_button.grab_focus()
	else:
		_next_round_button.disabled = false
		_next_round_button.text = "SIGUIENTE RONDA"
		_next_round_button.tooltip_text = ""
		_next_round_button.grab_focus()


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
		var scale_vec := preset.get("scale", Vector3.ONE) as Vector3
		var offset_vec := preset.get("offset", Vector3.ZERO) as Vector3
		model.transform = Transform3D(Basis().scaled(scale_vec), offset_vec)
		model.rotation.y = PI
		_winner_cuy_pivot.add_child(model)


func _play_winner_presentation() -> void:
	if _presentation_tween != null and _presentation_tween.is_valid():
		_presentation_tween.kill()

	_winner_cuy_pivot.scale = Vector3(0.72, 0.72, 0.72)
	_winner_cuy_pivot.rotation = Vector3(0, -0.52, 0)
	_presentation_tween = create_tween().set_parallel()
	_presentation_tween.tween_property(
		_winner_cuy_pivot,
		"scale",
		Vector3.ONE,
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_presentation_tween.tween_property(
		_winner_cuy_pivot,
		"rotation",
		Vector3(0, -0.12, 0),
		0.65
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_confetti_area() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_confetti.position = Vector2(viewport_size.x * 0.5, 40.0)

	var particles_material := _confetti.process_material as ParticleProcessMaterial
	if particles_material != null:
		particles_material.emission_box_extents.x = viewport_size.x * 0.48


func _return_to_main_menu() -> void:
	get_tree().paused = false
	ScreenFlow.go_to_main_menu()


func _start_next_round() -> void:
	if _scenario_manager == null or not _scenario_manager.has_method("start_next_round"):
		push_error("WinnerScreen: no se encontró ScenarioManager para la siguiente ronda.")
		return
	_scenario_manager.call("start_next_round")
