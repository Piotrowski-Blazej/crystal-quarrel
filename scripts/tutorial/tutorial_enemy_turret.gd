extends RigidBody2D

@onready var firepoint: Node2D = $Circle/Firepoint

var health = 500
var crack_thresholds = [375,250,125,0]

const BULLET = preload("res://scenes/bullets/enemy_bullet.tscn")
var bullet_damage = 10
var bullet_velocity = 10
var kb = 100
var parriable_chance = 25

var player
var bullet_holder:Node2D

const CIRCLE = preload("uid://b2ylru6nfjj31")
@onready var hit_sfx: AudioStreamPlayer2D = $Sfx/HitSfx
@onready var shatter_sfx: AudioStreamPlayer2D = $DeathEffects/ShatterSfx
@onready var shot_sfx: AudioStreamPlayer2D = $Sfx/ShotSfx
@onready var cracks: TextureRect = $Circle/CrackClip/Cracks
@onready var death_effects: Node2D = $DeathEffects
@onready var kill_particle_explosion: CPUParticles2D = $DeathEffects/KillParticleExplosion
@onready var shooting_c: Timer = $ShootingC


func _ready() -> void:
	player = GlobalValues.player
	bullet_holder = get_tree().get_first_node_in_group("bullet_holder")

func superdash_hit(damage, r_kb, hit_position:Vector2, strong_attack = false):
	player.apply_central_impulse(global_position.direction_to(player.global_position)*player.superdash_kb*0.1)
	
	VfxManager.spawn_enemy_particles(hit_position, Color.RED, "light_spray", CIRCLE, Vector2(0.1,0.2))
	VfxManager.frame_freeze(0.2,0.3)
	hit(damage, r_kb, strong_attack)

var is_dying = false
func hit(damage,r_kb,strong_attack = false):
	health -= damage
	apply_central_impulse(r_kb)
	
	flash()
	hit_sfx.pitch_scale = randf_range(0.9,1.1)
	hit_sfx.play()
	
	while crack_thresholds.size() != 0 && health <= crack_thresholds[0]:
		crack_thresholds.pop_front()
		cracks.progress()
	
	if !is_dying && health <= 0 && strong_attack:
		player.immortal = true
		is_dying = true
		
		death_effects.reparent(GlobalValues.world_center)
		kill_particle_explosion.emitting = true
		shatter_sfx.play()
		death_effects.set_timer(3)
		
		GlobalValues.camera.screen_shake(1,0.2)
		set_deferred("freeze",true)
		queue_free()

@onready var circle: Sprite2D = $Circle
var flashes:int = 0
func flash():
	flashes += 1
	circle.self_modulate = Color(1,0.5,0.5)
	await get_tree().create_timer(0.1).timeout
	flashes -= 1
	if flashes == 0:
		circle.self_modulate = Color(1,0,0)


func _on_shooting_c_timeout() -> void:
	var i_bullet = BULLET.instantiate()
	bullet_holder.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	var dir:Vector2 = Vector2(1,0).rotated(firepoint.global_rotation)
	
	var color
	var can_parry = false
	if randi_range(1,100) <= parriable_chance:
		can_parry = true
		color = Color8(255,0,127)
	else:
		color = Color8(255,0,0)
	
	i_bullet.setup(bullet_damage,kb,bullet_velocity*dir,color,can_parry,1)
	shot_sfx.play()
