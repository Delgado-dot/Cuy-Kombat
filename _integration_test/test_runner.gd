extends Node

const MAIN_SCENE := "res://main.tscn"

const P1_COMBAT := Vector3(0, 1.0, 9.0)
const P2_COMBAT := Vector3(0, 1.0, 9.7)

const STATE_NORMAL := 0
const STATE_ATTACKING := 1
const STATE_KNOCKBACK := 2
const STATE_STUNNED := 3
const STATE_GRABBING := 4
const STATE_GRABBED := 5
const STATE_KNOCKED := 6

const MATCH_WAITING := 0
const MATCH_PLAYING := 1
const MATCH_FINISHED := 2

var _main: Node
var _gm: Node
var _p1: Node
var _p2: Node
var _cam: Camera3D
var _arena_cam: Camera3D
var _winner_screen: CanvasLayer
var _pause_menu: CanvasLayer
var _main_menu: CanvasLayer
var _controls_screen: CanvasLayer

var _results: Array[Dictionary] = []
var _p1_eliminated_count := 0
var _p2_eliminated_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _setup()
	await _test_initial_state()
	await _test_menu_controls_options()
	await _test_movement_jump()
	await _test_combat()
	await _test_knocked()
	await _test_grab()
	await _test_camera()
	await _test_pause()
	await _test_elimination_winner()
	await _test_duplicates()
	_print_report()
	var fails := 0
	for r in _results:
		if not r.ok:
			fails += 1
	get_tree().quit(1 if fails > 0 else 0)


# --------------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------------

func _setup() -> void:
	var packed: PackedScene = load(MAIN_SCENE)
	_main = packed.instantiate()
	add_child(_main)
	await _ticks(10)

	_gm = _main.get_node("GameManager")
	_p1 = _main.get_node("Player1")
	_p2 = _main.get_node("Player2")
	_cam = _main.get_node("Camera3D") as Camera3D
	_arena_cam = _main.get_node_or_null("Arena/Camera3D") as Camera3D
	_winner_screen = _main.get_node("WinnerScreen") as CanvasLayer
	_pause_menu = _main.get_node("PauseMenu") as CanvasLayer
	_main_menu = _main.get_node("MainMenu") as CanvasLayer
	_controls_screen = _main.get_node("ControlsScreen") as CanvasLayer

	_p1.eliminated.connect(func(_n): _p1_eliminated_count += 1)
	_p2.eliminated.connect(func(_n): _p2_eliminated_count += 1)
	await _ticks(5)


# --------------------------------------------------------------------------
# Test 0 / 1 - Estado inicial
# --------------------------------------------------------------------------

func _test_initial_state() -> void:
	_result("S0 Match en WAITING al inicio", int(_gm.match_state) == MATCH_WAITING,
		"state=%d" % int(_gm.match_state))
	_result("S0 Inputs deshabilitados al inicio", not _p1.input_enabled and not _p2.input_enabled,
		"p1=%s p2=%s" % [_p1.input_enabled, _p2.input_enabled])
	_result("S0 Esquemas de control", _p1.control_scheme == "wasd" and _p2.control_scheme == "arrows",
		"p1=%s p2=%s" % [_p1.control_scheme, _p2.control_scheme])
	_result("S0 MainMenu visible", _main_menu._menu_root.visible, "")
	_result("S0 Controls oculto", not _controls_screen._controls_root.visible, "")
	_result("S0 Winner oculto", not _winner_screen.visible, "")
	_result("S0 Pause oculto", not _pause_menu._pause_menu.visible, "")

	_send_key(KEY_ESCAPE, true)
	_send_key(KEY_ESCAPE, false)
	await _ticks(2)
	_result("S0 ESC sin partida NO pausa", not get_tree().paused, "paused=%s" % get_tree().paused)


# --------------------------------------------------------------------------
# Test 9 / 10 - MainMenu, ControlsScreen y Opciones
# --------------------------------------------------------------------------

func _test_menu_controls_options() -> void:
	# Abrir CONTROLES desde MainMenu
	_main_menu._controls_button.pressed.emit()
	await _ticks(3)
	_result("T9 CONTROLES abre desde el menú",
		_controls_screen._controls_root.visible and not _main_menu._menu_root.visible,
		"controls_visible=%s menu_visible=%s" % [_controls_screen._controls_root.visible, _main_menu._menu_root.visible])

	var has_w: bool = false
	var has_g: bool = false
	var has_k: bool = false
	var has_shift: bool = false
	var has_ctrl: bool = false
	var has_punto: bool = false
	var has_j1: bool = false
	var has_j2: bool = false
	for lbl in _controls_screen._controls_root.find_children("*", "Label", true, false):
		if lbl.text == "G":
			has_g = true
		elif lbl.text == "K":
			has_k = true
		elif lbl.text.contains("W  A  S  D"):
			has_w = true
		elif lbl.text == "SHIFT":
			has_shift = true
		elif lbl.text == "CTRL":
			has_ctrl = true
		elif lbl.text.contains("PUNTO"):
			has_punto = true
		elif lbl.text.contains("JUGADOR 1"):
			has_j1 = true
		elif lbl.text.contains("JUGADOR 2"):
			has_j2 = true
	_result("T9 Muestra controles P1 (WASD/ESPACIO/SHIFT/F)", has_w and has_shift and has_j1,
		"w=%s shift=%s j1=%s" % [has_w, has_shift, has_j1])
	_result("T9 Muestra controles P2 (flechas/ENTER/CTRL/PUNTO)", has_ctrl and has_punto and has_j2,
		"ctrl=%s punto=%s j2=%s" % [has_ctrl, has_punto, has_j2])
	_result("T9 Teclas de agarre G (P1) y K (P2) visibles", has_g and has_k, "g=%s k=%s" % [has_g, has_k])

	# ESC cierra CONTROLES
	_send_key(KEY_ESCAPE, true)
	_send_key(KEY_ESCAPE, false)
	await _ticks(3)
	_result("T9 ESC cierra CONTROLES y vuelve al menú",
		not _controls_screen._controls_root.visible and _main_menu._menu_root.visible,
		"controls_visible=%s menu_visible=%s" % [_controls_screen._controls_root.visible, _main_menu._menu_root.visible])

	# Reabrir y usar botón VOLVER
	_main_menu._controls_button.pressed.emit()
	await _ticks(3)
	_controls_screen._back_button.pressed.emit()
	await _ticks(3)
	_result("T9 Botón VOLVER regresa al menú",
		_main_menu._menu_root.visible and not _controls_screen._controls_root.visible, "")

	# Opciones
	_main_menu._options_button.pressed.emit()
	await _ticks(2)
	_result("T10 OPCIONES muestra aviso y no rompe el menú",
		_main_menu._options_message.visible and _main_menu._options_message.text.contains("PRÓXIMAMENTE")
		and _main_menu._menu_root.visible,
		"msg_visible=%s text=%s" % [_main_menu._options_message.visible, _main_menu._options_message.text])

	# Jugar
	_main_menu._play_button.pressed.emit()
	await _ticks(5)
	_result("S0 JUGAR inicia la partida",
		int(_gm.match_state) == MATCH_PLAYING and _p1.input_enabled and _p2.input_enabled
		and not _main_menu._menu_root.visible,
		"state=%d input=%s/%s menu=%s" % [int(_gm.match_state), _p1.input_enabled, _p2.input_enabled, _main_menu._menu_root.visible])


# --------------------------------------------------------------------------
# Test 1 - Movimiento y salto
# --------------------------------------------------------------------------

func _test_movement_jump() -> void:
	# P1 avanza
	_reset_player(_p1, Vector3(0, 1.0, 12.0), 0.0)
	_reset_player(_p2, Vector3(12, 1.0, 0.0), PI)
	await _ticks(5)
	var before: Vector3 = _p1.global_position
	_press(KEY_W)
	await _ticks(30)
	_release(KEY_W)
	await _ticks(5)
	var d := _hdist(before, _p1.global_position)
	_result("T1 P1 avanza (W)", d > 1.2, "dist=%.2f" % d)

	before = _p1.global_position
	_press(KEY_S)
	await _ticks(30)
	_release(KEY_S)
	await _ticks(5)
	d = _hdist(before, _p1.global_position)
	_result("T1 P1 retrocede (S)", d > 0.8, "dist=%.2f" % d)

	before = _p1.global_position
	_press(KEY_D)
	await _ticks(30)
	_release(KEY_D)
	await _ticks(5)
	d = _hdist(before, _p1.global_position)
	_result("T1 P1 lateral derecha (D)", d > 0.8, "dist=%.2f" % d)
	_result("T1 P1 rota al moverse", absf(_p1.rotation.y) > 0.5, "rot_y=%.3f" % _p1.rotation.y)

	before = _p1.global_position
	_press(KEY_A)
	await _ticks(30)
	_release(KEY_A)
	await _ticks(5)
	d = _hdist(before, _p1.global_position)
	_result("T1 P1 lateral izquierda (A)", d > 0.8, "dist=%.2f" % d)

	# P1 salto
	await _wait_on_floor(_p1)
	var ground_y: float = _p1.global_position.y
	_press(KEY_SPACE)
	var max_y: float = ground_y
	for i in 20:
		await get_tree().physics_frame
		max_y = maxf(max_y, _p1.global_position.y)
	_release(KEY_SPACE)
	_result("T1 P1 salta (ESPACIO)", max_y > ground_y + 0.4, "subida=%.2f" % (max_y - ground_y))
	var landed := await _wait_on_floor(_p1, 120)
	_result("T1 P1 aterriza (gravedad)", landed and absf(_p1.global_position.y - ground_y) < 0.8,
		"landed=%s y=%.2f" % [landed, _p1.global_position.y])

	# P2 avanza con flechas
	_reset_player(_p1, Vector3(0, 1.0, 12.0), 0.0)
	_reset_player(_p2, Vector3(12, 1.0, 0.0), PI)
	await _ticks(5)
	before = _p2.global_position
	_press(KEY_UP)
	await _ticks(30)
	_release(KEY_UP)
	await _ticks(5)
	d = _hdist(before, _p2.global_position)
	_result("T1 P2 avanza (flechas)", d > 1.2, "dist=%.2f" % d)

	# P2 salto
	await _wait_on_floor(_p2)
	ground_y = _p2.global_position.y
	_press(KEY_ENTER)
	max_y = ground_y
	for i in 20:
		await get_tree().physics_frame
		max_y = maxf(max_y, _p2.global_position.y)
	_release(KEY_ENTER)
	_result("T1 P2 salta (ENTER)", max_y > ground_y + 0.4, "subida=%.2f" % (max_y - ground_y))
	landed = await _wait_on_floor(_p2, 120)
	_result("T1 P2 aterriza (gravedad)", landed and absf(_p2.global_position.y - ground_y) < 0.8,
		"landed=%s y=%.2f" % [landed, _p2.global_position.y])


# --------------------------------------------------------------------------
# Test 2 - Puño, tackle y knockback
# --------------------------------------------------------------------------

func _test_combat() -> void:
	_p1.set("knockout_hits", 0)
	_p2.set("knockout_hits", 0)
	# Puño P1
	_reset_player(_p1, P1_COMBAT, PI)
	_reset_player(_p2, P2_COMBAT, 0.0)
	await _ticks(5)
	var hitbox_active := false
	var p2_knocked := false
	_press(KEY_F)
	for i in 12:
		await get_tree().physics_frame
		if _p1.get_node("PunchHitbox").monitoring:
			hitbox_active = true
		if int(_p2.get("_state")) == STATE_KNOCKBACK:
			p2_knocked = true
	_release(KEY_F)
	_result("T2 P1 puño activa hitbox", hitbox_active, "")
	_result("T2 P1 puño impacta a P2 (KNOCKBACK)", p2_knocked, "p2_state=%d" % int(_p2.get("_state")))
	var p2_recovered := await _wait_player_state(_p2, STATE_NORMAL, 40)
	_result("T2 P2 se recupera del puño (sin stun)", p2_recovered, "p2_state=%d" % int(_p2.get("_state")))

	# Puño P2
	_reset_player(_p1, P1_COMBAT, PI)
	_reset_player(_p2, P2_COMBAT, 0.0)
	await _ticks(5)
	var p1_knocked := false
	_press(KEY_PERIOD)
	for i in 12:
		await get_tree().physics_frame
		if int(_p1.get("_state")) == STATE_KNOCKBACK:
			p1_knocked = true
	_release(KEY_PERIOD)
	_result("T2 P2 puño impacta a P1 (KNOCKBACK)", p1_knocked, "p1_state=%d" % int(_p1.get("_state")))
	var p1_recovered := await _wait_player_state(_p1, STATE_NORMAL, 40)
	_result("T2 P1 se recupera del puño", p1_recovered, "p1_state=%d" % int(_p1.get("_state")))

	# Tackle P1
	_reset_player(_p1, P1_COMBAT, PI)
	_reset_player(_p2, P2_COMBAT, 0.0)
	await _ticks(5)
	var became_attacking := false
	var p2_tackled := false
	_press(KEY_SHIFT)
	for i in 75:
		await get_tree().physics_frame
		if int(_p1.get("_state")) == STATE_ATTACKING:
			became_attacking = true
		if int(_p2.get("_state")) == STATE_KNOCKBACK:
			p2_tackled = true
		if p2_tackled:
			break
	_release(KEY_SHIFT)
	_result("T2 P1 tackle carga e inicia (ATTACKING)", became_attacking, "")
	_result("T2 P1 tackle impacta a P2 (KNOCKBACK)", p2_tackled, "p2_state=%d" % int(_p2.get("_state")))

	# P2 stun tras tackle
	var became_stunned := false
	for i in 120:
		await get_tree().physics_frame
		if int(_p2.get("_state")) == STATE_STUNNED:
			became_stunned = true
			break
	_result("T2 P2 entra en STUNNED tras tackle", became_stunned, "")
	var stun_recovered := false
	for i in 70:
		await get_tree().physics_frame
		if int(_p2.get("_state")) == STATE_NORMAL:
			stun_recovered = true
			break
	_result("T2 P2 se recupera del stun", stun_recovered, "p2_state=%d" % int(_p2.get("_state")))

	# Cooldown de tackle
	var re_attacking := false
	_press(KEY_SHIFT)
	for i in 30:
		await get_tree().physics_frame
		if int(_p1.get("_state")) == STATE_ATTACKING:
			re_attacking = true
			break
	_release(KEY_SHIFT)
	_result("T2 P1 tackle NO re-dispara en cooldown", not re_attacking,
		"p1_state=%d" % int(_p1.get("_state")))


# --------------------------------------------------------------------------
# Test 3 - KNOCKED
# --------------------------------------------------------------------------

func _test_knocked() -> void:
	_p1.set("knockout_hits", 0)
	_p2.set("knockout_hits", 0)
	_reset_player(_p1, P1_COMBAT, PI)
	_reset_player(_p2, P2_COMBAT, 0.0)
	await _ticks(5)

	# 4 golpes con reposicionamiento
	var all_hits := true
	for i in 4:
		_reset_player(_p2, P2_COMBAT, 0.0)
		await _ticks(3)
		while float(_p1.get("_punch_cooldown_left")) > 0.0:
			await get_tree().physics_frame
		_press(KEY_F)
		for j in 12:
			await get_tree().physics_frame
		_release(KEY_F)
		await _ticks(2)
		if int(_p2.get("knockout_hits")) != i + 1:
			all_hits = false
		for j in 40:
			await get_tree().physics_frame
			if int(_p2.get("_state")) == STATE_NORMAL:
				break
	_result("T3 P2 acumula 4 golpes", all_hits, "hits=%d" % int(_p2.get("knockout_hits")))

	# 5to golpe -> KNOCKED
	_reset_player(_p2, P2_COMBAT, 0.0)
	await _ticks(3)
	while float(_p1.get("_punch_cooldown_left")) > 0.0:
		await get_tree().physics_frame
	_press(KEY_F)
	for j in 12:
		await get_tree().physics_frame
	_release(KEY_F)
	await _ticks(2)
	_result("T3 P2 llega a 5 golpes", int(_p2.get("knockout_hits")) == 5,
		"hits=%d" % int(_p2.get("knockout_hits")))

	var became_knocked := false
	for i in 60:
		await get_tree().physics_frame
		if int(_p2.get("_state")) == STATE_KNOCKED:
			became_knocked = true
			break
	_result("T3 P2 entra en KNOCKED", became_knocked, "p2_state=%d" % int(_p2.get("_state")))

	await _ticks(2)
	_result("T3 KNOCKED NO emite eliminated", _p2_eliminated_count == 0,
		"eliminated=%d" % _p2_eliminated_count)
	_result("T3 KNOCKED NO muestra WinnerScreen", not _winner_screen.visible, "")

	# Pérdida de control durante KNOCKED
	var pos_before: Vector3 = _p2.global_position
	_press(KEY_UP)
	await _ticks(30)
	_release(KEY_UP)
	var moved := _hdist(pos_before, _p2.global_position)
	_result("T3 KNOCKED pierde control (sin movimiento)", moved < 0.3, "mov=%.2f" % moved)

	# Recuperación tras knocked_duration (3.5s)
	var recovered := false
	for i in 260:
		await get_tree().physics_frame
		if int(_p2.get("_state")) == STATE_NORMAL:
			recovered = true
			break
	_result("T3 KNOCKED se recupera solo", recovered, "p2_state=%d" % int(_p2.get("_state")))
	_result("T3 knockout_hits reseteado tras recuperar", int(_p2.get("knockout_hits")) == 0,
		"hits=%d" % int(_p2.get("knockout_hits")))


# --------------------------------------------------------------------------
# Test 4 - Agarre
# --------------------------------------------------------------------------

func _test_grab() -> void:
	# P1 agarra a P2 (G)
	_reset_player(_p1, Vector3(0, 1.0, 8.7), PI)
	_reset_player(_p2, Vector3(0, 1.0, 9.7), 0.0)
	await _ticks(3)
	_action_press("grab_p1", true)
	var p1_grabbing := false
	var p2_grabbed := false
	for i in 8:
		await get_tree().physics_frame
		if int(_p1.get("_state")) == STATE_GRABBING:
			p1_grabbing = true
		if int(_p2.get("_state")) == STATE_GRABBED:
			p2_grabbed = true
	_result("T4 P1 agarra a P2 (G)", p1_grabbing and p2_grabbed,
		"p1=%d p2=%d" % [int(_p1.get("_state")), int(_p2.get("_state"))])
	_result("T4 P2 desactiva colisión al ser agarrado", int(_p2.collision_layer) == 0,
		"layer=%d" % _p2.collision_layer)

	# Moverse mientras agarra (S = alejarse de la cámara/hueco)
	var a0: Vector3 = _p1.global_position
	_press(KEY_S)
	await _ticks(25)
	_release(KEY_S)
	await _ticks(5)
	var dist: float = _p1.global_position.distance_to(_p2.global_position)
	_result("T4 P1 se mueve mientras agarra", _hdist(a0, _p1.global_position) > 0.5,
		"mov=%.2f" % _hdist(a0, _p1.global_position))
	_result("T4 P2 acompaña (no atraviesa, distancia estable)", dist > 0.3 and dist < 2.0,
		"dist=%.2f" % dist)

	# Soltar
	_action_press("grab_p1", false)
	await _ticks(8)
	_result("T4 P1 suelta agarre (NORMAL)", int(_p1.get("_state")) == STATE_NORMAL,
		"p1=%d" % int(_p1.get("_state")))
	_result("T4 P2 libre tras soltar (NORMAL + colisión restaurada)",
		int(_p2.get("_state")) == STATE_NORMAL and int(_p2.collision_layer) == 1,
		"p2=%d layer=%d" % [int(_p2.get("_state")), _p2.collision_layer])

	# P2 agarra a P1 (K)
	_reset_player(_p1, Vector3(0, 1.0, 8.7), PI)
	_reset_player(_p2, Vector3(0, 1.0, 9.7), 0.0)
	await _ticks(3)
	_action_press("grab_p2", true)
	var p2_grabbing := false
	var p1_grabbed := false
	for i in 8:
		await get_tree().physics_frame
		if int(_p2.get("_state")) == STATE_GRABBING:
			p2_grabbing = true
		if int(_p1.get("_state")) == STATE_GRABBED:
			p1_grabbed = true
	_result("T4 P2 agarra a P1 (K)", p2_grabbing and p1_grabbed,
		"p1=%d p2=%d" % [int(_p1.get("_state")), int(_p2.get("_state"))])
	_action_press("grab_p2", false)
	await _ticks(8)
	_result("T4 Sin bloqueos tras soltar (ambos NORMAL)",
		int(_p1.get("_state")) == STATE_NORMAL and int(_p2.get("_state")) == STATE_NORMAL, "")

	# Ambos pueden moverse tras el agarre
	var p1_0: Vector3 = _p1.global_position
	_press(KEY_W)
	await _ticks(20)
	_release(KEY_W)
	_result("T4 Jugadores no quedan bloqueados tras agarre", _hdist(p1_0, _p1.global_position) > 0.5,
		"mov=%.2f" % _hdist(p1_0, _p1.global_position))


# --------------------------------------------------------------------------
# Test 5 - Cámara
# --------------------------------------------------------------------------

func _test_camera() -> void:
	_reset_player(_p1, Vector3(0, 1.0, 12.0), 0.0)
	_reset_player(_p2, Vector3(0, 1.0, 11.0), 0.0)
	await _ticks(120)
	var close_visible := _cam.is_position_in_frustum(_p1.global_position) \
		and _cam.is_position_in_frustum(_p2.global_position)
	_result("T5 Ambos jugadores visibles (juntos)", close_visible, "")
	var cam_y_close := _cam.global_position.y

	_reset_player(_p1, Vector3(0, 1.0, 8.0), 0.0)
	_reset_player(_p2, Vector3(8, 1.0, 0.0), 0.0)
	await _ticks(200)
	var far_visible := _cam.is_position_in_frustum(_p1.global_position) \
		and _cam.is_position_in_frustum(_p2.global_position)
	_result("T5 Ambos jugadores visibles (separados)", far_visible, "")
	_result("T5 Cámara se aleja/levanta al separarse",
		_cam.global_position.y > cam_y_close + 1.0,
		"y %.2f -> %.2f" % [cam_y_close, _cam.global_position.y])

	var midpoint: Vector3 = (_p1.global_position + _p2.global_position) * 0.5
	var local: Vector3 = _cam.global_transform.inverse() * midpoint
	_result("T5 Cámara enfoca el punto medio", local.z < 0.0, "local_z=%.2f" % local.z)

	_reset_player(_p1, Vector3(0, 1.0, 12.0), 0.0)
	_reset_player(_p2, Vector3(0, 1.0, 11.0), 0.0)
	await _ticks(200)
	_result("T5 Cámara vuelve a acercarse",
		absf(_cam.global_position.y - cam_y_close) < 2.0,
		"y=%.2f (close=%.2f)" % [_cam.global_position.y, cam_y_close])


# --------------------------------------------------------------------------
# Test 8 - Pausa
# --------------------------------------------------------------------------

func _test_pause() -> void:
	_result("T8 Partida activa antes de pausa", int(_gm.match_state) == MATCH_PLAYING,
		"state=%d" % int(_gm.match_state))

	_send_key(KEY_ESCAPE, true)
	_send_key(KEY_ESCAPE, false)
	await _ticks(3)
	_result("T8 ESC abre el menú de pausa",
		get_tree().paused and _pause_menu._pause_menu.visible,
		"paused=%s menu=%s" % [get_tree().paused, _pause_menu._pause_menu.visible])

	var p0: Vector3 = _p1.global_position
	_press(KEY_W)
	await _ticks(40)
	_release(KEY_W)
	await _ticks(3)
	_result("T8 Juego realmente pausado (sin movimiento)", _hdist(p0, _p1.global_position) < 0.01,
		"mov=%.2f" % _hdist(p0, _p1.global_position))

	_send_key(KEY_ESCAPE, true)
	_send_key(KEY_ESCAPE, false)
	await _ticks(3)
	_result("T8 REANUDAR funciona",
		not get_tree().paused and not _pause_menu._pause_menu.visible,
		"paused=%s menu=%s" % [get_tree().paused, _pause_menu._pause_menu.visible])

	var p1_0: Vector3 = _p1.global_position
	_press(KEY_W)
	await _ticks(25)
	_release(KEY_W)
	_result("T8 Juego continúa tras reanudar", _hdist(p1_0, _p1.global_position) > 0.5,
		"mov=%.2f" % _hdist(p1_0, _p1.global_position))


# --------------------------------------------------------------------------
# Test 6 / 7 - Eliminación y WinnerScreen
# --------------------------------------------------------------------------

func _test_elimination_winner() -> void:
	var count_before := _p2_eliminated_count
	_reset_player(_p1, Vector3(0, 1.0, 12.0), 0.0)
	_reset_player(_p2, Vector3(0, 0.0, 0.0), 0.0)
	await _ticks(3)

	var eliminated := false
	for i in 60:
		await get_tree().physics_frame
		if _p2_eliminated_count > count_before:
			eliminated = true
			break
	_result("T6 P2 eliminado al caer al agujero", eliminated, "count=%d" % _p2_eliminated_count)
	_result("T6 P2 invisible tras eliminar", not _p2.visible, "visible=%s" % _p2.visible)
	_result("T6 GameManager finaliza la partida", int(_gm.match_state) == MATCH_FINISHED,
		"state=%d" % int(_gm.match_state))
	_result("T6 Ganador es P1", _gm.get_player_number(_p1) == 1, "num=%d" % _gm.get_player_number(_p1))
	_result("T6 Árbol sin pausa tras eliminar", not get_tree().paused, "")

	await _ticks(3)
	_result("T7 WinnerScreen aparece", _winner_screen.visible, "")
	_result("T7 Muestra ganador correcto", _winner_screen._winner_label.text == "Jugador 1 gana",
		"text='%s'" % _winner_screen._winner_label.text)
	_result("T7 Confeti activo", _winner_screen._confetti.emitting, "emitting=%s" % _winner_screen._confetti.emitting)
	_result("T7 Botón volver al menú conectado y habilitado",
		_winner_screen._main_menu_button.pressed.get_connections().size() > 0
		and not _winner_screen._main_menu_button.disabled,
		"conns=%d" % _winner_screen._main_menu_button.pressed.get_connections().size())
	_result("T7 Botón siguiente ronda deshabilitado (sin reinicio)",
		_winner_screen._next_round_button.disabled,
		"disabled=%s" % _winner_screen._next_round_button.disabled)

	_gm.iniciar_partida()
	await _ticks(2)
	_result("T7 No inicia nueva partida tras ganar (PENDIENTE reinicio)",
		int(_gm.match_state) == MATCH_FINISHED,
		"state=%d" % int(_gm.match_state))


# --------------------------------------------------------------------------
# Test 11 - Duplicados y revisión
# --------------------------------------------------------------------------

func _test_duplicates() -> void:
	var checks := {
		"GameManager": "res://scripts/systems/game_manager.gd",
		"SpawnManager": "res://scripts/systems/spawn_manager.gd",
		"PauseMenu": "res://scripts/ui/pause_menu.gd",
		"ControlsScreen": "res://scripts/ui/controls_screen.gd",
		"WinnerScreen": "res://scripts/ui/winner_screen.gd",
		"MainMenu": "res://scripts/ui/main_menu.gd",
	}
	for key in checks:
		var c := _count_script(checks[key])
		_result("T11 Sin duplicados: " + key, c == 1, "count=%d" % c)

	var player_count := _count_script("res://entities/player/player.gd")
	_result("T11 Dos jugadores (no duplicados)", player_count == 2, "count=%d" % player_count)

	var current_cams := 0
	for n in get_tree().root.find_children("*", "Camera3D", true, false):
		if n.current:
			current_cams += 1
	_result("T11 Solo una cámara current", current_cams == 1, "current=%d" % current_cams)


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

func _result(name: String, ok: bool, detail: String = "") -> void:
	var status := "PASS" if ok else "FAIL"
	var line := "[%s] %s" % [status, name]
	if detail != "":
		line += "  (" + detail + ")"
	print(line)
	_results.append({"name": name, "ok": ok, "detail": detail})


func _print_report() -> void:
	var fails := 0
	for r in _results:
		if not r.ok:
			fails += 1
	print("")
	print("========== REPORTE PRUEBA INTEGRACIÓN ==========")
	print("TOTAL=%d PASS=%d FAIL=%d" % [_results.size(), _results.size() - fails, fails])
	if _arena_cam != null:
		print("Cámara activa (current): main=%s arena=%s" % [_cam.is_current(), _arena_cam.is_current()])
	print("=================================================")


func _ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _wait_on_floor(p: Node, max_ticks := 90) -> bool:
	for i in max_ticks:
		await get_tree().physics_frame
		if p.is_on_floor():
			return true
	return false


func _wait_player_state(p: Node, state: int, max_ticks := 60) -> bool:
	for i in max_ticks:
		await get_tree().physics_frame
		if int(p.get("_state")) == state:
			return true
	return false


func _press(key: Key) -> void:
	_send_key(key, true)


func _release(key: Key) -> void:
	_send_key(key, false)


func _send_key(key: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _action_press(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _hdist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _reset_player(p: Node, pos: Vector3, rot_y: float) -> void:
	p.velocity = Vector3.ZERO
	p.set("_state", STATE_NORMAL)
	p.set("_horizontal_velocity", Vector3.ZERO)
	p.set("_external_push", Vector3.ZERO)
	p.set("_knockback_time_left", 0.0)
	p.set("_knockout_pending", false)
	p.set("_stun_pending", false)
	p.set("_stun_time_left", 0.0)
	p.set("_grabbed_target", null)
	p.set("_grabbed_by", null)
	p.set("_knocked_time_left", 0.0)
	p.set("_knocked_timer_paused", false)
	p.set("_tackle_cooldown_left", 0.0)
	p.set("_tackle_time_left", 0.0)
	p.set("_punch_cooldown_left", 0.0)
	p.set("_punch_active_left", 0.0)
	p.set("_charge_time", 0.0)
	p.set("_punch_key_was_down", false)
	p.collision_layer = 1
	p.collision_mask = 1
	p.visible = true
	p.set_physics_process(true)
	var cs := p.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs != null:
		cs.disabled = false
	p.global_position = pos
	p.rotation.y = rot_y


func _count_script(res_path: String) -> int:
	var count := 0
	for node in get_tree().root.find_children("*", "", true, false):
		if node.script != null and node.script.resource_path == res_path:
			count += 1
	return count
