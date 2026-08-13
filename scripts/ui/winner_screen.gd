extends CanvasLayer

const PLAYER_ONE_COLOR := Color(1.0, 0.38, 0.69, 1.0)
const PLAYER_TWO_COLOR := Color(0.36, 0.78, 1.0, 1.0)

@export var game_manager_path: NodePath

@onready var _winner_label := %WinnerLabel as Label
@onready var _confetti := %Confetti as GPUParticles2D
@onready var _next_round_button := %NextRoundButton as Button
@onready var _main_menu_button := %MainMenuButton as Button
@onready var _winner_glow := %WinnerGlow as Polygon2D
@onready var _winner_light := %WinnerLight as OmniLight3D
@onready var _winner_cuy_pivot := %WinnerCuyPivot as Node3D

var _game_manager: Node
var _winner_shown := false
var _presentation_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_next_round_button.disabled = true
	_next_round_button.tooltip_text = "Disponible cuando exista un reinicio seguro de ronda."
	_main_menu_button.pressed.connect(_return_to_main_menu)
	_update_confetti_area()

	_game_manager = get_node_or_null(game_manager_path)
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
	show_winner(get_player_number(winner))


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
	_winner_label.text = "¡P%d GANA!" % player_number
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
	_main_menu_button.grab_focus()


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
