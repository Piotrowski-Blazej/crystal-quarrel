extends ProgressBar

var PLAYERBAR_FILL = preload("uid://b7k03rfoi4n0w")

var flashes:int = 0
func flash():
	flashes += 1
	PLAYERBAR_FILL.bg_color = Color(1,1,1)
	await get_tree().create_timer(0.15).timeout
	flashes -= 1
	if flashes == 0:
		PLAYERBAR_FILL.bg_color = Color(0,1,0)
