extends Node2D

const BOSS_HITBOX_MAX_DISTANCE:int = 16384
var travel_time:float = 1

const DAMAGE:int = 20
const KB:int = 10000
const ON_PARRY_BOSS_DAMAGE = 250

const shake_intensity = 5
const shake_time = 1

var traveling = false
var parriable = false
var make_sound = true

@onready var boss_hitbox: Area2D = $BossHitbox
@onready var laser_warning: Polygon2D = $LaserWarning
@onready var lifetime: Timer = $Lifetime
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fading_sprite_c: Timer = $FadingSpriteC
@onready var shatter_sfx: AudioStreamPlayer2D = $BossHitbox/ShatterSfx
@onready var thruster_particles: CPUParticles2D = $BossHitbox/ThrusterParticles
@onready var remote_transform_2d: RemoteTransform2D = $BossHitbox/RemoteTransform2D
@onready var dash_sfx: AudioStreamPlayer2D = $DashSfx

signal finished_dash

var boss:Area2D

func setup(r_pos, r_rot, can_parry = false, warn_time = 0.0, _irrelevant = true):
	show()
	global_position = r_pos
	global_rotation = r_rot
	parriable = can_parry
	if can_parry:
		laser_warning.modulate = Color(1,0,1)
	
	animation_player.play("fade_in")
	await animation_player.animation_finished
	if warn_time > 0.0: await get_tree().create_timer(warn_time).timeout
	animation_player.speed_scale = 1/travel_time
	animation_player.play("fade_out")
	
	lifetime.start(travel_time)
	traveling = true
	fading_sprite_c.start()
	
	GlobalValues.camera.screen_shake(shake_intensity, shake_time)
	
	boss = GlobalValues.boss
	remote_transform_2d.remote_path = remote_transform_2d.get_path_to(boss)

var spawn_fading_sprites = true
const FADING_SPRITE = preload("uid://ddgj3uubfus7u")
const HEPTAGON = preload("uid://cod7nspsk8anq")
var time_travelled:float
func _physics_process(delta: float) -> void:
	if traveling:
		time_travelled += delta
		boss_hitbox.position.x += BOSS_HITBOX_MAX_DISTANCE*delta/travel_time
		if make_sound && time_travelled > 0.2:
			dash_sfx.pitch_scale = randf_range(4,5)
			dash_sfx.play()
			make_sound = false
	
	if spawn_fading_sprites:
		var i_sprite = FADING_SPRITE.instantiate()
		GlobalValues.world_center.add_child(i_sprite)
		
		i_sprite.global_position = boss_hitbox.global_position
		i_sprite.global_rotation = self.global_rotation + PI*0.5
		i_sprite.setup(Color(1,0,1), 0.2, Vector2(3,3), HEPTAGON)


func parried():
	shatter_sfx.play()
	shatter_sfx.reparent(GlobalValues.world_center)
	shatter_sfx.connect("finished", shatter_sfx.die)
	
	VfxManager.spawn_enemy_particles(boss_hitbox.global_position, Color(1,0,1), "medium", HEPTAGON, Vector2(0.5,0.5), true, 128)
	
	boss_hitbox.set_deferred("monitoring", false)
	boss.hit(ON_PARRY_BOSS_DAMAGE, Vector2.ZERO)
	boss.parried()
	remote_transform_2d.remote_path = ^""
	remote_transform_2d.queue_free()
	
	spawn_fading_sprites = false


func die(): pass#needed to be parriable


func _on_lifetime_timeout() -> void:
	thruster_particles.reparent(GlobalValues.world_center)
	thruster_particles.set_timer(thruster_particles.lifetime)
	
	finished_dash.emit()
	queue_free()


func _on_boss_hitbox_body_entered(body: Node2D) -> void:
	var knockback = Vector2.RIGHT.rotated(global_rotation)*KB
	body.hit(DAMAGE, knockback, parriable, self)
