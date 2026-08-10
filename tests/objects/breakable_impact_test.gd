extends Node3D

@onready var box_a: BreakableBox = $BoxA
@onready var box_b: BreakableBox = $BoxB
@onready var rock: Rock = $Rock
@onready var player: CharacterBody3D = $Player

var _throw_scenario_started := false
var _throw_scenario_frames := 0


func _ready() -> void:
	_run_threshold_checks()


func _physics_process(_delta: float) -> void:
	if not _throw_scenario_started:
		return

	_throw_scenario_frames += 1
	if _throw_scenario_frames == 1:
		var direction := (box_b.global_position - rock.global_position).normalized()
		rock.apply_central_impulse(direction * 30.0)
	elif _throw_scenario_frames == 90:
		print("[IMPACT TEST] BoxB rota por impacto fisico del lanzamiento: broken=%s" % box_b.is_broken())
		_throw_scenario_started = false


func _run_threshold_checks() -> void:
	print("[IMPACT TEST] === Umbral de ruptura (impacto fisico) ===")
	print("[IMPACT TEST] BoxA inicial: broken=%s, en grupo interactable=%s, freeze=%s" % [
		box_a.is_broken(),
		box_a.is_in_group("interactable_objects"),
		box_a.freeze,
	])

	box_a._handle_impact(null, 2.0)
	print("[IMPACT TEST] Impacto debil (2.0 < break_threshold 3.0): broken=%s (esperado false)" % box_a.is_broken())

	box_a._handle_impact(null, 5.0)
	print("[IMPACT TEST] Impacto fuerte (5.0 >= 3.0): broken=%s (esperado true), en grupo interactable=%s, freeze=%s" % [
		box_a.is_broken(),
		box_a.is_in_group("interactable_objects"),
		box_a.freeze,
	])

	rock.start_being_grabbed(player)
	rock.throw(player)
	print("[IMPACT TEST] Rock lanzado: is_grabbed_by(player)=%s, freeze=%s (fisica restaurada)" % [
		rock.is_grabbed_by(player),
		rock.freeze,
	])

	_throw_scenario_started = true