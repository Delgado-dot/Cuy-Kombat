extends Node3D

const DURATION := 12.0

@export var disable_model := false

@onready var barrel: RigidBody3D = $Barrel

var _elapsed := 0.0
var _last_log_second: int = -1
var _start_pos: Vector3
var _start_model_pos: Vector3


func _ready() -> void:
	_start_pos = barrel.global_position
	_dump_tree(barrel, 0)

	print("[BARREL REST TEST] === Despertando fisica natural (instrumentacion de diagnostico) ===")
	if disable_model and barrel.has_node("BarrilModel"):
		barrel.get_node("BarrilModel").visible = false
		print("[BARREL REST TEST] MODELO DESACTIVADO (disable_model=true)")
	print("[BARREL REST TEST] freeze_antes=%s -> freeze_despues=... (se dejara caer y asentar)" % barrel.freeze)
	barrel.freeze = false
	barrel.sleeping = false
	_start_pos = barrel.global_position

	if barrel.has_node("BarrilModel"):
		_start_model_pos = barrel.get_node("BarrilModel").global_position
	else:
		_start_model_pos = _start_pos

	_log_state(0.0)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if int(_elapsed) > _last_log_second:
		_last_log_second = int(_elapsed)
		_log_state(float(_last_log_second))

	if _elapsed >= DURATION:
		_final_report()
		get_tree().quit(0)


func _log_state(t: float) -> void:
	var model_info := "sin_modelo"
	if barrel.has_node("BarrilModel"):
		var model := barrel.get_node("BarrilModel")
		model_info = "model_pos=%s" % model.global_position
	print("[BARREL REST TEST] t=%.1fs pos=%s vel=%s ang=%s freeze=%s sleeping=%s | %s" % [
		t,
		barrel.global_position,
		barrel.linear_velocity,
		barrel.angular_velocity,
		barrel.freeze,
		barrel.sleeping,
		model_info,
	])


func _final_report() -> void:
	var barrel_disp: float = barrel.global_position.distance_to(_start_pos)
	var model_disp := 0.0
	var model_pos := Vector3.ZERO
	if barrel.has_node("BarrilModel"):
		var model := barrel.get_node("BarrilModel")
		model_pos = model.global_position
		model_disp = model_pos.distance_to(_start_model_pos)

	print("[BARREL REST TEST] === RESUMEN ===")
	print("[BARREL REST TEST] pos_inicial_barrel=%s pos_final_barrel=%s desplazamiento_barrel=%.4f" % [
		_start_pos, barrel.global_position, barrel_disp,
	])
	print("[BARREL REST TEST] pos_inicial_modelo=%s pos_final_modelo=%s desplazamiento_modelo=%.4f" % [
		_start_model_pos, model_pos, model_disp,
	])
	print("[BARREL REST TEST] linear_velocity_final=%s angular_velocity_final=%s" % [
		barrel.linear_velocity, barrel.angular_velocity,
	])
	print("[BARREL REST TEST] is_broken=%s" % (barrel.is_broken() if barrel.has_method("is_broken") else "n/a"))


func _dump_tree(node: Node, depth: int) -> void:
	var indent := "  ".repeat(depth)
	var extra := ""
	if node is CollisionObject3D:
		extra = " [layer=%d mask=%d]" % [node.collision_layer, node.collision_mask]
	print("[BARREL REST TEST] %s%s '%s'<%s>%s" % [
		indent, "L" if node is Node3D else "N", node.name, node.get_class(), extra,
	])
	for child in node.get_children():
		_dump_tree(child, depth + 1)