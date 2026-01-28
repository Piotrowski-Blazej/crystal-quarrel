extends State

@export var animation_player:AnimationPlayer
@export var boss:RigidBody2D
@export var misc_timer:Timer
@export var state_machine:Node
@export var barriers:Array[Area2D]
var shooting_c = 0.16
var missile_amount = 200#ANIMATION_SPIN_TIME/shooting_c*4
var missile_positions:Array[Vector2]

const missile_damage = 20
const missile_velocity = 20
const missile_accel:float = 3
const missile_kb = 100
const missile_parry_chance = 1
const missile_scale = 1.5
const explosion_scale = 0.4

const CIRCLE_WARNING = preload("uid://bsuiardtyixtn")
const ANIMATION_CHARGE_TIME:int = 1
const ANIMATION_SPIN_TIME:int = 8
var warnings:Array[Sprite2D]

var player:RigidBody2D
var world_center:Node2D

const ARENA_SIZE = 2048

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	world_center = get_tree().get_first_node_in_group("world_center")

func enter():
	misc_timer.timeout.connect(on_misc_timer_timeout)
	
	for i in range(missile_amount):
		var new_pos:Vector2 = Vector2(randi_range(-ARENA_SIZE,ARENA_SIZE),
									randi_range(-ARENA_SIZE,ARENA_SIZE))
		
		missile_positions.append(new_pos)
		
		var i_warn = CIRCLE_WARNING.instantiate()
		world_center.add_child.call_deferred(i_warn)
		i_warn.global_position = missile_positions[i]
		i_warn.setup(explosion_scale)
		
		warnings.append(i_warn)
	
	animation_player.speed_scale = 1
	animation_player.play("missile_spin")
	
	await get_tree().create_timer(ANIMATION_CHARGE_TIME).timeout
	
	misc_timer.start(shooting_c)

func on_misc_timer_timeout():
	if missile_positions.size() > 0:
		for i in range(4):
			if randi_range(1,25) == 1:
				missile_positions[0] = player.global_position
				warnings[0].global_position = player.global_position
			warnings[0].appear()
			barriers[i].fire_missile(warnings[0], missile_damage, missile_velocity, missile_accel, missile_kb, missile_positions[0], missile_parry_chance, missile_scale, explosion_scale, boss)
			missile_positions.pop_front()
			warnings.pop_front()
	else:
		misc_timer.stop()
		await get_tree().create_timer(ANIMATION_CHARGE_TIME).timeout
		finish()

var attack_pool:Array = ["biglaserspin","dashattack","centerspin"]
func finish():
	if $"..".current_state == self:
		var chosen_attack = attack_pool.pick_random()
		while chosen_attack in state_machine.last_2_attacks:
			chosen_attack = attack_pool.pick_random()
		Transitioned.emit(self,chosen_attack)

func exit():
	misc_timer.wait_time = 0.5
	misc_timer.stop()
	
	misc_timer.disconnect("timeout",on_misc_timer_timeout)
