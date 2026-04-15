extends RigidBody2D

var hurt_sfx_pitch = Vector2(0.6,1)
var parry_sfx_pitch = Vector2(1.4,1.55)

var max_health = 100
var health = 100
var healing_per_charge = 5
var immortal = false
var invincibility_time:float = 0.5

var dash_to_mouse:bool  = true
const fading_sprite:PackedScene = preload("res://scenes/fading_sprite.tscn")
var speed:int = 2000
var dash_force:int = 2500
var dash_c:float = 0.25

var superdash_force_multiplier:int = 2
var superdash_damage:int = 80
var superdash_kb:int = 10000
var superdash_invincibility_time:float = 0.5
var superdash_c:float = 1
var is_superdashing:bool = false


const normal_bullet:PackedScene = preload("res://scenes/bullets/player_bullet.tscn")
const heavy_bullet:PackedScene = preload("res://scenes/bullets/heavy_player_bullet.tscn")
var shootingC:float = 0.2
var bullet_damage:int = 50
var bullet_kb:int = 25
var bullet_velocity:int = 15
var recoil:int = 1

var charge_time:float = 1
var duration:float = 0.5
var duration_increase:float = 0.1


var parry_duration:float = 0.3
var parry_cooldown:float = 0.5
var parry_charges:int = 0
var parry_time:float
var parrying = false
const PARRY_RANGE:int = 80

var can_shoot = false
var candash = true

@onready var kill_particle_explosion: CPUParticles2D = $KillParticleExplosion

@onready var rotator: Node2D = $Rotator
@onready var firepoint: Node2D = $Rotator/Firepoint
@onready var laser_cast: RayCast2D = $Rotator/LaserCast
@onready var laser_charge_vfx: CPUParticles2D = $Rotator/LaserChargeVfx
@onready var fire_detector: Area2D = $FireDetector


@onready var dash_cooldown: Timer = $Timers/DashCooldown
@onready var shooting_cooldown: Timer = $Timers/ShootingCooldown
@onready var parry_c: Timer = $Timers/ParryC
@onready var fading_sprite_c: Timer = $Timers/FadingSpriteC
@onready var i_frames: Timer = $Timers/IFrames

@onready var invincibility_animation: AnimationPlayer = $InvincibilityAnimation
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_anim_player: AnimationPlayer = $CameraAnimPlayer
@onready var parry_charge_pulse: AnimationPlayer = $ParryRingClip/ParryCharge/ParryChargePulse
@onready var parry_ring_clip: TextureProgressBar = $ParryRingClip
@onready var parry_effect_anim: AnimationPlayer = $ParryEffect/ParryEffectAnim

@onready var hurt_sfx: AudioStreamPlayer2D = $Sfx/HurtSfx
@onready var parry_sfx: AudioStreamPlayer2D = $Sfx/ParrySfx
@onready var laser_sfx: AudioStreamPlayer2D = $Sfx/LaserSfx
@onready var superdash_hit_sfx: AudioStreamPlayer2D = $Sfx/SuperdashHitSfx

@onready var healthbar: ProgressBar = $Healthbar

@onready var tutorial_node: Node2D = $".."

var can_move = true
var can_dash = false
var can_fire = false
var can_parry = false
var can_heal = false
var can_superdash = false
var can_laser = false

var teleporting_player = true
var teleport_destination:Vector2

signal player_parried

var world_center:Node2D
var bullet_holder:Node2D

func _ready() -> void:
	world_center = get_tree().get_first_node_in_group("world_center")
	bullet_holder = get_tree().get_first_node_in_group("bullet_holder")
	health = max_health
	parry_charge_pulse.play("pulse")
	$Rotator/Circle.self_modulate = Color8(255,255,255)
	
	healthbar.max_value = max_health
	healthbar.value = max_health

var delta_:float

func _process(delta):
	delta_ = delta
	
	if !candash:
		if fading_sprite_c.is_stopped():
			fading_sprite_c.start()
	else:
		fading_sprite_c.stop()
	
	if health > max_health:
		health = max_health
	
	if parry_time > 0:
		parry_time -= delta
	
	if parry_time > 0:
		parrying = true
	else:
		parrying = false
	
	if can_dash and Input.is_action_just_pressed("dash"):
		if candash:
			candash = false
			dash()
	if can_laser and Input.is_action_just_pressed("fire_laser"):
		if parry_charges > 4:
			charge_laser(charge_time)
	if can_heal and Input.is_action_just_pressed("heal"):
		if parry_charges > 0:
			heal()
	if can_superdash and Input.is_action_just_pressed("superdash"):
		if candash and parry_charges > 0:
			parry_charges -= 1
			parry_ring_clip.value = parry_charges
			superdash()
	elif can_fire and Input.is_action_pressed("shoot"):
		if can_shoot == true:
			shoot()
	if can_parry and Input.is_action_just_pressed("parry"):
		if parry_time <= 0 && parry_c.is_stopped():
			parry()
			parry_c.start(parry_cooldown)
	
	if parry_charges == 0:
		parry_ring_clip.hide()
	else:
		parry_ring_clip.show()
	healthbar.value = health

func _physics_process(_delta: float) -> void:
	if fire_detector.has_overlapping_areas():
		health -= 1
		if health <= 0:
			if !immortal: die()
			else:         health = 0

func play_camera_animation(animation_name:String): camera_anim_player.play(animation_name)

func parry():
	parry_time = parry_duration
	play_animation("parrying")
	parry_effect_anim.play("parry")


const MAX_PARRY_CHARGES:int = 10
func hit(r_damage,r_kb,r_can_parry,bullet,give_i_frames = true):
	var parried = false
	if parrying:
		if r_can_parry:
			parry_time = 0
			parried = true
			bullet.parried()
			GlobalValues.hits_parried += 1
			apply_central_impulse(r_kb/2)
			VfxManager.frame_freeze(0.05,0.4)
			
			parry_sfx.pitch_scale = randf_range(parry_sfx_pitch.x,parry_sfx_pitch.y)
			parry_sfx.play()
			
			parry_effect_anim.play("successfull_parry")
			candash = true
			parry_c.stop()
			
			player_parried.emit()
			if parry_charges < MAX_PARRY_CHARGES:
				parry_charges += 1
				parry_ring_clip.value = parry_charges
			else:
				heal(false)
		elif i_frames.is_stopped() && give_i_frames:
			GlobalValues.damage_taken += r_damage
			health -= r_damage
	
	if !parried && (i_frames.is_stopped() or !give_i_frames):
		GlobalValues.damage_taken += r_damage
		health -= r_damage
		if give_i_frames: i_frames.start(invincibility_time)
		invincibility_animation.play("inv_anim")
		apply_central_impulse(r_kb)
		play_animation("hurt")
		VfxManager.frame_freeze(0.25,0.2)
		
		hurt_sfx.volume_db = -10#I'm so sorry for my code
		hurt_sfx.pitch_scale = randf_range(hurt_sfx_pitch.x,hurt_sfx_pitch.y)
		hurt_sfx.play()
		
		healthbar.flash()
		
		if bullet != null:
			bullet.die()
	elif !i_frames.is_stopped() && bullet != null:
		bullet.die()
		hurt_sfx.volume_db = -20
		hurt_sfx.pitch_scale = randf_range(hurt_sfx_pitch.x,hurt_sfx_pitch.y)
		hurt_sfx.play()
	
	
	if health <= 0:
		health = max_health
		#if !immortal: die()
		#else:         health = 0

func die():
	healthbar.hide()
	parry_ring_clip.hide()
	rotator.hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	kill_particle_explosion.emitting = true
	
	hurt_sfx.volume_db = -2
	hurt_sfx.pitch_scale = 0.5
	hurt_sfx.play()
	
	get_tree().get_first_node_in_group("fadeout_rect").fade_out(3)

func play_animation(anim_name):
	if animation_player.is_playing():
		animation_player.stop()
	animation_player.play(anim_name)

var frame_velocity = Vector2(0,0)
func _integrate_forces(_state):
	if teleporting_player:
		teleporting_player = false
		global_position = teleport_destination
		linear_velocity = Vector2.ZERO
	else:
		frame_velocity = Vector2.ZERO
		if can_move:
			if Input.is_action_pressed("move_down"):
				frame_velocity.y += 1
			if Input.is_action_pressed("move_up"):
				frame_velocity.y -= 1
			if Input.is_action_pressed("move_right"):
				frame_velocity.x += 1
			if Input.is_action_pressed("move_left"):
				frame_velocity.x -= 1
			
			apply_central_force(frame_velocity.normalized()*speed)

func shoot():
	can_shoot = false
	var i_bullet = normal_bullet.instantiate()
	bullet_holder.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	var dir:Vector2 = (firepoint.global_position - global_position).normalized()
	i_bullet.set_velocity(bullet_velocity*dir)
	apply_central_impulse(-(firepoint.global_position - global_position)*recoil)
	shooting_cooldown.start(shootingC)

func superdash():
	VfxManager.frame_freeze(0.1,0.2)
	
	candash = false
	dash_cooldown.start(superdash_c)
	var d_dir: Vector2 = (Vector2(1,0).rotated(rotator.global_rotation))*dash_force*superdash_force_multiplier
	
	i_frames.start(superdash_invincibility_time)
	is_superdashing = true
	
	
	linear_velocity = Vector2(0,0)
	self.apply_central_impulse(d_dir)

func heal(all_charges = true):
	if all_charges:
		while health < max_health && parry_charges > 0:
			health += healing_per_charge
			parry_charges -= 1
		parry_ring_clip.value = parry_charges
	else:
		health += healing_per_charge

func charge_laser(charge_t):
	laser_charge_vfx.emitting = true
	var charged = false
	
	laser_sfx.volume_db = -6
	laser_sfx.pitch_scale = 1.5
	laser_sfx.play()
	
	while charge_t > 0 && Input.is_action_pressed("fire_laser"):
		charge_t -= delta_
		if charge_t <= 0:
			charged = true
		await get_tree().process_frame
	
	if charged:
		fire_laser()
		laser_sfx.volume_db = 0
		laser_sfx.pitch_scale = 1.8
		laser_sfx.play()
	else:
		laser_charge_vfx.emitting = false
		laser_sfx.stop()

func fire_laser():
	var laser_duration = duration + duration_increase*(parry_charges-5)
	laser_cast.fire(laser_duration)
	VfxManager.frame_freeze(0.5,laser_duration+1)
	parry_charges = 0

func dash():
	dash_cooldown.start(dash_c)
	var d_dir: Vector2
	if dash_to_mouse: d_dir = (Vector2(1,0).rotated(rotator.global_rotation))*dash_force
	else:             d_dir = (frame_velocity.normalized()*dash_force)
	
	linear_velocity = Vector2(0,0)
	self.apply_central_impulse(d_dir)


func _on_dash_cooldown_timeout() -> void:
	if is_superdashing: is_superdashing = false
	candash = true


func _on_shooting_cooldown_timeout() -> void:
	can_shoot = true

const circle_sprite = preload("res://sprites/Circle.png")

func _on_fading_sprite_c_timeout() -> void:
	var i_sprite = fading_sprite.instantiate()
	world_center.add_child(i_sprite)
	i_sprite.global_position = self.global_position
	i_sprite.setup(Color(0,1,0,0.5),0.2,Vector2(0.3,0.3),circle_sprite)


func _on_superdash_connection(body: Node) -> void:
	if is_superdashing:
		if body.is_in_group("takes_damage"):
			var kb: Vector2 = global_position.direction_to(body.global_position)*superdash_kb*25
			var hit_pos: Vector2 = global_position+global_position.direction_to(body.global_position)*38#38 is the player's radius
			
			linear_velocity = Vector2.ZERO
			body.superdash_hit(superdash_damage, kb, hit_pos, true)
		elif body.is_in_group("barrier"):
			linear_velocity = Vector2.ZERO
			apply_central_impulse(-global_position.direction_to(body.global_position)*superdash_kb*0.1)
		
		is_superdashing = false
		superdash_hit_sfx.pitch_scale = randf_range(0.9, 1.0)
		superdash_hit_sfx.play()
