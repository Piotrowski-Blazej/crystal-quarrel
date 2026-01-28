extends State

@export var barrier_anim:AnimationPlayer
@export var boss:RigidBody2D
@export var state_machine:Node

func enter():
	barrier_anim.speed_scale = 0.4
	boss.dash(randi_range(3,4))
	boss.move_to_target = false
	boss.linear_damp = 1
	
	boss.finished_dashing.connect(finish)

func finish():
	boss.finished_dashing.disconnect(finish)
	var attack_pool:Array = ["biglaserspin","centerspin","missilecross"]
	var chosen_attack = attack_pool.pick_random()
	while chosen_attack == state_machine.last_attack:
		chosen_attack = attack_pool.pick_random()
	Transitioned.emit(self,chosen_attack)

func exit():
	boss.linear_damp = 10
	barrier_anim.speed_scale = 0.2
