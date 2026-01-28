extends StaticBody2D

var health = 100

@onready var hit_sfx: AudioStreamPlayer2D = $HitSfx
@onready var death_effects: Node2D = $DeathEffects
@onready var shatter_sfx: AudioStreamPlayer2D = $DeathEffects/ShatterSfx
@onready var kill_particle_explosion: CPUParticles2D = $DeathEffects/KillParticleExplosion


func hit(damage,_r_kb,_strong_attack = false):
	health -= damage
	flash()
	hit_sfx.pitch_scale = randf_range(0.9,1.1)
	hit_sfx.play()
	
	if health <= 0: die()

@onready var polygon_2d: Polygon2D = $Polygon2D
var flashes:int = 0
func flash():
	flashes += 1
	polygon_2d.color = Color(1,0.5,0.5)
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
