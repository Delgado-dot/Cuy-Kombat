extends Node3D

## Feedback común de lanzamiento: burst + partículas direccionales de velocidad
## + flash breve. Se orienta con face_direction() hacia donde salió el objeto.

const FLASH_TIME := 0.18

@onready var _burst: GPUParticles3D = $Burst
@onready var _streak: GPUParticles3D = $Streak
@onready var _flash: MeshInstance3D = $FlashRing

var _flash_material: StandardMaterial3D
var _max_life := 0.35


func _ready() -> void:
	for particles in [_burst, _streak]:
		if particles == null:
			continue
		particles.restart()
		particles.emitting = true
		_max_life = maxf(_max_life, particles.lifetime)

	if _flash != null:
		_flash_material = _flash.get_surface_override_material(0) as StandardMaterial3D
		_play_flash()

	var clean := get_tree().create_timer(_max_life + 0.35)
	clean.timeout.connect(queue_free)


## Orienta el VFX para que los streaks apunten hacia `dir` (mundo).
func face_direction(dir: Vector3) -> void:
	if dir.length_squared() < 0.0001:
		return
	look_at(global_position + dir.normalized(), Vector3.UP)


func _play_flash() -> void:
	if _flash == null:
		return

	_flash.visible = true
	_flash.scale = Vector3.ONE * 0.2

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_flash, "scale", Vector3.ONE * 1.4, FLASH_TIME)
	if _flash_material != null:
		tween.tween_property(_flash_material, "albedo_color:a", 0.0, FLASH_TIME)
