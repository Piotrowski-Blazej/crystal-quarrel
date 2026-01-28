extends Area2D

#@export var explosion = preload("res://scenes/particles/light_bullet_explosion.tscn")
var damage: int
var kb: int
var b_velocity: Vector2
var can_parry


func setup(d,k,v,c:Color,p:bool = false,s=1):
	damage = d
	kb = k
	b_velocity = v
	modulate = c
	can_parry = p
	scale *= s

func _on_lifetime_timeout():
	die()

func _process(delta):
	global_position += b_velocity*delta*100

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.hit(damage,b_velocity*kb,can_parry,self)
	die()

func parried():
	die()

func die():
	VfxManager.spawn_bullet_particles(self.global_position, self.modulate, "light")
	queue_free()
