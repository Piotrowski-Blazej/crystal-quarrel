extends RayCast2D

@export var is_strong_attack = true
@export var damage:int = 10
@export var kb:int = 25
@export var recoil:int = 1000
@export var line_2d:Line2D
@export var laser_line_particles:CPUParticles2D
@export var laser_end_particles:CPUParticles2D
@export var laser_start_particles:CPUParticles2D
@export var rotator:Node2D
@export var laser_sfx:AudioStreamPlayer2D
var laser_end_position:Vector2

@onready var player: RigidBody2D = $"../.."

func _ready() -> void:
	set_physics_process(false)

func _physics_process(_delta: float) -> void:
	player.apply_central_force(-Vector2(1,0).rotated(rotator.global_rotation)*recoil)
	force_raycast_update()
	if is_colliding():
		laser_end_position = to_local(get_collision_point())
		
		var body = get_collider()
		if !body.is_in_group("wall") && body.is_in_group("takes_damage"):
			var knockback = global_position.direction_to(body.global_position)*kb
			body.hit(damage,knockback,is_strong_attack)
	line_2d.points[1] = laser_end_position
	
	laser_line_particles.emission_rect_extents.x = laser_end_position.x/2
	laser_line_particles.position.x = laser_end_position.x/2
	
	laser_end_particles.position.x = laser_end_position.x
	if !line_2d.visible:
		line_2d.show()

func fire(r_duration):
	laser_line_particles.emitting = true
	laser_end_particles.emitting = true
	laser_start_particles.emitting = true
	rotator.delayed = true
	
	set_physics_process(true)
	await get_tree().create_timer(r_duration,true,true).timeout
	set_physics_process(false)
	line_2d.hide()
	laser_sfx.stop()
	
	rotator.delayed = false
	laser_line_particles.emitting = false
	laser_end_particles.emitting = false
	laser_start_particles.emitting = false
