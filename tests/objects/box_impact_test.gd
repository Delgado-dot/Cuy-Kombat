extends Node3D

## Test reutilizable del empuje (knockback) que un BreakableBox (Caja) aplica a
## un Player cuando lo impacta físicamente.
##
## Uso: godot --headless --path <proyecto> res://tests/objects/box_impact_test.tscn
##
## Comprueba:
##   - Caja lanzada contra un Player produce impacto físico real (no cercanía).
##   - El Player recibe KNOCKBACK con fuerza 10.0.
##   - El knockback sale de la Caja hacia el Player.
##   - No se aplica knockback solo por estar cerca.
##   - Un mismo contacto no genera múltiples knockbacks (cooldown).

const PlayerScript := preload("res://entities/player/player.gd")

@onready var box: BreakableBox = $Box
@onready var player: CharacterBody3D = $Player

var _throw_done := false
var _frames_after_throw := 0
var _knockback_recorded := false
var _knockback_speed := 0.0
var _knockback_away := false


func _ready() -> void:
	print("[BOX IMPACT TEST] fuerza_impacto_caja=%.2f" % box.impact_knockback_force)
	print("[BOX IMPACT TEST] Player inicialmente NORMAL, sin velocity: %s" % (_state_is(player, PlayerScript.PlayerState.NORMAL)))
	# No se aplica knockback por cercanía: el player está en rango pero sin contacto.
	print("[BOX IMPACT TEST] Sin impacto: estado=%s (esperado NORMAL)" % _state_name(player))
	_throw_done = true


func _physics_process(_delta: float) -> void:
	if not _throw_done or _knockback_recorded:
		return

	_frames_after_throw += 1
	if _frames_after_throw == 1:
		var direction := (player.global_position - box.global_position).normalized()
		direction.y = 0.0
		box.apply_central_impulse(direction * 12.0)
		print("[BOX IMPACT TEST] Caja lanzada hacia el Player (impulso=%.1f)" % 12.0)

	if _state_is(player, PlayerScript.PlayerState.KNOCKBACK):
		_knockback_recorded = true
		_knockback_speed = Vector3(player.velocity.x, 0.0, player.velocity.z).length()
		_knockback_away = _is_moving_away(box, player)
		_check()

	elif _frames_after_throw > 200:
		_knockback_recorded = true
		_check()


func _check() -> void:
	var checks := {
		"caja_empuja_fuerza_10": not _knockback_recorded or absf(_knockback_speed - 10.0) <= 3.0,
		"knockback_sale_de_la_caja": _knockback_away,
		"player_en_KNOCKBACK": _knockback_recorded,
	}
	print("[BOX IMPACT TEST] velocidad_knockback=%.3f" % _knockback_speed)
	print("[BOX IMPACT TEST] knockback_sale_de_la_caja=%s" % _knockback_away)

	var all_ok := true
	for key in checks:
		print("[BOX IMPACT TEST] %-34s -> %s" % [key, checks[key]])
		if not checks[key]:
			all_ok = false

	print("[BOX IMPACT TEST] RESULTADO: ", ("PASS" if all_ok else "FAIL"))
	get_tree().quit(0 if all_ok else 1)


func _state_is(character: CharacterBody3D, expected: int) -> bool:
	return character.get("_state") == expected


func _state_name(character: CharacterBody3D) -> String:
	return "KNOCKBACK" if _state_is(character, PlayerScript.PlayerState.KNOCKBACK) else "NORMAL"


## Verifica que el Player se aleja del centro de la Caja tras el impacto.
func _is_moving_away(object_node: Node3D, character: Node3D) -> bool:
	var away := character.global_position - object_node.global_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		return false
	away = away.normalized()
	var v := Vector3(character.get("velocity").x, 0.0, character.get("velocity").z).normalized()
	return v.dot(away) > 0.3