extends CanvasLayer

const MAIN_SCENE_PATH := "res://main.tscn"
const PLAYER_ONE_COLOR := Color(1.0, 0.38, 0.69, 1.0)
const PLAYER_TWO_COLOR := Color(0.36, 0.78, 1.0, 1.0)

@onready var _champion_label := %ChampionLabel as Label
@onready var _player_one_score := %PlayerOneScore as Label
@onready var _player_two_score := %PlayerTwoScore as Label
@onready var _main_menu_button := %MainMenuButton as Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_main_menu_button.pressed.connect(_return_to_main_menu)


# FUTURO: llamar esta función cuando exista el sistema real de Mejor de 3.
func show_match_end(winner_number: int, p1_score: int, p2_score: int) -> void:
	if winner_number != 1 and winner_number != 2:
		push_error("MatchEndScreen: winner_number debe ser 1 o 2.")
		return

	_champion_label.text = "¡P%d CAMPEÓN!" % winner_number
	_champion_label.add_theme_color_override(
		"font_color",
		PLAYER_ONE_COLOR if winner_number == 1 else PLAYER_TWO_COLOR
	)
	_player_one_score.text = str(p1_score)
	_player_two_score.text = str(p2_score)
	visible = true
	_main_menu_button.grab_focus()


func hide_match_end() -> void:
	visible = false


func _return_to_main_menu() -> void:
	get_tree().paused = false
	var change_error := get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	if change_error != OK:
		push_error("MatchEndScreen: no se pudo volver a main.tscn.")
