extends Node3D

## Verifica la hipotesis de auto-punch: el Player inicia con input_enabled=false
## (como en main.tscn) y F se muestra presionada cuando se habilita input.
## Si el punch se activa SOLO, seria una fuerza no intencionada al Barrel.
##
## Pasos:
## 1. Simular que F sigue presionada desde el menu (Input.parse_input_event KEY_F down)
## 2. Habilitar input_enabled = true (como hace demo_start_screen al presionar ENTER)
## 3. En el siguiente frame fisico, revisar si _punch_active_left > 0 (punch auto-disparado)

var player: CharacterBody3D
var barrel: RigidBody3D
var _pressed_f := false
var _enabled_input := false
var _frames_after_enable := 0
var _done := false

func _ready() -> void:
	player = get_node("Player")
	barrel = get_node("Barrel")
	barrel.freeze = false
	barrel.sleeping = false
	print("[AP TEST] Player input_enabled inicial=", player.input_enabled)
	print("[AP TEST] Estado inicial _punch_key_was_down=", player.get("_punch_key_was_down"))
	print("[AP TEST] F presionada (simulada) desde menu...")
	# Simular que el jugador sostiene F desde el menu (tecla abajo, sin que el juego la registre)
	var ev := InputEventKey.new()
	ev.keycode = KEY_F
	ev.physical_keycode = KEY_F
	ev.pressed = true
	ev.echo = false
	Input.parse_input_event(ev)
	_pressed_f = true
	print("[AP TEST] _punch_key_was_down despues de simular F-down=", player.get("_punch_key_was_down"))
	print("[AP TEST] Habilitando input_enabled (simula presionar ENTER)...")
	player.set("input_enabled", true)
	_enabled_input = true

func _physics_process(_delta: float) -> void:
	if _done:
		return
	_frames_after_enable += 1
	var punch_active: float = player.get("_punch_active_left")
	var monitoring: bool = player.get("_punch_hitbox").monitoring
	print("[AP TEST] frame=%d punch_active_left=%.3f punch_hitbox.monitoring=%s barrel_pos=%s" % [
		_frames_after_enable, punch_active, monitoring, barrel.global_position])
	if _frames_after_enable >= 3:
		_finish()

func _finish() -> void:
	_done = true
	var punch_active: float = player.get("_punch_active_left")
	var veredicto := "AUTO-PUNCH CONFIRMADO" if punch_active > 0.0 else "no hubo auto-punch"
	print("[AP TEST] punch_active_left_final=", punch_active, " -> ", veredicto)
	print("[AP TEST] Implicacion: un punch auto-disparado aplica apply_central_impulse(8.0) al Barrel si esta en el hitbox.")
	get_tree().quit()