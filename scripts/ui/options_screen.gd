extends CanvasLayer

@export var open_button_path: NodePath

@onready var _options_root := %OptionsScreen as Control
@onready var _back_button := %OptionsBackButton as Button
@onready var _fullscreen_button := %FullscreenButton as Button
@onready var _windowed_button := %WindowedButton as Button
@onready var _volume_up_button := %VolumeUpButton as Button
@onready var _volume_down_button := %VolumeDownButton as Button
@onready var _volume_label := %VolumeLabel as Label

var _open_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_options_root.visible = false

	_back_button.pressed.connect(close)
	_fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	_windowed_button.pressed.connect(_on_windowed_pressed)
	_volume_up_button.pressed.connect(_on_volume_up_pressed)
	_volume_down_button.pressed.connect(_on_volume_down_pressed)

	_open_button = get_node_or_null(open_button_path) as Button
	if _open_button != null:
		_open_button.pressed.connect(open)

	_update_volume_label()
	_update_fullscreen_button_state()
	_update_windowed_button_state()


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
	_update_volume_label()
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


func _on_volume_up_pressed() -> void:
	var current_volume := MusicManager.get_volume()
	MusicManager.set_volume(clampf(current_volume + 0.1, 0.0, 1.0))
	_update_volume_label()
	_volume_up_button.grab_focus()


func _on_volume_down_pressed() -> void:
	var current_volume := MusicManager.get_volume()
	MusicManager.set_volume(clampf(current_volume - 0.1, 0.0, 1.0))
	_update_volume_label()
	_volume_down_button.grab_focus()


func _update_volume_label() -> void:
	if _volume_label == null:
		return
	var volume_percent := int(MusicManager.get_volume() * 100)
	_volume_label.text = "VOLUMEN: %d%%" % volume_percent


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
