extends CharacterBody3D

signal eliminated(player: Node)

enum PlayerState {
	NORMAL,
	ATTACKING,
	KNOCKBACK,
	STUNNED,
	GRABBING,
	GRABBED,
	KNOCKED,
}

@export var input_enabled := true
@export var player_color := Color(0.9, 0.62, 0.18, 1)
@export var move_speed := 6.0
@export var acceleration := 12.0
@export var deceleration := 14.0
@export var jump_velocity := 5.5
@export var gravity := 18.0
@export var rotation_speed := 8.0
@export_enum("wasd", "arrows") var control_scheme := "wasd"
@export var tackle_charge_time := 0.75
@export var tackle_force := 15.0
@export var tackle_duration := 0.22
@export var tackle_cooldown := 2.5
@export var knockback_force := 18.0
@export var knockback_up_force := 7.0
@export var knockback_duration := 0.45
@export var knockback_deceleration := 32.0
@export var stun_duration := 0.65
@export var body_push_force := 2.0
@export var body_push_velocity_factor := 0.10
@export var body_push_friction := 10.0
@export var body_push_max_speed := 2.0
@export var body_push_press_factor := 0.6
@export var punch_cooldown := 0.5
@export var punch_active_time := 0.12
@export var punch_knockback := 4.0
@export var punch_knockback_duration := 0.2
@export var punch_effect_duration := 0.18
@export var punch_effect_max_scale := 2.0
@export var punch_arm_extend_duration := 0.04
@export var punch_arm_hold_duration := 0.06
@export var punch_arm_return_duration := 0.07
@export var punch_arm_extend_rotation := 1.5
@export var punch_arm_forward_shift := 0.32
@export var knockout_threshold := 5
@export var knocked_duration := 3.5
@export var knockout_color := Color(0.6, 0.6, 0.66, 1.0)
@export var knockout_tilt := 1.5708
@export var grab_follow_speed := 12.0
@export var grab_pose_duration := 0.15
@export var grab_arm_rotation := 1.25
@export var grab_arm_shift := 0.35
@export var grab_arm_forward := -0.02
@export var lean_amount := 0.16
@export var walk_sway_amount := 0.08
@export var walk_sway_speed := 9.0
@export var stretch_amount := 0.08
@export var landing_squash_amount := 0.12
@export var visual_smoothing := 10.0
@export var stun_blink_frequency := 5.0
@export var stun_blink_color := Color(1.0, 0.02, 0.02, 1.0)

var _horizontal_velocity := Vector3.ZERO
var _external_push := Vector3.ZERO
var _state := PlayerState.NORMAL
var _was_on_floor := false
var _walk_time := 0.0
var _landing_squash := 0.0
var _charge_time := 0.0
var _tackle_time_left := 0.0
var _tackle_cooldown_left := 0.0
var _knockback_time_left := 0.0
var _stun_time_left := 0.0
var _stun_blink_time := 0.0
var _stun_pending := false
var _hit_players: Array[Node] = []
var _punch_cooldown_left := 0.0
var _punch_active_left := 0.0
var _punch_key_was_down := false
var _punch_hit_players: Array[Node] = []
var knockout_hits := 0
var _knockout_pending := false
var _knocked_time_left := 0.0
var _knocked_timer_paused := false
var _punch_effect_time := 0.0
var _punch_effect_material: StandardMaterial3D
var _body_material: StandardMaterial3D
var _limb_material: StandardMaterial3D
var _arm_tween: Tween
var _punch_arm_is_left := false
var _grabbed_target: Node3D
var _grabbed_by: Node3D
var _collision_layer_before_grab := 1
var _collision_mask_before_grab := 1
var _last_grab_point_pos := Vector3.ZERO
var _grab_point_tracking := false
var _left_arm_rest_pos := Vector3.ZERO
var _left_arm_rest_rot := Vector3.ZERO
var _right_arm_rest_pos := Vector3.ZERO
var _right_arm_rest_rot := Vector3.ZERO

@onready var _camera_pivot := get_node_or_null("CameraPivot") as Node3D
@onready var _tackle_hitbox := get_node_or_null("TackleHitbox") as Area3D
@onready var _punch_hitbox := get_node_or_null("PunchHitbox") as Area3D
@onready var _punch_effect := get_node_or_null("PunchEffect") as MeshInstance3D
@onready var _collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
@onready var _visual := get_node_or_null("Visual") as Node3D
@onready var _body_mesh := get_node_or_null("Visual/Body") as MeshInstance3D
@onready var _charge_bar := get_node_or_null("Visual/ChargeBar") as Node3D
@onready var _charge_fill := get_node_or_null("Visual/ChargeBar/Fill") as MeshInstance3D
@onready var _left_arm_mesh := get_node_or_null("LeftArm/ArmMesh") as MeshInstance3D
@onready var _right_arm_mesh := get_node_or_null("RightArm/ArmMesh") as MeshInstance3D
@onready var _left_hand_mesh := get_node_or_null("LeftArm/LeftHand/HandMesh") as MeshInstance3D
@onready var _right_hand_mesh := get_node_or_null("RightArm/RightHand/HandMesh") as MeshInstance3D
@onready var _left_arm := get_node_or_null("LeftArm") as Node3D
@onready var _right_arm := get_node_or_null("RightArm") as Node3D
@onready var _grab_hitbox := get_node_or_null("GrabHitbox") as Area3D
@onready var _grab_point := get_node_or_null("GrabPoint") as Node3D

func _physics_process(delta: float) -> void:
	_update_tackle_cooldown(delta)
	_update_punch_cooldown(delta)
	_update_punch(delta)
	_update_punch_effect(delta)

	if _state == PlayerState.KNOCKBACK:
		_update_knockback(delta)
		move_and_slide()
		return

	if _state == PlayerState.STUNNED:
		_update_stun(delta)
		move_and_slide()
		_update_visual_motion(delta, Vector3.ZERO)
		return

	if _state == PlayerState.KNOCKED:
		_update_knocked(delta)
		move_and_slide()
		return

	if _state == PlayerState.GRABBED:
		_update_grabbed(delta)
		move_and_slide()
		return

	if _state == PlayerState.ATTACKING:
		_update_tackle(delta)
		move_and_slide()
		return

	if _state == PlayerState.GRABBING:
		_update_grabbing(delta)
		move_and_slide()
		return

	if not input_enabled:
		_cancel_tackle_charge()
		_update_locked_motion(delta)
		move_and_slide()
		_update_visual_motion(delta, Vector3.ZERO)
		return

	_update_tackle_charge(delta)

	if _state == PlayerState.ATTACKING:
		_update_tackle(delta)
		move_and_slide()
		return

	var move_direction := _get_camera_relative_input()
	_apply_player_movement(delta, move_direction, true)
	_update_normal_state()
	_try_start_punch()
	_try_start_grab()
	_face_move_direction(move_direction, delta)
	move_and_slide()
	_push_colliding_players()
	_update_visual_motion(delta, move_direction)

func _apply_player_movement(delta: float, move_direction: Vector3, can_jump: bool) -> void:
	var target_velocity := move_direction * move_speed
	var blend_speed := acceleration if move_direction.length_squared() > 0.0 else deceleration

	_horizontal_velocity = _horizontal_velocity.move_toward(target_velocity, blend_speed * delta)
	_external_push = _external_push.move_toward(Vector3.ZERO, body_push_friction * delta)
	velocity.x = _horizontal_velocity.x + _external_push.x
	velocity.z = _horizontal_velocity.z + _external_push.z

	if is_on_floor():
		if can_jump and Input.is_key_pressed(_jump_key()):
			velocity.y = jump_velocity
		elif velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

func _ready() -> void:
	_was_on_floor = is_on_floor()
	_apply_player_color()
	_setup_punch_effect()
	_update_charge_bar(0.0, false)

	if _left_arm != null:
		_left_arm_rest_pos = _left_arm.position
		_left_arm_rest_rot = _left_arm.rotation
	if _right_arm != null:
		_right_arm_rest_pos = _right_arm.position
		_right_arm_rest_rot = _right_arm.rotation

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
	_state = PlayerState.NORMAL

func _update_locked_motion(delta: float) -> void:
	_charge_time = 0.0
	_horizontal_velocity = _horizontal_velocity.move_toward(Vector3.ZERO, deceleration * delta)
	_external_push = _external_push.move_toward(Vector3.ZERO, body_push_friction * delta)
	velocity.x = _horizontal_velocity.x + _external_push.x
	velocity.z = _horizontal_velocity.z + _external_push.z

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

func _face_move_direction(move_direction: Vector3, delta: float) -> void:
	if move_direction.length_squared() == 0.0:
		return

	var target_yaw := atan2(-move_direction.x, -move_direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(rotation_speed * delta, 0.0, 1.0))

func _update_visual_motion(delta: float, move_direction: Vector3) -> void:
	if _visual == null:
		return

	var speed_ratio := clampf(Vector3(velocity.x, 0.0, velocity.z).length() / move_speed, 0.0, 1.0)
	var just_landed := is_on_floor() and not _was_on_floor

	if just_landed:
		_landing_squash = landing_squash_amount

	_landing_squash = move_toward(_landing_squash, 0.0, delta * 4.0)

	if speed_ratio > 0.05 and is_on_floor():
		_walk_time += delta * walk_sway_speed * speed_ratio

	var local_direction := global_transform.basis.inverse() * move_direction
	var target_rotation := Vector3.ZERO
	target_rotation.x = -local_direction.z * lean_amount
	target_rotation.z = -local_direction.x * lean_amount
	target_rotation.z += sin(_walk_time) * walk_sway_amount * speed_ratio

	var target_scale := Vector3.ONE
	target_scale.x = 1.0 - stretch_amount * speed_ratio * 0.35 + _landing_squash
	target_scale.y = 1.0 + stretch_amount * speed_ratio - _landing_squash
	target_scale.z = 1.0 - stretch_amount * speed_ratio * 0.35 + _landing_squash

	_visual.rotation = _visual.rotation.lerp(target_rotation, clampf(visual_smoothing * delta, 0.0, 1.0))
	_visual.scale = _visual.scale.lerp(target_scale, clampf(visual_smoothing * delta, 0.0, 1.0))
	_was_on_floor = is_on_floor()

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

func _punch_key() -> Key:
	return KEY_PERIOD if control_scheme == "arrows" else KEY_F

func _grab_action() -> StringName:
	return &"grab_p2" if control_scheme == "arrows" else &"grab_p1"

func _throw_action() -> StringName:
	return &"throw_p2" if control_scheme == "arrows" else &"throw_p1"

func _update_tackle_charge(delta: float) -> void:
	if _tackle_cooldown_left > 0.0:
		_cancel_tackle_charge()
		return

	if Input.is_key_pressed(_tackle_key()):
		_charge_time += delta
		var ratio := clampf(_charge_time / tackle_charge_time, 0.0, 1.0)
		_update_charge_bar(ratio, true)

		if ratio >= 1.0:
			_start_tackle()
	elif _charge_time > 0.0:
		_cancel_tackle_charge()

func _start_tackle() -> void:
	var forward := -global_transform.basis.z.normalized()

	_state = PlayerState.ATTACKING
	_tackle_time_left = tackle_duration
	_hit_players.clear()
	velocity = forward * tackle_force
	velocity.y = maxf(velocity.y, 1.0)
	_horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)
	_charge_time = 0.0
	_tackle_cooldown_left = tackle_cooldown
	_update_charge_bar(0.0, false)

func _cancel_tackle_charge() -> void:
	_charge_time = 0.0
	_update_charge_bar(0.0, false)

func _update_tackle(delta: float) -> void:
	_tackle_time_left -= delta
	velocity.y -= gravity * delta
	_try_tackle_hits()

	if _tackle_time_left <= 0.0:
		_state = PlayerState.NORMAL

func _update_tackle_cooldown(delta: float) -> void:
	if _tackle_cooldown_left <= 0.0:
		return

	_tackle_cooldown_left = maxf(_tackle_cooldown_left - delta, 0.0)

func _update_punch_cooldown(delta: float) -> void:
	if _punch_cooldown_left <= 0.0:
		return

	_punch_cooldown_left = maxf(_punch_cooldown_left - delta, 0.0)

func _try_start_punch() -> void:
	var key_down := Input.is_key_pressed(_punch_key())
	var just_pressed := key_down and not _punch_key_was_down
	_punch_key_was_down = key_down

	if not just_pressed:
		return
	if _state != PlayerState.NORMAL:
		return
	if _punch_cooldown_left > 0.0:
		return

	_start_punch()

func _start_punch() -> void:
	_punch_active_left = punch_active_time
	_punch_cooldown_left = punch_cooldown
	_punch_hit_players.clear()
	_punch_effect_time = 0.0

	if _punch_effect != null:
		_punch_effect.visible = true
		_punch_effect.scale = Vector3.ONE * 0.4
	if _punch_effect_material != null:
		_punch_effect_material.albedo_color.a = 1.0

	if _punch_hitbox != null:
		_punch_hitbox.monitoring = true

	_start_punch_arm_animation()

func _start_punch_arm_animation() -> void:
	if _left_arm == null and _right_arm == null:
		return

	_punch_arm_is_left = not _punch_arm_is_left
	var arm := _left_arm if _punch_arm_is_left else _right_arm

	if arm == null:
		_punch_arm_is_left = not _punch_arm_is_left
		arm = _left_arm if _punch_arm_is_left else _right_arm
		if arm == null:
			return

	if _arm_tween != null and _arm_tween.is_valid():
		_arm_tween.kill()

	var is_left := arm == _left_arm
	var rest_pos := _left_arm_rest_pos if is_left else _right_arm_rest_pos
	var rest_rot := _left_arm_rest_rot if is_left else _right_arm_rest_rot
	var target_pos := Vector3(-punch_arm_forward_shift if is_left else punch_arm_forward_shift, rest_pos.y, rest_pos.z)
	var target_rot := Vector3(punch_arm_extend_rotation, rest_rot.y, rest_rot.z)

	_arm_tween = create_tween()
	_arm_tween.set_parallel(true)
	_arm_tween.tween_property(arm, "position", target_pos, punch_arm_extend_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_arm_tween.tween_property(arm, "rotation", target_rot, punch_arm_extend_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_arm_tween.set_parallel(false)
	_arm_tween.tween_interval(punch_arm_hold_duration)
	_arm_tween.set_parallel(true)
	_arm_tween.tween_property(arm, "position", rest_pos, punch_arm_return_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_arm_tween.tween_property(arm, "rotation", rest_rot, punch_arm_return_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _update_punch(delta: float) -> void:
	if _punch_active_left <= 0.0:
		return

	if _state == PlayerState.KNOCKED:
		_punch_active_left = 0.0
		if _punch_hitbox != null:
			_punch_hitbox.monitoring = false
		return

	_punch_active_left -= delta
	_try_punch_hits()

	if _punch_active_left <= 0.0 and _punch_hitbox != null:
		_punch_hitbox.monitoring = false

func _try_punch_hits() -> void:
	if _punch_active_left <= 0.0 or _punch_hitbox == null:
		return

	for body in _punch_hitbox.get_overlapping_bodies():
		if body == self or body in _punch_hit_players:
			continue
		if not body.has_method("apply_knockback"):
			continue

		_punch_hit_players.append(body)
		var hit_direction := body.global_position - global_position
		body.apply_knockback(hit_direction, punch_knockback, 0.0, false, punch_knockback_duration)
		if body.has_method("register_punch_hit"):
			body.register_punch_hit()

func register_punch_hit() -> void:
	if _state == PlayerState.KNOCKED:
		return

	knockout_hits += 1
	if knockout_hits >= knockout_threshold:
		_knockout_pending = true

func _try_start_grab() -> void:
	if not Input.is_action_just_pressed(_grab_action()):
		return
	if _state != PlayerState.NORMAL:
		return

	var target := _find_grab_target()
	if target == null:
		return

	_start_grab(target)

func _find_grab_target() -> Node3D:
	if _grab_hitbox == null:
		return null

	var best_target: Node3D = null
	var best_distance := INF

	for body in _grab_hitbox.get_overlapping_bodies():
		if body == self:
			continue
		if not (body is CharacterBody3D):
			if not body.is_in_group("interactable_objects"):
				continue
		if not body.has_method("can_be_grabbed"):
			continue
		if not body.can_be_grabbed():
			continue

		var distance := global_position.distance_to(body.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = body

	return best_target

func _start_grab(target: Node3D) -> void:
	_state = PlayerState.GRABBING
	_grabbed_target = target
	_charge_time = 0.0
	_horizontal_velocity = Vector3.ZERO
	_external_push = Vector3.ZERO
	_update_charge_bar(0.0, false)

	if target.has_method("start_being_grabbed"):
		target.start_being_grabbed(self)

	_set_grab_pose(true)

func _release_grab() -> void:
	if _grabbed_target == null:
		return

	var target := _grabbed_target
	_grabbed_target = null

	if is_instance_valid(target) and target.has_method("release_from_being_grabbed"):
		target.release_from_being_grabbed()

	if _state == PlayerState.GRABBING:
		_state = PlayerState.NORMAL

	_set_grab_pose(false)

func _update_grabbing(delta: float) -> void:
	if _grabbed_target == null or not is_instance_valid(_grabbed_target):
		_release_grab()
		return

	if _grabbed_target.get_player_state() != PlayerState.GRABBED:
		_release_grab()
		return

	if _grabbed_target is InteractableObject and Input.is_action_just_pressed(_throw_action()):
		(_grabbed_target as InteractableObject).throw(self)
		_release_grab()
		return

	if Input.is_action_just_released(_grab_action()) or not Input.is_action_pressed(_grab_action()):
		_release_grab()
		return

	var move_direction := _get_camera_relative_input()
	_apply_player_movement(delta, move_direction, true)
	_face_move_direction(move_direction, delta)
	_update_visual_motion(delta, move_direction)

func _update_grabbed(delta: float) -> void:
	if _grabbed_by == null or not is_instance_valid(_grabbed_by):
		release_from_being_grabbed()
		return
	if not _grabbed_by.is_grabbing():
		release_from_being_grabbed()
		return

	var target: Vector3 = _grabbed_by.get_grab_point_global()

	var carry := Vector3.ZERO
	if _grab_point_tracking:
		carry = (target - _last_grab_point_pos) / maxf(delta, 0.001)
	_last_grab_point_pos = target
	_grab_point_tracking = true

	var offset := target - global_position
	var correction := offset * grab_follow_speed
	correction = correction.limit_length(grab_follow_speed * 3.0)

	velocity = (carry + correction).limit_length(grab_follow_speed * 3.0)

	rotation.y = lerp_angle(rotation.y, _grabbed_by.rotation.y + PI, clampf(rotation_speed * 2.0 * delta, 0.0, 1.0))

func _set_grab_pose(active: bool) -> void:
	if _left_arm == null and _right_arm == null:
		return

	if _arm_tween != null and _arm_tween.is_valid():
		_arm_tween.kill()

	_arm_tween = create_tween()
	_arm_tween.set_parallel(true)

	for arm in [_left_arm, _right_arm]:
		var rest_pos := _left_arm_rest_pos if arm == _left_arm else _right_arm_rest_pos
		var rest_rot := _left_arm_rest_rot if arm == _left_arm else _right_arm_rest_rot

		var target_pos := rest_pos
		var target_rot := rest_rot
		if active:
			target_pos = Vector3(-grab_arm_shift if arm == _left_arm else grab_arm_shift, rest_pos.y, grab_arm_forward)
			target_rot = Vector3(grab_arm_rotation, rest_rot.y, rest_rot.z)

		_arm_tween.tween_property(arm, "position", target_pos, grab_pose_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_arm_tween.tween_property(arm, "rotation", target_rot, grab_pose_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func can_be_grabbed() -> bool:
	return _state == PlayerState.NORMAL

func get_player_state() -> int:
	return _state

func is_grabbing() -> bool:
	return _state == PlayerState.GRABBING and _grabbed_target != null

func get_grab_point_global() -> Vector3:
	if _grab_point != null:
		return _grab_point.global_position
	return global_position + -global_transform.basis.z * 0.9

func start_being_grabbed(grabbing_player: Node3D) -> void:
	_grabbed_by = grabbing_player
	_state = PlayerState.GRABBED
	_charge_time = 0.0
	_horizontal_velocity = Vector3.ZERO
	_external_push = Vector3.ZERO
	velocity = Vector3.ZERO

	_collision_layer_before_grab = collision_layer
	_collision_mask_before_grab = collision_mask
	collision_layer = 0

	_last_grab_point_pos = grabbing_player.get_grab_point_global() \
		if grabbing_player.has_method("get_grab_point_global") else grabbing_player.global_position
	_grab_point_tracking = false

func release_from_being_grabbed() -> void:
	if _grabbed_by == null and _state != PlayerState.GRABBED:
		return

	_grabbed_by = null
	velocity = Vector3.ZERO
	_horizontal_velocity = Vector3.ZERO
	_external_push = Vector3.ZERO

	if _state == PlayerState.GRABBED:
		_state = PlayerState.NORMAL

	collision_layer = _collision_layer_before_grab
	collision_mask = _collision_mask_before_grab
	_grab_point_tracking = false

func release_grab_if_target(target: Node3D) -> void:
	if _grabbed_target == target:
		_release_grab()

func _setup_punch_effect() -> void:
	if _punch_effect == null:
		return

	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.9, 0.55, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.6, 0.15, 1.0)
	material.emission_energy_multiplier = 1.5
	_punch_effect_material = material
	_punch_effect.material_override = material
	_punch_effect.scale = Vector3.ONE * 0.01
	_punch_effect.visible = false

func _update_punch_effect(delta: float) -> void:
	if _punch_effect == null or _punch_effect_time >= punch_effect_duration:
		return

	_punch_effect_time += delta

	if _punch_effect_time >= punch_effect_duration:
		_punch_effect.visible = false
		return

	var ratio := _punch_effect_time / punch_effect_duration
	var eased := 1.0 - pow(1.0 - ratio, 2.0)
	_punch_effect.scale = Vector3.ONE * lerpf(0.5, punch_effect_max_scale, eased)

	if _punch_effect_material != null:
		_punch_effect_material.albedo_color.a = 1.0 - ratio

func _update_knockback(delta: float) -> void:
	_knockback_time_left -= delta
	velocity.y -= gravity * delta

	var horizontal := Vector2(velocity.x, velocity.z)
	var horizontal_speed := horizontal.length()

	if horizontal_speed > 0.0:
		var new_speed := maxf(horizontal_speed - knockback_deceleration * delta, 0.0)
		horizontal = horizontal.normalized() * new_speed
		velocity.x = horizontal.x
		velocity.z = horizontal.y

	if is_on_floor() and _knockback_time_left <= 0.0:
		if _knockout_pending:
			_start_knocked()
		elif _stun_pending:
			_start_stun()
		else:
			_state = PlayerState.NORMAL
		_horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)

func _start_stun() -> void:
	_state = PlayerState.STUNNED
	_stun_time_left = stun_duration
	_stun_blink_time = 0.0
	_stun_pending = false
	_charge_time = 0.0
	_horizontal_velocity = Vector3.ZERO
	_set_body_color(stun_blink_color)

func _update_stun(delta: float) -> void:
	_stun_time_left -= delta
	_horizontal_velocity = _horizontal_velocity.move_toward(Vector3.ZERO, deceleration * delta)
	_external_push = _external_push.move_toward(Vector3.ZERO, body_push_friction * delta)
	velocity.x = _horizontal_velocity.x + _external_push.x
	velocity.z = _horizontal_velocity.z + _external_push.z

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	_update_stun_blink(delta)

	if _stun_time_left <= 0.0:
		_state = PlayerState.NORMAL
		_restore_body_color()

func _start_knocked() -> void:
	_state = PlayerState.KNOCKED
	_knockout_pending = false
	_knocked_time_left = knocked_duration
	_knocked_timer_paused = false
	_charge_time = 0.0
	_horizontal_velocity = Vector3.ZERO
	_external_push = Vector3.ZERO
	_set_body_color(knockout_color)

	if _visual != null:
		_visual.rotation.z = knockout_tilt

func _update_knocked(delta: float) -> void:
	if not _knocked_timer_paused:
		_knocked_time_left -= delta

	_horizontal_velocity = _horizontal_velocity.move_toward(Vector3.ZERO, deceleration * delta)
	_external_push = _external_push.move_toward(Vector3.ZERO, body_push_friction * delta)
	velocity.x = _horizontal_velocity.x + _external_push.x
	velocity.z = _horizontal_velocity.z + _external_push.z

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	if _knocked_time_left <= 0.0:
		_recover_from_knocked()

func _recover_from_knocked() -> void:
	_state = PlayerState.NORMAL
	knockout_hits = 0
	_knocked_time_left = 0.0
	_knocked_timer_paused = false
	_horizontal_velocity = Vector3.ZERO
	_external_push = Vector3.ZERO
	velocity = Vector3.ZERO
	_restore_body_color()

	if _visual != null:
		_visual.rotation.z = 0.0

func set_knocked_timer_paused(paused: bool) -> void:
	_knocked_timer_paused = paused

func apply_knockback(direction: Vector3, force: float, up_force: float, stun := true, duration := -1.0) -> void:
	if _state == PlayerState.KNOCKED:
		return
	if _grabbed_target != null:
		_release_grab()
	if _state == PlayerState.GRABBED:
		release_from_being_grabbed()

	var knockback_direction := direction
	knockback_direction.y = 0.0

	if knockback_direction.length_squared() == 0.0:
		knockback_direction = -global_transform.basis.z

	knockback_direction = knockback_direction.normalized()
	_horizontal_velocity = Vector3.ZERO
	_external_push = Vector3.ZERO
	velocity = knockback_direction * force
	velocity.y = up_force + force * 0.15
	_knockback_time_left = knockback_duration if duration <= 0.0 else duration
	_stun_pending = stun
	_state = PlayerState.KNOCKBACK

func apply_body_push(direction: Vector3, force: float) -> void:
	var push_direction := direction
	push_direction.y = 0.0

	if push_direction.length_squared() == 0.0:
		return

	_external_push = (_external_push + push_direction.normalized() * force).limit_length(body_push_max_speed)

func eliminate() -> void:
	if _grabbed_by != null and is_instance_valid(_grabbed_by) and _grabbed_by.has_method("release_grab_if_target"):
		_grabbed_by.release_grab_if_target(self)
	release_from_being_grabbed()
	_release_grab()

	velocity = Vector3.ZERO
	_horizontal_velocity = Vector3.ZERO
	visible = false
	set_physics_process(false)

	if _collision_shape != null:
		_collision_shape.disabled = true

	eliminated.emit(self)

func _on_tackle_hitbox_body_entered(_body: Node3D) -> void:
	_try_tackle_hits()

func _try_tackle_hits() -> void:
	if _state != PlayerState.ATTACKING or _tackle_hitbox == null:
		return

	for body in _tackle_hitbox.get_overlapping_bodies():
		if body == self or body in _hit_players:
			continue
		if not body.has_method("apply_knockback"):
			continue

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

		var push_dir := push_direction.normalized()

		var horizontal_speed := Vector3(velocity.x, 0.0, velocity.z).length()
		var push_force := body_push_force + horizontal_speed * body_push_velocity_factor
		other_player.apply_body_push(push_dir, push_force)

		var approach := _horizontal_velocity.dot(push_dir)
		if approach > 0.0:
			var approach_cap := body_push_max_speed * body_push_press_factor
			if approach > approach_cap:
				_horizontal_velocity -= push_dir * (approach - approach_cap)

func _connect_death_zone() -> void:
	var death_zone := get_tree().root.find_child("AgujeroCentral", true, false) as Area3D

	if death_zone != null and not death_zone.body_entered.is_connected(_on_death_zone_body_entered):
		death_zone.body_entered.connect(_on_death_zone_body_entered)

func _on_death_zone_body_entered(body: Node3D) -> void:
	if body == self:
		eliminate()

func _apply_player_color() -> void:
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = player_color
	body_material.roughness = 0.65

	if _body_mesh != null:
		_body_material = body_material
		_body_mesh.set_surface_override_material(0, _body_material)

	var limb_material := StandardMaterial3D.new()
	limb_material.albedo_color = player_color.darkened(0.15)
	limb_material.roughness = 0.7
	_limb_material = limb_material

	for mesh in [_left_arm_mesh, _right_arm_mesh, _left_hand_mesh, _right_hand_mesh]:
		if mesh != null:
			mesh.set_surface_override_material(0, _limb_material)

func _update_stun_blink(delta: float) -> void:
	if _body_material == null:
		return

	_stun_blink_time += delta
	var blink_phase := int(_stun_blink_time * stun_blink_frequency * 2.0) % 2
	_set_body_color(stun_blink_color if blink_phase == 0 else player_color)

func _set_body_color(color: Color) -> void:
	if _body_material != null:
		_body_material.albedo_color = color
	if _limb_material != null:
		_limb_material.albedo_color = color

func _restore_body_color() -> void:
	_set_body_color(player_color)

func _update_charge_bar(ratio: float, visible_bar: bool) -> void:
	if _charge_bar != null:
		_charge_bar.visible = visible_bar
	if _charge_fill == null:
		return

	var fill_ratio := clampf(ratio, 0.0, 1.0)
	_charge_fill.scale.x = fill_ratio
	_charge_fill.position.x = -0.5 + fill_ratio * 0.5
