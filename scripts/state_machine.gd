extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

var last_attack = ""

func setup():
	for child in get_children():#Creates the list of states from children
		if child is State:
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
	if initial_state:
		initial_state.enter()
		current_state = initial_state
		last_attack = initial_state.name.to_lower()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func on_child_transition(state, new_state_name):
	if state != current_state:
		return
	
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		return
	
	if current_state:
		current_state.exit()
	
	last_attack = current_state.name.to_lower()
	
	current_state = new_state
	
	new_state.enter()

func halt_all_states():
	if current_state:
		current_state.exit()
		current_state = null
