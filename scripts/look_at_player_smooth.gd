extends Node2D

@export var rot_speed = 0.02
var player:RigidBody2D
@export var offset:int

var active = true

var override = false
var override_direction:Vector2

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if !override:
		if active:
			var angle = global_position.direction_to(player.global_position).angle()+deg_to_rad(offset)
			global_rotation = lerp_angle(global_rotation, angle, rot_speed)
	else:
		var angle = override_direction.angle()+deg_to_rad(offset)
		global_rotation = lerp_angle(global_rotation, angle, rot_speed)
