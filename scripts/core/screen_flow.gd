extends CanvasLayer

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const LOBBY_SCENE := "res://scenes/lobby/lobby.tscn"
const MUTATION_SELECT_SCENE := "res://scenes/ui/mutation_select_ui.tscn"
const SCENARIO_SELECT_SCENE := "res://scenes/ui/scenario_select_ui.tscn"
const GAMEPLAY_SCENE := "res://main.tscn"

const TRANSITION_OVERLAY_LAYER := 100
const FADE_IN_DURATION := 0.22
const FADE_OUT_DURATION := 0.25
const ANDEAN_GOLD := Color(0.95, 0.72, 0.15, 1.0)

var selected_scenario: StringName = &"volcanica"

var _scenario_select: Node
var _mutation_select: Node
var _transition_overlay: CanvasLayer
var _overlay_rect: ColorRect
var _loading_label: Label
var _loading_cuy: Label
var _transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_transition_overlay()


func _build_transition_overlay() -> void:
	_transition_overlay = CanvasLayer.new()
	_transition_overlay.name = "TransitionOverlay"
	_transition_overlay.layer = TRANSITION_OVERLAY_LAYER
	_transition_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_transition_overlay.visible = false
	add_child(_transition_overlay)

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.add_child(root)

	_overlay_rect = ColorRect.new()
	_overlay_rect.name = "FadeRect"
	_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_rect.color = Color(0.01, 0.015, 0.03, 0.95)
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_transition_overlay.add_child(_overlay_rect)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.add_child(center)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(content)

	_loading_cuy = Label.new()
	_loading_cuy.name = "Cuy"
	_loading_cuy.text = "@.@"
	_loading_cuy.add_theme_font_size_override("font_size", 36)
	_loading_cuy.add_theme_color_override("font_color", ANDEAN_GOLD)
	_loading_cuy.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.01, 1))
	_loading_cuy.add_theme_constant_override("outline_size", 4)
	_loading_cuy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_loading_cuy)

	_loading_label = Label.new()
	_loading_label.name = "LoadingLabel"
	_loading_label.text = "Cargando..."
	_loading_label.add_theme_font_size_override("font_size", 18)
	_loading_label.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72, 0.9))
	_loading_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.04, 0.8))
	_loading_label.add_theme_constant_override("outline_size", 2)
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_loading_label)

	_overlay_rect.modulate.a = 0.0
	_loading_cuy.modulate.a = 0.0
	_loading_label.modulate.a = 0.0


func _transition_to_scene(scene_path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	get_viewport().set_input_as_handled()

	_transition_overlay.visible = true
	var tween := create_tween().set_parallel()
	tween.tween_property(_overlay_rect, "modulate:a", 1.0, FADE_IN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_loading_cuy, "modulate:a", 1.0, FADE_IN_DURATION * 0.8).set_delay(FADE_IN_DURATION * 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_loading_label, "modulate:a", 1.0, FADE_IN_DURATION * 0.6).set_delay(FADE_IN_DURATION * 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	get_tree().change_scene_to_file(scene_path)

	_fade_out_overlay()


func _reload_with_transition() -> void:
	if _transitioning:
		return
	_transitioning = true
	get_viewport().set_input_as_handled()

	_transition_overlay.visible = true
	var tween := create_tween().set_parallel()
	tween.tween_property(_overlay_rect, "modulate:a", 1.0, FADE_IN_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_loading_cuy, "modulate:a", 1.0, FADE_IN_DURATION * 0.8).set_delay(FADE_IN_DURATION * 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_loading_label, "modulate:a", 1.0, FADE_IN_DURATION * 0.6).set_delay(FADE_IN_DURATION * 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	get_tree().reload_current_scene()

	_fade_out_overlay()


func _fade_out_overlay() -> void:
	await get_tree().process_frame

	var tween := create_tween().set_parallel()
	tween.tween_property(_loading_cuy, "modulate:a", 0.0, FADE_OUT_DURATION * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_loading_label, "modulate:a", 0.0, FADE_OUT_DURATION * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_overlay_rect, "modulate:a", 0.0, FADE_OUT_DURATION).set_delay(FADE_OUT_DURATION * 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	_transition_overlay.visible = false
	_transitioning = false


# ===========================================================================
#  PUBLIC API — scene navigation (all go through transitions)
# ===========================================================================

func go_to_main_menu() -> void:
	selected_scenario = &"volcanica"
	MutationManager.clear()
	_unregister_scenario_select()
	_unregister_mutation_select()
	_transition_to_scene(MAIN_MENU_SCENE)


func go_to_mutation_select() -> void:
	_unregister_mutation_select()
	_transition_to_scene(MUTATION_SELECT_SCENE)


func go_to_scenario_select() -> void:
	_unregister_scenario_select()
	_unregister_mutation_select()
	_transition_to_scene(SCENARIO_SELECT_SCENE)


func go_to_lobby() -> void:
	MutationManager.clear()
	_unregister_scenario_select()
	_unregister_mutation_select()
	_transition_to_scene(LOBBY_SCENE)


func start_match(scenario_id: StringName) -> void:
	selected_scenario = scenario_id
	_unregister_scenario_select()
	_unregister_mutation_select()
	_transition_to_scene(GAMEPLAY_SCENE)


func reload_for_next_round() -> void:
	_reload_with_transition()


# ===========================================================================
#  Signal registration (unchanged logic)
# ===========================================================================

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


func register_mutation_select(node: Node) -> void:
	_unregister_mutation_select()
	_mutation_select = node
	if node.has_signal("confirmed"):
		node.confirmed.connect(_on_mutation_confirmed)
	if node.has_signal("back_requested"):
		node.back_requested.connect(_on_mutation_back_requested)


func unregister_mutation_select(node: Node) -> void:
	if _mutation_select != node:
		return
	_unregister_mutation_select()


func _unregister_mutation_select() -> void:
	if _mutation_select == null or not is_instance_valid(_mutation_select):
		_mutation_select = null
		return
	if _mutation_select.has_signal("confirmed") and _mutation_select.confirmed.is_connected(_on_mutation_confirmed):
		_mutation_select.confirmed.disconnect(_on_mutation_confirmed)
	if (
		_mutation_select.has_signal("back_requested")
		and _mutation_select.back_requested.is_connected(_on_mutation_back_requested)
	):
		_mutation_select.back_requested.disconnect(_on_mutation_back_requested)
	_mutation_select = null


func _on_mutation_confirmed() -> void:
	go_to_scenario_select()


func _on_mutation_back_requested() -> void:
	go_to_lobby()
