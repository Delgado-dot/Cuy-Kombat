extends CanvasLayer

const PLAYER_STATE_KNOCKED := 6

@export var game_manager_path: NodePath
@export var player_paths: Array[NodePath] = []
@export var match_time := 120.0

@onready var _root := %HudRoot as Control
@onready var _timer_label := %TimerLabel as Label
@onready var _intro_label := %IntroLabel as Label
@onready var _p1_name := %P1Name as Label
@onready var _p1_bar := %P1Bar as ProgressBar
@onready var _p1_status := %P1Status as Label
@onready var _p1_icon := %P1Icon as Control
@onready var _p1_leader := %P1Leader as Label
@onready var _p1_pips := %P1Pips as HBoxContainer
@onready var _p1_stars := %P1Stars as Label
@onready var _p2_name := %P2Name as Label
@onready var _p2_bar := %P2Bar as ProgressBar
@onready var _p2_status := %P2Status as Label
@onready var _p2_icon := %P2Icon as Control
@onready var _p2_leader := %P2Leader as Label
@onready var _p2_pips := %P2Pips as HBoxContainer
@onready var _p2_stars := %P2Stars as Label

var _game_manager: Node
var _players: Array[Node] = []
var _bar_colors: Array[Color] = [Color.WHITE, Color.WHITE]
var _bar_fills: Array[StyleBoxFlat] = [null, null]
var _pip_styles: Array = [[], []]
var _display_health: Array[float] = [1.0, 1.0]
var _ko_flash: Array[float] = [0.0, 0.0]
var _time_left := 0.0
var _pulse_time := 0.0
var _match_active := false
var _intro_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_timer_label.pivot_offset = _timer_label.size * 0.5

	_game_manager = get_node_or_null(game_manager_path)
	_connect_game_manager()

	for path in player_paths:
		var player := get_node_or_null(path)
		if player != null:
			_players.append(player)

	_setup_player_ui(0, _p1_name, _p1_bar, _p1_status, _p1_icon, _p1_leader, _p1_pips)
	_setup_player_ui(1, _p2_name, _p2_bar, _p2_status, _p2_icon, _p2_leader, _p2_pips)
	_update_stars()


func _connect_game_manager() -> void:
	if _game_manager == null:
		push_error("Hud: no se encontró GameManager.")
		return
	if not _game_manager.has_signal("match_started") or not _game_manager.has_signal("match_finished") or not _game_manager.has_signal("match_intro_updated"):
		push_error("Hud: GameManager no expone las señales esperadas.")
		return

	if not _game_manager.match_intro_updated.is_connected(_on_match_intro_updated):
		_game_manager.match_intro_updated.connect(_on_match_intro_updated)
	if not _game_manager.match_started.is_connected(_on_match_started):
		_game_manager.match_started.connect(_on_match_started)
	if not _game_manager.match_finished.is_connected(_on_match_finished):
		_game_manager.match_finished.connect(_on_match_finished)


func _setup_player_ui(index: int, name_label: Label, bar: ProgressBar, status_label: Label, icon: Control, leader_label: Label, pips_container: HBoxContainer) -> void:
	if index >= _players.size() or _players[index] == null:
		return

	var player := _players[index]
	var color: Color = player.get("player_color")

	_bar_colors[index] = color
	name_label.text = "P%d · CUY %d" % [index + 1, index + 1]
	name_label.add_theme_color_override("font_color", color.lightened(0.4))
	name_label.add_theme_color_override("font_outline_color", Color(0.01, 0.008, 0.015, 1))
	icon.set("tint", color)

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 10
	fill.corner_radius_top_right = 10
	fill.corner_radius_bottom_right = 10
	fill.corner_radius_bottom_left = 10
	bar.add_theme_stylebox_override("fill", fill)
	_bar_fills[index] = fill

	bar.value = 100.0
	status_label.text = _status_text(player)
	leader_label.visible = false

	var threshold := maxi(int(player.get("knockout_threshold")), 1)
	_setup_pips(pips_container, index, threshold)


func _setup_pips(pips_container: HBoxContainer, index: int, count: int) -> void:
	for child in pips_container.get_children():
		child.queue_free()

	_pip_styles[index].clear()

	for i in count:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.1, 0.16, 1)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.25, 0.35, 0.5, 1)
		sb.corner_radius_top_left = 5
		sb.corner_radius_top_right = 5
		sb.corner_radius_bottom_right = 5
		sb.corner_radius_bottom_left = 5

		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(20, 20)
		pip.add_theme_stylebox_override("panel", sb)
		pips_container.add_child(pip)
		_pip_styles[index].append(sb)


func _process(delta: float) -> void:
	if not _match_active:
		return

	if not get_tree().paused:
		_pulse_time += delta
		_time_left -= delta
		if _time_left <= 0.0:
			_time_left = 0.0
			if _game_manager != null and _game_manager.has_method("finalizar_partida_por_tiempo"):
				_game_manager.finalizar_partida_por_tiempo()

	_update_timer_label()
	_update_players(delta)


func _update_timer_label() -> void:
	var seconds := maxi(int(ceil(_time_left)), 0)
	_timer_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]

	if _time_left <= 15.0:
		_timer_label.add_theme_color_override("font_color", Color(1, 0.25, 0.2, 1))
		_timer_label.scale = Vector2.ONE * (1.0 + 0.1 * sin(_pulse_time * 8.0))
	else:
		_timer_label.add_theme_color_override("font_color", Color(1, 0.84, 0.35, 1))
		_timer_label.scale = Vector2.ONE


func _update_players(delta: float) -> void:
	for index in range(_players.size()):
		var player := _players[index]
		var target := 1.0
		var knocked := false
		var eliminated := false
		var hits := 0

		if player != null and is_instance_valid(player):
			var threshold := float(player.get("knockout_threshold"))
			hits = int(player.get("knockout_hits"))
			if threshold > 0.0:
				target = 1.0 - clampf(hits / threshold, 0.0, 1.0)
			knocked = player.get_player_state() == PLAYER_STATE_KNOCKED
			eliminated = not player.visible
		else:
			target = 0.0
			eliminated = true

		if eliminated:
			target = 0.0

		_display_health[index] = lerpf(_display_health[index], target, clampf(delta * 8.0, 0.0, 1.0))
		_update_bar(index, knocked, eliminated, delta)
		_update_pips(index, hits, knocked)
		_update_status(index, knocked, eliminated)

	_update_leader()


func _update_bar(index: int, knocked: bool, eliminated: bool, delta: float) -> void:
	var bar := _p1_bar if index == 0 else _p2_bar
	bar.value = _display_health[index] * 100.0

	var fill := _bar_fills[index]
	if fill == null:
		return

	if knocked or eliminated:
		_ko_flash[index] += delta * 7.0
		var pulse := 0.5 + 0.5 * sin(_ko_flash[index] * TAU)
		fill.bg_color = Color(1, 0.16, 0.12, 1).lerp(Color(0.5, 0.04, 0.04, 1), pulse)
	else:
		fill.bg_color = _bar_colors[index].lerp(Color(1, 0.22, 0.16, 1), 1.0 - _display_health[index])

	if not knocked and not eliminated and _display_health[index] < 0.3:
		var pulse := 0.5 + 0.5 * sin(_pulse_time * 10.0)
		bar.modulate.a = 0.65 + 0.35 * pulse
	else:
		bar.modulate.a = 1.0


func _update_pips(index: int, hits: int, knocked: bool) -> void:
	var styles: Array = _pip_styles[index]
	for i in styles.size():
		var sb := styles[i] as StyleBoxFlat
		if sb == null:
			continue

		if knocked:
			var flash := int(_ko_flash[index] * 4.0) % 2 == 0
			sb.bg_color = Color(1, 0.25, 0.2, 1) if flash else Color(0.5, 0.06, 0.05, 1)
		elif i < styles.size() - hits:
			sb.bg_color = _bar_colors[index].lerp(Color.WHITE, 0.35)
		else:
			sb.bg_color = Color(0.06, 0.1, 0.16, 1)


func _update_leader() -> void:
	var h1 := _display_health[0] if _players.size() > 0 else 0.0
	var h2 := _display_health[1] if _players.size() > 1 else 0.0
	_p1_leader.visible = h1 - h2 > 0.01
	_p2_leader.visible = h2 - h1 > 0.01


func _update_status(index: int, knocked: bool, eliminated: bool) -> void:
	var player := _players[index]
	var label := _p1_status if index == 0 else _p2_status

	if eliminated:
		label.text = "ELIMINADO"
		label.add_theme_color_override("font_color", Color(1, 0.35, 0.3, 1))
	elif knocked:
		label.text = "¡K.O.!"
		label.add_theme_color_override("font_color", Color(1, 0.3, 0.25, 1))
	else:
		label.text = _status_text(player)
		label.add_theme_color_override("font_color", Color(0.68, 0.77, 0.9, 1))


func _status_text(player: Node) -> String:
	var threshold := float(player.get("knockout_threshold"))
	var hits := float(player.get("knockout_hits"))
	return "GOLPES %d/%d" % [int(hits), int(threshold)]


func _update_stars() -> void:
	_p1_stars.text = _stars_text(RoundManager.get_wins(1))
	_p2_stars.text = _stars_text(RoundManager.get_wins(2))


func _stars_text(count: int) -> String:
	var text := "VICTORIAS: %d" % count
	for i in count:
		text += " ★"
	return text


func _on_match_started() -> void:
	_match_active = true
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_label.visible = false
	_pulse_time = 0.0
	_time_left = match_time
	_display_health = [1.0, 1.0]
	_ko_flash = [0.0, 0.0]
	_timer_label.scale = Vector2.ONE

	for index in range(_players.size()):
		var fill := _bar_fills[index]
		if fill != null:
			fill.bg_color = _bar_colors[index]
		_update_pips(index, 0, false)
		_update_status(index, false, false)

	_update_leader()
	_root.visible = true


func _on_match_intro_updated(text: String) -> void:
	_match_active = false
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()

	var is_fight := text == "¡PELEA!"
	_intro_label.text = text
	_intro_label.add_theme_color_override(
		"font_color",
		Color(1, 0.32, 0.18, 1) if is_fight else Color(1, 0.84, 0.35, 1)
	)
	_intro_label.pivot_offset = _intro_label.size * 0.5
	_intro_label.scale = Vector2.ONE * (0.5 if is_fight else 0.7)
	_intro_label.modulate = Color(1, 1, 1, 0)
	_intro_label.visible = true
	_root.visible = true

	_intro_tween = create_tween().set_parallel()
	_intro_tween.tween_property(_intro_label, "modulate:a", 1.0, 0.16)
	_intro_tween.tween_property(
		_intro_label,
		"scale",
		Vector2.ONE * (1.18 if is_fight else 1.0),
		0.24 if is_fight else 0.18
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_fight:
		_intro_tween.chain().tween_property(_intro_label, "scale", Vector2.ONE, 0.18)


func _on_match_finished(_winner: Node) -> void:
	_match_active = false
	_update_stars()
	_timer_label.text = "00:00"
	_timer_label.scale = Vector2.ONE
