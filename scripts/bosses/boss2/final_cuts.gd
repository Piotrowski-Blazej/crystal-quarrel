extends State

@export var animation_player:AnimationPlayer
@export var boss:Area2D

var true_cut:Node2D

const BOSS_2_CUT = preload("uid://wvounlrfbbm0")
const BOSS_2_TRUE_CUT = preload("uid://bsht1vsmct4ro")

var player:RigidBody2D
var world_center:Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	world_center = get_tree().get_first_node_in_group("world_center")


var first_time = true
func enter():
	if first_time:
		first_time = false
		player.play_camera_animation("boss_2_zoom_out")
		
		await animation_player.animation_finished
		
		animation_player.speed_scale = 0.5
		
		animation_player.play("fly_up")
		await animation_player.animation_finished
		boss.global_position = Vector2(0,10000)#move out of sight
		await get_tree().create_timer(4).timeout
		
		if GlobalValues.difficulty == 2: animation_player.speed_scale = 5
		else: animation_player.speed_scale = 3
	boss.global_position = Vector2(0,10000)#move out of sight
	animation_player.play("RESET")
	
	attack()

var warn_time = 1
const CUT_WIDTH = 384
func attack():
	if $"..".current_state == self:
		var direction = randi_range(0,3)
		var parriable = randi_range(0,10)
		
		var start_pos:float = -256-GlobalValues.ARENA_BOUNDS#this is to keep it symetrical, as they don't perfetly cover the arena
		
		var parriable_pos = start_pos + (CUT_WIDTH * (parriable+1))
		if direction%2 == 0: warn_time = abs(player.global_position.y-parriable_pos)/CUT_WIDTH*0.2
		else:                warn_time = abs(player.global_position.x-parriable_pos)/CUT_WIDTH*0.2
		
		for i in range(11):#11 is enough to cover the whole arena
			start_pos += CUT_WIDTH
			var cut_position:Vector2
			if direction%2 == 0: cut_position = Vector2(0,start_pos)
			else: cut_position = Vector2(start_pos,0)
			
			var rot = PI*0.5*direction
			
			var can_parry = false
			if parriable == i: can_parry = true
			
			
			var i_cut
			
			if parriable == i: 
				i_cut = BOSS_2_TRUE_CUT.instantiate()
				true_cut = i_cut
				true_cut.connect("finished_dash", attack)
			else: i_cut = BOSS_2_CUT.instantiate()
			
			world_center.add_child(i_cut)
			i_cut.setup(cut_position, rot, can_parry, warn_time, false)
	else:
		if true_cut != null:
			true_cut.disconnect("finished_dash", attack)
			true_cut = null


func finish():
	if $"..".current_state == self:
		Transitioned.emit(self, "quickmissiles")

func exit():
	pass
