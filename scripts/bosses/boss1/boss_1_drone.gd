extends RigidBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var rotator: Node2D = $Scaler/Rotator
@onready var pentagon: Sprite2D = $Scaler/Pentagon

@onready var laser_charge_vfx: CPUParticles2D = $Scaler/Pentagon/LaserChargeVfx
@onready var laser_cast: RayCast2D = $Scaler/Pentagon/LaserCast
@onready var laser_warning: Polygon2D = $Scaler/Pentagon/LaserWarning

@onready var shatter_sfx: AudioStreamPlayer2D = $DeathEffects/ShatterSfx
@onready var death_effects: Node2D = $DeathEffects
@onready var kill_particle_explosion: CPUParticles2D = $DeathEffects/KillParticleExplosion


var awake = false
var moving = false
var target_pos:Vector2
var speed = 350000

func setup(r_target_pos, start_pos):
	self.show()
	moving = true
	target_pos = r_target_pos
	global_position = start_pos
	freeze = false
	
	animation_player.play("start_flight")
	await animation_player.animation_finished
	
	awake = true

func die():
	kill_particle_explosion.emitting = true
	shatter_sfx.play()
	death_effects.set_timer(kill_particle_explosion.lifetime)
	death_effects.reparent(GlobalValues.world_center)
	
	self.queue_free()

func set_target_pos(r_pos:Vector2):
	target_pos = r_pos

func set_override_direction(r_direction):
	pentagon.override_direction = r_direction

#func rotate_around_boss(start_end:bool):
	#if start_end:
		#pentagon.override = true
	#else:
		#pentagon.override = false

func _process(delta: float) -> void:
	var distance_to_target = global_position.distance_to(target_pos)
	if moving:
		if distance_to_target>100:
			apply_central_force(global_position.direction_to(target_pos)*speed*delta)
		else:
			apply_central_force(global_position.direction_to(target_pos)*speed*delta/2)
	
	if awake:
		rotator.global_rotation_degrees += delta*180
		if rotator.global_rotation_degrees > 180:
			rotator.global_rotation_degrees -= 180

func fire_laser(r_duration = laser_cast.duration, stop_moving = true, warning_time:float = 0.5):
	pentagon.active = false
	laser_charge_vfx.emitting = true
	if stop_moving:
		moving = false
	
	warn()
	await get_tree().create_timer(warning_time).timeout
	warn(false)
	
	laser_cast.fire(r_duration)
	apply_central_impulse(Vector2(1,0).rotated(pentagon.global_rotation+deg_to_rad(90))*250)
	
	await get_tree().create_timer(r_duration).timeout
	
	pentagon.active = true
	if stop_moving:
		moving = true

func warn(on = true):
	if on:
		laser_warning.show()
	else:
		laser_warning.hide()
