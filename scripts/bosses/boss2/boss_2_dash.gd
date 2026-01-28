extends State

@export var animation_player:AnimationPlayer
@export var boss:Area2D
@export var misc_timer:Timer
var initial_dash_delay:float = 0.75
var dash_delay:float = 0.75
var shooting_c = 0.1
var dash_amount:int

var dash_amount_range = Vector2i(3,4)

@export var turrets:Array[Sprite2D]

func _ready() -> void:
	if GlobalValues.difficulty == 0:
		initial_dash_delay = 1.25
		shooting_c = 0.15
	elif GlobalValues.difficulty == 1:
		shooting_c = 0.15
		initial_dash_delay = 0.85

func enter():
	boss.finished_dashing.connect(finish)
	misc_timer.timeout.connect(on_misc_timer_timeout)
	
	dash_amount = randi_range(dash_amount_range.x,dash_amount_range.y)
	
	dash(initial_dash_delay)

func dash(r_delay):
	animation_player.play("dash_charge")
	boss.set_look_pos()
	boss.dash_at_player(r_delay)
	
	var offset:float = boss.look_angle
	for turret in turrets:
		if turret.left:
			turret.set_rot_target(offset- 0.5*PI)
		else:
			turret.set_rot_target(offset + 0.5*PI)
	
	await get_tree().create_timer(r_delay).timeout
	misc_timer.start(shooting_c)

func on_misc_timer_timeout():
	if boss.dashing_at_player:#yes this is needed
		for turret in turrets:
			turret.fire()

var attack_pool:Array = ["bulletwall","homingbullethell"]
func finish():
	misc_timer.stop()
	dash_amount -= 1
	if dash_amount != 0:
		dash(dash_delay)
	else:
		await get_tree().create_timer(dash_delay).timeout
		if $"..".current_state == self:
			var chosen_attack = attack_pool.pick_random()
			while chosen_attack == $"..".last_attack:
				chosen_attack = attack_pool.pick_random()
			
			Transitioned.emit(self,chosen_attack)

func exit():
	dash_amount = 1
	misc_timer.stop()
	
	boss.finished_dashing.disconnect(finish)
	misc_timer.disconnect("timeout",on_misc_timer_timeout)


func _on_boss_2_enter_phase_2() -> void:
	if GlobalValues.difficulty == 2:
		dash_amount_range = Vector2i(4,6)
		dash_delay = 0.25
	elif GlobalValues.difficulty == 1: 
		dash_amount_range = Vector2i(4,5)
		dash_delay = 0.35
	elif GlobalValues.difficulty == 0:
		dash_delay = 0.5
	attack_pool = ["quicklasers","homingbullethell","quickmissiles","quickcuts"]
