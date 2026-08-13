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
@export var tackle_knockback := 20.0
@export var tackle_knockback_up := 8.0
@export var tackle_tilt := 0.35
@export var knockback_force := 18.0
@export var knockback_up_force := 7.0
@export var knockback_duration := 0.45
@export var knockback_deceleration := 32.0
@export var stun_duration := 1.5
@export var stun_reaction_tilt := 0.25
@export var stun_sway_angle := 0.1
@export var stun_sway_speed := 6.0
@export var stun_visual_offset := Vector3(0.0, 0.08, 0.2)
@export var stun_recovery_time := 0.4
@export var body_push_force := 2.0
@export var body_push_velocity_factor := 0.10
@export var body_push_friction := 10.0
@export var body_push_max_speed := 2.0
@export var body_push_press_factor := 0.6
@export var punch_cooldown := 0.5
@export var punch_active_time := 0.12
@export var punch_knockback := 4.0
@export var punch_knockback_duration := 0.2
@export var punch_knockback_up := 0.0
@export var punch_tilt := 0.15
@export var punch_effect_duration := 0.18
@export var punch_effect_max_scale := 2.0
@export var head_sway_angle := 0.12
@export var head_sway_speed := 4.0
@export var headbutt_distance := 0.35
@export var headbutt_rotation := 1.15
@export var headbutt_anticipation_time := 0.05
@export var headbutt_anticipation_pull := 0.12
@export var headbutt_forward_time := 0.08
@export var headbutt_hold_time := 0.03
@export var headbutt_return_time := 0.1
@export var headbutt_rebound := 0.25
@export var hit_reaction_angle := 0.4
@export var hit_reaction_duration := 0.3
@export var knockout_threshold := 5
@export var knocked_duration := 4.5
@export var knocked_fall_duration := 0.7
@export var knocked_fall_speed := 4.0
@export var recovery_duration := 0.9
@export var knocked_recovery_speed := 6.0
@export var knocked_friction := 9.0
@export var knocked_pivot_offset := Vector3(0, -0.12, 0)
@export var knockout_color := Color(0.6, 0.6, 0.66, 1.0)
@export var grab_follow_speed := 12.0
@export var grab_pose_duration := 0.15
@export var grab_arm_rotation := 1.25
@export var grab_arm_shift := 0.35
@export var grab_arm_forward := -0.02
@export var impact_recovery_speed := 0.7
@export var throw_force := 14.0
@export var throw_upward_force := 7.0
@export var object_throw_force := 16.0
@export var object_throw_upward_force := 5.0
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
var _impact_tilt := Vector3.ZERO
var _charge_time := 0.0
var _tackle_time_left := 0.0
var _tackle_cooldown_left := 0.0
var _knockback_time_left := 0.0
var _stun_time_left := 0.0
var _stun_blink_time := 0.0
var _stun_pending := false
var _stun_visual_active := false
var _stun_sway_time := 0.0
var _stun_reaction_tilt := Vector3.ZERO
var _stun_rotation_offset := Vector3.ZERO
var _stun_position_offset := Vector3.ZERO
var _stun_recovery_left := 0.0
var _stun_recovery_total := 0.0
var _last_knockback_dir := Vector3.ZERO
var _hit_players: Array[Node] = []
var _punch_cooldown_left := 0.0
var _punch_active_left := 0.0
var _punch_key_was_down := false
var _punch_hit_players: Array[Node] = []
var knockout_hits := 0
var _knockout_pending := false
var _knocked_time_left := 0.0
var _knocked_timer_paused := false
var _knocked_pivot: Node3D
var _knocked_fall_axis := Vector3.RIGHT
var _knocked_fall_angle := 0.0
var _knocked_fall_time := 0.0
var _knocked_visual_active := false
var _recovering := false
var _recovery_time := 0.0
var _knocked_fall_start_angle := 0.0
var _cuy_model_local_transform := Transform3D.IDENTITY
var _punch_effect_time := 0.0
var _punch_effect_material: StandardMaterial3D
var _body_material: StandardMaterial3D
var _limb_material: StandardMaterial3D
var _arm_tween: Tween
var _cuy_skeleton: Skeleton3D
var _head_bone := -1
var _spine_bone := -1
var _head_moving := false
var _head_rest_forward_local := Vector3(0.0, 0.0, -1.0)
var _head_rest_right_local := Vector3(1.0, 0.0, 0.0)
var _headbutt_dir_local := Vector3(0.0, 0.0, 1.0)
var _head_anim_q := Quaternion.IDENTITY
var _head_offset_q := Quaternion.IDENTITY
var _head_offset_pos := Vector3.ZERO
var _head_sway_time := 0.0
var _head_sway_value := 0.0
var _head_sway_mix := 0.0
var _headbutt_active := false
var _headbutt_elapsed := 0.0
var _headbutt_k := 0.0
var _hit_reaction_left := 0.0
var _hit_reaction_total := 0.0
var _hit_reaction_sign := 1.0
var _grabbed_target: Node3D
var _grabbed_by: Node3D
var _carried_object: InteractableObject
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
@onready var _carry_point := get_node_or_null("CarryPoint") as Node3D
@onready var _cuy_model := get_node_or_null("Visual/CuyModel") as Node3D


func _physics_process(delta: float) -> void:
	_update_tackle_cooldown(delta)
	_update_punch_cooldown(delta)
	_update_punch(delta)
	_update_punch_effect(delta)
	_update_carried_object(delta)

	if _state == PlayerState.KNOCKBACK:
		_update_knockback(delta)
		move_and_slide()
		_push_colliding_players()
		_update_visual_motion(delta, Vector3.ZERO)
		return

	if _state == PlayerState.STUNNED:
		_update_stun(delta)
		move_and_slide()
		_update_visual_motion(delta, Vector3.ZERO)
		return

	if _state == PlayerState.KNOCKED:
		if _grabbed_by != null and is_instance_valid(_grabbed_by):
			_update_grabbed(delta)
			_update_knocked_progress(delta)
		else:
			_update_knocked(delta)
		move_and_slide()
		_push_colliding_players()
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
		if can_jump and (Input.is_key_pressed(_jump_key()) or _joy_button_down(JoyButton.JOY_BUTTON_A)):
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
	call_deferred("_apply_selected_character_model")


func _apply_selected_character_model() -> void:
	if _cuy_model == null:
		return
	var player_num := 1 if control_scheme == "wasd" else 2
	var preset: Dictionary = MatchSettings.get_player_character(player_num)
	if preset.is_empty() or not preset.has("scene_path"):
		return
	var scene_path := String(preset["scene_path"])
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return
	var model_scene := load(scene_path) as PackedScene
	if model_scene == null:
		return
	for child in _cuy_model.get_children():
		child.queue_free()
	var new_model := model_scene.instantiate() as Node3D
	if new_model != null:
		var scale_vec := preset.get("scale", Vector3.ONE) as Vector3
		var offset_vec := preset.get("offset", Vector3.ZERO) as Vector3
		new_model.transform = Transform3D(Basis().scaled(scale_vec), offset_vec)
		new_model.rotation.y = PI
		_cuy_model.add_child(new_model)

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

	input_vector += _joy_stick_vector()

	var device := _joypad_device()
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT):
		input_vector.x -= 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT):
		input_vector.x += 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP):
		input_vector.y -= 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN):
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
	_update_head_visual(delta)

	if _visual == null:
		return

	_update_impact_reaction(delta)
	_update_stun_visual_recovery(delta)

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

	target_rotation += _impact_tilt + _stun_rotation_offset

	var target_scale := Vector3.ONE
	target_scale.x = 1.0 - stretch_amount * speed_ratio * 0.35 + _landing_squash
	target_scale.y = 1.0 + stretch_amount * speed_ratio - _landing_squash
	target_scale.z = 1.0 - stretch_amount * speed_ratio * 0.35 + _landing_squash

	_visual.rotation = _visual.rotation.lerp(target_rotation, clampf(visual_smoothing * delta, 0.0, 1.0))
	_visual.scale = _visual.scale.lerp(target_scale, clampf(visual_smoothing * delta, 0.0, 1.0))
	_visual.position = _visual.position.lerp(_stun_position_offset, clampf(visual_smoothing * delta, 0.0, 1.0))
	_was_on_floor = is_on_floor()

func _update_impact_reaction(delta: float) -> void:
	_impact_tilt = _impact_tilt.move_toward(Vector3.ZERO, impact_recovery_speed * delta)

func _joypad_device() -> int:
	return 0 if control_scheme == "wasd" else 1

func _joy_stick_vector() -> Vector2:
	var axis := Vector2(
		Input.get_joy_axis(_joypad_device(), JOY_AXIS_LEFT_X),
		Input.get_joy_axis(_joypad_device(), JOY_AXIS_LEFT_Y)
	)
	var len := axis.length()
	if len < 0.2:
		return Vector2.ZERO
	return axis / len * clampf((len - 0.2) / 0.8, 0.0, 1.0)

func _joy_button_down(button: JoyButton) -> bool:
	return Input.is_joy_button_pressed(_joypad_device(), button)

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

func _update_tackle_charge(delta: float) -> void:
	if _tackle_cooldown_left > 0.0:
		_cancel_tackle_charge()
		return

	if Input.is_key_pressed(_tackle_key()) or _joy_button_down(JoyButton.JOY_BUTTON_B):
		_charge_time += delta
		var ratio := clampf(_charge_time / tackle_charge_time, 0.0, 1.0)
		_update_charge_bar(ratio, true)

		if ratio >= 1.0:
			_start_tackle()
	elif _charge_time > 0.0:
		_cancel_tackle_charge()

func _start_tackle() -> void:
	_reset_head_visual()

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
	var joy_down := _joy_button_down(JoyButton.JOY_BUTTON_X)
	var down := key_down or joy_down
	var just_pressed := down and not _punch_key_was_down
	_punch_key_was_down = down

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

	_start_headbutt()

func _process(_delta: float) -> void:
	call_deferred("_apply_head_pose")

func _start_headbutt() -> void:
	if _head_bone < 0:
		return

	_headbutt_active = true
	_headbutt_elapsed = 0.0
	_headbutt_k = 0.0

func _update_head_visual(delta: float) -> void:
	if _head_bone < 0 or _cuy_skeleton == null:
		return

	if _state == PlayerState.KNOCKED or _state == PlayerState.STUNNED:
		_headbutt_active = false
		_headbutt_k = 0.0
		_hit_reaction_left = 0.0
		_head_sway_value = 0.0
		_head_sway_mix = 0.0
		_head_moving = false
		_head_offset_q = Quaternion.IDENTITY
		_head_offset_pos = Vector3.ZERO
		return

	var speed_ratio := clampf(Vector3(velocity.x, 0.0, velocity.z).length() / move_speed, 0.0, 1.0)
	var moving := is_on_floor() and speed_ratio > 0.05
	_head_moving = moving

	if moving:
		_head_sway_time += delta * head_sway_speed * speed_ratio
	_head_sway_mix = move_toward(_head_sway_mix, 1.0 if moving else 0.0, delta * 3.0)
	_head_sway_value = sin(_head_sway_time) * head_sway_angle * _head_sway_mix

	if _headbutt_active:
		_headbutt_elapsed += delta
		var total := headbutt_anticipation_time + headbutt_forward_time + headbutt_hold_time + headbutt_return_time
		if _headbutt_elapsed >= total:
			_headbutt_active = false
			_headbutt_k = 0.0
		else:
			_headbutt_k = _headbutt_curve(_headbutt_elapsed)
	else:
		_headbutt_k = 0.0

	if _hit_reaction_left > 0.0:
		_hit_reaction_left = maxf(_hit_reaction_left - delta, 0.0)
		var p := 1.0 - _hit_reaction_left / maxf(_hit_reaction_total, 0.0001)
		var wobble := sin(p * PI * 2.0) * (1.0 - p)
		_head_offset_q = Quaternion(_head_rest_forward_local, wobble * _hit_reaction_sign * hit_reaction_angle)
		_head_offset_pos = Vector3.ZERO
	elif _headbutt_active:
		var headbutt_rot := Quaternion(_head_rest_right_local, _headbutt_k * headbutt_rotation)
		_head_offset_q = headbutt_rot
		_head_offset_pos = _headbutt_dir_local * (_headbutt_k * headbutt_distance)
	else:
		_head_offset_q = Quaternion(_head_rest_forward_local, _head_sway_value)
		_head_offset_pos = Vector3.ZERO

func _apply_head_pose() -> void:
	if _head_bone < 0 or _cuy_skeleton == null or not is_instance_valid(_cuy_skeleton):
		return

	if _head_moving and _spine_bone >= 0:
		_cuy_skeleton.set_bone_pose_rotation(_spine_bone, Quaternion.IDENTITY)

	var anim_q := _cuy_skeleton.get_bone_pose_rotation(_head_bone)
	_head_anim_q = anim_q
	_cuy_skeleton.set_bone_pose_rotation(_head_bone, (anim_q * _head_offset_q).normalized())
	_cuy_skeleton.set_bone_pose_position(_head_bone, _head_offset_pos)
	_cuy_skeleton.set_bone_pose_scale(_head_bone, Vector3.ONE)
	_cuy_skeleton.force_update_all_bone_transforms()

func _reset_head_visual() -> void:
	_headbutt_active = false
	_headbutt_k = 0.0
	_hit_reaction_left = 0.0
	_hit_reaction_total = 0.0
	_head_sway_value = 0.0
	_head_sway_mix = 0.0
	_head_moving = false
	_head_offset_q = Quaternion.IDENTITY
	_head_offset_pos = Vector3.ZERO
	if _head_bone >= 0 and _cuy_skeleton != null and is_instance_valid(_cuy_skeleton):
		_cuy_skeleton.set_bone_pose_rotation(_head_bone, _head_anim_q)
		_cuy_skeleton.set_bone_pose_position(_head_bone, Vector3.ZERO)
		_cuy_skeleton.set_bone_pose_scale(_head_bone, Vector3.ONE)
		_cuy_skeleton.force_update_all_bone_transforms()

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
		body.apply_knockback(hit_direction, punch_knockback, punch_knockback_up, false, punch_knockback_duration, false, punch_tilt)
		if body.has_method("register_punch_hit"):
			body.register_punch_hit()

func register_punch_hit() -> void:
	if _state == PlayerState.KNOCKED:
		return

	knockout_hits += 1
	if knockout_hits >= knockout_threshold:
		_knockout_pending = true
		_start_knocked()

func _try_start_grab() -> void:
	if not Input.is_action_just_pressed(_grab_action()):
		return
	if _state != PlayerState.NORMAL:
		return
	if _carried_object != null:
		return

	var target := _find_grab_target()
	if target == null:
		return

	if target is InteractableObject:
		_start_object_grab(target as InteractableObject)
	else:
		_start_grab(target)


## Agarre de objetos: sistema separado del agarre de jugadores.
## El jugador permanece en PlayerState.NORMAL; el objeto es el agarrado.
func _start_object_grab(object: InteractableObject) -> void:
	_carried_object = object
	object.start_being_grabbed(self)


## Busca objetivo de agarre con prioridad: primero jugadores (sistema Kevin),
## luego objetos InteractableObject (sistema de objetos).
func _find_grab_target() -> Node3D:
	if _grab_hitbox == null:
		return null

	var best_player: Node3D = null
	var best_player_distance := INF
	var best_object: InteractableObject = null
	var best_object_distance := INF

	for body in _grab_hitbox.get_overlapping_bodies():
		if body == self:
			continue
		if not body.has_method("can_be_grabbed"):
			continue
		if not body.can_be_grabbed():
			continue

		var distance := global_position.distance_to(body.global_position)
		if body is CharacterBody3D:
			if distance < best_player_distance:
				best_player_distance = distance
				best_player = body
		elif body is InteractableObject:
			if distance < best_object_distance:
				best_object_distance = distance
				best_object = body

	if best_player != null:
		return best_player
	return best_object

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


## Libera el objeto agarrado (sin lanzamiento).
func _release_object_carry() -> void:
	if _carried_object == null:
		return

	var object := _carried_object
	_carried_object = null

	if is_instance_valid(object):
		object.release_from_being_grabbed()


## Mantiene/suelta o lanza el objeto cargado. La posición del objeto sobre el
## CarryPoint la mantiene su propio _physics_process (mecanismo de Delgado);
## aquí solo se decide qué hacer con él: soltar si el jugador deja de agarrar
## (o su estado deja de ser NORMAL), o lanzar al pulsar THROW.
func _update_carried_object(_delta: float) -> void:
	if _carried_object == null:
		return
	if not is_instance_valid(_carried_object):
		_carried_object = null
		return
	if _state != PlayerState.NORMAL or not input_enabled:
		_release_object_carry()
		return
	if Input.is_action_just_pressed(_throw_action()):
		_throw_carried_object()
		return
	if not Input.is_action_pressed(_grab_action()):
		_release_object_carry()


## Lanzamiento de objetos: secuencia completa.
## 1. Guardar la referencia del objeto.
## 2. release_from_being_grabbed() (restaura física y capa de colisión).
## 3. Limpiar la referencia cargada.
## 4. Aplicar impulso hacia el frente del jugador (velocidad independiente de
##    la masa del objeto, escalando el impulso por su masa).
func _throw_carried_object() -> void:
	var object := _carried_object
	_release_object_carry()

	if object == null or not is_instance_valid(object):
		return

	var direction := -global_transform.basis.z
	direction.y = 0.0
	direction = direction.normalized()

	object.apply_central_impulse(
		direction * object_throw_force * object.mass
		+ Vector3.UP * object_throw_upward_force * object.mass
	)

	if object.has_method("mark_thrown"):
		object.mark_thrown(self)

func _update_grabbing(delta: float) -> void:
	if _try_start_throw():
		return

	if _grabbed_target == null or not is_instance_valid(_grabbed_target):
		_release_grab()
		return

	if not _grabbed_target.is_being_grabbed():
		_release_grab()
		return

	if Input.is_action_just_released(_grab_action()) or not Input.is_action_pressed(_grab_action()):
		_release_grab()
		return

	var move_direction := _get_camera_relative_input()
	_apply_player_movement(delta, move_direction, true)
	_face_move_direction(move_direction, delta)
	_update_visual_motion(delta, move_direction)

func _throw_action() -> StringName:
	return &"throw_p2" if control_scheme == "arrows" else &"throw_p1"

func _try_start_throw() -> bool:
	if not Input.is_action_just_pressed(_throw_action()):
		return false
	if _grabbed_target == null or not is_instance_valid(_grabbed_target):
		return false
	if _grabbed_target.get_player_state() != PlayerState.KNOCKED:
		return false
	_throw_grabbed_target()
	return true

func _throw_grabbed_target() -> void:
	var target := _grabbed_target
	_release_grab()
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("apply_throw_impulse"):
		return
	var dir := -global_transform.basis.z
	dir.y = 0.0
	dir = dir.normalized()
	target.apply_throw_impulse(dir, throw_force, throw_upward_force)

func apply_throw_impulse(direction: Vector3, force: float, up_force: float) -> void:
	if _state != PlayerState.KNOCKED:
		return
	_horizontal_velocity = direction * force
	_external_push = Vector3.ZERO
	velocity = direction * force
	velocity.y = up_force

func _update_grabbed(delta: float) -> void:
	if _grabbed_by == null or not is_instance_valid(_grabbed_by):
		release_from_being_grabbed()
		return
	if not _grabbed_by.is_grabbing():
		release_from_being_grabbed()
		return

	var target: Vector3 = _grabbed_by.get_grab_point_global()
	if _state == PlayerState.KNOCKED and _grabbed_by.has_method("get_carry_point_global"):
		target = _grabbed_by.get_carry_point_global()

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
	return _grabbed_by == null and (_state == PlayerState.NORMAL or _state == PlayerState.KNOCKED)

func is_being_grabbed() -> bool:
	return _grabbed_by != null

func get_player_state() -> int:
	return _state

func is_grabbing() -> bool:
	return _state == PlayerState.GRABBING and _grabbed_target != null

func get_grab_point_global() -> Vector3:
	if _grab_point != null:
		return _grab_point.global_position
	return global_position + -global_transform.basis.z * 1.35

func get_carry_point_global() -> Vector3:
	if _carry_point != null:
		return _carry_point.global_position
	return global_position + Vector3(0, 1.0, 0) + -global_transform.basis.z * 1.15

func start_being_grabbed(grabbing_player: Node3D) -> void:
	_reset_head_visual()

	_grabbed_by = grabbing_player
	if _state != PlayerState.KNOCKED:
		_state = PlayerState.GRABBED
	_charge_time = 0.0
	_horizontal_velocity = Vector3.ZERO
	_external_push = Vector3.ZERO
	velocity = Vector3.ZERO

	_collision_layer_before_grab = collision_layer
	_collision_mask_before_grab = collision_mask
	collision_layer = 0
	_impact_tilt = Vector3.ZERO
	_stun_visual_active = false
	_stun_recovery_left = 0.0
	_stun_rotation_offset = Vector3.ZERO
	_stun_position_offset = Vector3.ZERO

	if _state == PlayerState.KNOCKED and grabbing_player.has_method("get_carry_point_global"):
		_last_grab_point_pos = grabbing_player.get_carry_point_global()
	else:
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
	_impact_tilt = Vector3.ZERO
	_set_body_color(stun_blink_color)
	_start_stun_visual()

func _start_stun_visual() -> void:
	_stun_visual_active = true
	_stun_sway_time = 0.0
	_stun_recovery_left = 0.0
	_stun_recovery_total = 0.0
	var local_dir := global_transform.basis.inverse() * _last_knockback_dir
	local_dir.y = 0.0
	if local_dir.length_squared() < 0.001:
		local_dir = Vector3.BACK
	local_dir = local_dir.normalized()
	_stun_reaction_tilt = Vector3(-local_dir.z, local_dir.x * 0.5, -local_dir.x) * stun_reaction_tilt

func _update_stun_visual(delta: float) -> void:
	if not _stun_visual_active or _visual == null:
		return
	_stun_sway_time += delta
	var sway_z := sin(_stun_sway_time * stun_sway_speed) * stun_sway_angle
	var sway_x := sin(_stun_sway_time * stun_sway_speed * 0.5) * stun_sway_angle * 0.5
	_stun_rotation_offset = _stun_reaction_tilt + Vector3(sway_x, 0.0, sway_z)
	_stun_position_offset = stun_visual_offset

func _update_stun_visual_recovery(delta: float) -> void:
	if _stun_recovery_left <= 0.0 or _stun_recovery_total <= 0.0:
		return
	_stun_recovery_left = maxf(_stun_recovery_left - delta, 0.0)
	var k := clampf(delta / _stun_recovery_total, 0.0, 1.0)
	_stun_rotation_offset = _stun_rotation_offset.lerp(Vector3.ZERO, k)
	_stun_position_offset = _stun_position_offset.lerp(Vector3.ZERO, k)

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
	_update_stun_visual(delta)

	if _stun_time_left <= 0.0:
		_state = PlayerState.NORMAL
		_restore_body_color()
		_stun_visual_active = false
		_stun_recovery_left = stun_recovery_time
		_stun_recovery_total = stun_recovery_time

func _start_knocked() -> void:
	_reset_head_visual()

	_state = PlayerState.KNOCKED
	_knockout_pending = false
	_recovering = false
	_recovery_time = 0.0
	_knocked_time_left = knocked_duration
	_knocked_timer_paused = false
	_charge_time = 0.0
	_horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)
	_impact_tilt = Vector3.ZERO
	if _visual != null:
		_visual.rotation = Vector3.ZERO
	_set_body_color(knockout_color)
	_start_knocked_fall()

func _update_knocked(delta: float) -> void:
	_horizontal_velocity = _horizontal_velocity.move_toward(Vector3.ZERO, knocked_friction * delta)
	_external_push = _external_push.move_toward(Vector3.ZERO, body_push_friction * delta)
	velocity.x = _horizontal_velocity.x + _external_push.x
	velocity.z = _horizontal_velocity.z + _external_push.z

	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	_update_knocked_progress(delta)

func _update_knocked_progress(delta: float) -> void:
	if not _knocked_timer_paused:
		_knocked_time_left -= delta

	if _recovering:
		_update_knocked_recovery(delta)
	else:
		_update_knocked_fall(delta)
		if _knocked_time_left <= 0.0:
			_begin_knocked_recovery()

func _recover_from_knocked() -> void:
	var grabber: Node3D = _grabbed_by
	release_from_being_grabbed()

	_state = PlayerState.NORMAL
	knockout_hits = 0
	_knocked_time_left = 0.0
	_knocked_timer_paused = false
	_recovering = false
	_recovery_time = 0.0
	_knocked_fall_start_angle = 0.0
	_horizontal_velocity = Vector3.ZERO
	_external_push = Vector3.ZERO
	velocity = Vector3.ZERO
	_restore_body_color()
	_reset_knocked_visual()

	if grabber != null and is_instance_valid(grabber) and grabber.has_method("release_grab_if_target"):
		grabber.release_grab_if_target(self)

func _start_knocked_fall() -> void:
	_knocked_visual_active = false

	if _visual == null or _cuy_model == null:
		return

	if _knocked_pivot == null or not is_instance_valid(_knocked_pivot):
		_knocked_pivot = Node3D.new()
		_knocked_pivot.name = "KnockedPivot"
		_visual.add_child(_knocked_pivot)
		_knocked_pivot.position = knocked_pivot_offset
		_cuy_model_local_transform = _cuy_model.transform
		_cuy_model.reparent(_knocked_pivot)

	var dir := Vector3(_horizontal_velocity.x, 0.0, _horizontal_velocity.z)
	if dir.length_squared() < 0.001:
		dir = -global_transform.basis.z
	dir = dir.normalized()

	var axis_world := -Vector3.UP.cross(dir).normalized()
	if axis_world.length_squared() < 0.001:
		axis_world = -Vector3.RIGHT

	_knocked_fall_axis = (_knocked_pivot.global_transform.basis.inverse() * axis_world).normalized()
	_knocked_fall_angle = 0.0
	_knocked_fall_time = 0.0
	_knocked_visual_active = true

func _update_knocked_fall(delta: float) -> void:
	if not _knocked_visual_active or _knocked_pivot == null or not is_instance_valid(_knocked_pivot):
		return

	_knocked_fall_time += delta
	var progress := clampf(_knocked_fall_time / knocked_fall_duration, 0.0, 1.0)
	var target_angle := _ease_out_cubic(progress) * (PI / 2.0)
	if not is_on_floor():
		target_angle = minf(target_angle, deg_to_rad(30.0))

	_knocked_fall_angle = move_toward(_knocked_fall_angle, target_angle, knocked_fall_speed * delta)
	_knocked_pivot.basis = Basis(_knocked_fall_axis, _knocked_fall_angle)

func _begin_knocked_recovery() -> void:
	_recovering = true
	_recovery_time = 0.0
	_knocked_fall_start_angle = _knocked_fall_angle

func _update_knocked_recovery(delta: float) -> void:
	if not _knocked_timer_paused:
		_recovery_time += delta

	var progress := clampf(_recovery_time / recovery_duration, 0.0, 1.0)
	var target_angle := lerpf(_knocked_fall_start_angle, 0.0, _ease_in_out_cubic(progress))
	_knocked_fall_angle = move_toward(_knocked_fall_angle, target_angle, knocked_recovery_speed * delta)

	if _knocked_pivot != null and is_instance_valid(_knocked_pivot):
		_knocked_pivot.basis = Basis(_knocked_fall_axis, _knocked_fall_angle)

	if progress >= 1.0 and absf(_knocked_fall_angle) < 0.01:
		_recover_from_knocked()

func _reset_knocked_visual() -> void:
	_knocked_visual_active = false
	_knocked_fall_time = 0.0
	_knocked_fall_angle = 0.0

	if _knocked_pivot != null and is_instance_valid(_knocked_pivot):
		_knocked_pivot.basis = Basis.IDENTITY
		if _visual != null and _cuy_model != null and is_instance_valid(_cuy_model):
			_cuy_model.reparent(_visual)
			_cuy_model.transform = _cuy_model_local_transform
		_knocked_pivot.queue_free()
		_knocked_pivot = null

	if _visual != null:
		_visual.rotation = Vector3.ZERO
		_visual.scale = Vector3.ONE

func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

func _ease_out_quart(t: float) -> float:
	return 1.0 - pow(1.0 - t, 4.0)

func _headbutt_curve(elapsed: float) -> float:
	var ant := maxf(headbutt_anticipation_time, 0.0001)
	var fwd := maxf(headbutt_forward_time, 0.0001)
	var hold := maxf(headbutt_hold_time, 0.0)
	var ret := maxf(headbutt_return_time, 0.0001)
	var t := elapsed

	if t < ant:
		return lerpf(0.0, -headbutt_anticipation_pull, _ease_out_cubic(t / ant))

	t -= ant
	if t < fwd:
		return lerpf(-headbutt_anticipation_pull, 1.0, _ease_out_quart(t / fwd))

	t -= fwd
	if t < hold:
		return 1.0

	t -= hold
	var p := clampf(t / ret, 0.0, 1.0)
	return (1.0 - p) * cos(p * PI * (1.0 + headbutt_rebound))

func _ease_in_out_cubic(t: float) -> float:
	if t < 0.5:
		return 4.0 * t * t * t
	return 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0

func set_knocked_timer_paused(paused: bool) -> void:
	_knocked_timer_paused = paused

func apply_knockback(direction: Vector3, force: float, up_force: float, stun := true, duration := -1.0, knock_out := false, tilt_strength := 0.0, immediate_knockdown := false) -> void:
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
	_last_knockback_dir = knockback_direction
	_horizontal_velocity = Vector3.ZERO
	_external_push = Vector3.ZERO
	velocity = knockback_direction * force
	velocity.y = up_force + force * 0.15

	if immediate_knockdown:
		_start_knocked()
		return

	_knockback_time_left = knockback_duration if duration <= 0.0 else duration
	_stun_pending = stun and not knock_out
	if knock_out:
		_knockout_pending = true
	_stun_visual_active = false
	_stun_recovery_left = 0.0
	_stun_rotation_offset = Vector3.ZERO
	_stun_position_offset = Vector3.ZERO
	_state = PlayerState.KNOCKBACK

	_headbutt_active = false
	_headbutt_k = 0.0
	_hit_reaction_left = hit_reaction_duration
	_hit_reaction_total = hit_reaction_duration
	_hit_reaction_sign = 1.0 if randf() < 0.5 else -1.0

	if tilt_strength > 0.0:
		var local_dir := global_transform.basis.inverse() * knockback_direction
		local_dir.y = 0.0
		_impact_tilt = Vector3(-local_dir.z, local_dir.x * 0.5, -local_dir.x) * tilt_strength

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
		_collision_shape.set_deferred("disabled", true)

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
		body.apply_knockback(hit_direction, tackle_knockback, tackle_knockback_up, true, -1.0, false, tackle_tilt)

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
