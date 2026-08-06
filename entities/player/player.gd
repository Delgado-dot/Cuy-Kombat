extends CharacterBody3D

enum PlayerState {
	NORMAL,
	ATTACKING,
	KNOCKBACK,
	DEAD,
}

@export var move_speed := 6.0
@export var acceleration := 18.0
@export var deceleration := 24.0
@export var jump_velocity := 5.5
@export var gravity := 18.0
@export var rotation_speed := 12.0
@export_enum("wasd", "arrows") var control_scheme := "wasd"
@export var tackle_charge_time := 0.75
@export var min_tackle_force := 8.0
@export var max_tackle_force := 15.0
@export var tackle_duration := 0.22
@export var knockback_force := 13.0
@export var knockback_up_force := 5.0
@export var knockback_duration := 0.45
@export var body_push_force := 4.5
@export var body_push_velocity_factor := 0.35
@export var body_push_friction := 10.0

var _horizontal_velocity := Vector3.ZERO
var _external_push := Vector3.ZERO
var _state := PlayerState.NORMAL
var _charge_time := 0.0
var _tackle_time_left := 0.0
var _knockback_time_left := 0.0
var _hit_players: Array[Node] = []

@onready var _camera_pivot := get_node_or_null("CameraPivot") as Node3D
@onready var _tackle_hitbox := get_node_or_null("TackleHitbox") as Area3D
@onready var _collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D

func _physics_process(delta: float) -> void:
	if _state == PlayerState.DEAD:
		return

	if _state == PlayerState.KNOCKBACK:
		_update_knockback(delta)
		move_and_slide()
		return

	if _state == PlayerState.ATTACKING:
		_update_tackle(delta)
		move_and_slide()
		return

	_update_tackle_charge(delta)

	var move_direction := _get_camera_relative_input()
	var target_velocity := move_direction * move_speed
	var blend_speed := acceleration if move_direction.length_squared() > 0.0 else deceleration

	_horizontal_velocity = _horizontal_velocity.move_toward(target_velocity, blend_speed * delta)
	_external_push = _external_push.move_toward(Vector3.ZERO, body_push_friction * delta)
	velocity.x = _horizontal_velocity.x + _external_push.x
	velocity.z = _horizontal_velocity.z + _external_push.z

	if is_on_floor():
		if Input.is_key_pressed(_jump_key()):
			velocity.y = jump_velocity
		elif velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	_update_normal_state()
	_face_move_direction(move_direction, delta)
	move_and_slide()
	_push_colliding_players()

func _ready() -> void:
	if _tackle_hitbox != null:
		_tackle_hitbox.body_entered.connect(_on_tackle_hitbox_body_entered)

	call_deferred("_connect_death_zone")

func _get_camera_relative_input() -> Vector3:
	var input_vector := Vector2.ZERO

	if Input.is_key_pressed(_left_key()):
		input_vector.x -= 1.0
	if Input.is_key_pressed(_right_key()):
		input_vector.x += 1.0
	if Input.is_key_pressed(_forward_key()):
		input_vector.y -= 1.0
	if Input.is_key_pressed(_back_key()):
		input_vector.y += 1.0

	if input_vector.length_squared() == 0.0:
		return Vector3.ZERO

	input_vector = input_vector.normalized()
	var basis := _get_movement_basis()

	var forward := -basis.z
	var right := basis.x
	forward.y = 0.0
	right.y = 0.0

	if forward.length_squared() == 0.0 or right.length_squared() == 0.0:
		return Vector3(input_vector.x, 0.0, -input_vector.y).normalized()

	return (right.normalized() * input_vector.x + forward.normalized() * -input_vector.y).normalized()

func _get_movement_basis() -> Basis:
	var pivot_camera := _find_camera_in_pivot()

	if pivot_camera != null:
		return pivot_camera.global_transform.basis

	var viewport_camera := get_viewport().get_camera_3d()

	if viewport_camera != null:
		return viewport_camera.global_transform.basis

	return Basis()

func _find_camera_in_pivot() -> Camera3D:
	if _camera_pivot == null:
		return null

	for child in _camera_pivot.get_children():
		if child is Camera3D:
			return child

	return null

func _update_normal_state() -> void:
	if _state != PlayerState.DEAD:
		_state = PlayerState.NORMAL

func _face_move_direction(move_direction: Vector3, delta: float) -> void:
	if move_direction.length_squared() == 0.0:
		return

	var target_yaw := atan2(-move_direction.x, -move_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)

func _forward_key() -> Key:
	return KEY_UP if control_scheme == "arrows" else KEY_W

func _back_key() -> Key:
	return KEY_DOWN if control_scheme == "arrows" else KEY_S

func _left_key() -> Key:
	return KEY_LEFT if control_scheme == "arrows" else KEY_A

func _right_key() -> Key:
	return KEY_RIGHT if control_scheme == "arrows" else KEY_D

func _jump_key() -> Key:
	return KEY_ENTER if control_scheme == "arrows" else KEY_SPACE

func _tackle_key() -> Key:
	return KEY_CTRL if control_scheme == "arrows" else KEY_SHIFT

func _update_tackle_charge(delta: float) -> void:
	if Input.is_key_pressed(_tackle_key()):
		_charge_time += delta
	elif _charge_time > 0.0:
		_start_tackle()

func _start_tackle() -> void:
	var charge_ratio := clampf(_charge_time / tackle_charge_time, 0.0, 1.0)
	var tackle_force := lerpf(min_tackle_force, max_tackle_force, charge_ratio)
	var forward := -global_transform.basis.z.normalized()

	_state = PlayerState.ATTACKING
	_tackle_time_left = tackle_duration
	_hit_players.clear()
	velocity = forward * tackle_force
	velocity.y = maxf(velocity.y, 1.0)
	_horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)
	_charge_time = 0.0

func _update_tackle(delta: float) -> void:
	_tackle_time_left -= delta
	velocity.y -= gravity * delta

	if _tackle_time_left <= 0.0:
		_state = PlayerState.NORMAL

func _update_knockback(delta: float) -> void:
	_knockback_time_left -= delta
	velocity.y -= gravity * delta

	if is_on_floor() and _knockback_time_left <= 0.0:
		_state = PlayerState.NORMAL
		_horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)

func apply_knockback(direction: Vector3, force: float, up_force: float) -> void:
	if _state == PlayerState.DEAD:
		return

	var knockback_direction := direction
	knockback_direction.y = 0.0

	if knockback_direction.length_squared() == 0.0:
		knockback_direction = -global_transform.basis.z

	knockback_direction = knockback_direction.normalized()
	velocity = knockback_direction * force
	velocity.y = up_force
	_knockback_time_left = knockback_duration
	_state = PlayerState.KNOCKBACK

func apply_body_push(direction: Vector3, force: float) -> void:
	if _state == PlayerState.DEAD:
		return

	var push_direction := direction
	push_direction.y = 0.0

	if push_direction.length_squared() == 0.0:
		return

	_external_push += push_direction.normalized() * force

func eliminate() -> void:
	_state = PlayerState.DEAD
	velocity = Vector3.ZERO
	_horizontal_velocity = Vector3.ZERO
	visible = false
	set_physics_process(false)

	if _collision_shape != null:
		_collision_shape.disabled = true

func _on_tackle_hitbox_body_entered(body: Node3D) -> void:
	if _state != PlayerState.ATTACKING:
		return
	if body == self or body in _hit_players:
		return
	if not body.has_method("apply_knockback"):
		return

	_hit_players.append(body)
	var hit_direction := body.global_position - global_position
	body.apply_knockback(hit_direction, knockback_force, knockback_up_force)

func _push_colliding_players() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()

		if collider == self or not (collider is CharacterBody3D):
			continue
		if not collider.has_method("apply_body_push"):
			continue

		var other_player := collider as CharacterBody3D
		var push_direction := other_player.global_position - global_position
		push_direction.y = 0.0

		if push_direction.length_squared() == 0.0:
			push_direction = -collision.get_normal()
			push_direction.y = 0.0

		var horizontal_speed := Vector3(velocity.x, 0.0, velocity.z).length()
		var push_force := body_push_force + horizontal_speed * body_push_velocity_factor
		other_player.apply_body_push(push_direction, push_force)

func _connect_death_zone() -> void:
	var death_zone := get_tree().root.find_child("AgujeroCentral", true, false) as Area3D

	if death_zone != null and not death_zone.body_entered.is_connected(_on_death_zone_body_entered):
		death_zone.body_entered.connect(_on_death_zone_body_entered)

func _on_death_zone_body_entered(body: Node3D) -> void:
	if body == self:
		eliminate()
