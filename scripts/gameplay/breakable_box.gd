extends InteractableObject

class_name BreakableBox

signal impact_detected(collider: Object, intensity: float)

@export var impact_report_threshold := 1.0
@export var break_threshold := 3.0

## Proporción de break_threshold a partir de la cual un impacto avanza las
## grietas visuales. Solo afecta al feedback visual, NO al break_threshold.
@export var crack_impact_ratio := 0.4
## Cantidad máxima de grietas visuales superpuestas antes de romperse.
@export var damage_stages := 3
## Si false, no se generan grietas (p. ej. barril de metal).
@export var show_cracks := true
## Tiempo mínimo entre feedbacks visuales de impacto (evita spamear mientras
## el objeto está en contacto sostenido con una superficie).
@export var impact_feedback_cooldown := 0.12

## VFX de partículas por impacto (viruta de madera / chispas).
@export var impact_debris_scene: PackedScene
## VFX de ruptura (flash + ring + polvo + virutas).
@export var break_vfx_scene: PackedScene
## Escena de fragmentos físicos expulsados al romperse.
@export var debris_fragment_scene: PackedScene
@export var debris_count := 9
@export var debris_min_speed := 3.5
@export var debris_max_speed := 6.5
@export var debris_up_force := 4.0
@export var debris_size := 0.13

## Sonido de ruptura (punto de conexión; si es null no se reproduce nada).
@export var break_sfx: AudioStream

var last_impact_intensity := 0.0
var last_impact_collider: Object
var last_impact_position := Vector3.ZERO
var _is_broken := false
var _crack_stage := 0
var _crack_nodes: Array[Node3D] = []
var _model_shake_tween: Tween
var _last_feedback_time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	_rng.randomize()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	super._integrate_forces(state)

	if freeze or _is_broken:
		return

	var strongest_intensity := 0.0
	var strongest_collider: Object
	var strongest_position := global_position

	for contact_index in state.get_contact_count():
		var intensity := state.get_contact_impulse(contact_index).length()
		if intensity > strongest_intensity:
			strongest_intensity = intensity
			strongest_collider = state.get_contact_collider_object(contact_index)
			strongest_position = global_transform * state.get_contact_local_position(contact_index)

	if strongest_intensity < impact_report_threshold:
		return

	_handle_impact(strongest_collider, strongest_intensity, strongest_position)


func _handle_impact(collider: Object, intensity: float, impact_position: Vector3) -> void:
	last_impact_intensity = intensity
	last_impact_collider = collider
	last_impact_position = impact_position
	impact_detected.emit(collider, intensity)

	print("[BREAKABLE BOX] Impact detected | Strength: %.2f" % intensity)
	if intensity >= break_threshold:
		_break()
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_feedback_time < impact_feedback_cooldown:
		return
	_last_feedback_time = now

	_play_impact_shake(intensity)
	_play_impact_debris()
	_advance_crack_stage(intensity)


func is_broken() -> bool:
	return _is_broken


func _break() -> void:
	if _is_broken:
		return

	_is_broken = true
	_destroy_body()
	_play_break_feedback()
	print("[BREAKABLE BOX] BROKEN")
	queue_free()


## Limpieza física al romperse (la usa BreakableBox y las subclases).
func _destroy_body() -> void:
	remove_from_group("interactable_objects")
	freeze = true
	collision_layer = 0
	collision_mask = 0
	$InteractionArea.monitoring = false
	_stop_flight_trail()


## --- Feedback visual (solo visual, no altera umbrales ni física) ---

## Pequeño temblor del modelo al recibir un impacto fuerte.
func _play_impact_shake(intensity: float) -> void:
	var model := _find_visual_model()
	if model == null:
		return

	if _model_shake_tween != null and _model_shake_tween.is_valid():
		_model_shake_tween.kill()

	var amount := clampf(intensity / maxf(break_threshold, 0.001), 0.35, 1.0) * 0.045

	_model_shake_tween = model.create_tween()
	_model_shake_tween.tween_property(model, "rotation:z", amount, 0.05) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_model_shake_tween.tween_property(model, "rotation:z", 0.0, 0.14) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## Polvo/virutas/chispas en el punto del impacto.
func _play_impact_debris() -> void:
	if impact_debris_scene == null:
		return
	ObjectVFX.spawn_vfx(self, impact_debris_scene, last_impact_position)


## Acumula grietas visuales con los impactos fuertes (hasta damage_stages).
func _advance_crack_stage(intensity: float) -> void:
	if not show_cracks:
		return
	if _crack_stage >= damage_stages:
		return
	if intensity < break_threshold * crack_impact_ratio:
		return

	_spawn_crack()
	_crack_stage += 1


## Crea una grieta hecha de segmentos finos oscuros sobre una cara del cubo.
func _spawn_crack() -> void:
	var faces: Array[Vector3] = [
		Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK,
	]
	var face: Vector3 = faces[_rng.randi_range(0, faces.size() - 1)]

	var holder := Node3D.new()
	holder.name = "Crack%d" % _crack_stage
	holder.basis = _basis_aligning_to(face)
	add_child(holder)
	holder.position = face * 0.56

	var crack_material := StandardMaterial3D.new()
	crack_material.albedo_color = Color(0.07, 0.035, 0.02, 0.95)
	crack_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var current := Vector3(-0.32, _rng.randf_range(-0.05, 0.05), 0.015)
	var segments := 4

	for i in segments:
		var bend := _rng.randf_range(-0.55, 0.55)
		var length := 0.16 + _rng.randf() * 0.14

		var segment_mesh := BoxMesh.new()
		segment_mesh.size = Vector3(length, 0.013, 0.02)

		var segment := MeshInstance3D.new()
		segment.mesh = segment_mesh
		segment.material_override = crack_material
		segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		segment.position = current + Vector3(0.0, _rng.randf_range(-0.03, 0.03), 0.0)
		segment.rotation.z = bend
		holder.add_child(segment)

		current += Vector3(cos(bend) * length, sin(bend) * length, 0.0)

	_crack_nodes.append(holder)


func _basis_aligning_to(face: Vector3) -> Basis:
	var z := face.normalized()
	var reference := Vector3.UP
	if absf(z.dot(reference)) > 0.9:
		reference = Vector3.FORWARD
	var x := reference.cross(z).normalized()
	var y := z.cross(x)
	return Basis(x, y, z)


## Busca el nodo de modelo visual del objeto (RocaModel/CajaModel/BarrilModel).
func _find_visual_model() -> Node3D:
	for child in get_children():
		if child is Node3D and child.name.ends_with("Model"):
			return child as Node3D
	return null


## Secuencia de ruptura: flash + ring + polvo/virutas + fragmentos físicos.
func _play_break_feedback() -> void:
	if break_vfx_scene != null:
		ObjectVFX.spawn_vfx(self, break_vfx_scene, global_position)

	if debris_fragment_scene != null:
		ObjectVFX.spawn_debris(
			self,
			debris_fragment_scene,
			global_position,
			debris_count,
			debris_min_speed,
			debris_max_speed,
			debris_up_force,
			debris_size,
			Color(0.62, 0.38, 0.18, 1.0),
			0.0,
			0.9
		)

	ObjectVFX.play_sfx(self, break_sfx, global_position)
