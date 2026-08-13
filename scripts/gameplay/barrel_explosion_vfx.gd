extends Node3D

## VFX de la explosión del barril.
##
## Puramente visual: no aplica física, no hace knockback y no detecta jugadores
## ni determina el radio físico de la explosión. Las partículas son one-shot y
## el nodo se elimina solo al terminar, sin dejar partículas activas.
##
## Secuencia: flash breve → onda expansiva (≈6 m, coincide con el radio físico)
## → fuego → chispas → humo que sube y se expande.

const EXPANSION_TWEEN_TIME := 0.4

@onready var _fire: GPUParticles3D = $Fire
@onready var _sparks: GPUParticles3D = $Sparks
@onready var _smoke: GPUParticles3D = $Smoke
@onready var _shockwave: MeshInstance3D = $Shockwave
@onready var _flash_mesh: MeshInstance3D = $FlashMesh
@onready var _flash_light: OmniLight3D = $FlashLight

var _max_particle_lifetime := 0.5
var _shockwave_material: StandardMaterial3D
var _flash_material: StandardMaterial3D
var _done := false


func _ready() -> void:
	_collect_max_lifetime(_fire)
	_collect_max_lifetime(_sparks)
	_collect_max_lifetime(_smoke)

	if _shockwave != null:
		_shockwave_material = _shockwave.get_surface_override_material(0) as StandardMaterial3D
	if _flash_mesh != null:
		_flash_material = _flash_mesh.get_surface_override_material(0) as StandardMaterial3D

	_play_flash()
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


## Flash muy breve y brillante en el centro de la explosión.
func _play_flash() -> void:
	if _flash_light != null:
		_flash_light.light_energy = 9.0
		var light_tween := create_tween()
		light_tween.tween_property(_flash_light, "light_energy", 0.0, 0.3)

	if _flash_mesh == null:
		return

	_flash_mesh.visible = true
	_flash_mesh.scale = Vector3.ONE * 0.3

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_flash_mesh, "scale", Vector3.ONE * 2.4, 0.25)
	if _flash_material != null:
		tween.tween_property(_flash_material, "albedo_color:a", 0.0, 0.25)


## Anillo de onda que se expande rápido y desaparece tras ~0.5 s.
func _play_shockwave() -> void:
	if _shockwave == null:
		return

	_shockwave.scale = Vector3.ONE * 0.15
	_shockwave.visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_shockwave, "scale", Vector3.ONE * 1.0, EXPANSION_TWEEN_TIME)
	if _shockwave_material != null:
		tween.tween_property(_shockwave_material, "albedo_color:a", 0.0, EXPANSION_TWEEN_TIME)

	tween.chain().tween_property(_shockwave, "scale", Vector3.ONE * 6.2, 0.15)
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
