extends CanvasLayer

@export var open_button_path: NodePath

@onready var _controls_root := %ControlsScreen as Control
@onready var _back_button := %ControlsBackButton as Button

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
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not _controls_root.visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()


func open(_from_screen: Node = null) -> void:
	_controls_root.visible = true
	_back_button.grab_focus()


func close() -> void:
	_controls_root.visible = false
	if _open_button != null and _open_button.is_inside_tree():
		_open_button.grab_focus()
