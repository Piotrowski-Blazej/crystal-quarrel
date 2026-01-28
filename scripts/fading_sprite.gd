extends Sprite2D

var lifetime = 0.5
var starting_lifetime
var starting_a

func setup(c:Color,l,s,t):
	lifetime = l
	starting_lifetime = l
	self_modulate = c
	starting_a = c.a
	scale = s
	texture = t

func _process(delta: float) -> void:
	lifetime -= delta
	
	self_modulate.a = lifetime/starting_lifetime*starting_a
	
	if lifetime <= 0:
		queue_free()
