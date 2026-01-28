extends HBoxContainer


var line_index:int
var boss:String
var difficulty:String
var time:float

var is_selected:bool = false


func setup(r_boss:String, r_difficulty:String, r_time:float,r_index:int) -> void:
	boss = r_boss
	difficulty = r_difficulty
	time = r_time
	line_index = r_index


func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_selected = true
			modulate = Color("ff2f2fff")


func _process(_delta: float) -> void:
	if is_selected && Input.is_action_pressed("heal") && Input.is_action_just_pressed("delete"):
		$"../../../..".remove_record(line_index)
		queue_free()


func _on_mouse_entered() -> void:
	modulate = Color("ff7f7f")


func _on_mouse_exited() -> void:
	is_selected = false
	modulate = Color(1,1,1)
