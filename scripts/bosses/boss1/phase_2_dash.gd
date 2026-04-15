extends State

@export var barrier_anim:AnimationPlayer
@export var boss:RigidBody2D
@export var state_machine:Node
@export var drones:Array[RigidBody2D]

var player:RigidBody2D
var laser_warn_time:float = 0.5

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if GlobalValues.difficulty == 1: laser_warn_time = 0.6
	elif GlobalValues.difficulty == 0: laser_warn_time = 0.75
	elif GlobalValues.difficulty == 3: laser_warn_time = 1

func enter():
	barrier_anim.speed_scale = 0.4
	boss.dash(randi_range(3,4))
	boss.move_to_target = false
	boss.linear_damp = 1
	
	boss.dashed.connect(dashed)
	boss.finished_dashing.connect(finish)
	
	dashed()

var move = false
func dashed():
	var vector
	if !move:
		vector = Vector2(1900,0)
		move = true
	else:
		vector = Vector2(1900,1900)
		move = false
	
	for i in range(4):
		var pos = vector.rotated(deg_to_rad(90*i))
		drones[i].set_target_pos(pos)
	await get_tree().create_timer(1.6).timeout
	for i in range(4):
		drones[i].fire_laser(0.25, true, laser_warn_time)


func finish():
	boss.finished_dashing.disconnect(finish)
	boss.dashed.disconnect(dashed)
	var attack_pool:Array = ["laserspin","biglaserspin","missilecross"]
	var chosen_attack = attack_pool.pick_random()
	while chosen_attack == state_machine.last_attack:
		chosen_attack = attack_pool.pick_random()
	Transitioned.emit(self,chosen_attack)

func exit():
	boss.linear_damp = 10
	barrier_anim.speed_scale = 0.2
