extends Area2D

var damage: int
var kb: int
var max_velocity:float
var b_velocity: Vector2
var accel:float
var can_parry
var target:Vector2
var target_node:Node2D
var origin
var strong = false
var explosion_scale:float

const EXPLOSION = preload("uid://bxppculw4fxxk")

var was_parried = false
var warning:Sprite2D
var should_explode = false

@onready var circle: Sprite2D = $Circle

var world_center:Node2D
var player

func _ready() -> void:
	world_center = get_tree().get_first_node_in_group("world_center")

func setup(r_warning:Sprite2D,d,k,v:Vector2,a:float,c:Color,r_target:Vector2,p:bool = false,s=1,e_s=1,r_origin=null,r_strong=false):
	warning = r_warning
	damage = d
	kb = k
	b_velocity = v
	max_velocity = v.length()
	accel = a
	circle.self_modulate = c
	target = r_target
	can_parry = p
	scale *= s
	explosion_scale = e_s
	origin = r_origin
	strong = r_strong
	
	if p:
		set_collision_mask_value(2,true)
		player = GlobalValues.player
		warning.fade_away()
		circle.self_modulate.r = 1.5
		circle.self_modulate.b = 1.5


var quick_home_distance_mult:float = 10
func _process(delta):
	quick_home_distance_mult += delta
	circle.look_at(global_position+b_velocity)
	
	if !was_parried && !can_parry:
		var distance = global_position.distance_to(target)
		
		if distance <= max_velocity:
			should_explode = true
		elif distance <= max_velocity*quick_home_distance_mult:
			b_velocity = global_position.direction_to(target)*max_velocity
		else:
			b_velocity += global_position.direction_to(target)*accel*delta*100
	
	elif !was_parried:
		var p_pos = player.global_position
		if global_position.distance_to(p_pos) <= max_velocity*5:
			b_velocity = global_position.direction_to(p_pos)*max_velocity
		else:
			b_velocity += global_position.direction_to(p_pos)*accel*delta*100
	
	else:
		if is_instance_valid(target_node):
			b_velocity += global_position.direction_to(target_node.global_position)*accel*delta*100
		else:
			die()
	
	if b_velocity.length() > max_velocity:
		b_velocity = b_velocity.normalized()*max_velocity
	
	global_position += b_velocity*delta*100
	
	if should_explode:
		explode()

func explode():
	var i_explosion = EXPLOSION.instantiate()
	world_center.add_child(i_explosion)
	if !was_parried: i_explosion.global_position = target
	else: i_explosion.global_position = global_position
	i_explosion.setup(damage, kb, explosion_scale, was_parried)
	
	GlobalValues.camera.screen_shake(10,0.5,0.1)
	
	die()

func _on_body_entered(body):
	if body.is_in_group("player"):
		var knockback = global_position.direction_to(body.global_position)*kb
		body.hit(damage, knockback, true, self, true)
	else:
		should_explode = true

func _on_area_entered(_area: Area2D) -> void:
	should_explode = true

func parried():
	if origin != null:
		b_velocity *= -1
		accel *= 2
		was_parried = true
		target_node = origin
		set_collision_mask_value(2,false)
		set_collision_mask_value(4,true)
		damage *= 5
		circle.self_modulate = Color(0,1,0)
	else:
		die()

func die():
	VfxManager.spawn_bullet_particles(self.global_position, self.modulate, "light")
	if is_instance_valid(warning):
		warning.fade_away()
	queue_free()

const FADING_SPRITE = preload("uid://ddgj3uubfus7u")
const CIRCLE = preload("uid://b2ylru6nfjj31")

func _on_fading_spirte_c_timeout() -> void:
	var i_sprite = FADING_SPRITE.instantiate()
	world_center.add_child(i_sprite)
	
	i_sprite.global_position = self.global_position
	i_sprite.global_rotation = self.global_rotation
	i_sprite.setup(Color(modulate.r,modulate.g,modulate.b,0.5),0.2,scale*0.15,CIRCLE)
