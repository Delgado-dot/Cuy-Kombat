extends CanvasLayer

@export var controls_screen_path: NodePath
@export var options_screen_path: NodePath

@onready var _menu_root := %MainMenu as Control
@onready var _play_button := %PlayButton as Button
@onready var _controls_button := %ControlsButton as Button
@onready var _options_button := %MainOptionsButton as Button
@onready var _quit_button := %QuitButton as Button
@onready var _options_message := %OptionsMessage as Label

var _controls_screen: CanvasLayer
var _controls_root: Control
var _options_screen: CanvasLayer
var _options_root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_ensure_navigation_actions()

	_controls_screen = get_node_or_null(controls_screen_path) as CanvasLayer
	if _controls_screen != null:
		_controls_root = _controls_screen.get_node_or_null("ControlsScreen") as Control
		if _controls_root != null:
			_controls_root.visibility_changed.connect(_on_controls_visibility_changed)

	_options_screen = get_node_or_null(options_screen_path) as CanvasLayer
	if _options_screen != null:
		_options_root = _options_screen.get_node_or_null("OptionsScreen") as Control
		if _options_root != null:
			_options_root.visibility_changed.connect(_on_options_visibility_changed)

	_menu_root.visible = true
	_options_message.visible = false
	_play_button.grab_focus()

	_connect_buttons()
	MusicManager.play_menu_music()


func _connect_buttons() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_controls_button.pressed.connect(_on_controls_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	ScreenFlow.go_to_lobby()


func _on_controls_pressed() -> void:
	_menu_root.visible = false
	if _controls_screen != null and _controls_screen.has_method("open"):
		_controls_screen.open()


func _on_options_pressed() -> void:
	_menu_root.visible = false
	if _options_screen != null and _options_screen.has_method("open"):
		_options_screen.open()
	_options_message.visible = false


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_controls_visibility_changed() -> void:
	if _controls_root != null and not _controls_root.visible:
		_menu_root.visible = true
		_play_button.grab_focus()


func _on_options_visibility_changed() -> void:
	if _options_root != null and not _options_root.visible:
		_menu_root.visible = true
		_play_button.grab_focus()


# Registra de forma idempotente los eventos de D-pad y joystick en las
# acciones de navegación estándar de UI (ui_up/down/left/right y
# focus_next/prev). Godot ya crea las acciones ui_* por defecto (solo con
# teclado), así que solo se añaden los eventos de mando que falten.
func _ensure_navigation_actions() -> void:
	_ensure_navigation_action("ui_up", KEY_UP, JoyButton.JOY_BUTTON_DPAD_UP, JoyAxis.JOY_AXIS_LEFT_Y, -1.0)
	_ensure_navigation_action("ui_down", KEY_DOWN, JoyButton.JOY_BUTTON_DPAD_DOWN, JoyAxis.JOY_AXIS_LEFT_Y, 1.0)
	_ensure_navigation_action("ui_left", KEY_LEFT, JoyButton.JOY_BUTTON_DPAD_LEFT, JoyAxis.JOY_AXIS_LEFT_X, -1.0)
	_ensure_navigation_action("ui_right", KEY_RIGHT, JoyButton.JOY_BUTTON_DPAD_RIGHT, JoyAxis.JOY_AXIS_LEFT_X, 1.0)
	_ensure_focus_action("ui_focus_next", KEY_TAB, JoyButton.JOY_BUTTON_RIGHT_SHOULDER)
	_ensure_focus_action("ui_focus_prev", KEY_TAB, JoyButton.JOY_BUTTON_LEFT_SHOULDER, true)


func _ensure_navigation_action(action: StringName, key: Key, joy_button: JoyButton, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	_ensure_event(action, _navigation_key_event(key))
	_ensure_event(action, _navigation_joy_button_event(joy_button))
	_ensure_event(action, _navigation_joy_motion_event(axis, axis_value))


func _ensure_focus_action(action: StringName, key: Key, joy_button: JoyButton, shift_pressed := false) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var key_event := _navigation_key_event(key)
	key_event.shift_pressed = shift_pressed
	_ensure_event(action, key_event)
	_ensure_event(action, _navigation_joy_button_event(joy_button))


func _ensure_event(action: StringName, event: InputEvent) -> void:
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _navigation_key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	return event


func _navigation_joy_button_event(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


func _navigation_joy_motion_event(axis: JoyAxis, axis_value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	return event
