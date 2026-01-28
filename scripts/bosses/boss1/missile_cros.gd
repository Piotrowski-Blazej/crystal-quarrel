extends State

@export var animation_player:AnimationPlayer
@export var boss:RigidBody2D
@export var state_machine:Node
@export var shooters:Array[CollisionObject2D]

const missile_damage = 20
var missile_travel_time = 0.85
const missile_accel:float = 999999
const missile_kb = 2500
const missile_parry_chance = 0
const missile_scale = 2
const center_explosion_scale = 1
const explosion_scale = 0.7

const CIRCLE_WARNING = preload("uid://bsuiardtyixtn")

var player:RigidBody2D
var world_center:Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	world_center = get_tree().get_first_node_in_group("world_center")
	
	match GlobalValues.difficulty:
		0:
			missile_travel_time = 1.5
		1:
			missile_travel_time = 1.3

const WAIT_TIME = 1

func enter():
	animation_player.speed_scale = 0.27
	animation_player.play("rotate_barriers")
	
	fire()
	await get_tree().create_timer(WAIT_TIME).timeout
	finish()

const dist:int = 800
const POSITIONS = [Vector2(0,0),Vector2(dist,dist),Vector2(-dist,dist),Vector2(-dist,-dist),Vector2(dist,-dist)]

func fire():
	var pattern:int = randi_range(0,1)
	for i in range(5):
		var new_pos:Vector2 = player.global_position + POSITIONS[i].rotated(deg_to_rad(45)*pattern)
		
		var e_scale = explosion_scale
		if i == 0:
			e_scale = center_explosion_scale
		
		var i_warn = CIRCLE_WARNING.instantiate()
		world_center.add_child.call_deferred(i_warn)
		i_warn.global_position = new_pos
		i_warn.setup(e_scale)
		
		var distance_from_firepoint = shooters[i].firepoint.global_position.distance_to(new_pos)#bruh
		var missile_velocity:float = distance_from_firepoint/missile_travel_time/100#100 is the missiles' speed mult (magic numbers ik)
		
		shooters[i].fire_missile(i_warn, missile_damage, missile_velocity, missile_accel, missile_kb, new_pos, missile_parry_chance, missile_scale, e_scale, boss)

var attack_pool:Array = ["biglaserspin","dashattack","centerspin"]
func finish():
	if boss.in_phase_2:
		attack_pool = ["biglaserspin","phase2dash","laserspin"]
	
	if $"..".current_state == self:
		var chosen_attack = attack_pool.pick_random()
		while chosen_attack == state_machine.last_attack:
			chosen_attack = attack_pool.pick_random()
		Transitioned.emit(self,chosen_attack)
