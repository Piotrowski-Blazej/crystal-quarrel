extends Area2D

const bullet = preload("res://scenes/bullets/enemy_bullet.tscn")
var bullet_damage = 5
var bullet_velocity = 5
var kb = 100

var max_health:int = 1000
var health:int = 1000
var crack_thresholds = [850,700,550,400]#also set in the repair function (ik)
var broken = false

var contact_damage = 10

var world_center:Node2D

const TRIANGLE = preload("uid://qcxqwk2iu6h6")
const ENEMY_MISSILE = preload("uid://1cudyanr36wk")


@onready var firepoint: Node2D = $Firepoint
@onready var triangle: Sprite2D = $Triangle
@onready var cracks: TextureRect = $Triangle/Cracks
@export var hit_sfx: AudioStreamPlayer2D
@export var shatter_sfx: AudioStreamPlayer2D

func _ready() -> void:
	world_center = get_tree().get_first_node_in_group("world_center")
	if GlobalValues.difficulty == 0:
		max_health = 700
		health = 700
		crack_thresholds = [575,450,325,200]

func hit(damage,_kb = 0, strong_attack = false):
	health -= damage
	
	while crack_thresholds.size() != 0 && health <= crack_thresholds[0]:
		crack_thresholds.pop_front()
		cracks.progress()
	
	if (crack_thresholds.is_empty() && strong_attack) or health <= 0:
		cracks.stop_particles()
		set_collision_layer_value(4,false)
		triangle.self_modulate = Color(1,0,0,0.5)
		remove_from_group("takes_damage")
		broken = true
		shatter_sfx.play()
		VfxManager.spawn_enemy_particles(self.global_position, Color(1,0,0), "heavy", TRIANGLE, Vector2(0.4,0.4))
	else:
		flash()
		hit_sfx.pitch_scale = randf_range(0.6,0.8)
		hit_sfx.play()

func die():
	shatter_sfx.play()
	VfxManager.spawn_enemy_particles(self.global_position, Color(1,0,0), "heavier", TRIANGLE, Vector2(0.4,0.4))
	queue_free()

var flashes:int = 0
func flash():
	flashes += 1
	triangle.self_modulate = Color(1,0.5,0.5)
	await get_tree().create_timer(0.1).timeout
	flashes -= 1
	if flashes == 0 && !broken:
		triangle.self_modulate = Color(1,0,0)

func shoot():
	var i_bullet = bullet.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	var dir:Vector2 = Vector2(1,0).rotated(self.global_rotation-deg_to_rad(90))
	
	var color = Color8(255,0,0)
	i_bullet.setup(bullet_damage,kb,bullet_velocity*dir,color)

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

func repair():
	if GlobalValues.difficulty == 0: crack_thresholds = [300,250,200,150]
	else: crack_thresholds = [425,350,275,200]
	cracks.reset()
	@warning_ignore("integer_division")
	health = max_health/2
	broken = false
	set_collision_layer_value(4,true)
	triangle.self_modulate = Color(1,0,0)
	add_to_group("takes_damage")

func _on_body_entered(body: Node2D) -> void:
	body.hit(contact_damage,Vector2(0,0),false,null)
