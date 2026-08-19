extends GPUParticles3D

## Trail corto adjunto a un objeto mientras vuela como proyectil. Los
## partículas se simulan en coordenadas de mundo (local_coords = false), así
## que quedan "detrás" mientras el emisor se mueve con el objeto.

func _ready() -> void:
	emitting = false
	one_shot = false


func start_trail() -> void:
	restart()
	emitting = true


## Detiene la emisión y elimina el trail. Se llama cuando el objeto deja de ser
## proyectil o es agarrado; si el objeto se rompe antes, el trail (hijo del
## objeto) se elimina con él sin callbacks colgados.
func stop_trail() -> void:
	emitting = false
	queue_free()
