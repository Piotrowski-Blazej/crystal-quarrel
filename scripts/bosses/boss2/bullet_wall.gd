extends State

@export var main_anim_player:AnimationPlayer
@export var boss:Area2D
@export var misc_timer:Timer
@export var dash_d_timer:Timer
@export var front_turrets:Array[Sprite2D]
const attack_delay:float = 0.35
const shooting_c = 0.01

const bullet_damage = 10
const bullet_velocity = 15
const bullet_kb = 25
const parry_chance = 0

var player_direction:float
var turret_offset:float = -0.75
const turret_offset_limit = 0.75
var clockwise = true
var turn_time:float = 1
var rotating = false
var turn_amount:int
var turn_amount_range = Vector2i(3,5)

var fire_area_scale = 5

func _ready() -> void:
	if GlobalValues.difficulty == 0:
		turn_time = 1.7
		fire_area_scale = 4
		turn_amount_range = Vector2i(3,3)
	elif GlobalValues.difficulty == 1:
		turn_amount_range = Vector2i(3,4)
		turn_time = 1.3
		fire_area_scale = 4

func enter():
	misc_timer.timeout.connect(on_misc_timer_timeout)
	rotating = false
	
	if randi_range(1,2) == 1: clockwise = true
	else: clockwise = false
	
	if clockwise: turret_offset = -turret_offset_limit
	else: turret_offset = turret_offset_limit
	
	turn_amount = randi_range(turn_amount_range.x,turn_amount_range.y)
	
	boss.dash_to_position(Vector2(0,0))
	await dash_d_timer.timeout
	
	boss.set_look_pos()
	
	player_direction = boss.look_angle
	for turret in front_turrets:
		turret.rotate_instantly(player_direction + turret_offset*PI)
	
	main_anim_player.play("fire_area")
	await main_anim_player.animation_finished
	if $"..".current_state == self:
		main_anim_player.play("RESET")
		
		boss.spawn_fire_area(fire_area_scale, (2*turret_offset_limit*turn_time)*turn_amount + (attack_delay*(turn_amount-1)))
		rotating = true
		misc_timer.start(shooting_c)

func finished_rotation():
	turn_amount -= 1
	if turn_amount == 0:
		await get_tree().create_timer(attack_delay).timeout
		finish()
	else:
		if randi_range(1,2) == 1: clockwise = true
		else: clockwise = false
		
		misc_timer.stop()
		rotating = false
		await get_tree().create_timer(attack_delay).timeout
		rotating = true
		misc_timer.start()


func update(delta:float):
	if !rotating:
		boss.set_look_pos()
		player_direction = boss.look_angle
		
		if clockwise: turret_offset = -turret_offset_limit
		else: turret_offset = turret_offset_limit
		for turret in front_turrets:
			turret.set_rot_target(player_direction + turret_offset*PI)
	else:
		if clockwise:
			turret_offset += delta/turn_time
			for turret in front_turrets:
				turret.set_rot_target(player_direction + turret_offset*PI)
			if turret_offset >= turret_offset_limit:
				finished_rotation()
		else:
			turret_offset -= delta/turn_time
			for turret in front_turrets:
				turret.set_rot_target(player_direction + turret_offset*PI)
			if turret_offset <= -turret_offset_limit:
				finished_rotation()

func on_misc_timer_timeout():
	for turret in front_turrets:
		turret.fire(bullet_damage, bullet_velocity,bullet_kb,parry_chance,1.3)


func finish():
	if $"..".current_state == self:
		var attack_pool:Array = ["boss2dash","homingbullethell"]
		var chosen_attack = attack_pool.pick_random()
		while chosen_attack == $"..".last_attack:
			chosen_attack = attack_pool.pick_random()
		
		Transitioned.emit(self,chosen_attack)

func exit():
	misc_timer.stop()
	misc_timer.disconnect("timeout",on_misc_timer_timeout)
