extends InteractableObject

class_name BreakableBox

signal impact_detected(collider: Object, intensity: float)

@export var impact_report_threshold := 1.0

var last_impact_intensity := 0.0
var last_impact_collider: Object


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if freeze:
		return

	var strongest_intensity := 0.0
	var strongest_collider: Object

	for contact_index in state.get_contact_count():
		var intensity := state.get_contact_impulse(contact_index).length()
		if intensity > strongest_intensity:
			strongest_intensity = intensity
			strongest_collider = state.get_contact_collider_object(contact_index)

	if strongest_intensity < impact_report_threshold:
		return

	last_impact_intensity = strongest_intensity
	last_impact_collider = strongest_collider
	impact_detected.emit(strongest_collider, strongest_intensity)

	print("[BREAKABLE BOX] Impact detected | Strength: %.2f" % strongest_intensity)
