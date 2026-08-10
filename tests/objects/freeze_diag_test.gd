extends Node3D

## Verifica el fix de barrel.gd: usar `sleeping = true` en vez de `freeze = true`.
## Un barrel dormido (no congelado) DEBE ser detectado por el GrabHitbox,
## poder agarrarse con G y lanzarse con throw, sin moverse por sí solo.

@onready var player: CharacterBody3D = $Player
@onready var barrel: InteractableObject = $Barrel
@onready var rock: InteractableObject = $Rock

var _ticks := 0
var _done := false
var _barrel_detected_before := false


func _ready() -> void:
	player.set("input_enabled", true)
	print("[SLEEPEDIAG] Barrel freeze=", barrel.freeze, " sleeping=", barrel.sleeping,
		" | Rock freeze=", rock.freeze, " sleeping=", rock.sleeping)


func _physics_process(_delta: float) -> void:
	if _done:
		return
	_ticks += 1
	var hitbox := player.get("_grab_hitbox") as Area3D
	var overlapping := hitbox.get_overlapping_bodies()
	var barrel_detected := overlapping.has(barrel)
	var rock_detected := overlapping.has(rock)

	match _ticks:
		30:
			_barrel_detected_before = barrel_detected
			var barrel_moved := barrel.global_position.distance_to(Vector3(0.5, 0.7, 1.9)) > 0.001
			print("[SLEEPEDIAG] t=%d barrel_detected=%s rock_detected=%s barrel_still=%s overlap=%s" % [
				_ticks, barrel_detected, rock_detected, (not barrel_moved), overlapping])
		40:
			print("[SLEEPEDIAG] t=%d barrel_pos=%s dist_origen=%.4f" % [
				_ticks, barrel.global_position,
				barrel.global_position.distance_to(Vector3(0.5, 0.7, 1.9))])
		60:
			var barrel_moved := barrel.global_position.distance_to(Vector3(0.5, 0.7, 1.9)) > 0.001
			print("[SLEEPEDIAG] t=%d barrel_detected=%s rock_detected=%s barrel_still=%s overlap=%s" % [
				_ticks, barrel_detected, rock_detected, (not barrel_moved), overlapping])
		70:
			Input.action_press("grab_p1")
		75:
			Input.action_release("grab_p1")
			var target = player.get("_grabbed_target")
			var grabbed := (target != null and (target as Node) == barrel)
			print("[SLEEPEDIAG] G: state=", player.get("_state"),
				" grabbed_target=", (target.name if target != null else "null"),
				" barrel.agrabado=", barrel.is_grabbed_by(player), " barrel.freeze_ahora=", barrel.freeze)
			if grabbed:
				var obj := target as InteractableObject
				obj.throw(player)
				print("[SLEEPEDIAG] throw: is_grabbed=", barrel.is_grabbed_by(player),
					" freeze_despues=", barrel.freeze, " sleeping=", barrel.sleeping)
			else:
				print("[SLEEPEDIAG] NO se pudo agarrar el barrel.")
			_finish(_barrel_detected_before and grabbed)


func _finish(ok: bool) -> void:
	_done = true
	print("[SLEEPEDIAG] RESULTADO: ", ("PASS" if ok else "FAIL"),
		" (detectado dormido=", _barrel_detected_before, " grabado=", (player.get("_grabbed_target") != null), ")")
	get_tree().quit()