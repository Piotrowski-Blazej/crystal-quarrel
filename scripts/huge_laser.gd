extends Area2D


@export var max_damage:int = 40
@export var impact_damage:int = 20
@export var damage:int = 2
@export var kb:int = 200
@export var line_2d:Line2D
@export var duration:float
@export var laser_line_top_particles:CPUParticles2D
@export var laser_line_bottom_particles:CPUParticles2D
@export var laser_start_particles:CPUParticles2D
@export var anim_player:AnimationPlayer
@export var warning:Polygon2D
@export var laser_sfx:AudioStreamPlayer2D

var damage_dealt:int = 0


var player:RigidBody2D

func _ready() -> void:
	set_physics_process(false)
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	if !visible:
		show()
	if self.has_overlapping_bodies():
		var knockback = global_position.direction_to(player.global_position)*kb
		if damage_dealt < max_damage:
			player.hit(damage,knockback,false,null,false)
			damage_dealt += damage

func fire(r_duration = duration):#by default it's the duration var
	damage_dealt = 0
	laser_line_bottom_particles.emitting = true
	laser_line_top_particles.emitting = true
	laser_start_particles.emitting = true
	
	if anim_player != null:
		anim_player.play("FireLaser")
	
	warn(false)
	
	set_physics_process(true)
	set_collision_mask_value(2,true)
	
	laser_sfx.play()
	
	await get_tree().create_timer(r_duration,true,true).timeout
	
	if anim_player != null:
		anim_player.play_backwards("FireLaser")
	
	await anim_player.animation_finished
	
	laser_sfx.stop()
	
	hide()
	set_physics_process(false)
	set_collision_mask_value(2,false)
	laser_line_bottom_particles.emitting = false
	laser_line_top_particles.emitting = false
	laser_start_particles.emitting = false

func warn(on = true):
	if on:
		warning.show()
	else:
		warning.hide()


func _on_body_entered(_body: Node2D) -> void:
	player.hit(impact_damage,Vector2(0,0),false,null)
	if damage_dealt < max_damage:
		damage_dealt += impact_damage
