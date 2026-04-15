extends State

@export var animation_player:AnimationPlayer
@export var boss:Area2D
@export var misc_timer:Timer
var shooting_c = 0.01
var missile_positions:Array[Vector2]

@export var main_gun:Sprite2D

var missile_damage = 20
const missile_velocity = 50
const missile_accel:float = 50
const missile_kb = 100
const missile_parry_chance = 0
const missile_scale = 1.5
const explosion_scale = 0.4

const CIRCLE_WARNING = preload("uid://bsuiardtyixtn")
var warn_time = 0.5
var warnings:Array[Sprite2D]

var player:RigidBody2D
var world_center:Node2D

const DEFAULT_WARNING_DISTANCE = 1400
const ARENA_SIZE = 2048

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	world_center = get_tree().get_first_node_in_group("world_center")
	
	if GlobalValues.difficulty == 3:
		warn_time = 2
	elif GlobalValues.difficulty == 0:
		warn_time = 1.5
	elif GlobalValues.difficulty == 1:
		warn_time = 1
	elif GlobalValues.difficulty == 2:
		warn_time = 0.75

func enter():
	misc_timer.timeout.connect(on_misc_timer_timeout)
	missile_positions.clear()
	warnings.clear()
	
	for i in range(40):
		var new_pos:Vector2
		var found_pos = false
		
		while !found_pos:
			new_pos = Vector2(randi_range(-ARENA_SIZE,ARENA_SIZE),
			randi_range(-ARENA_SIZE,ARENA_SIZE))
			
			found_pos = true
			for pos in missile_positions:
				if new_pos.distance_to(pos) < DEFAULT_WARNING_DISTANCE*explosion_scale:
					found_pos = false
		
		missile_positions.append(new_pos)
		
		var i_warn = CIRCLE_WARNING.instantiate()
		world_center.add_child.call_deferred(i_warn)
		i_warn.global_position = missile_positions[i]
		i_warn.setup(explosion_scale)
		
		warnings.append(i_warn)
	
	boss.set_look_pos()
	
	misc_timer.start(warn_time)
	await misc_timer.timeout
	
	misc_timer.start(shooting_c)

var wait_time = 1
func on_misc_timer_timeout():
	if $"..".current_state == self:
		if missile_positions.size() > 0:
			main_gun.fire_missile(warnings[0], missile_damage, missile_velocity, missile_accel, missile_kb, missile_positions[0], missile_parry_chance, missile_scale, explosion_scale, boss)
			missile_positions.pop_front()
			warnings.pop_front()
		else:
			misc_timer.stop()
			await get_tree().create_timer(wait_time).timeout
			finish()

var attack_pool:Array = ["bulletwall","homingbullethell","boss2dash"]
func finish():
	if $"..".current_state == self:
		if boss.waiting_for_fastball_attack and !boss.in_phase_3:
			Transitioned.emit(self,"homingfastball")
		else:
			var chosen_attack = attack_pool.pick_random()
			while chosen_attack == $"..".last_attack:
				chosen_attack = attack_pool.pick_random()
			
			Transitioned.emit(self,chosen_attack)

func exit():
	if boss.in_phase_3:
		for warning in warnings:
			warning.fade_away()
	misc_timer.stop()
	
	misc_timer.disconnect("timeout",on_misc_timer_timeout)

func _on_boss_2_enter_phase_2() -> void:
	attack_pool = ["quicklasers","homingbullethell","boss2dash","quickcuts"]
	if GlobalValues.difficulty == 2:
		warn_time = 0.5

func _on_boss_2_enter_phase_3() -> void:
	attack_pool = ["quickcuts"]
	
	if GlobalValues.difficulty == 2:
		wait_time = 0
		warn_time = 0.5
	else:
		missile_damage = 10
		warn_time = 0.75
		wait_time = 0.5
