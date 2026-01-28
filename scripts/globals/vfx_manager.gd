extends Node


func frame_freeze(time_scale:float, duration:float):
	if Engine.time_scale > time_scale:
		Engine.time_scale = time_scale
		await get_tree().create_timer(duration * time_scale).timeout
		Engine.time_scale = 1.0

var bullet_particles =  preload("res://scenes/particles/bullet_explosion.tscn")
var enemy_particles = preload("res://scenes/particles/enemy_explosion.tscn")

var bullet_particle_presets = {
	"light":{
		"amount":24,
		"velocity":Vector2i(75,250),
		"scale":Vector2(0.1,0.2)
	},
	"heavy":{
		"amount":32,
		"velocity":Vector2i(100,300),
		"scale":Vector2(0.2,0.4)
	}
}

var enemy_particle_presets = {
	"light":{
		"amount":32,
		"lifetime":5,
		"velocity":Vector2i(50,250),
		"ang_velocity":Vector2i(16,64)
	},
	"medium":{
		"amount":40,
		"lifetime":5,
		"velocity":Vector2i(100,350),
		"ang_velocity":Vector2i(16,64)
	},
	"heavy":{
		"amount":64,
		"lifetime":5,
		"velocity":Vector2i(100,500),
		"ang_velocity":Vector2i(32,128)
	},
	"heavier":{
		"amount":96,
		"lifetime":6,
		"velocity":Vector2i(100,750),
		"ang_velocity":Vector2i(32,192)
	},
	"heaviest":{
		"amount":192,
		"lifetime":7,
		"velocity":Vector2i(250,1250),
		"ang_velocity":Vector2i(32,192)
	}
}

var world_center:Node2D

func _ready() -> void:
	get_tree().scene_changed.connect(on_scene_changed)
	on_scene_changed()

func on_scene_changed():
	world_center = get_tree().get_first_node_in_group("world_center")


func spawn_bullet_particles(position:Vector2, color:Color, preset:String):
	var i_particles:CPUParticles2D = bullet_particles.instantiate()
	world_center.add_child(i_particles)
	i_particles.global_position = position
	i_particles.color = color
	
	i_particles.amount = bullet_particle_presets[preset]["amount"]
	i_particles.initial_velocity_min = bullet_particle_presets[preset]["velocity"].x
	i_particles.initial_velocity_max = bullet_particle_presets[preset]["velocity"].y
	i_particles.scale_amount_min = bullet_particle_presets[preset]["scale"].x
	i_particles.scale_amount_max = bullet_particle_presets[preset]["scale"].y

func spawn_enemy_particles(position:Vector2, color:Color, preset:String, texture:CompressedTexture2D, scale:Vector2, circle_emission_shape:bool = false, circle_radius:int = 32, z_order = -4):
	var i_particles:CPUParticles2D = enemy_particles.instantiate()
	world_center.add_child(i_particles)
	i_particles.global_position = position
	i_particles.color = color
	i_particles.texture = texture
	i_particles.scale_amount_min = scale.x
	i_particles.scale_amount_max = scale.y
	
	i_particles.amount = enemy_particle_presets[preset]["amount"]
	i_particles.initial_velocity_min = enemy_particle_presets[preset]["velocity"].x
	i_particles.initial_velocity_max = enemy_particle_presets[preset]["velocity"].y
	i_particles.angular_velocity_min = enemy_particle_presets[preset]["ang_velocity"].x
	i_particles.angular_velocity_max = enemy_particle_presets[preset]["ang_velocity"].y
	
	if circle_emission_shape:
		i_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		i_particles.emission_sphere_radius = circle_radius
	
	i_particles.z_index = z_order
