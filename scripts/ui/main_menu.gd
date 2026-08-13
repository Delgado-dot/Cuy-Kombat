extends CanvasLayer

@export var controls_screen_path: NodePath

@onready var _menu_root := %MainMenu as Control
@onready var _play_button := %PlayButton as Button
@onready var _controls_button := %ControlsButton as Button
@onready var _options_button := %MainOptionsButton as Button
@onready var _quit_button := %QuitButton as Button
@onready var _options_message := %OptionsMessage as Label

var _controls_screen: CanvasLayer
var _controls_root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_ensure_navigation_actions()

	_controls_screen = get_node_or_null(controls_screen_path) as CanvasLayer
	if _controls_screen != null:
		_controls_root = _controls_screen.get_node_or_null("ControlsScreen") as Control
		if _controls_root != null:
			_controls_root.visibility_changed.connect(_on_controls_visibility_changed)

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
	ScreenFlow.go_to_scenario_select()


func _on_controls_pressed() -> void:
	_menu_root.visible = false
	if _controls_screen != null and _controls_screen.has_method("open"):
		_controls_screen.open()


func _on_options_pressed() -> void:
	_options_message.text = "OPCIONES PRÓXIMAMENTE"
	_options_message.visible = true
	_play_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_controls_visibility_changed() -> void:
	if _controls_root != null and not _controls_root.visible:
		_menu_root.visible = true
		_play_button.grab_focus()


# Registra las acciones de navegación estándar de UI (ui_up/down/left/right y
# focus_next/prev) solo si faltan, para permitir navegar el menú con teclado,
# D-pad y joystick sin modificar el InputMap de project.godot.
func _ensure_navigation_actions() -> void:
	_ensure_navigation_action("ui_up", KEY_UP, JoyButton.JOY_BUTTON_DPAD_UP, JoyAxis.JOY_AXIS_LEFT_Y, -1.0)
	_ensure_navigation_action("ui_down", KEY_DOWN, JoyButton.JOY_BUTTON_DPAD_DOWN, JoyAxis.JOY_AXIS_LEFT_Y, 1.0)
	_ensure_navigation_action("ui_left", KEY_LEFT, JoyButton.JOY_BUTTON_DPAD_LEFT, JoyAxis.JOY_AXIS_LEFT_X, -1.0)
	_ensure_navigation_action("ui_right", KEY_RIGHT, JoyButton.JOY_BUTTON_DPAD_RIGHT, JoyAxis.JOY_AXIS_LEFT_X, 1.0)

	if not InputMap.has_action("ui_focus_next"):
		InputMap.add_action("ui_focus_next")
		InputMap.action_add_event("ui_focus_next", _navigation_key_event(KEY_TAB))
		InputMap.action_add_event("ui_focus_next", _navigation_joy_button_event(JoyButton.JOY_BUTTON_RIGHT_SHOULDER))
	if not InputMap.has_action("ui_focus_prev"):
		InputMap.add_action("ui_focus_prev")
		var shift_tab := _navigation_key_event(KEY_TAB)
		shift_tab.shift_pressed = true
		InputMap.action_add_event("ui_focus_prev", shift_tab)
		InputMap.action_add_event("ui_focus_prev", _navigation_joy_button_event(JoyButton.JOY_BUTTON_LEFT_SHOULDER))


func _ensure_navigation_action(action: StringName, key: Key, joy_button: JoyButton, axis: JoyAxis, axis_value: float) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	InputMap.action_add_event(action, _navigation_key_event(key))
	InputMap.action_add_event(action, _navigation_joy_button_event(joy_button))
	InputMap.action_add_event(action, _navigation_joy_motion_event(axis, axis_value))


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
