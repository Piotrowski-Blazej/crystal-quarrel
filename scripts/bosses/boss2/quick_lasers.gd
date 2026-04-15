extends State

@export var main_anim_player:AnimationPlayer
@export var boss:Area2D
@export var dash_d_timer:Timer
@export var left_turret:Sprite2D
@export var right_turret:Sprite2D

var left_player_direction:float
var right_player_direction:float

var left_turret_offset:float = 0.1
var right_turret_offset:float = 0.1

var warn_time:float = 0.4
const turret_offset_min:float = 0.25
const turret_offset_max:float = 1
var turret_limits:Array[float] = []
var clockwise = true
var turn_time:float = 1.4
var finished_rot = true
var turn_amount_range = Vector2i(5,7)

const FIRE_AREA_SCALE:float = 5

var player:RigidBody2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	if GlobalValues.difficulty == 3:
		turn_time = 3
		warn_time = 1.2
		turn_amount_range = Vector2i(3,4)
	elif GlobalValues.difficulty == 0: 
		turn_time = 2
		warn_time = 0.8
		turn_amount_range = Vector2i(4,5)
	elif GlobalValues.difficulty == 1: 
		turn_time = 1.7
		warn_time = 0.6
		turn_amount_range = Vector2i(4,6)

func enter():
	finished_rot = true
	clockwise = false
	
	for i in range(randi_range(turn_amount_range.x,turn_amount_range.y)):
		turret_limits.append(randf_range(turret_offset_min, turret_offset_max))
	
	boss.dash_to_position(Vector2(0,0))
	await dash_d_timer.timeout
	
	boss.set_look_pos()
	
	left_player_direction = boss.look_angle
	right_player_direction = boss.look_angle
	
	left_turret.rotate_instantly(left_player_direction + left_turret_offset*PI)
	right_turret.rotate_instantly(right_player_direction + right_turret_offset*PI)
	
	main_anim_player.play("fire_area")
	await main_anim_player.animation_finished
	main_anim_player.play("RESET")
	
	finished_rotation()
	
	var duration:float = 0
	for i in range(turret_limits.size()):
		duration += ((STARTING_TURRET_OFFSET+turret_limits[i])*turn_time) + warn_time
	
	boss.spawn_fire_area(FIRE_AREA_SCALE, duration)


func finished_rotation():
	turret_limits.pop_front()
	if turret_limits.size() != 0:
		if clockwise:
			right_turret.fire_laser((STARTING_TURRET_OFFSET+turret_limits[0])*turn_time, warn_time)
			await get_tree().create_timer(warn_time).timeout
			clockwise = false
		else:
			left_turret.fire_laser((STARTING_TURRET_OFFSET+turret_limits[0])*turn_time, warn_time)
			await get_tree().create_timer(warn_time).timeout
			clockwise = true
		finished_rot = false
	else:
		finish()

const STARTING_TURRET_OFFSET = 0.2
func update(delta:float):
	if clockwise:
		right_player_direction = boss.global_position.angle_to_point(player.global_position)
		right_turret_offset = STARTING_TURRET_OFFSET
		right_turret.rotate_instantly(right_player_direction + right_turret_offset*PI)
	else:
		left_player_direction = boss.global_position.angle_to_point(player.global_position)
		left_turret_offset = -STARTING_TURRET_OFFSET
		left_turret.rotate_instantly(left_player_direction + left_turret_offset*PI)
	
	if clockwise:
		left_turret_offset += delta/turn_time
		left_turret.rotate_instantly(left_player_direction + left_turret_offset*PI)
		if left_turret_offset >= turret_limits[0] && !finished_rot:
			finished_rot = true
			finished_rotation()
	else:
		right_turret_offset -= delta/turn_time
		right_turret.rotate_instantly(right_player_direction + right_turret_offset*PI)
		if right_turret_offset <= -turret_limits[0] && !finished_rot:
			finished_rot = true
			finished_rotation()



func finish():
	var attack_pool:Array = ["boss2dash","homingbullethell","quickmissiles","quickcuts"]
	if $"..".current_state == self:
		if boss.waiting_for_fastball_attack:
			Transitioned.emit(self,"homingfastball")
		else:
			var chosen_attack = attack_pool.pick_random()
			while chosen_attack == $"..".last_attack:
				chosen_attack = attack_pool.pick_random()
			
			Transitioned.emit(self,chosen_attack)
