extends Node3D

## Diagnostico: por que el Barrel no se detecta/us agarra con el GrabHitbox
## mientras Rock si. Compara ambos objetos en la misma escena con el Player.
## Simula la pulsacion de G (grab_p1) a traves de input para probar el flujo real.

const PlayerScript := preload("res://entities/player/player.gd")

@onready var player: CharacterBody3D = $Player
@onready var barrel: InteractableObject = $Barrel
@onready var rock: InteractableObject = $Rock

var _grab_pressed := false
var _ticks := 0
var _settle_ticks := 0
var _done := false


func _ready() -> void:
	print("[GRABDIAG] === Diagnostico agarre Barrel vs Rock ===")
	print("[GRABDIAG] Barrel en grupo interactable=", barrel.is_in_group("interactable_objects"),
		" has_method(can_be_grabbed)=", barrel.has_method("can_be_grabbed"),
		" can_be_grabbed()=", barrel.can_be_grabbed(),
		" freeze=", barrel.freeze)
	print("[GRABDIAG] Rock   en grupo interactable=", rock.is_in_group("interactable_objects"),
		" has_method(can_be_grabbed)=", rock.has_method("can_be_grabbed"),
		" can_be_grabbed()=", rock.can_be_grabbed(),
		" freeze=", rock.freeze)
	player.set("input_enabled", true)


func _physics_process(_delta: float) -> void:
	if _done:
		return
	_ticks += 1

	# Dejar que la fisica asiente las posiciones (evitar empujones por overlap).
	_settle_ticks += 1
	if _settle_ticks < 30:
		return

	if _settle_ticks == 30:
		_reporte_overlap()
	elif _settle_ticks == 40 and not _grab_pressed:
		_grab_pressed = true
		Input.action_press("grab_p1")
		print("[GRABDIAG] G presionada (grab_p1). state antes=", player.get("_state"))
	elif _settle_ticks == 41:
		Input.action_release("grab_p1")
		var target = player.get("_grabbed_target")
		print("[GRABDIAG] Despues de G: state=", player.get("_state"),
			" grabbed_target=", (target.name if target != null else "null"),
			" barrel.is_grabbed_by(player)=", barrel.is_grabbed_by(player),
			" rock.is_grabbed_by(player)=", rock.is_grabbed_by(player))
	elif _settle_ticks >= 50:
		_finish()


func _reporte_overlap() -> void:
	var grab_hitbox = player.get("_grab_hitbox") as Area3D
	if grab_hitbox == null:
		print("[GRABDIAG] player._grab_hitbox == null")
		return
	var overlapping := grab_hitbox.get_overlapping_bodies()
	var names: Array = []
	for b in overlapping:
		names.append(b.name)
	print("[GRABDIAG] GrabHitbox.overlapping_bodies=", names,
		" (barrel presente=", overlapping.has(barrel), " rock presente=", overlapping.has(rock), ")")
	print("[GRABDIAG] player_pos=", player.global_position, " barrel_pos=", barrel.global_position,
		" rock_pos=", rock.global_position)


func _finish() -> void:
	_done = true
	var target = player.get("_grabbed_target")
	var veredicto := "UNEAGLEABLE: BDETECT" if (target == barrel or (target == null)) else "grabbed=%s" % (target.name if target != null else "null")
	print("[GRABDIAG] veredicto=barrel_agarrado=", (target == barrel),
		" | target=", (target.name if target != null else "null"))
	get_tree().quit()