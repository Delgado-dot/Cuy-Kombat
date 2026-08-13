extends CanvasLayer

@export var open_button_path: NodePath

@onready var _options_root := %OptionsScreen as Control
@onready var _back_button := %OptionsBackButton as Button
@onready var _fullscreen_button := %FullscreenButton as Button
@onready var _windowed_button := %WindowedButton as Button
@onready var _volume_slider := %VolumeSlider as HSlider
@onready var _volume_label := %VolumeLabel as Label

var _open_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_options_root.visible = false

	_back_button.pressed.connect(close)
	_fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	_windowed_button.pressed.connect(_on_windowed_pressed)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_volume_slider.gui_input.connect(_on_volume_slider_input)

	_open_button = get_node_or_null(open_button_path) as Button
	if _open_button != null:
		_open_button.pressed.connect(open)

	_sync_slider_to_volume()


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
	_sync_slider_to_volume()
	_update_fullscreen_button_state()
	_update_windowed_button_state()
	_back_button.grab_focus()


func close() -> void:
	_options_root.visible = false


func _on_fullscreen_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_fullscreen_button_state()
	_update_windowed_button_state()


func _on_windowed_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_update_fullscreen_button_state()
	_update_windowed_button_state()


func _on_volume_changed(value: float) -> void:
	var linear_volume := value / 100.0
	MusicManager.set_volume(linear_volume)
	_update_volume_label(value)


func _on_volume_slider_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_volume_from_slider_position(event.position.x)
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_set_volume_from_slider_position(event.position.x)


func _set_volume_from_slider_position(local_x: float) -> void:
	var slider_width := maxf(_volume_slider.size.x, 1.0)
	_volume_slider.value = clampf(local_x / slider_width * 100.0, 0.0, 100.0)


func _sync_slider_to_volume() -> void:
	if _volume_slider == null:
		return
	var current_volume := MusicManager.get_volume()
	var slider_value := int(current_volume * 100.0)
	_volume_slider.value = slider_value
	_update_volume_label(slider_value)


func _update_volume_label(value: float = -1.0) -> void:
	if _volume_label == null:
		return
	if value < 0:
		value = _volume_slider.value
	_volume_label.text = "VOLUMEN: %d%%" % int(value)


func _update_fullscreen_button_state() -> void:
	if _fullscreen_button == null:
		return
	var is_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	_fullscreen_button.disabled = is_fullscreen


func _update_windowed_button_state() -> void:
	if _windowed_button == null:
		return
	var is_windowed := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
	_windowed_button.disabled = is_windowed
