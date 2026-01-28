extends Node2D

func set_timer(time):
	await get_tree().create_timer(time).timeout
	die(null)

func die(_irrelevant = null):
	queue_free()
