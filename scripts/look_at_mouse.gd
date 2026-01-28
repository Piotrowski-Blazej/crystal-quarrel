extends Node2D

var rot_speed = 0.02
var delayed = false

func _process(_delta):
	if !delayed:
		var v = get_global_mouse_position() - global_position
		var angle = v.angle()
		global_rotation = angle
	else:
		var angle = global_position.direction_to(get_global_mouse_position()).angle()
		global_rotation = lerp_angle(global_rotation, angle, rot_speed)
