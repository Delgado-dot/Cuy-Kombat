extends Node3D

## Feedback común de agarre: pequeño burst de partículas + flash breve.
## One-shot, se elimina solo. No toca física.

const FLASH_TIME := 0.22

@onready var _burst: GPUParticles3D = $Burst
@onready var _flash: MeshInstance3D = $FlashRing

var _flash_material: StandardMaterial3D
var _max_life := 0.4


func _ready() -> void:
	if _burst != null:
		_burst.restart()
		_burst.emitting = true
		_max_life = maxf(_max_life, _burst.lifetime)

	if _flash != null:
		_flash_material = _flash.get_surface_override_material(0) as StandardMaterial3D
		_play_flash()

	var clean := get_tree().create_timer(_max_life + 0.4)
	clean.timeout.connect(queue_free)


func _play_flash() -> void:
	if _flash == null:
		return

	_flash.visible = true
	_flash.scale = Vector3.ONE * 0.15

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_flash, "scale", Vector3.ONE * 1.1, FLASH_TIME)
	if _flash_material != null:
		tween.tween_property(_flash_material, "albedo_color:a", 0.0, FLASH_TIME)
