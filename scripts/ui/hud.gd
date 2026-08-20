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
@onready var _p3_name := %P3Name as Label
@onready var _p3_bar := %P3Bar as ProgressBar
@onready var _p3_status := %P3Status as Label
@onready var _p3_icon := %P3Icon as Control
@onready var _p3_leader := %P3Leader as Label
@onready var _p3_pips := %P3Pips as HBoxContainer
@onready var _p3_stars := %P3Stars as Label
@onready var _p3_panel := %PlayerThreePanel as Control
@onready var _p4_name := %P4Name as Label
@onready var _p4_bar := %P4Bar as ProgressBar
@onready var _p4_status := %P4Status as Label
@onready var _p4_icon := %P4Icon as Control
@onready var _p4_leader := %P4Leader as Label
@onready var _p4_pips := %P4Pips as HBoxContainer
@onready var _p4_stars := %P4Stars as Label
@onready var _p4_panel := %PlayerFourPanel as Control

var _game_manager: Node
var _players: Array[Node] = []
var _bar_colors: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]
var _bar_fills: Array[StyleBoxFlat] = [null, null, null, null]
var _pip_styles: Array = [[], [], [], []]
var _display_health: Array[float] = [1.0, 1.0, 1.0, 1.0]
var _ko_flash: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _time_left := 0.0
var _pulse_time := 0.0
var _match_active := false
var _intro_tween: Tween = null
var _idle_tween: Tween = null
var _shake_tweens: Array[Tween] = [null, null, null, null]
var _player_count := 2

const ANDEAN_GOLD := Color(0.95, 0.72, 0.15, 1.0)


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

	_player_count = MatchSettings.get_player_count()

	_setup_player_ui(0, _p1_name, _p1_bar, _p1_status, _p1_icon, _p1_leader, _p1_pips)
	_setup_player_ui(1, _p2_name, _p2_bar, _p2_status, _p2_icon, _p2_leader, _p2_pips)
	if _player_count >= 3:
		_setup_player_ui(2, _p3_name, _p3_bar, _p3_status, _p3_icon, _p3_leader, _p3_pips)
	if _player_count >= 4:
		_setup_player_ui(3, _p4_name, _p4_bar, _p4_status, _p4_icon, _p4_leader, _p4_pips)
	_update_stars()
	_apply_andean_styling()
	_setup_idle_breathing()
	_root.pivot_offset = _root.size * 0.5
	_update_panel_visibility()


func _update_panel_visibility() -> void:
	if _p3_panel != null:
		_p3_panel.visible = _player_count >= 3
	if _p4_panel != null:
		_p4_panel.visible = _player_count >= 4


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
	name_label.text = "P%d · CUY" % (index + 1)
	name_label.add_theme_color_override("font_color", color.lightened(0.4))
	name_label.add_theme_color_override("font_outline_color", Color(0.01, 0.008, 0.015, 1))
	icon.set("tint", color)

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 4
	fill.corner_radius_top_right = 4
	fill.corner_radius_bottom_right = 4
	fill.corner_radius_bottom_left = 4
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
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.25, 0.35, 0.5, 0.7)
		sb.corner_radius_top_left = 3
		sb.corner_radius_top_right = 3
		sb.corner_radius_bottom_right = 3
		sb.corner_radius_bottom_left = 3

		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.add_theme_stylebox_override("panel", sb)
		pips_container.add_child(pip)
		_pip_styles[index].append(sb)


func _apply_andean_styling() -> void:
	_timer_label.add_theme_color_override("font_color", ANDEAN_GOLD)
	_timer_label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.01, 1))

	_intro_label.add_theme_color_override("font_color", ANDEAN_GOLD)
	_intro_label.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.01, 1))
	_intro_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))

	_setup_andean_panel(0, _p1_bar, _p1_name, _p1_status, _p1_stars, _p1_pips)
	_setup_andean_panel(1, _p2_bar, _p2_name, _p2_status, _p2_stars, _p2_pips)
	if _player_count >= 3:
		_setup_andean_panel(2, _p3_bar, _p3_name, _p3_status, _p3_stars, _p3_pips)
	if _player_count >= 4:
		_setup_andean_panel(3, _p4_bar, _p4_name, _p4_status, _p4_stars, _p4_pips)


func _setup_andean_panel(index: int, bar: ProgressBar, name_label: Label, status_label: Label, stars_label: Label, pips_container: HBoxContainer) -> void:
	var color := _bar_colors[index]

	name_label.add_theme_color_override("font_color", color.lightened(0.5))

	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.01, 0.015, 0.03, 0.85)
	bg_sb.border_width_left = 2
	bg_sb.border_width_top = 2
	bg_sb.border_width_right = 2
	bg_sb.border_width_bottom = 2
	bg_sb.border_color = color.darkened(0.3).lerp(Color(0.15, 0.1, 0.05), 0.4)
	bg_sb.corner_radius_top_left = 6
	bg_sb.corner_radius_top_right = 6
	bg_sb.corner_radius_bottom_right = 6
	bg_sb.corner_radius_bottom_left = 6
	bar.add_theme_stylebox_override("background", bg_sb)

	stars_label.add_theme_color_override("font_color", ANDEAN_GOLD)
	status_label.add_theme_color_override("font_color", Color(0.6, 0.68, 0.82, 0.9))

	var panel_parent := bar.get_parent()
	if panel_parent != null:
		var accent := ColorRect.new()
		accent.custom_minimum_size = Vector2(0, 2)
		accent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		accent.color = color.darkened(0.2).lerp(ANDEAN_GOLD, 0.25)
		accent.modulate.a = 0.6
		var bar_index := bar.get_index()
		panel_parent.add_child(accent)
		panel_parent.move_child(accent, bar_index + 1)


func _setup_idle_breathing() -> void:
	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()

	var icons: Array[Control] = [_p1_icon, _p2_icon]
	if _player_count >= 3:
		icons.append(_p3_icon)
	if _player_count >= 4:
		icons.append(_p4_icon)

	for icon in icons:
		if icon == null:
			continue
		_idle_tween.parallel().tween_property(icon, "scale", Vector2.ONE * 1.06, 1.2).set_ease(
			Tween.EASE_IN_OUT
		).set_trans(Tween.TRANS_SINE)
		_idle_tween.parallel().tween_property(icon, "scale", Vector2.ONE, 1.2).set_ease(
			Tween.EASE_IN_OUT
		).set_trans(Tween.TRANS_SINE)


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
		_timer_label.scale = Vector2.ONE * (1.0 + 0.08 * sin(_pulse_time * 8.0))
	else:
		_timer_label.add_theme_color_override("font_color", ANDEAN_GOLD)
		_timer_label.scale = Vector2.ONE


func _update_players(delta: float) -> void:
	for index in range(mini(_players.size(), _player_count)):
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


func _get_bar(index: int) -> ProgressBar:
	match index:
		0: return _p1_bar
		1: return _p2_bar
		2: return _p3_bar
		3: return _p4_bar
	return _p1_bar


func _get_status_label(index: int) -> Label:
	match index:
		0: return _p1_status
		1: return _p2_status
		2: return _p3_status
		3: return _p4_status
	return _p1_status


func _get_stars_label(index: int) -> Label:
	match index:
		0: return _p1_stars
		1: return _p2_stars
		2: return _p3_stars
		3: return _p4_stars
	return _p1_stars


func _get_leader_label(index: int) -> Label:
	match index:
		0: return _p1_leader
		1: return _p2_leader
		2: return _p3_leader
		3: return _p4_leader
	return _p1_leader


func _update_bar(index: int, knocked: bool, eliminated: bool, delta: float) -> void:
	var bar := _get_bar(index)
	bar.value = _display_health[index] * 100.0

	var fill := _bar_fills[index]
	if fill == null:
		return

	if knocked or eliminated:
		_ko_flash[index] += delta * 7.0
		var pulse := 0.5 + 0.5 * sin(_ko_flash[index] * TAU)
		fill.bg_color = Color(1, 0.16, 0.12, 1).lerp(Color(0.5, 0.04, 0.04, 1), pulse)
		if knocked and delta > 0.0:
			if _shake_tweens[index] == null or not _shake_tweens[index].is_valid():
				_shake_tweens[index] = create_tween()
				_shake_tweens[index].tween_property(bar, "offset_left", -3.0, 0.04)
				_shake_tweens[index].tween_property(bar, "offset_left", 3.0, 0.04)
				_shake_tweens[index].tween_property(bar, "offset_left", 0.0, 0.04)
	else:
		fill.bg_color = _bar_colors[index].lerp(Color(1, 0.22, 0.16, 1), 1.0 - _display_health[index])
		bar.offset_left = 0.0

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
	var best_index := 0
	var best_health := -1.0
	for i in range(mini(_players.size(), _player_count)):
		if _display_health[i] > best_health:
			best_health = _display_health[i]
			best_index = i

	for i in range(mini(_players.size(), _player_count)):
		var leader := _get_leader_label(i)
		leader.visible = (i == best_index and _player_count > 1 and best_health > 0.0)


func _update_status(index: int, knocked: bool, eliminated: bool) -> void:
	var player := _players[index]
	var label := _get_status_label(index)

	if eliminated:
		label.text = "ELIMINADO"
		label.add_theme_color_override("font_color", Color(1, 0.35, 0.3, 1))
	elif knocked:
		label.text = "¡K.O.!"
		label.add_theme_color_override("font_color", Color(1, 0.3, 0.25, 1))
	else:
		label.text = _status_text(player)
		label.add_theme_color_override("font_color", Color(0.6, 0.68, 0.82, 0.9))


func _status_text(player: Node) -> String:
	var threshold := float(player.get("knockout_threshold"))
	var hits := float(player.get("knockout_hits"))
	return "GOLPES %d/%d" % [int(hits), int(threshold)]


func _update_stars() -> void:
	for i in range(mini(_players.size(), _player_count)):
		var stars := _get_stars_label(i)
		stars.text = _stars_text(RoundManager.get_wins(i + 1))


func _stars_text(count: int) -> String:
	var text := "VICTORIAS: %d" % count
	for i in count:
		text += " ★"
	return text


# ===========================================================================
#  MATCH LIFECYCLE
# ===========================================================================

func _on_match_started() -> void:
	_match_active = true
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_label.visible = false
	_pulse_time = 0.0
	_time_left = match_time
	_display_health = [1.0, 1.0, 1.0, 1.0]
	_ko_flash = [0.0, 0.0, 0.0, 0.0]
	_timer_label.scale = Vector2.ONE

	for index in range(mini(_players.size(), _player_count)):
		var fill := _bar_fills[index]
		if fill != null:
			fill.bg_color = _bar_colors[index]
		_update_pips(index, 0, false)
		_update_status(index, false, false)

	_update_leader()

	_root.visible = true
	_root.modulate.a = 0.0
	_p1_bar.offset_left = -40.0
	_p2_bar.offset_left = 40.0
	if _player_count >= 3 and _p3_bar != null:
		_p3_bar.offset_left = -40.0
	if _player_count >= 4 and _p4_bar != null:
		_p4_bar.offset_left = 40.0

	var entrance := create_tween().set_parallel()
	entrance.tween_property(_root, "modulate:a", 1.0, 0.3)
	entrance.tween_property(_p1_bar, "offset_left", 0.0, 0.45).set_ease(
		Tween.EASE_OUT
	).set_trans(Tween.TRANS_CUBIC)
	entrance.tween_property(_p2_bar, "offset_left", 0.0, 0.45).set_ease(
		Tween.EASE_OUT
	).set_trans(Tween.TRANS_CUBIC)
	if _player_count >= 3 and _p3_bar != null:
		entrance.tween_property(_p3_bar, "offset_left", 0.0, 0.45).set_ease(
			Tween.EASE_OUT
		).set_trans(Tween.TRANS_CUBIC)
	if _player_count >= 4 and _p4_bar != null:
		entrance.tween_property(_p4_bar, "offset_left", 0.0, 0.45).set_ease(
			Tween.EASE_OUT
		).set_trans(Tween.TRANS_CUBIC)

	_setup_idle_breathing()


func _on_match_intro_updated(text: String) -> void:
	_match_active = false
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()

	var is_fight := text == "¡PELEA!"
	_intro_label.text = text
	_intro_label.add_theme_color_override(
		"font_color",
		Color(1, 0.32, 0.18, 1) if is_fight else ANDEAN_GOLD
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

	for i in range(mini(_players.size(), _player_count)):
		_pop_stars(i)

	if _idle_tween != null and _idle_tween.is_valid():
		_idle_tween.kill()


func _pop_stars(index: int) -> void:
	var stars := _get_stars_label(index)
	var wins := RoundManager.get_wins(index + 1)
	if wins <= 0:
		return
	stars.pivot_offset = stars.size * 0.5
	var pop := create_tween()
	pop.tween_property(stars, "scale", Vector2.ONE * 1.4, 0.12).set_ease(
		Tween.EASE_OUT
	).set_trans(Tween.TRANS_BACK)
	pop.tween_property(stars, "scale", Vector2.ONE, 0.25).set_ease(
		Tween.EASE_OUT
	).set_trans(Tween.TRANS_ELASTIC)
