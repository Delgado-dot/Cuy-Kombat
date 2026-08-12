extends Node

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const SCENARIO_SELECT_SCENE := "res://scenes/ui/scenario_select_ui.tscn"
const GAMEPLAY_SCENE := "res://main.tscn"

var selected_scenario: StringName = &"volcanica"

var _scenario_select: Node


func go_to_main_menu() -> void:
	selected_scenario = &"volcanica"
	_unregister_scenario_select()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func go_to_scenario_select() -> void:
	_unregister_scenario_select()
	get_tree().change_scene_to_file(SCENARIO_SELECT_SCENE)


func start_match(scenario_id: StringName) -> void:
	selected_scenario = scenario_id
	_unregister_scenario_select()
	get_tree().change_scene_to_file(GAMEPLAY_SCENE)


func register_scenario_select(node: Node) -> void:
	_unregister_scenario_select()
	_scenario_select = node
	if node.has_signal("scenario_confirmed"):
		node.scenario_confirmed.connect(_on_scenario_confirmed)
	if node.has_signal("back_requested"):
		node.back_requested.connect(_on_back_requested)


func unregister_scenario_select(node: Node) -> void:
	if _scenario_select != node:
		return
	_unregister_scenario_select()


func _unregister_scenario_select() -> void:
	if _scenario_select == null or not is_instance_valid(_scenario_select):
		_scenario_select = null
		return
	if (
		_scenario_select.has_signal("scenario_confirmed")
		and _scenario_select.scenario_confirmed.is_connected(_on_scenario_confirmed)
	):
		_scenario_select.scenario_confirmed.disconnect(_on_scenario_confirmed)
	if (
		_scenario_select.has_signal("back_requested")
		and _scenario_select.back_requested.is_connected(_on_back_requested)
	):
		_scenario_select.back_requested.disconnect(_on_back_requested)
	_scenario_select = null


func _on_scenario_confirmed(scenario_id: StringName) -> void:
	start_match(scenario_id)


func _on_back_requested() -> void:
	go_to_main_menu()
