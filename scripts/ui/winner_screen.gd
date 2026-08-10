extends CanvasLayer

const PLAYER_ONE_COLOR := Color(1.0, 0.38, 0.69, 1.0)
const PLAYER_TWO_COLOR := Color(0.36, 0.78, 1.0, 1.0)

@onready var _winner_label := %WinnerLabel as Label
@onready var _confetti := %Confetti as CPUParticles2D
@onready var _next_round_button := %NextRoundButton as Button
@onready var _main_menu_button := %MainMenuButton as Button

var _winner_shown := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_next_round_button.disabled = true
	_next_round_button.tooltip_text = "Disponible cuando exista un reinicio seguro de ronda."
	_main_menu_button.pressed.connect(_return_to_main_menu)
	_update_confetti_area()


func show_winner(player_number: int) -> void:
	if _winner_shown:
		return

	_winner_shown = true
	_winner_label.text = "Jugador %d gana" % player_number
	_winner_label.add_theme_color_override(
		"font_color",
		PLAYER_ONE_COLOR if player_number == 1 else PLAYER_TWO_COLOR
	)
	visible = true
	_update_confetti_area()
	_confetti.restart()
	_confetti.emitting = true
	_main_menu_button.grab_focus()


func _update_confetti_area() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_confetti.position = Vector2(viewport_size.x * 0.5, 40.0)
	_confetti.emission_rect_extents.x = viewport_size.x * 0.48


func _return_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
