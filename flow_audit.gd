extends SceneTree

var _failures := 0


func _init() -> void:
	await _run_all()
	print("RESULTADO: ", "OK" if _failures == 0 else "%d FALLOS" % _failures)
	quit(0 if _failures == 0 else 1)


func _check(label: String, condition: bool) -> void:
	if condition:
		print("[OK] ", label)
	else:
		_failures += 1
		print("[FAIL] ", label)


func _settle(frames: int = 45) -> void:
	for i in frames:
		await process_frame


func _key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventKey.new()
	release.keycode = keycode
	release.pressed = false
	Input.parse_input_event(release)


func _joy(button: int) -> void:
	var press := InputEventJoypadButton.new()
	press.button_index = button
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventJoypadButton.new()
	release.button_index = button
	release.pressed = false
	Input.parse_input_event(release)


func _click(control: Control) -> void:
	var rect: Rect2 = control.get_global_rect()
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		control.pressed.emit()
		return
	var center: Vector2 = rect.get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	press.global_position = center
	Input.parse_input_event(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = center
	release.global_position = center
	Input.parse_input_event(release)


func _make_instance() -> Node:
	var scene: PackedScene = load("res://main.tscn")
	var inst: Node = scene.instantiate()
	root.add_child(inst)
	return inst


func _free_instance(inst: Node) -> void:
	if is_instance_valid(inst):
		inst.queue_free()
	await process_frame
	await process_frame


func _run_all() -> void:
	print("### Test 1: Menu ENTER -> Selector ENTER -> Gameplay ###")
	await _test1_menu_enter_selector_enter()

	print("### Test 2: Menu boton Jugar -> Selector -> confirmar -> Gameplay ###")
	await _test2_button_jugar_confirm()

	print("### Test 3: Menu A (mando) -> Selector -> A -> Gameplay ###")
	await _test3_joypad_a()

	print("### Test 4: ENTER directo NUNCA inicia gameplay ###")
	await _test4_no_direct_gameplay()

	print("### Test 5: Menu ENTER -> Selector -> ESC -> Menu ###")
	await _test5_back_flow()

	print("### Test 6: cambio entre arenas -> confirmar -> Gameplay ###")
	await _test6_arena_change()


func _test1_menu_enter_selector_enter() -> void:
	var inst := _make_instance()
	await _settle(30)
	var gm: Node = inst.get_node("GameManager")
	var menu: Node = inst.get_node("MainMenu")
	var sel: Node = inst.get_node("ScenarioSelectUI")
	var menu_root: Control = menu.get_node("%MainMenu")
	var arena: Node = inst.get_node("Arena")

	_check("menu visible al inicio", menu_root.visible)
	_check("selector oculto al inicio", not sel.visible)
	_check("match WAITING al inicio", int(gm.get("match_state")) == 0)

	_key(KEY_ENTER)
	await _settle(20)
	_check("ENTER: menu oculto", not menu_root.visible)
	_check("ENTER: selector visible", sel.visible)
	_check("ENTER: match sigue WAITING (no gameplay directo)", int(gm.get("match_state")) == 0)
	_check("ENTER: arena inicial intacta (volcanica)", arena.get_node_or_null("EscenarioPelea/EntornoVolcanico3D") != null)

	_key(KEY_ENTER)
	await _settle(60)
	_check("ENTER x2: selector oculto tras confirmar", not sel.visible)
	_check("ENTER x2: match PLAYING", int(gm.get("match_state")) == 1)
	_check("ENTER x2: arena sigue siendo volcanica", arena.get_node_or_null("EscenarioPelea/EntornoVolcanico3D") != null)
	_check("ENTER x2: SpawnJugador1 presente", arena.get_node_or_null("PuntosDeAparicion/SpawnJugador1") != null)

	await _free_instance(inst)


func _test2_button_jugar_confirm() -> void:
	var inst := _make_instance()
	await _settle(30)
	var gm: Node = inst.get_node("GameManager")
	var menu: Node = inst.get_node("MainMenu")
	var sel: Node = inst.get_node("ScenarioSelectUI")
	var play_button: Button = menu.get_node("%PlayButton")

	_click(play_button)
	await _settle(20)
	_check("boton Jugar: selector visible", sel.visible)
	_check("boton Jugar: match WAITING (no directo)", int(gm.get("match_state")) == 0)

	var confirm_button: Button = sel.get_node("%ScenarioConfirmButton")
	_click(confirm_button)
	await _settle(60)
	_check("boton confirmar: match PLAYING", int(gm.get("match_state")) == 1)
	_check("boton confirmar: selector oculto", not sel.visible)

	await _free_instance(inst)


func _test3_joypad_a() -> void:
	var inst := _make_instance()
	await _settle(30)
	var gm: Node = inst.get_node("GameManager")
	var menu: Node = inst.get_node("MainMenu")
	var sel: Node = inst.get_node("ScenarioSelectUI")
	var menu_root: Control = menu.get_node("%MainMenu")

	_joy(JOY_BUTTON_A)
	await _settle(20)
	_check("mando A: selector visible", sel.visible)
	_check("mando A: match WAITING (no directo)", int(gm.get("match_state")) == 0)

	_joy(JOY_BUTTON_A)
	await _settle(60)
	_check("mando A x2: match PLAYING", int(gm.get("match_state")) == 1)
	_check("mando A x2: selector oculto", not sel.visible)

	await _free_instance(inst)


func _test4_no_direct_gameplay() -> void:
	var inst := _make_instance()
	await _settle(30)
	var gm: Node = inst.get_node("GameManager")
	var menu: Node = inst.get_node("MainMenu")
	var sel: Node = inst.get_node("ScenarioSelectUI")
	var menu_root: Control = menu.get_node("%MainMenu")

	for i in 3:
		_key(KEY_ENTER)
		await _settle(10)
		_check("ENTER repetido (%d): match WAITING" % (i + 1), int(gm.get("match_state")) == 0)
	_check("ENTER repetido: selector visible", sel.visible)
	_check("ENTER repetido: menu oculto", not menu_root.visible)

	_key(KEY_ESCAPE)
	await _settle(15)
	_check("ESC vuelve al menu (match sigue WAITING)", menu_root.visible)
	_check("ESC: match WAITING", int(gm.get("match_state")) == 0)

	_key(KEY_ENTER)
	await _settle(15)
	_check("ENTER de nuevo: selector visible y no gameplay", sel.visible)
	_check("ENTER de nuevo: match WAITING", int(gm.get("match_state")) == 0)

	await _free_instance(inst)


func _test5_back_flow() -> void:
	var inst := _make_instance()
	await _settle(30)
	var gm: Node = inst.get_node("GameManager")
	var menu: Node = inst.get_node("MainMenu")
	var sel: Node = inst.get_node("ScenarioSelectUI")
	var menu_root: Control = menu.get_node("%MainMenu")

	_key(KEY_ENTER)
	await _settle(20)
	_check("back flow: selector visible", sel.visible)

	_key(KEY_ESCAPE)
	await _settle(15)
	_check("back flow ESC: menu visible", menu_root.visible)
	_check("back flow ESC: selector oculto", not sel.visible)
	_check("back flow ESC: match WAITING", int(gm.get("match_state")) == 0)

	_key(KEY_ENTER)
	await _settle(20)
	_joy(JOY_BUTTON_B)
	await _settle(15)
	_check("back flow mando B: menu visible", menu_root.visible)
	_check("back flow mando B: selector oculto", not sel.visible)

	await _free_instance(inst)


func _test6_arena_change() -> void:
	var mitad := _make_instance()
	await _settle(30)
	var sel_m: Node = mitad.get_node("ScenarioSelectUI")
	var gm_m: Node = mitad.get_node("GameManager")
	var arena_m: Node = mitad.get_node("Arena")
	_key(KEY_ENTER)
	await _settle(20)
	var mitad_card: Button = sel_m.get_node("%MitadDelMundoCard")
	_click(mitad_card)
	await _settle(10)
	_check("arena change: seleccion MitadDelMundo", sel_m.get_selected_scenario() == &"mitad_del_mundo")
	_key(KEY_ENTER)
	await _settle(60)
	_check("arena change: match PLAYING", int(gm_m.get("match_state")) == 1)
	_check("arena change: arena es MitadDelMundo (LineaEcuatorial)", arena_m.get_node_or_null("Gameplay/Piso/LineaEcuatorial") != null)
	_check("arena change: SpawnJugador4 en Mitad", arena_m.get_node_or_null("PuntosDeAparicion/SpawnJugador4") != null)
	await _free_instance(mitad)

	var quito := _make_instance()
	await _settle(30)
	var sel_q: Node = quito.get_node("ScenarioSelectUI")
	var gm_q: Node = quito.get_node("GameManager")
	var arena_q: Node = quito.get_node("Arena")
	_key(KEY_ENTER)
	await _settle(20)
	var quito_card: Button = sel_q.get_node("%QuitoCard")
	_click(quito_card)
	await _settle(10)
	_check("arena change: seleccion Quito", sel_q.get_selected_scenario() == &"quito")
	_joy(JOY_BUTTON_A)
	await _settle(60)
	_check("arena change (confirm mando): match PLAYING", int(gm_q.get("match_state")) == 1)
	_check("arena change: arena es Quito (BordeExteriorVisual)", arena_q.get_node_or_null("Gameplay/BordeExteriorVisual") != null)
	_check("arena change: SpawnJugador4 en Quito", arena_q.get_node_or_null("PuntosDeAparicion/SpawnJugador4") != null)
	await _free_instance(quito)
