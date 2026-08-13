extends CanvasLayer

@export var open_button_path: NodePath
@export var scroll_step := 140.0

@onready var _controls_root := %ControlsScreen as Control
@onready var _back_button := %ControlsBackButton as Button
@onready var _scroll_container := %ControlsScreen/Margin/Center as ScrollContainer

var _open_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_controls_root.visible = false

	_back_button.pressed.connect(close)

	_open_button = get_node_or_null(open_button_path) as Button
	if _open_button != null:
		_open_button.pressed.connect(open)


func _input(event: InputEvent) -> void:
	if not _controls_root.visible:
		return

	if event.is_action_pressed("ui_cancel"):
		if event is InputEventKey and event.echo:
			return
		get_viewport().set_input_as_handled()
		close()

	if event is InputEventJoypadMotion:
		if event.axis == JoyAxis.JOY_AXIS_RIGHT_Y:
			get_viewport().set_input_as_handled()
			_scroll_by(event.axis_value)
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JoyButton.JOY_BUTTON_DPAD_UP, JoyButton.JOY_BUTTON_LEFT_SHOULDER:
				get_viewport().set_input_as_handled()
				_scroll_by(-1.0)
			JoyButton.JOY_BUTTON_DPAD_DOWN, JoyButton.JOY_BUTTON_RIGHT_SHOULDER:
				get_viewport().set_input_as_handled()
				_scroll_by(1.0)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_PAGEUP:
				get_viewport().set_input_as_handled()
				_scroll_by(-1.0)
			KEY_DOWN, KEY_PAGEDOWN:
				get_viewport().set_input_as_handled()
				_scroll_by(1.0)


func _scroll_by(direction: float) -> void:
	if _scroll_container == null:
		return
	var max_scroll := _scroll_container.get_v_scroll_bar().max_value
	_scroll_container.scroll_vertical = clampi(
		_scroll_container.scroll_vertical + int(scroll_step * direction),
		0,
		int(max_scroll)
	)


func open(_from_screen: Node = null) -> void:
	_controls_root.visible = true
	if _scroll_container != null:
		_scroll_container.scroll_vertical = 0
	_back_button.grab_focus()


func close() -> void:
	_controls_root.visible = false
