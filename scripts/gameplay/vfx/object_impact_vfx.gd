extends Node3D

## Feedback común cuando un objeto golpea a un jugador: flash breve + ring de
## impacto en el suelo + chispas + polvo. One-shot, se elimina solo.
## No modifica el knockback: solo acompaña visualmente.

const RING_TIME := 0.4
const FLASH_TIME := 0.18

@onready var _sparks: GPUParticles3D = $Sparks
@onready var _dust: GPUParticles3D = $Dust
@onready var _impact_ring: MeshInstance3D = $ImpactRing
@onready var _flash: MeshInstance3D = $Flash

var _ring_material: StandardMaterial3D
var _flash_material: StandardMaterial3D
var _max_life := 0.4


func _ready() -> void:
	for particles in [_sparks, _dust]:
		if particles == null:
			continue
		particles.restart()
		particles.emitting = true
		_max_life = maxf(_max_life, particles.lifetime)

	if _impact_ring != null:
		_ring_material = _impact_ring.get_surface_override_material(0) as StandardMaterial3D
		_play_ring()
	if _flash != null:
		_flash_material = _flash.get_surface_override_material(0) as StandardMaterial3D
		_play_flash()

	var clean := get_tree().create_timer(_max_life + 0.4)
	clean.timeout.connect(queue_free)


func _play_ring() -> void:
	if _impact_ring == null:
		return

	_impact_ring.visible = true
	_impact_ring.scale = Vector3.ONE * 0.25

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_impact_ring, "scale", Vector3.ONE * 2.2, RING_TIME)
	if _ring_material != null:
		tween.tween_property(_ring_material, "albedo_color:a", 0.0, RING_TIME)


func _play_flash() -> void:
	if _flash == null:
		return

	_flash.visible = true
	_flash.scale = Vector3.ONE * 0.3

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_flash, "scale", Vector3.ONE * 1.1, FLASH_TIME)
	if _flash_material != null:
		tween.tween_property(_flash_material, "albedo_color:a", 0.0, FLASH_TIME)
