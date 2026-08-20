extends Node3D

## Feedback de ruptura de la caja: flash breve + ring + polvo + virutas.
## Los fragmentos de madera físicos los genera la caja aparte (debris).
## One-shot, se elimina solo.

const RING_TIME := 0.45
const FLASH_TIME := 0.2

@onready var _chips: GPUParticles3D = $Chips
@onready var _dust: GPUParticles3D = $Dust
@onready var _ring: MeshInstance3D = $Ring
@onready var _flash: MeshInstance3D = $Flash

var _ring_material: StandardMaterial3D
var _flash_material: StandardMaterial3D
var _max_life := 0.5


func _ready() -> void:
	for particles in [_chips, _dust]:
		if particles == null:
			continue
		particles.restart()
		particles.emitting = true
		_max_life = maxf(_max_life, particles.lifetime)

	if _ring != null:
		_ring_material = _ring.get_surface_override_material(0) as StandardMaterial3D
		_play_ring()
	if _flash != null:
		_flash_material = _flash.get_surface_override_material(0) as StandardMaterial3D
		_play_flash()

	var clean := get_tree().create_timer(_max_life + 0.4)
	clean.timeout.connect(queue_free)


func _play_ring() -> void:
	if _ring == null:
		return

	_ring.visible = true
	_ring.scale = Vector3.ONE * 0.3

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_ring, "scale", Vector3.ONE * 2.6, RING_TIME)
	if _ring_material != null:
		tween.tween_property(_ring_material, "albedo_color:a", 0.0, RING_TIME)


func _play_flash() -> void:
	if _flash == null:
		return

	_flash.visible = true
	_flash.scale = Vector3.ONE * 0.4

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_flash, "scale", Vector3.ONE * 1.3, FLASH_TIME)
	if _flash_material != null:
		tween.tween_property(_flash_material, "albedo_color:a", 0.0, FLASH_TIME)
