extends RigidBody2D

@export var hurt_sfx_pitch = Vector2(0.6,1)
@export var parry_sfx_pitch = Vector2(1.4,1.6)

@export_category("health")
@export var max_health = 100
var health = 100
@export var healing_per_charge = 5
var immortal = false

@export_category("movement")
@export var dash_to_mouse  = true
const fading_sprite = preload("res://scenes/fading_sprite.tscn")
@export var speed = 2000
@export var dash_force = 2500

@export_category("bullets")
const normal_bullet = preload("res://scenes/bullets/player_bullet.tscn")
const heavy_bullet = preload("res://scenes/bullets/heavy_player_bullet.tscn")
@export var shootingC = 0.2
@export var bullet_damage = 50
@export var bullet_kb = 25
@export var bullet_velocity = 15
@export var recoil = 1

@export_category("laser")
@export var charge_time:float = 1
@export var duration = 0.5
@export var duration_increase = 0.1

@export_category("parrying")
@export var parry_duration:float = 0.3
@export var parry_cooldown:float = 0.5
var parry_charges:int = 0
var parry_time:float
var parrying = false

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


@onready var hurt_sfx: AudioStreamPlayer2D = $HurtSfx
@onready var parry_sfx: AudioStreamPlayer2D = $ParrySfx
@onready var laser_sfx: AudioStreamPlayer2D = $LaserSfx

@onready var healthbar: ProgressBar = $Healthbar

var world_center:Node2D

func _ready() -> void:
	world_center = get_tree().get_first_node_in_group("world_center")
	health = max_health
	parry_charge_pulse.play("pulse")
	$Rotator/Circle.self_modulate = Color8(255,255,255)
	
	if GlobalValues.difficulty == 0:
		health = 200
		max_health = 200
		healing_per_charge = 10
	elif GlobalValues.difficulty == 1:
		health = 160
		max_health = 160
		healing_per_charge = 8
	elif GlobalValues.difficulty == -1:
		immortal = true
	
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
	
	if Input.is_action_just_pressed("dash"):
		if candash == true:
			candash = false
			dash()
	if Input.is_action_just_pressed("fire_laser"):
		if parry_charges > 4:
			charge_laser(charge_time)
	if Input.is_action_just_pressed("heal"):
		if parry_charges > 0:
			heal()
	if Input.is_action_just_pressed("shoot_heavy"):
		if parry_charges > 0:
			shoot_heavy()
	elif Input.is_action_pressed("shoot"):
		if can_shoot == true:
			shoot()
	if Input.is_action_just_pressed("parry"):
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
		if give_i_frames: i_frames.start()
		invincibility_animation.play("inv_anim")
		if bullet != null:
			bullet.die()
		apply_central_impulse(r_kb)
		play_animation("hurt")
		VfxManager.frame_freeze(0.25,0.2)
		hurt_sfx.pitch_scale = randf_range(hurt_sfx_pitch.x,hurt_sfx_pitch.y)
		hurt_sfx.play()
		
		healthbar.flash()
	
	if health <= 0:
		if !immortal: die()
		else:         health = 0

func die():
	healthbar.hide()
	parry_ring_clip.hide()
	rotator.hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	kill_particle_explosion.emitting = true
	
	hurt_sfx.volume_db = 4
	hurt_sfx.pitch_scale = 0.5
	hurt_sfx.play()
	
	get_tree().get_first_node_in_group("fadeout_rect").fade_out(3)

func play_animation(anim_name):
	if animation_player.is_playing():
		animation_player.stop()
	animation_player.play(anim_name)

var frame_velocity = Vector2(0,0)
func _integrate_forces(_state):
	frame_velocity = Vector2.ZERO
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
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	var dir:Vector2 = (firepoint.global_position - global_position).normalized()
	i_bullet.set_velocity(bullet_velocity*dir)
	apply_central_impulse(-(firepoint.global_position - global_position)*recoil)
	shooting_cooldown.start(shootingC)

func shoot_heavy():
	VfxManager.frame_freeze(0.1,0.2)
	
	can_shoot = false
	var i_bullet = heavy_bullet.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	var dir:Vector2 = (firepoint.global_position - global_position).normalized()
	i_bullet.set_velocity(bullet_velocity*dir*2)
	apply_central_impulse(-(firepoint.global_position - global_position)*recoil*10)
	shooting_cooldown.start(shootingC*2)
	
	parry_charges -= 1
	parry_ring_clip.value = parry_charges

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
	dash_cooldown.start()
	var d_dir: Vector2
	if dash_to_mouse: d_dir = (Vector2(1,0).rotated(rotator.global_rotation))*dash_force
	else:             d_dir = (frame_velocity.normalized()*dash_force)
	
	linear_velocity = Vector2(0,0)
	self.apply_central_impulse(d_dir)


func _on_dash_cooldown_timeout() -> void:
	candash = true


func _on_shooting_cooldown_timeout() -> void:
	can_shoot = true

const circle_sprite = preload("res://sprites/Circle.png")

func _on_fading_sprite_c_timeout() -> void:
	var i_sprite = fading_sprite.instantiate()
	world_center.add_child(i_sprite)
	i_sprite.global_position = self.global_position
	i_sprite.setup(Color(0,1,0,0.5),0.2,Vector2(0.3,0.3),circle_sprite)
