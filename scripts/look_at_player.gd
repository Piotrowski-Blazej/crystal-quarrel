extends Node2D

@export var rot_speed = 0.1
@export var degree_of_accuracy = 1
@export var velocity_threshold = 750

var player:RigidBody2D
@onready var firepoint: Node2D = $Firepoint

var enabled = true

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if enabled:
		var true_target:Vector2 = player.global_position
		var old_distance = 0
		
		if player.linear_velocity.length() > velocity_threshold:
			for i in range(degree_of_accuracy):
				var distance = firepoint.global_position.distance_to(true_target)-old_distance
				var target = true_target + (player.linear_velocity)*(distance/$"..".bullet_velocity*delta)
				true_target = target
				old_distance = distance
			
			const arena_size = 2048
			if true_target.x < -arena_size:
				true_target.x = -arena_size
			elif true_target.x > arena_size:
				true_target.x = arena_size
			if true_target.y < -arena_size:
				true_target.y = -arena_size
			elif true_target.y > arena_size:
				true_target.y = arena_size
		else:
			true_target = player.global_position
		
		
		var v2 = player.global_position - global_position
		var angle2 = v2.angle()
		
		var v = true_target - global_position
		var angle = v.angle()
		
		if abs(wrapf(angle - angle2,-PI,PI)) < 2:
			global_rotation = lerp_angle(global_rotation, angle, rot_speed)
		else:
			global_rotation = lerp_angle(global_rotation, angle2, rot_speed)
