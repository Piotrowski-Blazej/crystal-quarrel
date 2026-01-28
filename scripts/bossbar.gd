extends ProgressBar

var BOSSBAR_FILL = preload("uid://cx5upcxjp7jky")

var flashes:int = 0
func flash():
	flashes += 1
	BOSSBAR_FILL.bg_color = Color(1,1,1)
	await get_tree().create_timer(0.15).timeout
	flashes -= 1
	if flashes == 0:
		BOSSBAR_FILL.bg_color = Color(0,1,0)
