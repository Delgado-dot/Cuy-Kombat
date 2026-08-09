extends CharacterBody3D

signal eliminated(player: Node)

enum PlayerState {
	NORMAL,
	ATTACKING,
	KNOCKBACK,
	STUNNED,
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
var _punch_effect_time := 0.0
var _punch_effect_material: StandardMaterial3D
var _body_material: StandardMaterial3D

@onready var _camera_pivot := get_node_or_null("CameraPivot") as Node3D
@onready var _tackle_hitbox := get_node_or_null("TackleHitbox") as Area3D
@onready var _punch_hitbox := get_node_or_null("PunchHitbox") as Area3D
@onready var _punch_effect := get_node_or_null("PunchEffect") as MeshInstance3D
@onready var _collision_shape := get_node_or_null("CollisionShape3D") as CollisionShape3D
@onready var _visual := get_node_or_null("Visual") as Node3D
@onready var _body_mesh := get_node_or_null("Visual/Body") as MeshInstance3D
@onready var _charge_bar := get_node_or_null("Visual/ChargeBar") as Node3D
@onready var _charge_fill := get_node_or_null("Visual/ChargeBar/Fill") as MeshInstance3D

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

	if _state == PlayerState.ATTACKING:
		_update_tackle(delta)
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
	_try_start_punch()
	_face_move_direction(move_direction, delta)
	move_and_slide()
	_push_colliding_players()
	_update_visual_motion(delta, move_direction)

func _ready() -> void:
	_was_on_floor = is_on_floor()
	_apply_player_color()
	_setup_punch_effect()
	_update_charge_bar(0.0, false)

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

func _update_punch(delta: float) -> void:
	if _punch_active_left <= 0.0:
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
		if _stun_pending:
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

func apply_knockback(direction: Vector3, force: float, up_force: float, stun := true, duration := -1.0) -> void:
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
	if _body_mesh == null:
		return

	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = player_color
	_body_material.roughness = 0.65
	_body_mesh.set_surface_override_material(0, _body_material)

func _update_stun_blink(delta: float) -> void:
	if _body_material == null:
		return

	_stun_blink_time += delta
	var blink_phase := int(_stun_blink_time * stun_blink_frequency * 2.0) % 2
	_set_body_color(stun_blink_color if blink_phase == 0 else player_color)

func _set_body_color(color: Color) -> void:
	if _body_material != null:
		_body_material.albedo_color = color

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
