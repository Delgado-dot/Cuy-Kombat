extends Node

enum MusicType {
	NONE,
	MENU,
	ARENA
}

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

const MENU_TRACKS: Array[String] = [
	"res://assets/audio/Menu1.mp3",
	"res://assets/audio/Menu2.mp3",
	"res://assets/audio/Menu3.mp3"
]

const ARENA_TRACKS: Array[String] = [
	"res://assets/audio/Arena1.mp3",
	"res://assets/audio/Arena2.mp3",
	"res://assets/audio/Arena3.mp3",
	"res://assets/audio/Arena4.mp3",
	"res://assets/audio/Arena5.mp3",
	"res://assets/audio/Arena6.mp3",
	"res://assets/audio/Arena7.mp3",
	"res://assets/audio/Arena8.mp3",
	"res://assets/audio/Arena9.mp3"
]

var _audio_player: AudioStreamPlayer
var _current_type := MusicType.NONE
var _current_track_path := ""
var _last_menu_track := ""
var _last_arena_track := ""
var _volume_linear := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = MUSIC_BUS
	add_child(_audio_player)
	_apply_volume()


func play_random_menu_music() -> void:
	_play_random_from_list(MENU_TRACKS, MusicType.MENU)


func play_random_arena_music() -> void:
	_play_random_from_list(ARENA_TRACKS, MusicType.ARENA)


func play_menu_music() -> void:
	if _current_type == MusicType.MENU and _audio_player.playing:
		return
	play_random_menu_music()


func play_arena_music() -> void:
	play_random_arena_music()


func change_track(stream_path: String, type: MusicType = MusicType.NONE) -> void:
	if stream_path == "":
		stop_music()
		return

	var stream = load(stream_path)
	if stream == null:
		push_error("MusicManager: No se pudo cargar el stream en: " + stream_path)
		return

	_audio_player.stop()
	_audio_player.stream = stream
	_audio_player.play()
	_current_type = type
	_current_track_path = stream_path

	if type == MusicType.MENU:
		_last_menu_track = stream_path
	elif type == MusicType.ARENA:
		_last_arena_track = stream_path


func stop_music() -> void:
	_audio_player.stop()
	_audio_player.stream = null
	_current_type = MusicType.NONE
	_current_track_path = ""


func set_volume(volume_linear: float) -> void:
	_volume_linear = clampf(volume_linear, 0.0, 1.0)
	_apply_volume()


func get_volume() -> float:
	return _volume_linear


func _ensure_audio_bus(bus_name: StringName) -> int:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		return bus_index

	AudioServer.add_bus()
	bus_index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, MASTER_BUS)
	return bus_index


func _apply_volume() -> void:
	var bus_index := _ensure_audio_bus(MUSIC_BUS)
	AudioServer.set_bus_mute(bus_index, _volume_linear <= 0.0001)
	if _volume_linear > 0.0001:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(_volume_linear))
	if _audio_player != null:
		_audio_player.volume_db = 0.0


func _play_random_from_list(tracks: Array[String], type: MusicType) -> void:
	if tracks.is_empty():
		return

	var available_tracks = tracks.duplicate()
	var last_track = _last_menu_track if type == MusicType.MENU else _last_arena_track

	if available_tracks.size() > 1 and last_track != "":
		available_tracks.erase(last_track)

	var random_index := randi() % available_tracks.size()
	var chosen_track: String = available_tracks[random_index]

	change_track(chosen_track, type)
