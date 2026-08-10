extends Node3D

## Test reutilizable de la explosión del barrel.
##
## Uso: godot --headless --path <proyecto> res://tests/objects/barrel_explosion_test.tscn
##
## Comprueba (radio por defecto 6.0 m):
##   - El barrel rompe correctamente con un impacto fuerte.
##   - Jugador a menos de 6 m recibe el efecto (KNOCKBACK).
##   - Jugador exactamente a 6 m recibe el efecto.
##   - Jugador a más de 6 m NO recibe el efecto.
##   - Varios jugadores dentro del radio reciben el efecto.
##   - La fuerza del knockback decrece con la distancia.
##   - La dirección del knockback sale del centro del barrel.
##   - La explosión no se ejecuta dos veces.
##   - El VFX se activa al explotar, solo visual (sin knockback ni detección física).

const PlayerScript := preload("res://entities/player/player.gd")

@onready var barrel: Barrel = $Barrel
@onready var player_near: CharacterBody3D = $PlayerNear
@onready var player_mid: CharacterBody3D = $PlayerMid
@onready var player_edge: CharacterBody3D = $PlayerEdge
@onready var player_far: CharacterBody3D = $PlayerFar

var _explosions := 0


func _ready() -> void:
	barrel.exploded.connect(func() -> void:
		_explosions += 1
		print("[BEXP TEST] señal exploded emitida (total=%d)" % _explosions)
	)

	var center := barrel.global_position
	print("[BEXP TEST] === Barrel explosion test (radio=%.2f) ===" % barrel.explosion_radius)
	print("[BEXP TEST] Center=%s" % center)
	print("[BEXP TEST] dist: near=%.4f mid=%.4f edge=%.4f far=%.4f" % [
		center.distance_to(player_near.global_position),
		center.distance_to(player_mid.global_position),
		center.distance_to(player_edge.global_position),
		center.distance_to(player_far.global_position),
	])

	# Primera rotura: debe explotar.
	barrel._handle_impact(null, 5.0)
	# Segundo impacto: no debe existir una segunda explosión.
	barrel._handle_impact(null, 8.0)

	_check()


func _check() -> void:
	var center := barrel.global_position
	var near_dist := center.distance_to(player_near.global_position)
	var mid_dist := center.distance_to(player_mid.global_position)
	var edge_dist := center.distance_to(player_edge.global_position)
	var far_dist := center.distance_to(player_far.global_position)

	var near_state: int = player_near.get("_state")
	var mid_state: int = player_mid.get("_state")
	var edge_state: int = player_edge.get("_state")
	var far_state: int = player_far.get("_state")

	var near_speed := Vector3(player_near.velocity.x, 0.0, player_near.velocity.z).length()
	var mid_speed := Vector3(player_mid.velocity.x, 0.0, player_mid.velocity.z).length()
	var edge_speed := Vector3(player_edge.velocity.x, 0.0, player_edge.velocity.z).length()

	var away_near := (player_near.global_position - center)
	away_near.y = 0.0
	away_near = away_near.normalized()
	var move_dir := Vector3(player_near.velocity.x, 0.0, player_near.velocity.z).normalized()
	var knocked_away_from_center := near_speed > 0.05 and move_dir.dot(away_near) > 0.5

	# Verificar que se instanció el VFX y que es únicamente visual.
	var vfx: Node3D = barrel.get("_last_spawned_vfx") as Node3D
	var vfx_spawned := vfx != null and vfx.is_inside_tree()
	var vfx_purely_visual := _is_purely_visual(vfx)

	# El empuje de la explosión: explosion_force = 19.8 (18.0 × 1.10).
	var explosion_force: float = barrel.explosion_force
	var force_is_19_8 := absf(explosion_force - 19.8) <= 0.01
	# La explosión NO debe aturdir ni cambiar el color del Player (sin stun).
	var near_stun_pending: bool = player_near.get("_stun_pending")
	var explosion_sin_cambio_color := not near_stun_pending

	print("[BEXP TEST] barrel.is_broken=%s" % barrel.is_broken())
	print("[BEXP TEST] explosiones totales=%d (esperado 1)" % _explosions)
	print("[BEXP TEST] explosion_force=%.2f (esperado 19.8) -> %s" % [explosion_force, force_is_19_8])
	print("[BEXP TEST] explosion_sin_stun/sin_cambio_color=%s" % explosion_sin_cambio_color)
	print("[BEXP TEST] estados: near=%d mid=%d edge=%d far=%d (KNOCKBACK=%d NORMAL=%d)" % [
		near_state, mid_state, edge_state, far_state,
		PlayerScript.PlayerState.KNOCKBACK, PlayerScript.PlayerState.NORMAL,
	])
	print("[BEXP TEST] velocidad_horiz: near=%.3f mid=%.3f edge=%.3f" % [near_speed, mid_speed, edge_speed])
	print("[BEXP TEST] vfx_spawned=%s vfx_purely_visual=%s" % [vfx_spawned, vfx_purely_visual])

	var checks := {
		"barrel_roto": barrel.is_broken(),
		"explotado_una_vez": _explosions == 1,
		"near_menos_6m_afectado": near_dist < barrel.explosion_radius and near_state == PlayerScript.PlayerState.KNOCKBACK,
		"mid_dentro_afectado": mid_dist < barrel.explosion_radius and mid_state == PlayerScript.PlayerState.KNOCKBACK,
		"edge_6m_afectado": absf(edge_dist - barrel.explosion_radius) <= 0.05 and edge_state == PlayerScript.PlayerState.KNOCKBACK,
		"far_mas_6m_NO_afectado": far_dist > barrel.explosion_radius and far_state == PlayerScript.PlayerState.NORMAL,
		"fuerza_decrece_con_distancia": near_speed > mid_speed and mid_speed > edge_speed,
		"knockback_sale_del_centro": knocked_away_from_center,
		"fuerza_base_explosion_19_8": force_is_19_8,
		"explosion_sin_cambio_color": explosion_sin_cambio_color,
		"vfx_activado_al_explorar": vfx_spawned,
		"vfx_solo_visual": vfx_purely_visual,
	}

	var all_ok := true
	for key in checks:
		print("[BEXP TEST] %-30s -> %s" % [key, checks[key]])
		if not checks[key]:
			all_ok = false

	print("[BEXP TEST] RESULTADO: ", ("PASS" if all_ok else "FAIL"))
	get_tree().quit()


## El VFX debe ser Node3D con solo hijos visuales/partículas (Node3D,
## GPUParticles3D, MeshInstance3D). No debe contener PhysicsBody3D, Area3D ni
## CollisionObject3D (no aplica física ni detecta jugadores).
func _is_purely_visual(node: Node3D) -> bool:
	if node == null:
		return true

	for child in node.get_children():
		if child is CollisionObject3D:
			return false
		if child is Node3D and not _is_purely_visual(child as Node3D):
			return false
	return true