extends InteractableObject

class_name BreakableBox

signal impact_detected(collider: Object, intensity: float)

@export var impact_report_threshold := 1.0
@export var break_threshold := 3.0

var last_impact_intensity := 0.0
var last_impact_collider: Object
var _is_broken := false


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	super._integrate_forces(state)

	if freeze or _is_broken:
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

	_handle_impact(strongest_collider, strongest_intensity)


func _handle_impact(collider: Object, intensity: float) -> void:
	last_impact_intensity = intensity
	last_impact_collider = collider
	impact_detected.emit(collider, intensity)

	print("[BREAKABLE BOX] Impact detected | Strength: %.2f" % intensity)
	if intensity >= break_threshold:
		_break()


func is_broken() -> bool:
	return _is_broken


func _break() -> void:
	if _is_broken:
		return

	_is_broken = true
	remove_from_group("interactable_objects")
	freeze = true
	collision_layer = 0
	collision_mask = 0
	$InteractionArea.monitoring = false
	print("[BREAKABLE BOX] BROKEN")
	queue_free()
