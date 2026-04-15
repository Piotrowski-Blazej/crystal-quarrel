extends Label

signal finished_text
var received_text:String
var letter_delay:float
var letter_index:int = 0

@onready var timer: Timer = $Timer


func change_text(new_text:String):#, speed_multiplier:float = 1.0):
	text = ""
	#@warning_ignore("integer_division")
	#letter_delay = 5/new_text.length()/speed_multiplier
	#if letter_delay < 0.03:
	letter_delay = 0.02
	received_text = new_text
	letter_index = 0
	
	timer.start(letter_delay)


func _on_timer_timeout() -> void:
	self.text += received_text[letter_index]
	letter_index += 1
	if text.length() < received_text.length():
		timer.start(letter_delay)
	else:
		finished_text.emit()
