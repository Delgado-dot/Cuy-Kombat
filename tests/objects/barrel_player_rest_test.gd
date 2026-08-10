extends Node3D

const DURATION := 12.0
const MOTION_SPEED_THRESHOLD := 0.1
const LOG_INTERVAL := 0.1

## 0 = lejos, 1 = cerca (sin tocar), 2 = contacto, 3 = contacto sin fisica del player
@export var scenario := 0

@onready var barrel: RigidBody3D = $Barrel
@onready var player: CharacterBody3D = $Player

var _elapsed := 0.0
var _last_log_time := 0.0
var _barrel_start_pos: Vector3
var _prev_frame_speed := 0.0
var _prev_frame_vel := Vector3.ZERO
var _first_motion_logged := false
var _motion_detected := false


func _ready() -> void:
	scenario = _read_scenario_arg()
	_barrel_start_pos = barrel.global_position

	print("[BPR TEST] === Barrel + Player en reposo (sin interaccion) ===")
	print("[BPR TEST] Escenario=%d | barrel_inicial=%s" % [scenario, barrel.global_position])
	print("[BPR TEST] Player input_enabled=%s(al inicio) physics_process activo inicia SI" % player.input_enabled)

	var target_pos := Vector3.ZERO
	match scenario:
		0:
			target_pos = Vector3(0, 0.9, 6)
		1:
			target_pos = Vector3(0, 0.9, 2.6)
		2:
			target_pos = Vector3(0, 0.9, 0.8)
		3:
			target_pos = Vector3(0, 0.9, 0.8)

	player.global_position = target_pos
	player.velocity = Vector3.ZERO

	if scenario == 3:
		player.set_physics_process(false)
		print("[BPR TEST] Player FISICA DESACTIVADA (set_physics_process(false))")

	## Instrumentacion: despertar fisica natural del barrel (sin freeze).
	## NO modifica barrel.gd; es diagnostico local de esta prueba.
	print("[BPR TEST] Barrel freeze_antes=%s -> unfreeze (fisica natural)" % barrel.freeze)
	barrel.freeze = false
	barrel.sleeping = false
	_barrel_start_pos = barrel.global_position

	print("[BPR TEST] Barrel=", barrel.global_position, " Player=", player.global_position,
		" distancia=", "%.3f" % barrel.global_position.distance_to(player.global_position))
	_log_state(0.0, true)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_check_first_motion()
	if _elapsed - _last_log_time >= LOG_INTERVAL:
		_last_log_time = _elapsed
		_log_state(_elapsed, false)
	if _elapsed >= DURATION:
		_final_report()
		get_tree().quit(0)


func _check_first_motion() -> void:
	var speed: float = barrel.linear_velocity.length()
	var just_moved := _first_motion_logged

	if not just_moved:
		if speed > MOTION_SPEED_THRESHOLD:
			_first_motion_logged = true
			_motion_detected = true
			print("[BPR TEST] *** PRIMER MOVIMIENTO DETECTADO *** fr mostrar_anterior")
			print("[BPR TEST] ANTES: barrel_vel=%s speed=%.4f barrel_pos=%s" % [
				_prev_frame_vel, _prev_frame_speed, barrel.global_position - barrel.linear_velocity * (1.0 / 60.0),
			])
			print("[BPR TEST] DESPUES(t=%06.3f): barrel_pos=%s barrel_vel=%s | Player=%s | dist=%.4f | freeze=%s sleeping=%s" % [
				_elapsed, barrel.global_position, barrel.linear_velocity,
				player.global_position, barrel.global_position.distance_to(player.global_position),
				barrel.freeze, barrel.sleeping,
			])
			print("[BPR TEST] Cuerpos contactando al Barrel: %s" % _contact_names())
		if speed > 0.01 and not just_moved:
			pass

	_prev_frame_speed = speed
	_prev_frame_vel = barrel.linear_velocity


func _log_state(t: float, initial: bool) -> void:
	print("[BPR TEST] t=%.2fs B_pos=%s B_vel=%s B_ang=%s B_sleep=%s B_freeze=%s | P_pos=%s P_vel=%s dist=%.4f" % [
		t,
		barrel.global_position,
		barrel.linear_velocity,
		barrel.angular_velocity,
		barrel.sleeping,
		barrel.freeze,
		player.global_position,
		player.velocity,
		barrel.global_position.distance_to(player.global_position),
	])


func _contact_names() -> String:
	var names: Array[String] = []
	if barrel.contact_monitor:
		for body in barrel.get_colliding_bodies():
			names.append("%s<%s>" % [body.name, body.get_class()])
	return "[%s]" % ", ".join(names)


func _final_report() -> void:
	var disp: float = barrel.global_position.distance_to(_barrel_start_pos)
	var player_disp: float = player.global_position.distance_to(
		player.global_position - player.velocity * 0.0
	)
	print("[BPR TEST] === RESUMEN ===")
	print("[BPR TEST] Escenario=%d | movimiento_detectado=%s" % [scenario, _motion_detected])
	print("[BPR TEST] Barrel inicio=%s final=%s desplazamiento=%.4f" % [
		_barrel_start_pos, barrel.global_position, disp,
	])
	print("[BPR TEST] Barrel vel_final=%s ang_final=%s sleeping_final=%s" % [
		barrel.linear_velocity, barrel.angular_velocity, barrel.sleeping,
	])
	print("[BPR TEST] Player final=%s | cuerpos_tocando_barrel=%s" % [
		player.global_position, _contact_names(),
	])


func _read_scenario_arg() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("scenario="):
			return int(arg.get_slice("=", 1))
	return scenario