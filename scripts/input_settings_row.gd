extends HBoxContainer

@export var input_name:StringName = "move_up"
@export var label_text:String = "Move Up"
@onready var input_button: Label = $InputButton
@onready var input_name_label: Label = $InputName


var is_selected:bool = false
var is_mouse_over:bool = false


func _ready() -> void:
	input_name_label.text = label_text + " - "
	input_button.text = InputMap.action_get_events(input_name)[0].as_text().replace(" (Physical)", "")

func _input(event: InputEvent) -> void:
	if is_mouse_over and event.is_released():
		if !is_selected and event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				is_selected = true
				modulate = Color("f00")
		elif is_selected and (event is InputEventKey or event is InputEventMouseButton):
			input_button.text = event.as_text()
			InputMap.action_erase_events(input_name)
			InputMap.action_add_event(input_name, event)


func _on_mouse_entered() -> void:
	modulate = Color("ff5f5fff")
	is_mouse_over = true


func _on_mouse_exited() -> void:
	is_selected = false
	is_mouse_over = false
	modulate = Color("ff7f7f")
