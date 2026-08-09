extends CharacterBody3D

@export var move_speed := 5.0
@export var jump_velocity := 5.0
@export var gravity := 18.0

func _physics_process(delta: float) -> void:
	var input_direction := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		input_direction.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_direction.z += 1.0
	if Input.is_key_pressed(KEY_A):
		input_direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_direction.x += 1.0

	input_direction = input_direction.normalized()
	velocity.x = input_direction.x * move_speed
	velocity.z = input_direction.z * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_velocity
	else:
		velocity.y = 0.0

	move_and_slide()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_J:
		_request_interaction()
	elif key_event.keycode == KEY_K:
		_request_throw()


func _request_interaction() -> void:
	var interactable_objects := get_tree().get_nodes_in_group("interactable_objects")

	for node in interactable_objects:
		var grabbed_object := node as InteractableObject
		if grabbed_object != null and grabbed_object.is_grabbed_by(self):
			grabbed_object.release(self)
			return

	for node in interactable_objects:
		var interactable_object := node as InteractableObject
		if interactable_object == null:
			continue
		if interactable_object.get_interacting_player() != self:
			continue

		interactable_object.interact(self)
		return


func _request_throw() -> void:
	for node in get_tree().get_nodes_in_group("interactable_objects"):
		var grabbed_object := node as InteractableObject
		if grabbed_object != null and grabbed_object.is_grabbed_by(self):
			grabbed_object.throw(self)
			return
