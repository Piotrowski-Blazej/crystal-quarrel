extends Area2D

@onready var thruster_particles: CPUParticles2D = $ThrusterParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var lifetime:float
var player:RigidBody2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func setup(s:float = 1,l:float = 1):
	self.scale *= s
	lifetime = l
	@warning_ignore("narrowing_conversion")
	thruster_particles.amount *= s*s
	thruster_particles.emitting = true
	
	animation_player.play("fade_in_ring")

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 1:
		animation_player.play("fade_away")
	if lifetime <= 0:
		queue_free()
