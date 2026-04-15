extends State

@export var boss:Area2D
@export var barrier:Area2D
@export var misc_timer:Timer
@export var dash_d_timer:Timer
@export var main_gun:Sprite2D

var homing_shooting_c = 1
const homing_bullet_damage = 10
var homing_bullet_velocity = 30
var homing_bullet_accel:float = 2.5
var homing_bullet_kb = 100
const homing_parry_chance = 50
var homing_bullet_lifetime = 1.2

var player_direction:float

var can_shoot = false

func _ready() -> void:
	if GlobalValues.difficulty == 3:
		homing_bullet_lifetime = 1.6
		homing_shooting_c = 1.8
		homing_bullet_velocity = 20
		homing_bullet_kb = 10
		homing_bullet_accel = 1.25
	elif GlobalValues.difficulty == 0:
		homing_bullet_lifetime = 1.6
		homing_shooting_c = 1.4
		homing_bullet_velocity = 20
		homing_bullet_kb = 20
	elif GlobalValues.difficulty == 1:
		homing_bullet_lifetime = 1.4
		homing_shooting_c = 1.2
		homing_bullet_velocity = 25
		homing_bullet_kb = 50

var wait_time = 2#wait time before and after atack finishes
func enter():
	can_shoot = false
	misc_timer.timeout.connect(on_misc_timer_timeout)
	barrier.barrier_shattered.connect(finish)
	boss.dash_to_position(Vector2(0,0))
	
	await get_tree().create_timer(wait_time).timeout
	
	can_shoot = true
	misc_timer.start(homing_shooting_c)


func update(_delta:float):
	boss.set_look_pos()


func on_misc_timer_timeout():
	if can_shoot:
		main_gun.fire_homing(homing_bullet_damage, homing_bullet_velocity, homing_bullet_accel, homing_bullet_kb, homing_parry_chance,homing_bullet_lifetime , 1.5, boss, true, true)


var attack_pool:Array = ["boss2dash","bulletwall","homingbullethell"]
func finish():
	misc_timer.stop()
	
	await get_tree().create_timer(wait_time).timeout
	
	if $"..".current_state == self:
		var chosen_attack = attack_pool.pick_random()
		while chosen_attack == $"..".last_attack:
			chosen_attack = attack_pool.pick_random()
		
		Transitioned.emit(self,chosen_attack)

func exit():
	boss.waiting_for_fastball_attack = false
	misc_timer.stop()
	misc_timer.disconnect("timeout",on_misc_timer_timeout)
	barrier.disconnect("barrier_shattered",finish)


func _on_boss_2_enter_phase_2() -> void:
	attack_pool = ["boss2dash","quicklasers","quickcuts"]
