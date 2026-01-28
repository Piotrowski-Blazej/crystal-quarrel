extends Area2D

#@export var explosion = preload("res://scenes/particles/light_bullet_explosion.tscn")
var damage: int
var kb: int
var max_velocity:float
var b_velocity: Vector2
var accel:float
var can_parry
var target:Node2D
var origin
var strong = false

var player:RigidBody2D
var world_center:Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	world_center = get_tree().get_first_node_in_group("world_center")
	
	target = player

func setup(d,k,v:Vector2,a:float,c:Color,p:bool = false,l = 5,s=1,r_origin=null,r_strong=false):
	damage = d
	kb = k
	b_velocity = v
	max_velocity = v.length()
	accel = a
	modulate = c
	can_parry = p
	scale *= s
	origin = r_origin
	$Lifetime.start(l)
	strong = r_strong

func _on_lifetime_timeout():
	die()

func _process(delta):
	if is_instance_valid(target):
		if can_parry && global_position.distance_to(target.global_position) < 100:
			b_velocity = global_position.direction_to(target.global_position)*max_velocity
		else:
			b_velocity += global_position.direction_to(target.global_position)*accel*delta*100
		
		if b_velocity.length() > max_velocity:
			b_velocity = b_velocity.normalized()*max_velocity
		
		global_position += b_velocity*delta*100
	else:
		die()

func _on_body_entered(body):
	if body.is_in_group("takes_damage"):
		var knockback = global_position.direction_to(body.global_position)*kb
		body.hit(damage,knockback)
	if body.is_in_group("player"):
		body.hit(damage,b_velocity*kb,can_parry,self)
	else:
		die()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("takes_damage"):
		area.hit(damage,Vector2(0,0))
		die()
	if strong && area.is_in_group("barrier"):
		area.hit_special()
		die()

func parried():
	if origin != null:
		b_velocity *= -1
		accel *= 2
		$Lifetime.start(10)
		target = origin
		set_collision_mask_value(2,false)
		set_collision_mask_value(4,true)
		damage *= 5
		modulate = Color(0,1,0)
	else:
		die()

func die():
	VfxManager.spawn_bullet_particles(self.global_position, self.modulate, "light")
	queue_free()

const FADING_SPRITE = preload("uid://ddgj3uubfus7u")
const CIRCLE = preload("uid://b2ylru6nfjj31")

func _on_fading_spirte_c_timeout() -> void:
	var i_sprite = FADING_SPRITE.instantiate()
	world_center.add_child(i_sprite)
	
	i_sprite.global_position = self.global_position
	i_sprite.global_rotation = self.global_rotation
	i_sprite.setup(Color(modulate.r,modulate.g,modulate.b,0.5),0.2,scale*0.15,CIRCLE)
