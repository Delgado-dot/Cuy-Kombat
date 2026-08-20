extends CanvasLayer

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

@export var game_manager_path: NodePath

@onready var _pause_menu := %PauseMenu as Control
@onready var _pause_panel := %PausePanel as Control
@onready var _options_panel := %PauseOptionsPanel as Control
@onready var _resume_button := %ResumeButton as Button
@onready var _restart_button := %RestartButton as Button
@onready var _pause_options_button := %PauseOptionsButton as Button
@onready var _pause_main_menu_button := %PauseMainMenuButton as Button
@onready var _options_back_button := %PauseOptionsBackButton as Button
@onready var _master_slider := %MasterVolumeSlider as HSlider
@onready var _music_slider := %MusicVolumeSlider as HSlider
@onready var _sfx_slider := %SfxVolumeSlider as HSlider
@onready var _master_value := %MasterVolumeValue as Label
@onready var _music_value := %MusicVolumeValue as Label
@onready var _sfx_value := %SfxVolumeValue as Label
@onready var _fullscreen_toggle := %FullscreenToggle as CheckButton

var _game_manager: Node
var _match_active := false
var _button_tweens: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_menu.visible = false
	_pause_panel.visible = true
	_options_panel.visible = false
	_game_manager = get_node_or_null(game_manager_path)

	_resume_button.pressed.connect(_resume_match)
	_restart_button.pressed.connect(_restart_round)
	_pause_options_button.pressed.connect(_open_options)
	_pause_main_menu_button.pressed.connect(_exit_to_main_menu)
	_options_back_button.pressed.connect(_back_to_pause)
	_master_slider.value_changed.connect(_on_master_volume_changed)
	_music_slider.value_changed.connect(_on_music_volume_changed)
	_sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)

	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_setup_button_animations()
	_sync_options_controls()
	_connect_game_manager()


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if event is InputEventKey and event.echo:
		return
	if not _match_active:
		return

	get_viewport().set_input_as_handled()
	if _options_panel.visible:
		_back_to_pause()
	elif get_tree().paused:
		_resume_match()
	else:
		_pause_match()


func _pause_match() -> void:
	_pause_menu.visible = true
	_pause_panel.visible = true
	_options_panel.visible = false
	get_tree().paused = true
	_animate_panel_entry(_pause_panel)
	_resume_button.grab_focus()


func _resume_match() -> void:
	_pause_menu.visible = false
	_pause_panel.visible = true
	_options_panel.visible = false
	get_tree().paused = false


func _restart_round() -> void:
	_pause_menu.visible = false
	_options_panel.visible = false
	get_tree().paused = false
	ScreenFlow.reload_for_next_round()


func _open_options() -> void:
	_pause_panel.visible = false
	_options_panel.visible = true
	_sync_options_controls()
	_animate_panel_entry(_options_panel)
	_master_slider.grab_focus()


func _back_to_pause() -> void:
	_options_panel.visible = false
	_pause_panel.visible = true
	_animate_panel_entry(_pause_panel)
	_pause_options_button.grab_focus()


func _exit_to_main_menu() -> void:
	_match_active = false
	_pause_menu.visible = false
	_options_panel.visible = false
	get_tree().paused = false
	ScreenFlow.go_to_main_menu()


func _connect_game_manager() -> void:
	if _game_manager == null:
		push_error("PauseMenu: no se encontró GameManager.")
		return
	if not _game_manager.has_signal("match_started") or not _game_manager.has_signal("match_finished"):
		push_error("PauseMenu: GameManager no expone las señales esperadas.")
		return

	if not _game_manager.match_started.is_connected(_on_match_started):
		_game_manager.match_started.connect(_on_match_started)
	if not _game_manager.match_finished.is_connected(_on_match_finished):
		_game_manager.match_finished.connect(_on_match_finished)


func _on_match_started() -> void:
	_match_active = true
	get_tree().paused = false
	_pause_menu.visible = false
	_pause_panel.visible = true
	_options_panel.visible = false


func _on_match_finished(_winner: Node) -> void:
	_match_active = false
	_pause_menu.visible = false
	_pause_panel.visible = true
	_options_panel.visible = false
	get_tree().paused = false


func _ensure_audio_bus(bus_name: StringName) -> int:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		return bus_index

	AudioServer.add_bus()
	bus_index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, MASTER_BUS)
	return bus_index


func _sync_options_controls() -> void:
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


func _setup_button_animations() -> void:
	var buttons: Array[Button] = [
		_resume_button,
		_restart_button,
		_pause_options_button,
		_pause_main_menu_button,
		_options_back_button,
	]
	for button in buttons:
		button.resized.connect(_center_button_pivot.bind(button))
		button.focus_entered.connect(_animate_button.bind(button, true))
		button.focus_exited.connect(_refresh_button_animation.bind(button))
		button.mouse_entered.connect(_animate_button.bind(button, true))
		button.mouse_exited.connect(_refresh_button_animation.bind(button))
		_center_button_pivot(button)


func _center_button_pivot(button: Button) -> void:
	button.pivot_offset = button.size * 0.5


func _refresh_button_animation(button: Button) -> void:
	call_deferred("_animate_button", button, button.has_focus() or button.is_hovered())


func _animate_button(button: Button, selected: bool) -> void:
	var current := _button_tweens.get(button) as Tween
	if current != null and current.is_valid():
		current.kill()

	var tween := create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_button_tweens[button] = tween
	tween.tween_property(button, "scale", Vector2.ONE * (1.035 if selected else 1.0), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "modulate", Color(1.08, 1.08, 1.08, 1.0) if selected else Color.WHITE, 0.1)


func _animate_panel_entry(panel: Control) -> void:
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2.ONE * 0.965
	panel.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.12)
