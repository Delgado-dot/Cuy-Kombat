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
