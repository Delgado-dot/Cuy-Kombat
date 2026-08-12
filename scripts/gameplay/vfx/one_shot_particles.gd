extends GPUParticles3D

## Base para VFX de partículas one-shot: se emiten una vez al entrar en el
## árbol y el nodo se elimina solo al terminar. No requiere gestión externa.

@export var auto_emit := true

var _started := false


func _ready() -> void:
	one_shot = true
	emitting = false
	if not auto_emit:
		return
	restart()
	emitting = true
	_started = true
	finished.connect(queue_free)


## Emite el burst manualmente (útil si auto_emit está desactivado).
func play_once() -> void:
	if _started:
		return
	_started = true
	restart()
	emitting = true
	finished.connect(queue_free)
