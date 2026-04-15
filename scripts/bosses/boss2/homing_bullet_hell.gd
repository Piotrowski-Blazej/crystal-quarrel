extends State

@export var boss:Area2D
@export var misc_timer:Timer
@export var misc_timer_2:Timer
@export var dash_d_timer:Timer
@export var turrets:Array[Sprite2D]
@export var main_gun:Sprite2D

var can_fire = false

var shooting_c:float = 0.2
const bullet_damage:int = 5
const bullet_velocity:int = 10
const bullet_kb:int = 50
var parry_chance:int = 5

var homing_shooting_c:float = 2
const homing_bullet_damage:int = 10
var homing_bullet_velocity:int = 15
var homing_bullet_accel:float = 0.5
const homing_bullet_kb:int = 100
var homing_parry_chance:int = 50
const homing_bullet_lifetime:int = 5

var offset_min_max = 0.2
var player_direction:float

func _ready() -> void:
	if GlobalValues.difficulty == 3:
		shooting_c = 0.5
		parry_chance = 10
		homing_shooting_c = 3
		homing_parry_chance = 100
		homing_bullet_velocity = 11
		homing_bullet_accel = 0.35
	elif GlobalValues.difficulty == 0:
		shooting_c = 0.4
		parry_chance = 10
		homing_shooting_c = 3
		homing_bullet_velocity = 11
		homing_bullet_accel = 0.35
	elif GlobalValues.difficulty == 1:
		shooting_c = 0.3
		parry_chance = 8
		homing_shooting_c = 3
		homing_bullet_velocity = 12
		homing_bullet_accel = 0.45

var wait_time = 3#wait time after atack finishes
var duration:float
func enter():
	misc_timer.timeout.connect(on_misc_timer_timeout)
	misc_timer_2.timeout.connect(on_misc_timer_2_timeout)
	
	duration = randi_range(10,15)
	done = false
	
	var rolled_position = Vector2(1800,1800).rotated(0.5*PI*randi_range(0,3))
	boss.dash_to_position(rolled_position)
	
	boss.set_look_pos()
	player_direction = boss.look_angle
	for turret in turrets:
		turret.set_rot_target(player_direction + randf_range(-offset_min_max,offset_min_max)*PI)
	
	await dash_d_timer.timeout
	
	can_fire = true
	misc_timer.start(shooting_c)
	misc_timer_2.start(homing_shooting_c)

var done = false
func update(delta:float):
	duration -= delta
	boss.set_look_pos()
	if duration <= 0 && !done:
		done = true
		finish()

func on_misc_timer_timeout():
	if can_fire:
		for turret in turrets:
			if !turret.front:
				turret.fire(bullet_damage, bullet_velocity,bullet_kb,parry_chance,1.1,true)
		
		player_direction = boss.look_angle
		for turret in turrets:
			turret.set_rot_target(player_direction + randf_range(-offset_min_max,offset_min_max)*PI)

var left = false
func on_misc_timer_2_timeout():
	if can_fire:
		for turret in turrets:
			if turret.front and turret.left == left:
				turret.fire_homing(homing_bullet_damage, homing_bullet_velocity, homing_bullet_accel, homing_bullet_kb, homing_parry_chance,homing_bullet_lifetime , 1.5, boss, true)
		if left: left = false
		else: left = true
		
		player_direction = boss.look_angle
		for turret in turrets:
			turret.set_rot_target(player_direction + randf_range(-offset_min_max,offset_min_max)*PI)

var attack_pool:Array = ["boss2dash","bulletwall","quickmissiles"]
func finish():
	misc_timer.stop()
	misc_timer_2.stop()
	
	await get_tree().create_timer(wait_time).timeout
	
	if $"..".current_state == self:
		if boss.waiting_for_fastball_attack:
			Transitioned.emit(self,"homingfastball")
		else:
			var chosen_attack = attack_pool.pick_random()
			while chosen_attack == $"..".last_attack:
				chosen_attack = attack_pool.pick_random()
			
			Transitioned.emit(self,chosen_attack)

func exit():
	can_fire = false
	misc_timer.stop()
	misc_timer_2.stop()
	
	misc_timer.disconnect("timeout",on_misc_timer_timeout)
	misc_timer_2.disconnect("timeout",on_misc_timer_2_timeout)


func _on_boss_2_enter_phase_2() -> void:
	attack_pool = ["quicklasers","boss2dash","quickmissiles","quickcuts"]
	if GlobalValues.difficulty == 2:
		shooting_c = 0.15
		homing_shooting_c = 1
		homing_parry_chance = 40
		homing_bullet_accel = 0.6
	elif GlobalValues.difficulty == 1:
		shooting_c = 0.3
		homing_shooting_c = 1.5
		homing_bullet_velocity = 15
		homing_bullet_accel = 0.5
	elif GlobalValues.difficulty == 0 or GlobalValues.difficulty == 3:
		shooting_c = 0.3
		homing_shooting_c = 2.5
