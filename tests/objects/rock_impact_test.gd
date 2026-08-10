extends Node3D

## Test reutilizable del empuje (knockback) que una Rock aplica a un Player
## cuando lo impacta físicamente.
##
## Uso: godot --headless --path <proyecto> res://tests/objects/rock_impact_test.tscn
##
## Comprueba:
##   - Roca lanzada contra un Player produce impacto físico real (no cercanía).
##   - El Player recibe KNOCKBACK con fuerza 10.5.
##   - 10.5 es exactamente un 5% más que la Caja (10.0 × 1.05).
##   - El knockback sale de la Roca hacia el Player.

const PlayerScript := preload("res://entities/player/player.gd")
const BOX_FORCE := 10.0

@onready var rock: Rock = $Rock
@onready var player: CharacterBody3D = $Player

var _throw_done := false
var _frames_after_throw := 0
var _knockback_recorded := false
var _knockback_speed := 0.0
var _knockback_away := false


func _ready() -> void:
	print("[ROCK IMPACT TEST] fuerza_impacto_roca=%.2f" % rock.impact_knockback_force)
	print("[ROCK IMPACT TEST] esperado=%.2f (caja 10.0 × 1.05)" % (BOX_FORCE * 1.05))
	print("[ROCK IMPACT TEST] Player inicialmente NORMAL: %s" % _state_is(player, PlayerScript.PlayerState.NORMAL))
	print("[ROCK IMPACT TEST] Sin impacto: estado=%s (esperado NORMAL)" % _state_name(player))
	_throw_done = true


func _physics_process(_delta: float) -> void:
	if not _throw_done or _knockback_recorded:
		return

	_frames_after_throw += 1
	if _frames_after_throw == 1:
		var direction := (player.global_position - rock.global_position).normalized()
		direction.y = 0.0
		rock.apply_central_impulse(direction * 12.0)
		print("[ROCK IMPACT TEST] Roca lanzada hacia el Player (impulso=%.1f)" % 12.0)

	if _state_is(player, PlayerScript.PlayerState.KNOCKBACK):
		_knockback_recorded = true
		_knockback_speed = Vector3(player.velocity.x, 0.0, player.velocity.z).length()
		_knockback_away = _is_moving_away(rock, player)
		_check()

	elif _frames_after_throw > 200:
		_knockback_recorded = true
		_check()


func _check() -> void:
	var is_five_percent_more := _knockback_recorded and absf(_knockback_speed - BOX_FORCE * 1.05) <= 3.0
	var checks := {
		"roca_empuja_fuerza_10_5": not _knockback_recorded or absf(_knockback_speed - 10.5) <= 3.0,
		"5pct_mas_que_caja": is_five_percent_more,
		"knockback_sale_de_la_roca": _knockback_away,
		"player_en_KNOCKBACK": _knockback_recorded,
	}
	print("[ROCK IMPACT TEST] velocidad_knockback=%.3f" % _knockback_speed)
	print("[ROCK IMPACT TEST] knockback_sale_de_la_roca=%s" % _knockback_away)

	var all_ok := true
	for key in checks:
		print("[ROCK IMPACT TEST] %-34s -> %s" % [key, checks[key]])
		if not checks[key]:
			all_ok = false

	print("[ROCK IMPACT TEST] RESULTADO: ", ("PASS" if all_ok else "FAIL"))
	get_tree().quit(0 if all_ok else 1)


func _state_is(character: CharacterBody3D, expected: int) -> bool:
	return character.get("_state") == expected


func _state_name(character: CharacterBody3D) -> String:
	return "KNOCKBACK" if _state_is(character, PlayerScript.PlayerState.KNOCKBACK) else "NORMAL"


func _is_moving_away(object_node: Node3D, character: Node3D) -> bool:
	var away := character.global_position - object_node.global_position
	away.y = 0.0
	if away.length_squared() < 0.0001:
		return false
	away = away.normalized()
	var v := Vector3(character.get("velocity").x, 0.0, character.get("velocity").z).normalized()
	return v.dot(away) > 0.3