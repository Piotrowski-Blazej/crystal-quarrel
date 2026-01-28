extends State

@export var animation_player:AnimationPlayer
@export var boss:Area2D
@export var misc_timer:Timer
var cut_c = 0.2
var parriable_chance = 40

const BOSS_2_CUT = preload("uid://wvounlrfbbm0")
var cut_amount:int
var cut_amount_range = Vector2i(22,28)

var in_phase_3 = false

var player:RigidBody2D
var world_center:Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	world_center = get_tree().get_first_node_in_group("world_center")
	if GlobalValues.difficulty == 0: 
		cut_c = 0.5
		cut_amount_range = Vector2i(10,14)
	elif GlobalValues.difficulty == 1: 
		cut_c = 0.35
		cut_amount_range = Vector2i(14,18)

func enter():
	animation_player.play("fly_up")
	await animation_player.animation_finished
	
	if $"..".current_state == self:
		if in_phase_3: boss.global_position = Vector2(0,10000)#move out of sight (cause particles are visible)
		else: boss.global_position = Vector2.ZERO
		
		cut_amount = randi_range(cut_amount_range.x, cut_amount_range.y)
		
		misc_timer.timeout.connect(on_misc_timer_timeout)
		misc_timer.start(cut_c)

const WAIT_TIME = 1
func on_misc_timer_timeout():
	if cut_amount > 0:
		var p = GlobalValues.ARENA_BOUNDS
		var rand_pos:Vector2
		if cut_amount % 4 == 0:
			rand_pos = player.global_position
		else:
			rand_pos = Vector2(randi_range(-p, p), randi_range(-p, p))
		var rand_rot = randf_range(0,2)*PI
		
		var can_parry = false
		if randi_range(1,100) <= parriable_chance: can_parry = true
		
		var i_cut = BOSS_2_CUT.instantiate()
		world_center.add_child(i_cut)
		i_cut.setup(rand_pos, rand_rot, can_parry)
		
		cut_amount -= 1
	else:
		misc_timer.stop()
		await get_tree().create_timer(WAIT_TIME).timeout
		if !in_phase_3:
			animation_player.play_backwards("fly_up")
			await animation_player.animation_finished
		finish()

var attack_pool:Array = ["quickmissiles","quicklasers","homingbullethell","boss2dash"]
func finish():
	if $"..".current_state == self:
		var chosen_attack = attack_pool.pick_random()
		while !in_phase_3 && chosen_attack == $"..".last_attack:
			chosen_attack = attack_pool.pick_random()
		
		Transitioned.emit(self,chosen_attack)

func exit():
	misc_timer.stop()
	
	misc_timer.disconnect("timeout",on_misc_timer_timeout)

func _on_boss_2_enter_phase_3() -> void:
	attack_pool = ["finalcuts"]
	if GlobalValues.difficulty == 2:
		cut_amount_range = Vector2(10,14)
		cut_c = 0.12
	else:
		cut_amount_range = Vector2(8,12)
		cut_c = 0.15
	
	in_phase_3 = true
	parriable_chance = 0
