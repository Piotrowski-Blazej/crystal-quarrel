extends ColorRect

const MAIN_MENU = "res://scenes/main_menu.tscn"
const WIN_SCREEN = "res://scenes/win_screen.tscn"

var changed_scene = false
var fadeout_time = 1.0
@export var fading_in = false

var has_won = false

func _ready() -> void:
	if fading_in: show()

var fading_out = false
func fade_out(time:float, won = false, delay = 0.0):
	if delay > 0.0: await get_tree().create_timer(delay).timeout
	
	fading_out = true
	fadeout_time = time
	
	has_won = won

func _process(delta: float) -> void:
	if fading_out:
		color.a += delta/fadeout_time
		if color.a >= 1 && !changed_scene:
			changed_scene = true
			if !has_won: get_tree().change_scene_to_file(MAIN_MENU)
			else:        get_tree().change_scene_to_file(WIN_SCREEN)
	elif fading_in:
		color.a -= delta
		if color.a <= 0:
			queue_free()
