extends RigidBody3D

## Base reusable for physical objects that will support interactions later.
class_name InteractableObject

const PlayerScript := preload("res://entities/player/player.gd")

## Emitted when a player enters this object's interaction range.
signal player_entered_interaction_range(player: CharacterBody3D)

## Emitted when a player leaves this object's interaction range.
signal player_exited_interaction_range(player: CharacterBody3D)

## Emitted when the currently selected player requests an interaction.
signal interaction_requested(player: CharacterBody3D)

@export var throw_impulse := 20.0

var _nearby_players: Array[CharacterBody3D] = []
var _current_interacting_player: CharacterBody3D
var _grabbed_player: CharacterBody3D
var _is_grabbed := false
var _is_elevating := false
var _elevation_tween: Tween
var _collision_layer_before_grab := 1


func _ready() -> void:
	add_to_group("interactable_objects")
	$InteractionArea.body_entered.connect(_on_interaction_area_body_entered)
	$InteractionArea.body_exited.connect(_on_interaction_area_body_exited)
	interaction_requested.connect(_on_interaction_requested)


## Returns true while at least one CharacterBody3D is inside the interaction area.
func has_player_in_interaction_range() -> bool:
	return not _nearby_players.is_empty()


## Returns the player currently selected to interact with this object.
func get_interacting_player() -> CharacterBody3D:
	return _current_interacting_player


func is_grabbed_by(player: CharacterBody3D) -> bool:
	return _is_grabbed and _grabbed_player == player


## Validates whether the supplied player is currently able to interact.
func interact(player: CharacterBody3D) -> void:
	if player != _current_interacting_player:
		print("[INTERACTION] Interaction rejected: %s" % player.name)
		return

	print("[INTERACTION] Interaction accepted: %s" % player.name)
	interaction_requested.emit(player)


func _on_interaction_requested(player: CharacterBody3D) -> void:
	_grabbed_player = player
	_is_grabbed = true
	_is_elevating = true
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	if _elevation_tween != null and _elevation_tween.is_valid():
		_elevation_tween.kill()

	_elevation_tween = create_tween()
	_elevation_tween.set_trans(Tween.TRANS_QUAD)
	_elevation_tween.set_ease(Tween.EASE_OUT)
	_elevation_tween.tween_property(
		self,
		"global_position",
		player.global_position + Vector3.UP * 2.0,
		0.4
	)
	_elevation_tween.tween_callback(_finish_grab_elevation)


func release(player: CharacterBody3D) -> void:
	if not is_grabbed_by(player):
		return

	_release_from_player(player, -player.global_transform.basis.z.normalized())


func throw(player: CharacterBody3D) -> void:
	if not is_grabbed_by(player):
		return

	var throw_direction := -player.global_transform.basis.z.normalized()
	_release_from_player(player, throw_direction)
	apply_central_impulse(throw_direction * throw_impulse)


func _release_from_player(player: CharacterBody3D, direction: Vector3) -> void:
	if _elevation_tween != null and _elevation_tween.is_valid():
		_elevation_tween.kill()

	_is_grabbed = false
	_is_elevating = false
	_grabbed_player = null
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = player.global_position + direction * 1.5 + Vector3.UP * 0.75
	freeze = false
	sleeping = false


func _physics_process(_delta: float) -> void:
	if not _is_grabbed or _is_elevating or not is_instance_valid(_grabbed_player):
		return

	if _grabbed_player.has_method("get_grab_point_global"):
		global_position = _grabbed_player.get_grab_point_global()
	else:
		global_position = _grabbed_player.global_position + Vector3.UP * 2.0


## Kevin grab protocol: whether this object can currently be grabbed.
func can_be_grabbed() -> bool:
	return not _is_grabbed


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
	_is_elevating = false

	if _elevation_tween != null and _elevation_tween.is_valid():
		_elevation_tween.kill()
		_elevation_tween = null

	_collision_layer_before_grab = collision_layer
	collision_layer = 0
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


## Kevin grab protocol: called by the grabbing player when the grab ends.
func release_from_being_grabbed() -> void:
	if not _is_grabbed:
		return

	if _elevation_tween != null and _elevation_tween.is_valid():
		_elevation_tween.kill()
		_elevation_tween = null

	_is_grabbed = false
	_is_elevating = false
	_grabbed_player = null
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = _collision_layer_before_grab
	freeze = false
	sleeping = false


func _finish_grab_elevation() -> void:
	_is_elevating = false


func _on_interaction_area_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return

	var player := body as CharacterBody3D
	if player in _nearby_players:
		return

	_nearby_players.append(player)
	if _current_interacting_player == null:
		_current_interacting_player = player

	player_entered_interaction_range.emit(player)


func _on_interaction_area_body_exited(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return

	var player := body as CharacterBody3D
	if player not in _nearby_players:
		return

	_nearby_players.erase(player)
	if _current_interacting_player == player:
		if _nearby_players.is_empty():
			_current_interacting_player = null
		else:
			_current_interacting_player = _nearby_players[0]

	player_exited_interaction_range.emit(player)
