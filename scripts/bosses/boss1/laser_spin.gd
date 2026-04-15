extends State

@export var barrier_anim:AnimationPlayer
@export var boss:RigidBody2D
@export var shooting_timer:Timer
@export var barrier_s_timer:Timer
@export var misc_state_timer:Timer
@export var state_machine:Node
@export var rotator:Node2D
@export var drones:Array[RigidBody2D]

var exiting = false

var barrier_shooting_c:float = 0.15
var bullet_attack_speed:float = 0.75
var laser_attack_speed:float = 1
var laser_warn_time:float = 0.5
const laser_duration:float = 0.5


func _ready() -> void:
	if GlobalValues.difficulty == 3:
		laser_attack_speed = 2
		laser_warn_time = 1.25
		barrier_shooting_c = 0.5;
		bullet_attack_speed = 1
		parriable_chance = 100
	if GlobalValues.difficulty == 0:
		laser_attack_speed = 1.5
		laser_warn_time = 1
		barrier_shooting_c = 0.35;
		bullet_attack_speed = 1
	elif GlobalValues.difficulty == 1:
		laser_attack_speed = 1.25
		laser_warn_time = 0.75
		barrier_shooting_c = 0.25
		bullet_attack_speed = 1

func enter():
	exiting = false
	barrier_anim.speed_scale = 0.2
	barrier_anim.play("rotate_barriers")
	barrier_anim.connect("animation_finished",restart_animation)
	
	boss.move_to_target = true
	boss.target_position = Vector2(0,0)
	duration = randi_range(10,14)
	
	await get_tree().create_timer(2).timeout
	
	shooting_timer.connect("timeout",_on_shooting_c_timeout)
	barrier_s_timer.connect("timeout",_on_barrier_shooting_c_timeout)
	misc_state_timer.connect("timeout",_on_misc_timer_timeout)
	
	shooting_timer.start(bullet_attack_speed)
	barrier_s_timer.start(barrier_shooting_c)
	misc_state_timer.start(laser_attack_speed)

func restart_animation(_irrelevant):#can't be looped cause it would never transition to phase 2 from centerspin
	barrier_anim.play("rotate_barriers")

func exit():
	barrier_s_timer.stop()
	shooting_timer.stop()
	misc_state_timer.stop()
	
	shooting_timer.wait_time = 0.5
	
	barrier_anim.disconnect("animation_finished",restart_animation)
	shooting_timer.disconnect("timeout",_on_shooting_c_timeout)
	barrier_s_timer.disconnect("timeout",_on_barrier_shooting_c_timeout)
	misc_state_timer.disconnect("timeout",_on_misc_timer_timeout)

var duration:float = 10
func update(delta:float):
	duration -= delta
	if duration <= 0 && !exiting:
		exiting = true
		barrier_anim.speed_scale = 0.4
		await barrier_anim.animation_finished
		
		var attack_pool:Array = ["phase2dash","biglaserspin","missilecross"]
		var chosen_attack = attack_pool.pick_random()
		while chosen_attack == state_machine.last_attack:
			chosen_attack = attack_pool.pick_random()
		Transitioned.emit(self,chosen_attack)
		
	elif duration <= 0.5 && !shooting_timer.is_stopped():
		shooting_timer.stop()
		barrier_s_timer.stop()
		misc_state_timer.stop()
	
	for i in range(4):
		var pos = boss.global_position + Vector2(512,0).rotated(rotator.global_rotation + deg_to_rad(90*i))
		drones[i].set_target_pos(pos)


func _on_barrier_shooting_c_timeout() -> void:
	boss.barrier_shoot()

const bullet_damage = 10
const bullet_velocity = 10
const kb = 100
var parriable_chance = 40
func _on_shooting_c_timeout() -> void:
	boss.shoot(bullet_damage, kb, bullet_velocity, parriable_chance)

var current_drone:int = 0
func _on_misc_timer_timeout() -> void:
	drones[current_drone].fire_laser(laser_duration, true, laser_warn_time)
	current_drone += 1
	if current_drone > 3: current_drone = 0
