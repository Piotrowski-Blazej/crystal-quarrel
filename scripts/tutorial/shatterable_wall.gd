extends StaticBody2D

@export var health = 400
var crack_thresholds = [health*0.75,health*0.5,health*0.25,0]


@onready var hit_sfx: AudioStreamPlayer2D = $HitSfx
@onready var death_effects: Node2D = $DeathEffects
@onready var shatter_sfx: AudioStreamPlayer2D = $DeathEffects/ShatterSfx
@onready var kill_particle_explosion: CPUParticles2D = $DeathEffects/KillParticleExplosion
@onready var cracks: TextureRect = $Cracks


func hit(damage,_r_kb,strong_attack = false):
	health -= damage
	flash()
	hit_sfx.pitch_scale = randf_range(0.9,1.1)
	hit_sfx.play()
	
	while crack_thresholds.size() != 0 && health <= crack_thresholds[0]:
		crack_thresholds.pop_front()
		cracks.progress()
	
	if crack_thresholds.size() == 0 && strong_attack:
		die()

@onready var polygon_2d: Polygon2D = $Polygon2D
var flashes:int = 0
func flash():
	flashes += 1
	polygon_2d.color = Color(1,0.1,0.1)
	await get_tree().create_timer(0.1).timeout
	flashes -= 1
	if flashes == 0:
		polygon_2d.color = Color(1,0,0)

func die():
	kill_particle_explosion.emitting = true
	shatter_sfx.play()
	death_effects.reparent(GlobalValues.world_center)
	death_effects.set_timer(5)
	
	queue_free()
