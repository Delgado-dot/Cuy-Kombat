extends Node3D

## VFX provisional de la explosión del barrel.
##
## Puramente visual: no aplica física, no hace knockback y no detecta jugadores
## ni determina el radio físico de la explosión. Las partículas son one-shot y
## el nodo se elimina solo al terminar, sin dejar partículas activas.

const EXPANSION_TWEEN_TIME := 0.5

@onready var _fire: GPUParticles3D = $Fire
@onready var _sparks: GPUParticles3D = $Sparks
@onready var _smoke: GPUParticles3D = $Smoke
@onready var _shockwave: MeshInstance3D = $Shockwave

var _max_particle_lifetime := 0.5
var _shockwave_material: StandardMaterial3D
var _done := false


func _ready() -> void:
	_collect_max_lifetime(_fire)
	_collect_max_lifetime(_sparks)
	_collect_max_lifetime(_smoke)

	if _shockwave != null:
		_shockwave_material = _shockwave.get_surface_override_material(0) as StandardMaterial3D

	_play_shockwave()

	if _fire != null:
		_fire.restart()
		_fire.emitting = true
	if _sparks != null:
		_sparks.restart()
		_sparks.emitting = true
	if _smoke != null:
		_smoke.restart()
		_smoke.emitting = true

	var clean := get_tree().create_timer(_max_particle_lifetime + 0.5)
	clean.timeout.connect(_finish)


func _collect_max_lifetime(particles: GPUParticles3D) -> void:
	if particles == null:
		return
	_max_particle_lifetime = maxf(_max_particle_lifetime, particles.lifetime)


func _play_shockwave() -> void:
	if _shockwave == null:
		return

	_shockwave.scale = Vector3.ONE * 0.1
	_shockwave.visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_shockwave, "scale", Vector3.ONE * 1.0, EXPANSION_TWEEN_TIME)

	if _shockwave_material != null:
		tween.tween_property(_shockwave_material, "albedo_color:a", 0.0, EXPANSION_TWEEN_TIME)

	tween.chain().tween_property(_shockwave, "scale", Vector3.ONE * 6.0, 0.15)
	tween.set_parallel(false)
	await tween.finished
	if _shockwave != null:
		_shockwave.visible = false


func _finish() -> void:
	if _done:
		return
	_done = true
	if _fire != null:
		_fire.emitting = false
	if _sparks != null:
		_sparks.emitting = false
	if _smoke != null:
		_smoke.emitting = false
	queue_free()