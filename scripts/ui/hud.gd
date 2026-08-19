extends CanvasLayer

const PLAYER_STATE_KNOCKED := 6
const ACTIVE_STAR := "★"
const INACTIVE_STAR := "☆"
const ANDEAN_GOLD := Color(0.95, 0.72, 0.15, 1.0)

@export var game_manager_path: NodePath
@export var player_paths: Array[NodePath] = []
@export var match_time := 120.0

@onready var _root := %HudRoot as Control
@onready var _timer_label := %TimerLabel as Label
@onready var _intro_label := %IntroLabel as Label

@onready var _p1_panel := %PlayerOnePanel as Control
@onready var _p1_name := %P1Name as Label
@onready var _p1_bar := %P1Bar as ProgressBar
@onready var _p1_status := %P1Status as Label
@onready var _p1_icon := %P1Icon as Control
@onready var _p1_leader := %P1Leader as Label
@onready var _p1_stars := %P1Stars as HBoxContainer

@onready var _p2_panel := %PlayerTwoPanel as Control
@onready var _p2_name := %P2Name as Label
@onready var _p2_bar := %P2Bar as ProgressBar
@onready var _p2_status := %P2Status as Label
@onready var _p2_icon := %P2Icon as Control
@onready var _p2_leader := %P2Leader as Label
@onready var _p2_stars := %P2Stars as HBoxContainer

@onready var _p3_panel := %PlayerThreePanel as Control
@onready var _p3_name := %P3Name as Label
@onready var _p3_bar := %P3Bar as ProgressBar
@onready var _p3_status := %P3Status as Label
@onready var _p3_icon := %P3Icon as Control
@onready var _p3_leader := %P3Leader as Label
@onready var _p3_stars := %P3Stars as HBoxContainer

@onready var _p4_panel := %PlayerFourPanel as Control
@onready var _p4_name := %P4Name as Label
@onready var _p4_bar := %P4Bar as ProgressBar
@onready var _p4_status := %P4Status as Label
@onready var _p4_icon := %P4Icon as Control
@onready var _p4_leader := %P4Leader as Label
@onready var _p4_stars := %P4Stars as HBoxContainer

var _game_manager: Node
var _players: Array[Node] = []
var _player_count := 2
var _bar_colors: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]
var _bar_fills: Array[StyleBoxFlat] = [null, null, null, null]
var _star_labels: Array = [[], [], [], []]
var _displayed_hits: Array[int] = [0, 0, 0, 0]
var _display_health: Array[float] = [1.0, 1.0, 1.0, 1.0]
var _ko_flash: Array[float] = [0.0, 0.0, 0.0, 0.0]
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

	_player_count = mini(clampi(MatchSettings.get_player_count(), 2, 4), _players.size())
	_update_panel_visibility()
	for index in range(_player_count):
		_setup_player_ui(index)


func _update_panel_visibility() -> void:
	_p1_panel.visible = _player_count >= 1
	_p2_panel.visible = _player_count >= 2
	_p3_panel.visible = _player_count >= 3
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


func _setup_player_ui(index: int) -> void:
	if index >= _players.size() or _players[index] == null:
		return

	var player := _players[index]
	var name_label := _get_name_label(index)
	var bar := _get_bar(index)
	var status_label := _get_status_label(index)
	var icon := _get_icon(index)
	var leader_label := _get_leader_label(index)
	var stars_container := _get_stars_container(index)
	var color: Color = player.get("player_color")

	_bar_colors[index] = color
	name_label.text = "CUY %d" % (index + 1)
	name_label.add_theme_color_override("font_color", color.lightened(0.4))
	name_label.add_theme_color_override("font_outline_color", Color(0.01, 0.008, 0.015, 1))
	icon.set("tint", color)

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_right = 3
	fill.corner_radius_bottom_left = 3
	fill.border_width_top = 2
	fill.border_color = color.lightened(0.42)
	bar.add_theme_stylebox_override("fill", fill)
	_bar_fills[index] = fill

	bar.value = 100.0
	status_label.text = _status_text(player)
	leader_label.visible = false

	var threshold := maxi(int(player.get("knockout_threshold")), 1)
	_setup_hit_stars(stars_container, index, threshold)


func _setup_hit_stars(stars_container: HBoxContainer, index: int, count: int) -> void:
	for child in stars_container.get_children():
		child.queue_free()

	_star_labels[index].clear()
	for _star_index in count:
		var star := Label.new()
		star.custom_minimum_size = Vector2(27, 29)
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.text = INACTIVE_STAR
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star.add_theme_font_size_override("font_size", 24)
		star.add_theme_constant_override("outline_size", 4)
		star.add_theme_color_override("font_outline_color", Color(0.005, 0.008, 0.02, 1.0))
		stars_container.add_child(star)
		_star_labels[index].append(star)
		star.resized.connect(_center_star_pivot.bind(star))
		_center_star_pivot(star)

	_update_hit_stars(index, 0, false, false)


func _center_star_pivot(star: Label) -> void:
	star.pivot_offset = star.size * 0.5


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
		_timer_label.add_theme_color_override("font_color", ANDEAN_GOLD)
		_timer_label.scale = Vector2.ONE


func _update_players(delta: float) -> void:
	for index in range(_player_count):
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
		_update_hit_stars(index, hits, knocked)
		_update_status(index, knocked, eliminated)

	_update_leader()


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
	else:
		fill.bg_color = _bar_colors[index].lerp(Color.WHITE, 0.10 + (1.0 - _display_health[index]) * 0.10)

	if not knocked and not eliminated and _display_health[index] < 0.3:
		var pulse := 0.5 + 0.5 * sin(_pulse_time * 10.0)
		bar.modulate.a = 0.65 + 0.35 * pulse
	else:
		bar.modulate.a = 1.0


func _update_hit_stars(index: int, hits: int, knocked: bool, animate_new := true) -> void:
	var stars: Array = _star_labels[index]
	var clamped_hits := clampi(hits, 0, stars.size())
	var previous_hits := _displayed_hits[index]

	for i in stars.size():
		var star := stars[i] as Label
		if star == null:
			continue

		var active := i < clamped_hits
		star.text = ACTIVE_STAR if active else INACTIVE_STAR
		if active:
			var active_color := _bar_colors[index].lightened(0.32)
			if knocked:
				var flash := int(_ko_flash[index] * 4.0) % 2 == 0
				active_color = Color.WHITE if flash else active_color
			star.add_theme_color_override("font_color", active_color)
		else:
			star.add_theme_color_override("font_color", _bar_colors[index].darkened(0.68))

		if animate_new and hits > previous_hits and i >= previous_hits and i < clamped_hits:
			_animate_star(star)

	_displayed_hits[index] = clamped_hits


func _animate_star(star: Label) -> void:
	star.scale = Vector2.ONE * 0.7
	star.modulate = Color(1.65, 1.65, 1.65, 1.0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	tween.tween_property(star, "scale", Vector2.ONE * 1.2, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "modulate", Color.WHITE, 0.18)
	tween.tween_property(star, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _update_leader() -> void:
	var best_index := 0
	var best_health := -1.0
	for index in range(_player_count):
		if _display_health[index] > best_health:
			best_health = _display_health[index]
			best_index = index

	for index in range(_player_count):
		var leader := _get_leader_label(index)
		leader.visible = index == best_index and _player_count > 1 and best_health > 0.0


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
		label.add_theme_color_override("font_color", Color(0.68, 0.77, 0.9, 1))


func _status_text(player: Node) -> String:
	var threshold := float(player.get("knockout_threshold"))
	var hits := float(player.get("knockout_hits"))
	return "GOLPES %d/%d" % [int(hits), int(threshold)]


func _on_match_started() -> void:
	_match_active = true
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_label.visible = false
	_pulse_time = 0.0
	_time_left = match_time
	_display_health = [1.0, 1.0, 1.0, 1.0]
	_ko_flash = [0.0, 0.0, 0.0, 0.0]
	_displayed_hits = [0, 0, 0, 0]
	_timer_label.scale = Vector2.ONE

	for index in range(_player_count):
		var fill := _bar_fills[index]
		if fill != null:
			fill.bg_color = _bar_colors[index]
		_update_hit_stars(index, 0, false, false)
		_update_status(index, false, false)

	_update_leader()
	_root.visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.3)


func _on_match_intro_updated(text: String) -> void:
	_match_active = false
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()

	var is_fight := text == "¡PELEA!"
	_intro_label.text = text
	_intro_label.add_theme_color_override("font_color", Color(1, 0.32, 0.18, 1) if is_fight else ANDEAN_GOLD)
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
	_timer_label.text = "00:00"
	_timer_label.scale = Vector2.ONE


func _get_name_label(index: int) -> Label:
	match index:
		0: return _p1_name
		1: return _p2_name
		2: return _p3_name
		3: return _p4_name
	return _p1_name


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


func _get_icon(index: int) -> Control:
	match index:
		0: return _p1_icon
		1: return _p2_icon
		2: return _p3_icon
		3: return _p4_icon
	return _p1_icon


func _get_leader_label(index: int) -> Label:
	match index:
		0: return _p1_leader
		1: return _p2_leader
		2: return _p3_leader
		3: return _p4_leader
	return _p1_leader


func _get_stars_container(index: int) -> HBoxContainer:
	match index:
		0: return _p1_stars
		1: return _p2_stars
		2: return _p3_stars
		3: return _p4_stars
	return _p1_stars
