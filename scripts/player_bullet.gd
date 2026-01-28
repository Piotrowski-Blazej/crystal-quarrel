extends Area2D

@export var damage = 10
@export var kb = 25
@export var strong = false
var b_velocity: Vector2

func set_velocity(v):
	b_velocity = v

func _on_lifetime_timeout():
	die()

func _process(delta):
	global_position += b_velocity*delta*100

func _on_body_entered(body):
	if body.is_in_group("takes_damage"):
		body.hit(damage,(body.global_position-global_position)*kb,strong)
	
	die()

func die():
	if !strong:
		VfxManager.spawn_bullet_particles(self.global_position, Color(0,1,0), "light")
	else:
		VfxManager.spawn_bullet_particles(self.global_position, Color(0,1,0), "heavy")
	queue_free()


func _on_area_entered(area: Area2D) -> void: 
	if area.is_in_group("takes_damage"):
		area.hit(damage,0,strong)
	die()
