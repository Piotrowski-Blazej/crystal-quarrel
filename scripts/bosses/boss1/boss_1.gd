extends RigidBody2D

var health = 4000
var phase_2_hp = 2000
var in_phase_2 = false
var entering_phase_2 = false
var crack_thresholds = [3000,2000,1000,0]

const ENEMY_MISSILE = preload("uid://1cudyanr36wk")
const HOMING_ENEMY_BULLET = preload("uid://h2ffpsyid0df")
const bullet = preload("res://scenes/bullets/enemy_bullet.tscn")
var bullet_damage = 10
var bullet_velocity = 10
var kb = 100
var parriable_chance = 25

var movement_speed = 250
var move_to_target = false
var target_position:Vector2
var dash_speed = 1000

var world_center:Node2D
var player:RigidBody2D
var bossbar:ProgressBar

@onready var barriers = [get_node(^"Rotator/TriangleBarrier"),get_node(^"Rotator/TriangleBarrier2"),get_node(^"Rotator/TriangleBarrier3"),get_node(^"Rotator/TriangleBarrier4")]
@onready var drones = [get_node(^"Drones/Boss1Drone"),get_node(^"Drones/Boss1Drone2"),get_node(^"Drones/Boss1Drone3"),get_node(^"Drones/Boss1Drone4")]


@onready var animation_player: AnimationPlayer = $Rotator/AnimationPlayer
@onready var firepoint: Node2D = $Circle/Firepoint
@onready var state_machine: Node = $StateMachine
@onready var fading_sprite_c: Timer = $FadingSpriteC
@onready var hit_sfx: AudioStreamPlayer2D = $Sfx/HitSfx
@onready var cracks: TextureRect = $Circle/CrackClip/Cracks
@onready var death_effects: Node2D = $DeathEffects


func _ready() -> void:
	animation_player.play("rotate_barriers")
	player = get_tree().get_first_node_in_group("player")
	bossbar = get_tree().get_first_node_in_group("bossbar")
	world_center = get_tree().get_first_node_in_group("world_center")
	state_machine.setup()
	
	if GlobalValues.difficulty != 2:
		health = 3000
		phase_2_hp = 1500
		crack_thresholds = [2250,1500,750,0]
		if GlobalValues.difficulty == 0: dash_speed = 900
		elif GlobalValues.difficulty == 3:
			dash_speed = 800
			parriable_chance = 100
	
	bossbar.max_value = health
	bossbar.value = health

func _process(delta: float) -> void:
	if move_to_target && global_position.distance_to(target_position)>100:
		apply_central_force(global_position.direction_to(target_position)*100000*movement_speed*delta)

func barrier_superdash_hit(r_kb):
	player.apply_central_impulse(global_position.direction_to(player.global_position)*player.superdash_kb*0.1)
	if state_machine.current_state == $StateMachine/DashAttack or state_machine.current_state == $StateMachine/Phase2Dash:
		linear_velocity = Vector2.ZERO
		apply_central_impulse(r_kb/2)
		VfxManager.frame_freeze(0.05,0.5)
	else:
		apply_central_impulse(r_kb)
		VfxManager.frame_freeze(0.2,0.3)

func superdash_hit(damage, r_kb, hit_position:Vector2, strong_attack = false):
	player.apply_central_impulse(global_position.direction_to(player.global_position)*player.superdash_kb*0.1)
	if state_machine.current_state == $StateMachine/DashAttack or state_machine.current_state == $StateMachine/Phase2Dash:
		linear_velocity = Vector2.ZERO
		hit(damage*1.5, r_kb/2, strong_attack)
		
		VfxManager.spawn_enemy_particles(hit_position, Color.RED, "medium_spray", CIRCLE, Vector2(0.1,0.3))
		VfxManager.frame_freeze(0.05,0.5)
	else:
		VfxManager.spawn_enemy_particles(hit_position, Color.RED, "light_spray", CIRCLE, Vector2(0.1,0.2))
		VfxManager.frame_freeze(0.2,0.3)
		hit(damage, r_kb, strong_attack)

var is_dying = false
func hit(damage,r_kb,strong_attack = false):
	health -= damage
	apply_central_impulse(r_kb)
	bossbar.value = health
	bossbar.flash()
	flash()
	hit_sfx.pitch_scale = randf_range(0.9,1.1)
	hit_sfx.play()
	
	while crack_thresholds.size() != 0 && health <= crack_thresholds[0]:
		crack_thresholds.pop_front()
		cracks.progress()
	
	if !in_phase_2 && health <= phase_2_hp:
		entering_phase_2 = true
		in_phase_2 = true
		
		if !state_machine.current_state == $StateMachine/BigLaserSpin:
			state_machine.on_child_transition(state_machine.current_state, "phase2start")
	
	if !is_dying && health <= 0 && strong_attack:
		player.immortal = true
		is_dying = true
		state_machine.queue_free()
		animation_player.speed_scale = 1
		animation_player.play("die")
		for drone in drones:
			drone.die()
		for barrier in barriers:
			barrier.set_collision_layer_value(4,false)
		
		GlobalValues.camera.screen_shake(20,5)
		set_deferred("freeze",true)

@onready var shatter_sfx: AudioStreamPlayer2D = $Sfx/ShatterSfx
@onready var kill_particle_explosion: CPUParticles2D = $DeathEffects/KillParticleExplosion

func remove():
	shatter_sfx.reparent(death_effects)
	death_effects.reparent(world_center)
	death_effects.set_timer(kill_particle_explosion.lifetime)
	
	GlobalValues.camera.screen_shake(50,0.5)
	
	get_tree().get_first_node_in_group("fadeout_rect").fade_out(3,true, 3)
	queue_free()

func enter_phase_2():
	#circle.velocity_threshold = 0
	for i in range(4):
		barriers[i].repair()
		drones[i].setup(self.global_position + Vector2(1024,0).rotated(deg_to_rad(i*90)), self.global_position)
		entering_phase_2 = false

@onready var circle: Sprite2D = $Circle
var flashes:int = 0
func flash():
	flashes += 1
	circle.self_modulate = Color(1,0.5,0.5)
	await get_tree().create_timer(0.1).timeout
	flashes -= 1
	if flashes == 0:
		circle.self_modulate = Color(1,0,0)

func shoot(r_dmg = bullet_damage,r_kb = kb, r_v = bullet_velocity, r_p_c = parriable_chance,r_size = 1.2):
	var i_bullet = bullet.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	var dir:Vector2 = Vector2(1,0).rotated(firepoint.global_rotation)
	
	var color
	var can_parry = false
	if randi_range(1,100) <= r_p_c:
		can_parry = true
		color = Color8(255,0,127)
	else:
		color = Color8(255,0,0)
	
	i_bullet.setup(r_dmg,r_kb,r_v*dir,color,can_parry,r_size)
	play_sfx()

func shoot_homing(r_damage = bullet_damage, r_velocity = bullet_velocity, accel:float = 0.1,r_knockback = kb,r_parry_chance = parriable_chance, lifetime = 5, r_scale = 1.2, origin = null):
	var i_bullet = HOMING_ENEMY_BULLET.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	
	var velocity = Vector2(-1,0).rotated(self.global_rotation)*r_velocity
	var color
	var can_parry = false
	if randi_range(1,100) <= r_parry_chance:
		can_parry = true
		color = Color8(255,0,127)
	else:
		color = Color8(255,0,0)
	
	i_bullet.setup(r_damage, r_knockback, velocity, accel, color, can_parry, lifetime, r_scale, origin)
	play_sfx()

func fire_missile(warning:Sprite2D ,r_damage = bullet_damage, r_velocity = bullet_velocity, accel:float = 0.1,r_knockback = kb, target=Vector2(0,0), r_parry_chance = 0, r_scale = 1, r_e_scale = 1, origin = null):
	var i_bullet = ENEMY_MISSILE.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	
	var velocity = Vector2(0,-1).rotated(self.global_rotation)*r_velocity
	var color = Color(1,0,0)
	var can_parry = false
	if randi_range(1,100) <= r_parry_chance:
		color = Color(1,0,1)
		can_parry = true
	
	i_bullet.setup(warning, r_damage, r_knockback, velocity, accel, color, target, can_parry, r_scale, r_e_scale, origin)
	i_bullet.b_velocity = velocity*1000#ik...
	play_sfx(2)

func barrier_shoot():
	play_sfx(1)
	for i in range(barriers.size()):
		barriers[i].shoot()

@onready var shot_sfx: AudioStreamPlayer2D = $Sfx/ShotSfx
@onready var shot_sfx_loud: AudioStreamPlayer2D = $Sfx/ShotSfxLoud
@onready var missile_shot: AudioStreamPlayer2D = $Sfx/MissileShot
@onready var dash_sfx: AudioStreamPlayer2D = $Sfx/DashSfx
func play_sfx(index = 0):
	match index:
		0:
			shot_sfx_loud.pitch_scale = randf_range(1.5,2.5)
			shot_sfx_loud.play()
		1:
			shot_sfx.pitch_scale = randf_range(1.5,2.5)
			shot_sfx.play()
		2:
			missile_shot.pitch_scale = randf_range(1,1.5)
			missile_shot.play(0.1)
		3:
			dash_sfx.pitch_scale = randf_range(2.5,3.5)
			dash_sfx.play()


signal finished_dashing
signal dashed
func dash(dash_amount):
	if !entering_phase_2:
		fading_sprite_c.start()
		animation_player.play("dash_start")
		await animation_player.animation_finished
		
		play_sfx(3)
		animation_player.play("dash_end")
		apply_central_impulse(global_position.direction_to(player.global_position)*500*dash_speed)
		await animation_player.animation_finished
		
		dash_amount -= 1
		if dash_amount > 0:
			dash(dash_amount)
			dashed.emit()
		else:
			finished_dashing.emit()
			fading_sprite_c.stop()

const FADING_SPRITE = preload("uid://ddgj3uubfus7u")
const CIRCLE = preload("uid://b2ylru6nfjj31")


func _on_fading_sprite_c_timeout() -> void:
	var i_sprite = FADING_SPRITE.instantiate()
	world_center.add_child(i_sprite)
	i_sprite.global_position = self.global_position
	i_sprite.setup(Color(1,0,0,0.5),0.2,Vector2(0.8,0.8),CIRCLE)


func _on_dying_sound_timer_timeout() -> void:
	hit_sfx.pitch_scale = randf_range(0.4,1.3)
	hit_sfx.play()
