extends CanvasLayer

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

@export var open_button_path: NodePath

@onready var _options_root := %OptionsScreen as Control
@onready var _back_button := %OptionsBackButton as Button
@onready var _master_slider := %MasterVolumeSlider as HSlider
@onready var _music_slider := %MusicVolumeSlider as HSlider
@onready var _sfx_slider := %SfxVolumeSlider as HSlider
@onready var _master_value := %MasterVolumeValue as Label
@onready var _music_value := %MusicVolumeValue as Label
@onready var _sfx_value := %SfxVolumeValue as Label
@onready var _fullscreen_toggle := %FullscreenToggle as CheckButton
@onready var _title_label := %Title as Label

var _open_button: Button
var _time_accumulator := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_options_root.visible = false
	_back_button.pressed.connect(close)
	_master_slider.value_changed.connect(_on_master_volume_changed)
	_music_slider.value_changed.connect(_on_music_volume_changed)
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

	_open_button = get_node_or_null(open_button_path) as Button if not open_button_path.is_empty() else null
	if _open_button != null:
		_open_button.pressed.connect(open)

	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_sync_controls()


func _input(event: InputEvent) -> void:
	if not _options_root.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if event is InputEventKey and event.echo:
			return
		get_viewport().set_input_as_handled()
		close()


func open(_from_screen: Node = null) -> void:
	_options_root.visible = true
	_sync_controls()
	_back_button.grab_focus()


func close() -> void:
	_options_root.visible = false


func _process(delta: float) -> void:
	if not _options_root.visible:
		return
	_time_accumulator += delta
	var pulse := (sin(_time_accumulator * 2.0) + 1.0) * 0.5
	_title_label.add_theme_color_override(
		"font_color",
		Color(1, 0.18, 0.62, 1).lerp(Color(1, 0.38, 0.76, 1), pulse)
	)


func _ensure_audio_bus(bus_name: StringName) -> int:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		return bus_index
	AudioServer.add_bus()
	bus_index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, MASTER_BUS)
	return bus_index


func _sync_controls() -> void:
	_master_slider.set_value_no_signal(_get_bus_volume_percent(MASTER_BUS))
	_music_slider.set_value_no_signal(_get_bus_volume_percent(MUSIC_BUS))
	_sfx_slider.set_value_no_signal(_get_bus_volume_percent(SFX_BUS))
	_update_volume_value(_master_value, _master_slider.value)
	_update_volume_value(_music_value, _music_slider.value)
	_update_volume_value(_sfx_value, _sfx_slider.value)

	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	_fullscreen_toggle.set_pressed_no_signal(is_fullscreen)
	_update_fullscreen_text(is_fullscreen)


func _get_bus_volume_percent(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0 or AudioServer.is_bus_mute(bus_index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100.0, 0.0, 100.0)


func _set_bus_volume_percent(bus_name: StringName, value: float) -> void:
	var bus_index := _ensure_audio_bus(bus_name)
	var normalized := clampf(value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, normalized <= 0.0001)
	if normalized > 0.0001:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(normalized))


func _on_master_volume_changed(value: float) -> void:
	_set_bus_volume_percent(MASTER_BUS, value)
	_update_volume_value(_master_value, value)


func _on_music_volume_changed(value: float) -> void:
	MusicManager.set_volume(value / 100.0)
	_update_volume_value(_music_value, value)


func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume_percent(SFX_BUS, value)
	_update_volume_value(_sfx_value, value)


func _update_volume_value(label: Label, value: float) -> void:
	label.text = "%d%%" % roundi(value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_update_fullscreen_text(enabled)


func _update_fullscreen_text(enabled: bool) -> void:
	_fullscreen_toggle.text = "ON" if enabled else "OFF"
