extends Sprite2D

@export var left = false
@export var front = false

var look_rot:float
var rot_speed = 0.05

const BULLET = preload("res://scenes/bullets/enemy_bullet.tscn")
const HOMING_BULLET = preload("res://scenes/bullets/homing_enemy_bullet.tscn")
var bullet_damage = 10
var bullet_velocity = 10
var kb = 100
var parriable_chance = 20

var world_center:Node2D
@onready var firepoint: Node2D = $Triangle/Firepoint
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var laser_cast: RayCast2D = $LaserCast
@onready var laser_charge_vfx: CPUParticles2D = $LaserChargeVfx
@onready var laser_warning: Polygon2D = $LaserWarning
@onready var laser_sfx: AudioStreamPlayer2D = $LaserSfx

func _ready() -> void:
	world_center = get_tree().get_first_node_in_group("world_center")

func _process(_delta: float) -> void:
	global_rotation = lerp_angle(global_rotation, look_rot, rot_speed)

func rotate_instantly(r_rot):
	global_rotation = r_rot

func set_rot_target(r_rot):
	look_rot = r_rot
	#if look_rot > PI*2:
		#look_rot -= PI*2

func fire(r_damage = bullet_damage, r_velocity = bullet_velocity,r_knockback = kb,r_parry_chance = parriable_chance, r_scale = 1.2, play_anim = false):
	if play_anim:
		animation_player.play("gun_recoil")
	
	var i_bullet = BULLET.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	
	var velocity = Vector2(1,0).rotated(self.global_rotation)*r_velocity
	var color = Color(1,0,0)
	var can_parry = false
	if randi_range(1,100) <= r_parry_chance:
		color = Color(1,0,1)
		can_parry = true
	
	i_bullet.setup(r_damage,r_knockback,velocity,color,can_parry,r_scale)
	play_sfx(1)

func fire_homing(r_damage = bullet_damage, r_velocity = bullet_velocity, accel:float = 0.1,r_knockback = kb,r_parry_chance = parriable_chance, lifetime = 5, r_scale = 1.2, origin = null, play_anim = false):
	if play_anim:
		animation_player.play("gun_recoil")
	
	var i_bullet = HOMING_BULLET.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	
	var velocity = Vector2(1,0).rotated(self.global_rotation)*r_velocity
	var color = Color(1,0,0)
	var can_parry = false
	if randi_range(1,100) <= r_parry_chance:
		color = Color(1,0,1)
		can_parry = true
	
	i_bullet.setup(r_damage, r_knockback, velocity, accel, color, can_parry, lifetime, r_scale, origin)
	play_sfx(0)

@onready var shot_sfx: AudioStreamPlayer2D = $ShotSfx
@onready var shot_sfx_loud: AudioStreamPlayer2D = $ShotSfxLoud
func play_sfx(index = 0):
	match index:
		0:
			shot_sfx_loud.pitch_scale = randf_range(1.5,2.5)
			shot_sfx_loud.play()
		1:
			shot_sfx.pitch_scale = randf_range(1.5,2.5)
			shot_sfx.play()

func fire_laser(r_duration = laser_cast.duration, warn_time = 0.5):
	laser_charge_vfx.emitting = true
	
	warn()
	await get_tree().create_timer(warn_time).timeout
	warn(false)
	
	laser_cast.fire(r_duration)

func warn(on = true):
	if on:
		laser_warning.show()
	else:
		laser_warning.hide()

const CIRCLE = preload("uid://b2ylru6nfjj31")
func die():
	VfxManager.spawn_enemy_particles(global_position, self.self_modulate ,"heavier", CIRCLE, Vector2(0.2,0.4), false, 0, -2)
	queue_free()
