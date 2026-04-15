extends ColorRect

signal has_faded
var fadeout_time = 1.0
var fading_in = false

func _ready() -> void:
	if fading_in: show()

var is_fading = false
func fade_in(time:float = 0.5):
	fading_in = false
	is_fading = true
	fadeout_time = time

func fade_out(time:float = 0.5):
	fading_in = true
	is_fading = true
	fadeout_time = time

func _process(delta: float) -> void:
	if is_fading:
		if fading_in:
			color.a += delta/fadeout_time
			if color.a >= 1:
				is_fading = false
				has_faded.emit()
		else:
			color.a -= delta
			if color.a <= 0:
				is_fading = false
				has_faded.emit()
