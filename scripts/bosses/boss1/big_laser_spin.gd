extends State

@export var barrier_anim:AnimationPlayer
@export var boss:RigidBody2D
@export var state_machine:Node
@export var laser_charge_vfx:CPUParticles2D
@export var laser:Area2D
@export var circle:Sprite2D
@export var laser_sfx:AudioStreamPlayer2D

var attack_duration:float = 4.5
var charge_time:float = 2.5
var laser_duration:float = 1.5
var animation_duration:float = 0.5
var rotaion_speed:int = 240

var rotate = false

func _ready() -> void:
	match GlobalValues.difficulty:
		3:
			charge_time = 3
			attack_duration = 7.5
		0:
			charge_time = 2.5
			attack_duration = 6.5
		1:
			charge_time = 2.5
			attack_duration = 5.5
		2:
			charge_time = 2.5
			attack_duration = 4.5

var changed_values_in_phase_2 = false
func enter():
	if boss.in_phase_2 && !changed_values_in_phase_2:
		charge_time -= 1
		attack_duration -= 1
		changed_values_in_phase_2 = true
	
	duration = attack_duration
	laser_duration = duration-charge_time-0.5
	@warning_ignore("narrowing_conversion")
	rotaion_speed = 360/laser_duration
	
	barrier_anim.speed_scale = 1.5/(charge_time+duration)
	
	barrier_anim.stop()
	barrier_anim.play("rotate_barriers")
	
	boss.move_to_target = true
	boss.target_position = Vector2(0,0)
	
	if randi_range(0,1) == 1:
		direction = -1
	
	laser.warn()
	circle.enabled = false
	laser_charge_vfx.lifetime = charge_time
	laser_charge_vfx.emitting = true
	rotate = false
	
	laser_sfx.pitch_scale = 0.8
	laser_sfx.volume_db = -12
	laser_sfx.play()
	
	await get_tree().create_timer(charge_time).timeout
	laser.fire(laser_duration)
	await get_tree().create_timer(animation_duration).timeout
	rotate = true


func exit():
	circle.enabled = true

var direction:int = 1
var duration:float
func update(delta:float):
	duration -= delta
	if rotate && duration > 0:
		circle.global_rotation_degrees += rotaion_speed*delta*direction
	
	if duration <= 0 && !barrier_anim.is_playing():
		if !boss.entering_phase_2:
			if boss.in_phase_2:
				var attack_pool:Array = ["laserspin","phase2dash","missilecross"]
				var chosen_attack = attack_pool.pick_random()
				while chosen_attack == state_machine.last_attack:
					chosen_attack = attack_pool.pick_random()
				Transitioned.emit(self,chosen_attack)
			else:
				var attack_pool:Array = ["dashattack","centerspin","missilecross"]
				var chosen_attack = attack_pool.pick_random()
				while chosen_attack == state_machine.last_attack:
					chosen_attack = attack_pool.pick_random()
				Transitioned.emit(self,chosen_attack)
		else:
			Transitioned.emit(self,"phase2start")
