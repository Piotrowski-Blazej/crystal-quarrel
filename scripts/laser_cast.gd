extends RayCast2D

var damage_dealt:int = 0
@export var max_damage:int = 20
@export var impact_damage:int = 10
@export var damage:int
@export var kb:int
@export var line_2d:Line2D
@export var duration:float
@export var laser_line_particles:CPUParticles2D
@export var laser_end_particles:CPUParticles2D
@export var laser_start_particles:CPUParticles2D
@export var laser_sfx:AudioStreamPlayer2D
var laser_end_position:Vector2
var has_dealt_damage = false
var did_damage_last_frame = false

func _ready() -> void:
	set_physics_process(false)

func _physics_process(_delta: float) -> void:
	force_raycast_update()
	if is_colliding():
		laser_end_position = to_local(get_collision_point())
		
		var body = get_collider()
		if body.is_in_group("player"):
			var knockback = global_position.direction_to(body.global_position)*kb
			
			if !has_dealt_damage:
				body.hit(impact_damage,knockback,false,null,false)
				damage_dealt += impact_damage
				has_dealt_damage = true
			elif !did_damage_last_frame:
				if damage_dealt < max_damage:
					body.hit(damage,knockback,false,null,false)
					damage_dealt += damage
			
			if !did_damage_last_frame:
				did_damage_last_frame = true
			else:
				did_damage_last_frame = false
	line_2d.points[1] = laser_end_position
	
	laser_line_particles.emission_rect_extents.x = laser_end_position.x/2
	laser_line_particles.position.x = laser_end_position.x/2
	
	laser_end_particles.position.x = laser_end_position.x
	if !line_2d.visible:
		line_2d.show()

func fire(r_duration = duration):#by default it's the duration var
	has_dealt_damage = false
	laser_line_particles.emitting = true
	laser_end_particles.emitting = true
	laser_start_particles.emitting = true
	
	laser_sfx.pitch_scale = randf_range(1.4,1.6)
	laser_sfx.play()
	set_physics_process(true)
	await get_tree().create_timer(r_duration,true,true).timeout
	set_physics_process(false)
	line_2d.hide()
	laser_sfx.stop()
	
	laser_line_particles.emitting = false
	laser_end_particles.emitting = false
	laser_start_particles.emitting = false
