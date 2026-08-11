extends RigidBody3D

## Base reusable for physical objects that will support interactions later.
class_name InteractableObject

const PlayerScript := preload("res://entities/player/player.gd")

## Emitted when a player enters this object's interaction range.
signal player_entered_interaction_range(player: CharacterBody3D)

## Emitted when a player leaves this object's interaction range.
signal player_exited_interaction_range(player: CharacterBody3D)

@export var throw_impulse := 40.0

## Offset local para colocar este objeto sobre el CarryPoint del jugador
## mientras es cargado. No modifica el CarryPoint del jugador.
@export var carry_offset := Vector3.ZERO

## Fuerza horizontal del knockback aplicada al Player cuando este objeto lo
## impacta físicamente. 0.0 = el objeto no empuja a los jugadores.
@export var impact_knockback_force := 10.0
## Impulso mínimo del contacto (PhysicsDirectBodyState3D.get_contact_impulse)
## para considerar el impacto como real y aplicar el knockback.
@export var impact_knockback_threshold := 1.0
## Tiempo mínimo entre knockbacks a un mismo Player (evita múltiples knockbacks
## por el mismo contacto mientras los cuerpos siguen tocándose).
@export var impact_knockback_cooldown := 0.5

var _nearby_players: Array[CharacterBody3D] = []
var _grabbed_player: CharacterBody3D
var _is_grabbed := false
var _collision_layer_before_grab := 1
var _last_impact_knockback_times := {}


func _ready() -> void:
	add_to_group("interactable_objects")
	$InteractionArea.body_entered.connect(_on_interaction_area_body_entered)
	$InteractionArea.body_exited.connect(_on_interaction_area_body_exited)


## Returns true while at least one CharacterBody3D is inside the interaction area.
func has_player_in_interaction_range() -> bool:
	return not _nearby_players.is_empty()


func is_grabbed_by(player: CharacterBody3D) -> bool:
	return _is_grabbed and _grabbed_player == player


## Applies a throw impulse toward the player's facing direction.
func throw(player: CharacterBody3D) -> void:
	if not is_grabbed_by(player):
		return

	var throw_direction := -player.global_transform.basis.z.normalized()
	release_from_being_grabbed()
	apply_central_impulse(throw_direction * throw_impulse)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_apply_impact_knockback(state)


## Detecta contactos físicos reales con jugadores y, para los impactos
## significativos, les aplica el knockback configurado (impact_knockback_force).
##
## Usa el mecanismo físico existente de Godot (contactos reportados en
## PhysicsDirectBodyState3D), no la proximidad. Se ejecuta una vez por impacto
## (con cooldown por jugador) para no spamear knockbacks mientras los cuerpos
## siguen en contacto.
func _apply_impact_knockback(state: PhysicsDirectBodyState3D) -> void:
	if impact_knockback_force <= 0.0:
		return
	if freeze or _is_grabbed:
		return
	if state.get_contact_count() <= 0:
		return

	var now := Time.get_ticks_msec() / 1000.0

	for contact_index in state.get_contact_count():
		var impulse := state.get_contact_impulse(contact_index).length()
		if impulse < impact_knockback_threshold:
			continue

		var collider: Object = state.get_contact_collider_object(contact_index)
		if collider == null or not (collider is CharacterBody3D):
			continue
		if not collider.has_method("apply_knockback"):
			continue

		var player := collider as CharacterBody3D
		var player_id := player.get_instance_id()
		if _last_impact_knockback_times.has(player_id):
			var last_time: float = _last_impact_knockback_times[player_id]
			if now - last_time < impact_knockback_cooldown:
				continue

		_last_impact_knockback_times[player_id] = now

		var direction := player.global_position - global_position
		direction.y = 0.0
		if direction.length_squared() < 0.0001:
			direction = -player.global_transform.basis.z

		player.apply_knockback(direction.normalized(), impact_knockback_force, 0.0, false)


func _physics_process(_delta: float) -> void:
	if not _is_grabbed or not is_instance_valid(_grabbed_player):
		return

	var anchor := _grabbed_player.global_position + Vector3.UP * 2.0
	if _grabbed_player.has_method("get_carry_point_global"):
		anchor = _grabbed_player.get_carry_point_global()

	global_position = anchor + carry_offset

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


## Kevin grab protocol: whether this object can currently be grabbed.
func can_be_grabbed() -> bool:
	return not _is_grabbed


## Estado de agarre propio del objeto (no usa PlayerState del jugador).
func is_being_grabbed() -> bool:
	return _is_grabbed


## Kevin grab protocol: state reported to the grabbing player while held.
func get_player_state() -> int:
	return PlayerScript.PlayerState.GRABBED if _is_grabbed else PlayerScript.PlayerState.NORMAL


## Kevin grab protocol: called by the grabbing player when the grab starts.
func start_being_grabbed(grabbing_player: Node3D) -> void:
	if _is_grabbed:
		return
	if not is_instance_valid(grabbing_player):
		return

	_grabbed_player = grabbing_player as CharacterBody3D
	_is_grabbed = true

	_collision_layer_before_grab = collision_layer
	collision_layer = 0
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


## Kevin grab protocol: called by the grabbing player when the grab ends.
func release_from_being_grabbed() -> void:
	if not _is_grabbed:
		return

	_is_grabbed = false
	_grabbed_player = null
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = _collision_layer_before_grab
	freeze = false
	sleeping = false


func _on_interaction_area_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return

	var player := body as CharacterBody3D
	if player in _nearby_players:
		return

	_nearby_players.append(player)

	player_entered_interaction_range.emit(player)


func _on_interaction_area_body_exited(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return

	var player := body as CharacterBody3D
	if player not in _nearby_players:
		return

	_nearby_players.erase(player)

	player_exited_interaction_range.emit(player)
