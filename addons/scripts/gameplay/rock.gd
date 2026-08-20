extends InteractableObject

class_name Rock

## Feedback visual de la roca al caer/chocar contra una superficie sólida
## (suelo, bordes). No modifica la física: solo detecta contactos y muestra
## un puff de polvo. Los impactos contra jugadores ya tienen su VFX común.

## Escena de polvo instanciada al impactar contra el suelo.
@export var ground_impact_scene: PackedScene
## Velocidad mínima (m/s) para considerar el contacto como impacto real.
@export var ground_impact_speed := 3.5
## Tiempo mínimo entre puffs (evita repetir mientras rueda sobre el suelo).
@export var ground_impact_cooldown := 0.3
## Impulso mínimo del contacto (además de la velocidad) para validar el impacto.
@export var ground_impact_min_impulse := 2.0
## Decaimiento por segundo de la "velocidad retenida" usada para detectar el
## impacto. El solver deja linear_velocity en 0 justo en el tick del contacto,
## así que se retiene la velocidad del tick anterior y se deja decaer.
@export var ground_impact_speed_decay := 60.0

var _last_ground_impact_time := 0.0
var _retained_speed := 0.0


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	super._integrate_forces(state)

	if freeze or _is_grabbed:
		return

	_detect_ground_impact(state)


## Busca contactos con superficies sólidas (StaticBody3D/CSGShape3D, igual que
## el raycast del ObjectsSpawner) y, si el contacto es fuerte, muestra polvo.
func _detect_ground_impact(state: PhysicsDirectBodyState3D) -> void:
	if ground_impact_scene == null:
		return
	if state.get_contact_count() <= 0:
		_retained_speed = maxf(linear_velocity.length(), _retained_speed)
		return

	_retained_speed = maxf(linear_velocity.length(), _retained_speed - ground_impact_speed_decay * state.step)
	var speed := _retained_speed
	if speed < ground_impact_speed:
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_ground_impact_time < ground_impact_cooldown:
		return

	for contact_index in state.get_contact_count():
		var collider: Object = state.get_contact_collider_object(contact_index)
		if collider == null:
			continue
		if collider is CharacterBody3D:
			continue
		if not (collider is StaticBody3D or collider is CSGShape3D):
			continue

		var impulse := state.get_contact_impulse(contact_index).length()
		if impulse < ground_impact_min_impulse and speed < ground_impact_speed * 1.5:
			continue

		_last_ground_impact_time = now
		var impact_position := global_transform * state.get_contact_local_position(contact_index)
		ObjectVFX.spawn_vfx(self, ground_impact_scene, impact_position)
		break
