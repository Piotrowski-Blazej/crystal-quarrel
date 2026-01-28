extends State

@export var barrier_anim:AnimationPlayer
@export var boss:RigidBody2D
@export var state_machine:Node
@export var barrier:Area2D

func enter():
	barrier.setup(1)
	if barrier_anim.is_playing():
		await barrier_anim.animation_finished
	
	barrier_anim.speed_scale = 1
	barrier_anim.play("phase_2_start")
	await barrier_anim.animation_finished
	
	boss.enter_phase_2()
	barrier_anim.play("phase_2_start",-1,-1,true)
	await barrier_anim.animation_finished
	
	barrier.hit_special()
	Transitioned.emit(self,"laserspin")


func exit():
	pass
