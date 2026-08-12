extends RigidBody3D

## Base reusable for physical objects that will support interactions later.
class_name InteractableObject

const PlayerScript := preload("res://entities/player/player.gd")

## Emitted when a player enters this object's interaction range.
signal player_entered_interaction_range(player: CharacterBody3D)

## Emitted when a player leaves this object's interaction range.
signal player_exited_interaction_range(player: CharacterBody3D)

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
## Velocidad lineal mínima del objeto para considerarlo un proyectil (objeto
## lanzado). Por debajo de este umbral el impacto usa el knockback normal.
@export var projectile_speed_threshold := 8.0
## Velocidad (m/s) que pierde cada segundo la "velocidad de vuelo" del objeto
## tras un lanzamiento. Mantiene al objeto como proyectil durante un breve
## periodo después de ser lanzado (el solver ya deceleró al objeto en el frame
## del contacto, así que no se puede leer la velocidad instantánea).
@export var projectile_speed_decay := 6.0
## Fuerza horizontal del lanzamiento que derriba (KNOCKED) al jugador cuando un
## objeto lanzado lo impacta directamente.
@export var projectile_knockback_force := 16.0
## Fuerza vertical del lanzamiento que derriba (KNOCKED) al jugador.
@export var projectile_knockback_up_force := 4.0

## Escena VFX común al agarrar el objeto (flash + partículas). Puramente visual.
@export var grab_vfx_scene: PackedScene
## Escena VFX común al lanzar el objeto (burst de velocidad). Puramente visual.
@export var throw_vfx_scene: PackedScene
## Escena de trail corto adjunta al objeto mientras vuela como proyectil. Opcional.
@export var flight_trail_scene: PackedScene
## Escena VFX común cuando el objeto impacta a un jugador (flash + ring + polvo).
@export var impact_vfx_scene: PackedScene

## Puntos de conexión de audio (opcionales). Si quedan en null no se reproduce
## nada: el sistema está preparado para que se asignen assets posteriormente.
@export var grab_sfx: AudioStream
@export var throw_sfx: AudioStream
@export var impact_sfx: AudioStream

var _nearby_players: Array[CharacterBody3D] = []
var _grabbed_player: CharacterBody3D
var _is_grabbed := false
var _collision_layer_before_grab := 1
var _last_impact_knockback_times := {}
var _projectile_speed := 0.0
## True mientras el objeto está en vuelo tras ser lanzado por un jugador.
## Permite reconocer impactos reales de proyectiles aunque el primer frame del
## contacto reporte impulso 0 (ver get_contact_impulse / bug de Godot #73541).
var _is_projectile := false
## Jugador que lanzó este objeto. Mientras el objeto vuela como proyectil, ese
## jugador queda excluido del impacto de su propio objeto; los demás jugadores
## sí reciben el golpe. Se limpia cuando el objeto deja de ser proyectil.
var _last_thrower: CharacterBody3D
## Nodo trail temporal adjunto al objeto mientras vuela (se elimina solo).
var _flight_trail: Node3D


func _ready() -> void:
	add_to_group("interactable_objects")
	$InteractionArea.body_entered.connect(_on_interaction_area_body_entered)
	$InteractionArea.body_exited.connect(_on_interaction_area_body_exited)


## Returns true while at least one CharacterBody3D is inside the interaction area.
func has_player_in_interaction_range() -> bool:
	return not _nearby_players.is_empty()


func is_grabbed_by(player: CharacterBody3D) -> bool:
	return _is_grabbed and _grabbed_player == player


## Kevin grab protocol: marca este objeto como proyectil en vuelo. El jugador lo
## llama justo después de aplicar el impulso de lanzamiento para que el primer
## contacto físico real cuente como impacto derribante, sin depender del impulso
## reportado por el solver (que es 0 en el primer frame de contacto). El lanzador
## (thrower) queda temporalmente excluido del impacto de su propio objeto.
func mark_thrown(thrower: CharacterBody3D) -> void:
	_is_projectile = true
	_last_thrower = thrower
	_projectile_speed = maxf(_projectile_speed, linear_velocity.length())
	_play_throw_feedback()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_projectile_speed = maxf(_projectile_speed - projectile_speed_decay * state.step, 0.0)
	_projectile_speed = maxf(_projectile_speed, linear_velocity.length())
	if _projectile_speed < projectile_speed_threshold:
		_is_projectile = false
		_last_thrower = null
		_stop_flight_trail()
	_apply_impact_knockback(state)


## Detecta contactos físicos reales con jugadores y les aplica el knockback
## configurado (impact_knockback_force).
##
## Si el objeto viaja como proyectil (marcado por mark_thrown() o velocidad >=
## projectile_speed_threshold) el impacto derriba directamente al jugador
## (KNOCKED inmediato + lanzamiento): caída directa, sin reacción de golpe ni
## estado KNOCKBACK previo.
##
## Usa el mecanismo físico existente de Godot (contactos reportados en
## PhysicsDirectBodyState3D), no la proximidad. Se ejecuta una vez por impacto
## (con cooldown por jugador) para no spamear knockbacks mientras los cuerpos
## siguen en contacto.
func _apply_impact_knockback(state: PhysicsDirectBodyState3D) -> void:
	if freeze or _is_grabbed:
		return
	if state.get_contact_count() <= 0:
		return

	var thrown := _is_projectile or _projectile_speed >= projectile_speed_threshold
	if not thrown and impact_knockback_force <= 0.0:
		return

	var now := Time.get_ticks_msec() / 1000.0

	for contact_index in state.get_contact_count():
		var impulse := state.get_contact_impulse(contact_index).length()
		# get_contact_impulse() devuelve 0 en el primer frame del contacto (bug
		# de Godot #73541), lo que ocurría con los lanzamientos lejanos. Un
		# proyectil en vuelo cuenta como impacto real por estar en contacto.
		if impulse < impact_knockback_threshold and not thrown:
			continue

		var collider: Object = state.get_contact_collider_object(contact_index)
		if collider == null or not (collider is CharacterBody3D):
			continue
		if not collider.has_method("apply_knockback"):
			continue

		# Mientras es proyectil, el objeto ignora temporalmente a quien lo lanzó
		# (evita que P1 quede KNOCKED por su propio objeto). El resto de jugadores
		# siguen recibiendo el impacto normalmente.
		if thrown and _last_thrower != null \
				and is_instance_valid(_last_thrower) and collider == _last_thrower:
			continue

		var player := collider as CharacterBody3D
		var player_id := player.get_instance_id()
		if _last_impact_knockback_times.has(player_id):
			var last_time: float = _last_impact_knockback_times[player_id]
			if now - last_time < impact_knockback_cooldown:
				continue

		_last_impact_knockback_times[player_id] = now

		_play_player_impact_vfx(player)

		var direction := player.global_position - global_position
		direction.y = 0.0
		if direction.length_squared() < 0.0001:
			direction = -player.global_transform.basis.z

		if thrown:
			player.apply_knockback(
				direction.normalized(),
				projectile_knockback_force,
				projectile_knockback_up_force,
				false,
				-1.0,
				true,
				0.0,
				true
			)
			_is_projectile = false
			_projectile_speed = 0.0
		else:
			player.apply_knockback(direction.normalized(), impact_knockback_force, 0.0, false)


## --- Feedback visual/audiovisual común (solo visual, no toca física) ---

func _play_grab_feedback() -> void:
	ObjectVFX.spawn_vfx(self, grab_vfx_scene, global_position)
	ObjectVFX.play_sfx(self, grab_sfx, global_position)


func _play_throw_feedback() -> void:
	var direction := linear_velocity
	direction.y = 0.0

	var vfx := ObjectVFX.spawn_vfx(self, throw_vfx_scene, global_position)
	if vfx != null and vfx.has_method("face_direction"):
		vfx.face_direction(direction)

	ObjectVFX.play_sfx(self, throw_sfx, global_position)
	_start_flight_trail()


func _play_player_impact_vfx(player: CharacterBody3D) -> void:
	if player == null:
		return
	var impact_position := player.global_position + Vector3.UP * 0.4
	ObjectVFX.spawn_vfx(self, impact_vfx_scene, impact_position)
	ObjectVFX.play_sfx(self, impact_sfx, impact_position)


func _start_flight_trail() -> void:
	if flight_trail_scene == null or _flight_trail != null:
		return

	_flight_trail = ObjectVFX.attach_vfx(self, flight_trail_scene)
	if _flight_trail != null and _flight_trail.has_method("start_trail"):
		_flight_trail.start_trail()


func _stop_flight_trail() -> void:
	if _flight_trail == null:
		return
	if not is_instance_valid(_flight_trail):
		_flight_trail = null
		return

	var trail := _flight_trail
	_flight_trail = null
	if trail.has_method("stop_trail"):
		trail.stop_trail()


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
	_projectile_speed = 0.0
	_is_projectile = false
	_last_thrower = null

	_collision_layer_before_grab = collision_layer
	collision_layer = 0
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	_stop_flight_trail()
	_play_grab_feedback()


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
