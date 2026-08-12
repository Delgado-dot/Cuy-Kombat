@tool
extends Node

## Configuración de animaciones para P1 (conejo_andino)
## Ejecutar en el editor: seleccionar el nodo AnimationPlayer y ejecutar este script

@export var generate_animations: bool = false

## Nombres de los 20 huesos del modelo (ordenados según la auditoría)
const BONE_NAMES = [
	"Root",
	"Pelvis",
	"Spine",
	"Chest",
	"Neck",
	"Head",
	"Ear_L",
	"Ear_L_Tip",
	"Ear_R",
	"Ear_R_Tip",
	"Leg_L",
	"Foot_L",
	"Leg_R",
	"Foot_R",
	"Arm_L",
	"Forearm_L",
	"Hand_L",
	"Arm_R",
	"Forearm_R",
	"Hand_R"
]

## Rutas de huesos relativas al root_node del AnimationPlayer
func _get_bone_paths(skeleton_path: NodePath) -> Array[NodePath]:
	var paths = []
	for name in BONE_NAMES:
		paths.append(skeleton_path.subpath(name))
	return paths

## Crear una animación vacía con tracks para todos los huesos
func _create_animation(anim_player: AnimationPlayer, name: str, length: float, loop: bool = false) -> Animation:
	var anim = Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	anim_player.add_animation(name, anim)
	return anim

## Añadir tracks de transformación para todos los huesos
func _add_bone_tracks(anim: Animation, bone_paths: Array[NodePath]):
	for path in bone_paths:
		anim.add_track(Animation.TYPE_TRANSFORM)
		anim.track_set_path(anim.get_track_count() - 1, path)

## Insertar keyframe de transformación en un track
func _set_keyframe(anim: Animation, track_idx: int, time: float, location: Vector3 = Vector3.ZERO, rotation: Quaternion = Quaternion.IDENTITY, scale: Vector3 = Vector3.ONE):
	anim.track_insert_key(track_idx, time, location, rotation, scale)

## Obtener pose de referencia (pose inicial del modelo)
func _get_reference_pose(anim_player: AnimationPlayer, bone_paths: Array[NodePath]) -> Array[Dictionary]:
	var poses = []
	var skel = anim_player.get_node_or_null(NodePath("Visual/CuyModel/CuyCharacter/Character_Rig"))
	if not skel:
		skel = anim_player.get_node_or_null(NodePath("Visual/CuyModel/CuyCharacter"))
	
	for path in bone_paths:
		var bone = anim_player.get_node_or_null(path)
		if bone:
			poses.append({
				"location": bone.global_position - skel.global_position,
				"rotation": bone.global_rotation,
				"scale": bone.scale
			})
		else:
			poses.append({"location": Vector3.ZERO, "rotation": Quaternion.IDENTITY, "scale": Vector3.ONE})
	return poses

## Generar todas las animaciones base
func _generate_all_animations(anim_player: AnimationPlayer):
	var skeleton_path = NodePath("Visual/CuyModel/CuyCharacter/Character_Rig")
	var bone_paths = _get_bone_paths(skeleton_path)
	
	print("Generando animaciones para P1...")
	
	# 1. IDLE (loop, 2.0s)
	var idle = _create_animation(anim_player, "Idle", 2.0, true)
	_add_bone_tracks(idle, bone_paths)
	# Pose neutra - solo micro-movimiento sutil de respiración
	for i in range(bone_paths.size()):
		_set_keyframe(idle, i, 0.0)
		_set_keyframe(idle, i, 1.0, Vector3(0, sin(1.0)*0.005, 0))
		_set_keyframe(idle, i, 2.0)
	
	# 2. WALK (loop, 1.0s)
	var walk = _create_animation(anim_player, "Walk", 1.0, true)
	_add_bone_tracks(walk, bone_paths)
	# Ciclo de caminata básico
	# Piernas alternadas
	_set_keyframe(walk, bone_paths.find("Leg_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	_set_keyframe(walk, bone_paths.find("Foot_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.1))
	_set_keyframe(walk, bone_paths.find("Leg_R"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	_set_keyframe(walk, bone_paths.find("Foot_R"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.1))
	
	_set_keyframe(walk, bone_paths.find("Leg_L"), 0.5, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	_set_keyframe(walk, bone_paths.find("Foot_L"), 0.5, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.1))
	_set_keyframe(walk, bone_paths.find("Leg_R"), 0.5, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	_set_keyframe(walk, bone_paths.find("Foot_R"), 0.5, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.1))
	
	_set_keyframe(walk, bone_paths.find("Leg_L"), 1.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	_set_keyframe(walk, bone_paths.find("Foot_L"), 1.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.1))
	_set_keyframe(walk, bone_paths.find("Leg_R"), 1.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	_set_keyframe(walk, bone_paths.find("Foot_R"), 1.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.1))
	
	# Brazos opuestos a piernas
	_set_keyframe(walk, bone_paths.find("Arm_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.2))
	_set_keyframe(walk, bone_paths.find("Arm_R"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.2))
	_set_keyframe(walk, bone_paths.find("Arm_L"), 0.5, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.2))
	_set_keyframe(walk, bone_paths.find("Arm_R"), 0.5, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.2))
	_set_keyframe(walk, bone_paths.find("Arm_L"), 1.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.2))
	_set_keyframe(walk, bone_paths.find("Arm_R"), 1.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.2))
	
	# 3. RUN (loop, 0.7s)
	var run = _create_animation(anim_player, "Run", 0.7, true)
	_add_bone_tracks(run, bone_paths)
	# Ciclo de carrera más rápido y amplio
	_set_keyframe(run, bone_paths.find("Leg_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.6))
	_set_keyframe(run, bone_paths.find("Foot_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	_set_keyframe(run, bone_paths.find("Leg_R"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.6))
	_set_keyframe(run, bone_paths.find("Foot_R"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	
	_set_keyframe(run, bone_paths.find("Leg_L"), 0.35, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.6))
	_set_keyframe(run, bone_paths.find("Foot_L"), 0.35, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	_set_keyframe(run, bone_paths.find("Leg_R"), 0.35, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.6))
	_set_keyframe(run, bone_paths.find("Foot_R"), 0.35, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	
	_set_keyframe(run, bone_paths.find("Leg_L"), 0.7, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.6))
	_set_keyframe(run, bone_paths.find("Foot_L"), 0.7, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	_set_keyframe(run, bone_paths.find("Leg_R"), 0.7, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.6))
	_set_keyframe(run, bone_paths.find("Foot_R"), 0.7, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	
	# Brazos más amplios
	_set_keyframe(run, bone_paths.find("Arm_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.5))
	_set_keyframe(run, bone_paths.find("Forearm_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	_set_keyframe(run, bone_paths.find("Arm_R"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.5))
	_set_keyframe(run, bone_paths.find("Forearm_R"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	
	_set_keyframe(run, bone_paths.find("Arm_L"), 0.35, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.5))
	_set_keyframe(run, bone_paths.find("Forearm_L"), 0.35, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	_set_keyframe(run, bone_paths.find("Arm_R"), 0.35, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.5))
	_set_keyframe(run, bone_paths.find("Forearm_R"), 0.35, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	
	_set_keyframe(run, bone_paths.find("Arm_L"), 0.7, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.5))
	_set_keyframe(run, bone_paths.find("Forearm_L"), 0.7, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	_set_keyframe(run, bone_paths.find("Arm_R"), 0.7, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.5))
	_set_keyframe(run, bone_paths.find("Forearm_R"), 0.7, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	
	# Inclinación del cuerpo hacia adelante
	_set_keyframe(run, bone_paths.find("Chest"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.15))
	_set_keyframe(run, bone_paths.find("Chest"), 0.35, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.15))
	_set_keyframe(run, bone_paths.find("Chest"), 0.7, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.15))
	
	# 4. JUMP (no loop, 1.2s)
	var jump = _create_animation(anim_player, "Jump", 1.2, false)
	_add_bone_tracks(jump, bone_paths)
	
	# Preparación (0.0-0.3s): agacharse
	_set_keyframe(jump, bone_paths.find("Pelvis"), 0.0)
	_set_keyframe(jump, bone_paths.find("Leg_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.4))
	_set_keyframe(jump, bone_paths.find("Leg_R"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.4))
	_set_keyframe(jump, bone_paths.find("Foot_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.2))
	_set_keyframe(jump, bone_paths.find("Foot_R"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.2))
	_set_keyframe(jump, bone_paths.find("Arm_L"), 0.0, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.5))
	_set_keyframe(jump, jump.get_track_count() - 1, 0.0) # placeholder
	
	# Subida (0.3-0.5s): extensión completa
	# ... (keyframes de subida)
	
	# Caída (0.5-0.9s): en el aire
	# ...
	
	# Aterrizaje (0.9-1.2s): absorción
	# ...
	
	# Para simplificar, marcamos keyframes básicos
	_set_keyframe(jump, bone_paths.find("Pelvis"), 0.3, Vector3(0, 0.5, 0))
	_set_keyframe(jump, bone_paths.find("Pelvis"), 0.6, Vector3(0, 1.2, 0))
	_set_keyframe(jump, bone_paths.find("Pelvis"), 0.9, Vector3(0, 0.3, 0))
	_set_keyframe(jump, bone_paths.find("Pelvis"), 1.2)
	
	# 5. PUNCH (no loop, 0.5s)
	var punch = _create_animation(anim_player, "Punch", 0.5, false)
	_add_bone_tracks(punch, bone_paths)
	# Golpe con brazo derecho
	_set_keyframe(punch, bone_paths.find("Arm_R"), 0.0)
	_set_keyframe(punch, bone_paths.find("Forearm_R"), 0.0)
	_set_keyframe(punch, bone_paths.find("Hand_R"), 0.0)
	
	_set_keyframe(punch, bone_paths.find("Arm_R"), 0.1, Vector3.ZERO, Quaternion(Vector3.RIGHT, -1.2))
	_set_keyframe(punch, bone_paths.find("Forearm_R"), 0.1, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.5))
	
	_set_keyframe(punch, bone_paths.find("Arm_R"), 0.25, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.0))
	_set_keyframe(punch, bone_paths.find("Forearm_R"), 0.25, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.0))
	
	_set_keyframe(punch, bone_paths.find("Arm_R"), 0.5)
	_set_keyframe(punch, bone_paths.find("Forearm_R"), 0.5)
	
	# 6. TACKLE (no loop, 0.8s)
	var tackle = _create_animation(anim_player, "Tackle", 0.8, false)
	_add_bone_tracks(tackle, bone_paths)
	# Inclinación completa del cuerpo hacia adelante
	_set_keyframe(tackle, bone_paths.find("Chest"), 0.0)
	_set_keyframe(tackle, bone_paths.find("Chest"), 0.2, Vector3.ZERO, Quaternion(Vector3.RIGHT, 1.0))
	_set_keyframe(tackle, bone_paths.find("Chest"), 0.6, Vector3.ZERO, Quaternion(Vector3.RIGHT, 1.0))
	_set_keyframe(tackle, bone_paths.find("Chest"), 0.8)
	
	# Brazos extendidos hacia adelante
	_set_keyframe(tackle, bone_paths.find("Arm_L"), 0.0)
	_set_keyframe(tackle, bone_paths.find("Arm_R"), 0.0)
	_set_keyframe(tackle, bone_paths.find("Forearm_L"), 0.0)
	_set_keyframe(tackle, bone_paths.find("Forearm_R"), 0.0)
	
	_set_keyframe(tackle, bone_paths.find("Arm_L"), 0.2, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	_set_keyframe(tackle, bone_paths.find("Arm_R"), 0.2, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.3))
	_set_keyframe(tackle, bone_paths.find("Forearm_L"), 0.2, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.2))
	_set_keyframe(tackle, bone_paths.find("Forearm_R"), 0.2, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.2))
	
	# 7. GRAB (no loop, 0.6s)
	var grab = _create_animation(anim_player, "Grab", 0.6, false)
	_add_bone_tracks(grab, bone_paths)
	# Brazos extendidos para agarre
	_set_keyframe(grab, bone_paths.find("Arm_L"), 0.0)
	_set_keyframe(grab, bone_paths.find("Arm_R"), 0.0)
	_set_keyframe(grab, bone_paths.find("Forearm_L"), 0.0)
	_set_keyframe(grab, bone_paths.find("Forearm_R"), 0.0)
	
	_set_keyframe(grab, bone_paths.find("Arm_L"), 0.2, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.5))
	_set_keyframe(grab, bone_paths.find("Arm_R"), 0.2, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.5))
	_set_keyframe(grab, bone_paths.find("Forearm_L"), 0.2, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	_set_keyframe(grab, bone_paths.find("Forearm_R"), 0.2, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.3))
	_set_keyframe(grab, bone_paths.find("Hand_L"), 0.2, Vector3.ZERO, Quaternion(Vector3.UP, 0.5))
	_set_keyframe(grab, bone_paths.find("Hand_R"), 0.2, Vector3.ZERO, Quaternion(Vector3.UP, -0.5))
	
	_set_keyframe(grab, bone_paths.find("Arm_L"), 0.4)
	_set_keyframe(grab, bone_paths.find("Arm_R"), 0.4)
	_set_keyframe(grab, bone_paths.find("Forearm_L"), 0.4)
	_set_keyframe(grab, bone_paths.find("Forearm_R"), 0.4)
	_set_keyframe(grab, bone_paths.find("Hand_L"), 0.4)
	_set_keyframe(grab, bone_paths.find("Hand_R"), 0.4)
	
	_set_keyframe(grab, bone_paths.find("Arm_L"), 0.6)
	_set_keyframe(grab, bone_paths.find("Arm_R"), 0.6)
	_set_keyframe(grab, bone_paths.find("Forearm_L"), 0.6)
	_set_keyframe(grab, bone_paths.find("Forearm_R"), 0.6)
	_set_keyframe(grab, bone_paths.find("Hand_L"), 0.6)
	_set_keyframe(grab, bone_paths.find("Hand_R"), 0.6)
	
	# 8. KNOCKED (no loop, 1.5s)
	var knocked = _create_animation(anim_player, "Knocked", 1.5, false)
	_add_bone_tracks(knocked, bone_paths)
	# Caída lateral
	_set_keyframe(knocked, bone_paths.find("Pelvis"), 0.0)
	_set_keyframe(knocked, bone_paths.find("Chest"), 0.0)
	_set_keyframe(knocked, bone_paths.find("Head"), 0.0)
	
	_set_keyframe(knocked, bone_paths.find("Pelvis"), 0.3, Vector3(0.5, -0.5, 0), Quaternion(Vector3.FORWARD, 1.57))
	_set_keyframe(knocked, bone_paths.find("Chest"), 0.3, Vector3.ZERO, Quaternion(Vector3.FORWARD, 1.57))
	_set_keyframe(knocked, bone_paths.find("Head"), 0.3, Vector3.ZERO, Quaternion(Vector3.RIGHT, 0.5))
	
	# Brazos y piernas relajados
	for name in ["Arm_L", "Arm_R", "Forearm_L", "Forearm_R", "Leg_L", "Leg_R", "Foot_L", "Foot_R"]:
		_set_keyframe(knocked, bone_paths.find(name), 0.3, Vector3.ZERO, Quaternion(Vector3.RIGHT, -0.1))
	
	_set_keyframe(knocked, bone_paths.find("Pelvis"), 1.5, Vector3(0.5, -0.5, 0), Quaternion(Vector3.FORWARD, 1.57))
	
	# 9. GETUP (no loop, 1.0s)
	var getup = _create_animation(anim_player, "GetUp", 1.0, false)
	_add_bone_tracks(getup, bone_paths)
	# Levantarse desde Knocked
	_set_keyframe(getup, bone_paths.find("Pelvis"), 0.0, Vector3(0.5, -0.5, 0), Quaternion(Vector3.FORWARD, 1.57))
	_set_keyframe(getup, bone_paths.find("Chest"), 0.0, Vector3.ZERO, Quaternion(Vector3.FORWARD, 1.57))
	
	_set_keyframe(getup, bone_paths.find("Pelvis"), 0.5, Vector3(0, 0.2, 0), Quaternion(Vector3.FORWARD, 0.5))
	_set_keyframe(getup, bone_paths.find("Chest"), 0.5, Vector3.ZERO, Quaternion(Vector3.FORWARD, 0.5))
	
	_set_keyframe(getup, bone_paths.find("Pelvis"), 1.0)
	_set_keyframe(getup, bone_paths.find("Chest"), 1.0)
	
	print("¡Todas las animaciones generadas!")
	
	# Guardar las animaciones como recursos .tres
	_save_animations(anim_player)

func _save_animations(anim_player: AnimationPlayer):
	var anim_names = anim_player.get_animation_list()
	for name in anim_names:
		var anim = anim_player.get_animation(name)
		var path = "res://entities/player/animations/%s.tres" % name
		ResourceSaver.save(anim, path)
		print("Guardada: %s" % path)

## Función principal para ejecutar en el editor
func _ready():
	if Engine.is_editor_hint() and generate_animations:
		var anim_player = get_node_or_null("AnimationPlayer")
		if anim_player:
			_generate_all_animations(anim_player)
			generate_animations = false
			print("¡Configuración de animaciones completada!")
		else:
			print("ERROR: No se encontró AnimationPlayer")

## Para ejecutar manualmente desde el inspector
func _on_generate_animations():
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player:
		_generate_all_animations(anim_player)
		print("¡Animaciones generadas manualmente!")
