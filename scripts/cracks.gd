extends TextureRect

var crack_textures = [preload("res://sprites/crack1.png"),preload("res://sprites/crack2.png"),preload("res://sprites/crack3.png"),preload("res://sprites/crack4.png")]
var crack_progress:int = 0

@export var particles:CPUParticles2D
@export var starting_alpha:float = 0.6
@export var alpha_increase:float = 0.1

@export var particle_amount_small = 32
@export var particle_amount_large = 128

func _ready() -> void:
	self_modulate.a = starting_alpha

func progress():
	if crack_progress < 5:
		texture = crack_textures[crack_progress]
		crack_progress += 1
		self_modulate.a += alpha_increase
	
	if crack_progress == 4:
		particles.emitting = false
		particles.amount = particle_amount_large
		particles.explosiveness = 0
		particles.one_shot = false
		particles.emitting = true
	else:
		particles.emitting = false
		particles.amount = particle_amount_small
		particles.emitting = true

func stop_particles():
	particles.emitting = false
	particles.explosiveness = 1
	particles.one_shot = true

func reset():
	crack_progress = 0
	texture = null
	self_modulate.a = starting_alpha
	stop_particles()
