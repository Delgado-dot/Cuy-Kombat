extends Node3D

## Diagnostico: el Player CAMINA (move_and_slide controlado por el test) directamente
## hacia el Barrel, SIN input, SIN punch, SIN grab. Mide si el solver de contacto
## transfiere fuerza al Barrel (RigidBody3D) y lo empuja.
##
## Uso: godot --headless --path <proyecto> res://tests/objects/barrel_player_walk_test.tscn
##      [-- --direction=+Z| -Z | +X | -X] [-- --speed=6.0] [-- --graza=0]

var barrel: RigidBody3D
var player: CharacterBody3D
var _barrel_start: Vector3
var _player_start: Vector3
var _direction := Vector3(0, 0, -1)
var _speed := 6.0
var _time := 0.0
var _hit_time := -1.0
var _hit_dict := {}
var _log_every := 0.25
var _last_log := 0.0
var _frames := 0
var _done := false
var _max_speed_after_hit := 0.0

func _ready() -> void:
	barrel = get_node("Barrel")
	player = get_node("Player")
	_parse_args()
	_barrel_start = barrel.global_position
	_player_start = player.global_position
	print("[BWK TEST] Player caminando hacia Barrel | dir=%s speed=%.2f" % [_direction, _speed])
	print("[BWK TEST] Barrel_inicial=%s Player_inicial=%s dist=%.3f" % [_barrel_start, _player_start, barrel.global_position.distance_to(player.global_position)])
	barrel.freeze = false
	barrel.sleeping = false

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("direction="):
			match arg.trim_prefix("direction="):
				"+Z": _direction = Vector3(0, 0, 1)
				"-Z": _direction = Vector3(0, 0, -1)
				"+X": _direction = Vector3(1, 0, 0)
				"-X": _direction = Vector3(-1, 0, 0)
		elif arg.begins_with("speed="):
			_speed = float(arg.trim_prefix("speed="))

func _physics_process(delta: float) -> void:
	if _done:
		return
	_time += delta
	_frames += 1

	# Simular jugador caminando: velocidad horizontal control + posicionar de pie
	player.velocity = _direction * _speed
	player.velocity.y = -18.0 * delta
	player.move_and_slide()

	var dist := barrel.global_position.distance_to(player.global_position)

	# Registrar impacto (primer contacto del player con el barrel)
	var slide_hit := false
	for i in range(player.get_slide_collision_count()):
		var c := player.get_slide_collision(i)
		if c.get_collider() == barrel:
			slide_hit = true
			break
	if slide_hit and _hit_time < 0.0:
		_hit_time = _time

	# Velocidad horizontal del barrel tras el impacto
	if _hit_time >= 0.0:
		var hs := Vector3(barrel.linear_velocity.x, 0.0, barrel.linear_velocity.z).length()
		_max_speed_after_hit = maxf(_max_speed_after_hit, hs)

	if _time - _last_log >= _log_every:
		_last_log = _time
		print("[BWK TEST] t=%.2f B_pos=%s B_vel=%s B_sleep=%s | P_pos=%s P_vel=%s dist=%.3f impact=%s" % [
			_time, barrel.global_position, barrel.linear_velocity, barrel.sleeping,
			player.global_position, player.velocity, dist, ("" if _hit_time < 0 else "SI(%.2fs)" % _hit_time)])

	if _time >= 6.0:
		_finish()

func _finish() -> void:
	_done = true
	var disp := barrel.global_position.distance_to(_barrel_start)
	var player_disp := player.global_position.distance_to(_player_start)
	print("=== RESUMEN ===")
	var impact_txt := "NA (sin contacto)" if _hit_time < 0.0 else "%.2fs" % _hit_time
	var veredicto := "EL JUGADOR EMPUJA EL BARREL AL CAMINAR" if (_hit_time >= 0.0 and disp > 0.05) else "caminar de frente NO mueve el barrel (desplazamiento <= 0.05)"
	print("[BWK TEST] impact_time=", impact_txt)
	print("[BWK TEST] Barrel inicio=", _barrel_start, " final=", barrel.global_position, " desplazamiento=%.4f" % disp)
	print("[BWK TEST] Barrel max_speed_horiz_tras_impacto=%.4f vel_final=" % _max_speed_after_hit, barrel.linear_velocity)
	print("[BWK TEST] Player inicio=", _player_start, " final=", player.global_position, " desplazamiento=%.4f" % player_disp)
	print("[BWK TEST] veredicto=", veredicto)
	get_tree().quit()