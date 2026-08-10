extends RigidBody3D

## Base reusable for physical objects that will support interactions later.
class_name InteractableObject

const PlayerScript := preload("res://entities/player/player.gd")

## Emitted when a player enters this object's interaction range.
signal player_entered_interaction_range(player: CharacterBody3D)

## Emitted when a player leaves this object's interaction range.
signal player_exited_interaction_range(player: CharacterBody3D)

@export var throw_impulse := 20.0

var _nearby_players: Array[CharacterBody3D] = []
var _grabbed_player: CharacterBody3D
var _is_grabbed := false
var _collision_layer_before_grab := 1


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


func _physics_process(_delta: float) -> void:
	if not _is_grabbed or not is_instance_valid(_grabbed_player):
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
