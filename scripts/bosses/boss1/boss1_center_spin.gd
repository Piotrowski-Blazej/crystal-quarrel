extends State

@export var barrier_anim:AnimationPlayer
@export var boss:RigidBody2D
@export var shooting_timer:Timer
@export var barrier_s_timer:Timer
@export var state_machine:Node

var shooting_c = 0.5
var barrier_shooting_c = 0.15

func _ready() -> void:
	if GlobalValues.difficulty == 1:
		barrier_shooting_c = 0.25;
		shooting_c = 0.7
	elif GlobalValues.difficulty == 0:
		barrier_shooting_c = 0.35;
		shooting_c = 1

func enter():
	barrier_anim.speed_scale = 0.2
	barrier_anim.play("rotate_barriers")
	barrier_anim.connect("animation_finished",restart_animation)
	shooting_timer.start(shooting_c)
	barrier_s_timer.start(barrier_shooting_c)
	
	boss.move_to_target = true
	boss.target_position = Vector2(0,0)
	duration = randi_range(8,12)
	
	shooting_timer.connect("timeout",_on_shooting_c_timeout)
	barrier_s_timer.connect("timeout",_on_barrier_shooting_c_timeout)

func restart_animation(_anim_name):#can't be looped cause it would never transition to phase 2
	barrier_anim.play("rotate_barriers")

func exit():
	shooting_timer.stop()
	barrier_s_timer.stop()
	
	barrier_anim.disconnect("animation_finished",restart_animation)
	shooting_timer.disconnect("timeout",_on_shooting_c_timeout)
	barrier_s_timer.disconnect("timeout",_on_barrier_shooting_c_timeout)

var duration:float = 10
func update(delta:float):
	duration -= delta
	if duration <= 0:
		barrier_anim.speed_scale = 0.4
		await barrier_anim.animation_finished
		var attack_pool:Array = ["biglaserspin","dashattack","missilecross"]
		var chosen_attack = attack_pool.pick_random()
		while chosen_attack == state_machine.last_attack:
			chosen_attack = attack_pool.pick_random()
		Transitioned.emit(self,chosen_attack)
	elif duration <= 0.5:
		shooting_timer.stop()
		barrier_s_timer.stop()

func _on_shooting_c_timeout() -> void:
	boss.shoot()


func _on_barrier_shooting_c_timeout() -> void:
	boss.barrier_shoot()
