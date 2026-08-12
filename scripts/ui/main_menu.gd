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
