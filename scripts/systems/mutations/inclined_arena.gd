class_name InclinedArenaMutation
extends Mutation

## Mantiene 9 grados de inclinacion mientras su direccion recorre X/Z a una
## velocidad angular moderada. El deslizamiento sigue la normal real del piso.

const TILT_ANGLE := deg_to_rad(9.0)
const TILT_SPEED := 0.55
const SLIDE_SPEED := 1.8


func get_id() -> StringName:
	return &"inclined_arena"


func get_display_name() -> String:
	return "Arena inclinada"


func get_description() -> String:
	return "La direccion de la pendiente gira lentamente durante la ronda."


func get_slide_direction(player: Node) -> Vector3:
	var character := player as CharacterBody3D
	if character == null or not character.is_on_floor():
		return Vector3.ZERO

	var downhill := Vector3.DOWN.slide(character.get_floor_normal())
	var slope_strength := clampf(downhill.length() / sin(TILT_ANGLE), 0.0, 1.0)
	downhill.y = 0.0
	if downhill.length_squared() < 0.000001:
		return Vector3.ZERO
	return downhill.normalized() * SLIDE_SPEED * slope_strength


func get_arena_tilt_angle() -> float:
	return TILT_ANGLE


func get_arena_tilt_speed() -> float:
	return TILT_SPEED
