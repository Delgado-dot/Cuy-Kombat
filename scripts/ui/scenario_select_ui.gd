class_name ScenarioSelectUI
extends Control

signal scenario_selection_changed(scenario_id: StringName)
signal scenario_confirmed(scenario_id: StringName)
signal back_requested

const SCENARIO_VOLCANICA := &"volcanica"
const SCENARIO_MITAD_DEL_MUNDO := &"mitad_del_mundo"
const SCENARIO_QUITO := &"quito"

const SCENARIO_NAMES := {
	SCENARIO_VOLCANICA: "ARENA VOLCÁNICA",
	SCENARIO_MITAD_DEL_MUNDO: "MITAD DEL MUNDO",
	SCENARIO_QUITO: "CENTRO HISTÓRICO DE QUITO",
}

@onready var _volcano_card := %VolcanoCard as Button
@onready var _mitad_del_mundo_card := %MitadDelMundoCard as Button
@onready var _quito_card := %QuitoCard as Button
@onready var _volcano_badge := %VolcanoSelectedBadge as Label
@onready var _mitad_del_mundo_badge := %MitadSelectedBadge as Label
@onready var _quito_badge := %QuitoSelectedBadge as Label
@onready var _selected_scenario_label := %SelectedScenarioLabel as Label
@onready var _back_button := %ScenarioBackButton as Button

var _selected_scenario: StringName = SCENARIO_VOLCANICA


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_volcano_card.pressed.connect(
		_select_scenario.bind(SCENARIO_VOLCANICA, _volcano_card)
	)
	_mitad_del_mundo_card.pressed.connect(
		_select_scenario.bind(SCENARIO_MITAD_DEL_MUNDO, _mitad_del_mundo_card)
	)
	_quito_card.pressed.connect(
		_select_scenario.bind(SCENARIO_QUITO, _quito_card)
	)
	_back_button.pressed.connect(_on_back_pressed)
	_select_scenario(SCENARIO_VOLCANICA, _volcano_card, false)


func show_selector() -> void:
	visible = true
	var selected_card := _get_card_for_scenario(_selected_scenario)
	_select_scenario(_selected_scenario, selected_card, false)
	selected_card.grab_focus()


func hide_selector() -> void:
	visible = false


func get_selected_scenario() -> StringName:
	return _selected_scenario


func _select_scenario(
	scenario_id: StringName,
	selected_card: Button,
	emit_change: bool = true
) -> void:
	_selected_scenario = scenario_id
	selected_card.button_pressed = true
	_volcano_badge.self_modulate.a = 1.0 if scenario_id == SCENARIO_VOLCANICA else 0.0
	_mitad_del_mundo_badge.self_modulate.a = (
		1.0 if scenario_id == SCENARIO_MITAD_DEL_MUNDO else 0.0
	)
	_quito_badge.self_modulate.a = 1.0 if scenario_id == SCENARIO_QUITO else 0.0
	_selected_scenario_label.text = "SELECCIONADO: %s" % SCENARIO_NAMES[scenario_id]

	if emit_change:
		scenario_selection_changed.emit(scenario_id)


func _get_card_for_scenario(scenario_id: StringName) -> Button:
	match scenario_id:
		SCENARIO_MITAD_DEL_MUNDO:
			return _mitad_del_mundo_card
		SCENARIO_QUITO:
			return _quito_card
		_:
			return _volcano_card


func _on_confirm_pressed() -> void:
	scenario_confirmed.emit(_selected_scenario)


func _on_back_pressed() -> void:
	back_requested.emit()
