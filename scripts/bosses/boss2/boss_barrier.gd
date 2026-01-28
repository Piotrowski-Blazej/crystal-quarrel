extends Area2D

@onready var cracks: TextureRect = $Visuals/Circle2/Cracks
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visuals: Node2D = $Visuals

@onready var shatter_effects: Node2D = $ShatterEffects
@onready var kill_particle_explosion: CPUParticles2D = $ShatterEffects/KillParticleExplosion
@onready var shatter_sfx: AudioStreamPlayer2D = $ShatterEffects/ShatterSfx


var health:int = 5
var shatter_on_death = false

signal barrier_shattered

func setup(r_health = 5, should_shatter_on_death = false):
	shatter_on_death = should_shatter_on_death
	health = r_health
	visuals.show()
	process_mode = Node.PROCESS_MODE_INHERIT
	cracks.reset()
	animation_player.play("barrier_grow")
	await animation_player.animation_finished
	animation_player.play("barrier_pulse")

func hit_special():
	health -= 1
	if health == 0:
		if !shatter_on_death:
			kill_particle_explosion.emitting = true
			shatter_sfx.play()
			
			barrier_shattered.emit()
			cracks.stop_particles()
			visuals.hide()
			process_mode = Node.PROCESS_MODE_DISABLED
		else:
			kill_particle_explosion.emitting = true
			shatter_sfx.play()
			shatter_effects.reparent(GlobalValues.world_center)
			shatter_effects.set_timer(kill_particle_explosion.lifetime)
			queue_free()
	else:
		cracks.progress()
