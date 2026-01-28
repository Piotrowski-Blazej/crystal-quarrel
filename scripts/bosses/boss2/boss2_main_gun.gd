extends Sprite2D

const BULLET = preload("res://scenes/bullets/enemy_bullet.tscn")
const HOMING_BULLET = preload("res://scenes/bullets/homing_enemy_bullet.tscn")
const ENEMY_MISSILE = preload("uid://1cudyanr36wk")

var bullet_damage = 20
var bullet_velocity = 10
var kb = 100
var parriable_chance = 20

var world_center:Node2D
@onready var firepoint: Node2D = $Pentagon/Firepoint
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var pentagon: Sprite2D = $Pentagon

func _ready() -> void:
	world_center = get_tree().get_first_node_in_group("world_center")


func fire(r_damage = bullet_damage, r_velocity = bullet_velocity,r_knockback = kb,r_parry_chance = parriable_chance, r_scale = 1.2, play_anim = false):
	if play_anim:
		animation_player.speed_scale = 1
		animation_player.play("gun_recoil")
	
	var i_bullet = BULLET.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	
	var velocity = Vector2(0,-1).rotated(self.global_rotation)*r_velocity
	var color = Color(1,0,0)
	var can_parry = false
	if randi_range(1,100) <= r_parry_chance:
		color = Color(1,0,1)
		can_parry = true
	
	i_bullet.setup(r_damage,r_knockback,velocity,color,can_parry,r_scale)
	play_sfx(1)

func fire_homing(r_damage = bullet_damage, r_velocity = bullet_velocity, accel:float = 0.1,r_knockback = kb,r_parry_chance = parriable_chance, lifetime = 5, r_scale = 1.2, origin = null, play_anim = false, strong = false):
	if play_anim:
		animation_player.speed_scale = 1
		animation_player.play("gun_recoil")
	
	var i_bullet = HOMING_BULLET.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	
	var velocity = Vector2(0,-1).rotated(self.global_rotation)*r_velocity
	var color = Color(1,0,0)
	var can_parry = false
	if randi_range(1,100) <= r_parry_chance:
		color = Color(1,0,1)
		can_parry = true
	
	i_bullet.setup(r_damage, r_knockback, velocity, accel, color, can_parry, lifetime, r_scale, origin, strong)
	play_sfx(0)

func fire_missile(warning:Sprite2D ,r_damage = bullet_damage, r_velocity = bullet_velocity, accel:float = 0.1,r_knockback = kb, target=Vector2(0,0), r_parry_chance = parriable_chance, r_scale = 1, r_e_scale = 1, origin = null, play_anim = true, strong = false):
	if play_anim:
		animation_player.speed_scale = 5
		animation_player.play("gun_recoil")
	
	var i_bullet = ENEMY_MISSILE.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	
	var velocity = Vector2(0,-1).rotated(self.global_rotation)*r_velocity
	var color = Color(1,0,0)
	var can_parry = false
	if randi_range(1,100) <= r_parry_chance:
		color = Color(1,0,1)
		can_parry = true
	
	i_bullet.setup(warning, r_damage, r_knockback, velocity, accel, color, target, can_parry, r_scale, r_e_scale, origin, strong)
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

const PENTAGON = preload("uid://24hsw0luxhoj")
func die():
	VfxManager.spawn_enemy_particles(global_position, pentagon.self_modulate , "heaviest", PENTAGON, Vector2(0.4,0.6), false, 0, -2)
	queue_free()
