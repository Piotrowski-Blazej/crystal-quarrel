extends Area2D

var health = 8000
var crack_thresholds = [6000,4000,2000,0]
var waiting_for_fastball_attack:bool = false
var phase_2_threshold = 4000
var in_phase_2 = false
var in_phase_3 = false
signal enter_phase_2
signal enter_phase_3

const bullet = preload("res://scenes/bullets/enemy_bullet.tscn")
var bullet_damage = 10
var bullet_velocity = 10
var kb = 100
var parriable_chance = 25

var movement_speed = 250
var dash_speed = 4000
var dashing_at_player = false
var dashing_to_position = false
var dash_target:Vector2
var dash_step:Vector2
var dash_damage = 20
var dash_kb = 3000
var has_hit_with_dash = false
signal finished_dashing

var can_rotate = true
var rot_speed = 0.1
var look_angle:float

@onready var turrets = [get_node(^"Heptagon/Turret"),get_node(^"Heptagon/Turret2"),get_node(^"Heptagon/Turret3"),get_node(^"Heptagon/Turret4")]


var world_center:Node2D
var player:RigidBody2D
var bossbar:ProgressBar

@onready var thruster_particles: CPUParticles2D = $ThrusterParticles
@onready var fading_sprite_c: Timer = $Timers/FadingSpriteC
@onready var dash_d: Timer = $Timers/DashD
@onready var state_machine: Node = $StateMachine
@onready var heptagon: Sprite2D = $Heptagon
@onready var player_collider: StaticBody2D = $PlayerCollider
@onready var hit_sfx: AudioStreamPlayer2D = $HitSfx
@onready var cracks: TextureRect = $Heptagon/ClipHeptagon/Cracks
@onready var barrier: Area2D = $Barrier
@onready var front_warning: Polygon2D = $Heptagon/Node/FrontWarning
@onready var main_animation_player: AnimationPlayer = $MainAnimationPlayer
@onready var death_effects: Node2D = $DeathEffects
@onready var dash_sfx: AudioStreamPlayer2D = $DashSfx


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	bossbar = get_tree().get_first_node_in_group("bossbar")
	world_center = get_tree().get_first_node_in_group("world_center")
	state_machine.setup()
	
	if GlobalValues.difficulty == 3 or GlobalValues.difficulty == 0:
		health = 6000
		crack_thresholds = [4500,3000,1500,0]
	
	bossbar.max_value = health
	bossbar.value = health

func _process(delta: float) -> void:
	global_rotation = lerp_angle(global_rotation, look_angle, rot_speed)
	
	if dashing_to_position:
		global_position += dash_step*delta
	if dashing_at_player:
		global_position += dash_step*delta
		if abs(global_position.x) > 2048 || abs(global_position.y) > 2048:
			hit_wall()

func set_look_pos(r_pos:Vector2 = player.global_position):
	look_angle = global_position.angle_to_point(r_pos)

func dash_at_player(delay:float):
	dash_target = player.global_position
	dash_step = global_position.direction_to(dash_target)*dash_speed
	
	if delay > 0.0:
		front_warning.global_position = self.global_position
		front_warning.look_at(player.global_position)
		front_warning.show()
		await get_tree().create_timer(delay).timeout
		front_warning.hide()
	
	if !dashing_to_position:
		player_collider.process_mode = Node.PROCESS_MODE_DISABLED
		has_hit_with_dash = false 
		dashing_at_player = true
		fading_sprite_c.start()
		dash_sfx.pitch_scale = randf_range(2.5,3.5)
		dash_sfx.play()

func dash_to_position(r_pos:Vector2):
	dashing_at_player = false
	has_hit_with_dash = true
	
	dash_target = r_pos
	dash_step = global_position.direction_to(dash_target)*dash_speed
	dashing_to_position = true
	fading_sprite_c.start()
	
	var dash_duration = global_position.distance_to(r_pos)/dash_step.length()
	dash_d.start(dash_duration)

func hit_wall():
	dashing_at_player = false
	fading_sprite_c.stop()
	finished_dashing.emit()
	player_collider.process_mode = Node.PROCESS_MODE_INHERIT
	global_position.x = clamp(global_position.x,-2048,2048)
	global_position.y = clamp(global_position.y,-2048,2048)


@onready var final_cuts: Node = $StateMachine/FinalCuts
func parried():
	if is_instance_valid(barrier):
		VfxManager.frame_freeze(0.02, 0.5)
		barrier.hit_special()
		final_cuts.finish()
	else:
		VfxManager.frame_freeze(0.02, 0.9)
		GlobalValues.camera.screen_shake(20,6)
		state_machine.halt_all_states()
		main_animation_player.speed_scale = 1
		main_animation_player.play("die")
		player.immortal = true

const FIRE_AREA = preload("uid://ckowdpdefiht7")

func spawn_fire_area(r_scale:float, r_lifetime:float):
	var i_area = FIRE_AREA.instantiate()
	world_center.add_child(i_area)
	i_area.global_position = self.global_position
	i_area.setup(r_scale, r_lifetime)

func superdash_hit(damage, r_kb, hit_position:Vector2, strong_attack = false):
	player.apply_central_impulse(global_position.direction_to(player.global_position)*player.superdash_kb*0.1)
	if dashing_at_player:
		hit(damage*1.5, r_kb/2, strong_attack)
		
		VfxManager.spawn_enemy_particles(hit_position, Color.RED, "medium_spray", HEPTAGON, Vector2(0.5,1))
		VfxManager.frame_freeze(0.05,0.5)
	else:
		VfxManager.spawn_enemy_particles(hit_position, Color.RED, "light_spray", HEPTAGON, Vector2(0.3,0.5))
		VfxManager.frame_freeze(0.2,0.3)
		hit(damage, r_kb, strong_attack)

func hit(damage,_r_kb,strong_attack = false):
	health -= damage
	
	bossbar.value = health
	bossbar.flash()
	flash()
	hit_sfx.pitch_scale = randf_range(0.6,1.1)
	hit_sfx.play()
	
	while crack_thresholds.size() != 0 && health <= crack_thresholds[0]:
		crack()
		crack_thresholds.pop_front()
		if health > 0:
				barrier.setup()
				waiting_for_fastball_attack = true
	if health <= 0 && strong_attack && !in_phase_3 && GlobalValues.difficulty != 0 and GlobalValues.difficulty != 3:
		barrier.setup(5,true)
		in_phase_3 = true
		
		if state_machine.current_state == $StateMachine/QuickCuts:
			main_animation_player.play_backwards("fly_up")
			await main_animation_player.animation_finished
		
		player_collider.set_collision_layer_value(6,false)
		enter_phase_3.emit()
		
		main_animation_player.play("turn_parriable")
		
		state_machine.on_child_transition(state_machine.current_state, "finalcuts")
		crack_thresholds.clear()
		
		set_collision_layer_value(4, false)
		set_collision_mask_value(2, false)
	
	if strong_attack && health <= 0 && (GlobalValues.difficulty == 0 or GlobalValues.difficulty == 3):
		GlobalValues.camera.screen_shake(20,6)
		state_machine.halt_all_states()
		main_animation_player.speed_scale = 1
		main_animation_player.play("die")
		player.immortal = true

func crack():
	cracks.progress()
	if health <= phase_2_threshold && !in_phase_2:
		enter_phase_2.emit()
		in_phase_2 = true


var flashes:int = 0
func flash():
	flashes += 1
	heptagon.self_modulate = Color(1,0.5,0.5)
	await get_tree().create_timer(0.1).timeout
	flashes -= 1
	if flashes == 0:
		if in_phase_3: heptagon.self_modulate = Color(1,0,0.5)
		else:          heptagon.self_modulate = Color(1,0,0)

const FADING_SPRITE = preload("uid://ddgj3uubfus7u")
const HEPTAGON = preload("uid://cod7nspsk8anq")

func _on_fading_sprite_c_timeout() -> void:
	var i_sprite = FADING_SPRITE.instantiate()
	world_center.add_child(i_sprite)
	
	i_sprite.global_position = self.global_position
	i_sprite.global_rotation = heptagon.global_rotation
	i_sprite.setup(Color(1,0,0,0.5), 0.2, Vector2(3,3), HEPTAGON)


func _on_body_entered(_body: Node2D) -> void:
	if dashing_at_player && !has_hit_with_dash:
		var knockback = Vector2(1,0).rotated(heptagon.global_rotation)*dash_kb
		if global_position.angle_to_point(player.global_position) > heptagon.global_rotation:
			knockback *= -1
		player.hit(dash_damage,knockback,false,null)


func _on_dash_d_timeout() -> void:
	global_position = dash_target
	dashing_to_position = false
	fading_sprite_c.stop()

func _on_dying_sound_timer_timeout() -> void:
	hit_sfx.pitch_scale = randf_range(0.4,1.3)
	hit_sfx.play()

func remove():
	death_effects.reparent(world_center)
	death_effects.set_timer(5)
	
	GlobalValues.camera.screen_shake(50,0.5)
	
	get_tree().get_first_node_in_group("fadeout_rect").fade_out(3,true, 3)
	queue_free()
