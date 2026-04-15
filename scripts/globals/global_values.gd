extends Node

var player:RigidBody2D
var world_center:Node2D
var camera:Camera2D
var boss:CollisionObject2D

var selected_boss = 0
var boss_names = ["Whirlwind","The Airship"]
var difficulty = -1
var diff_names = ["Easy","Medium","Hard","Very Easy"]

var timer_on = false
var time_elapsed:float = 0.0
var damage_taken:int = 0
var hits_parried:int = 0

const ARENA_BOUNDS = 2048

func _ready() -> void:
	get_tree().scene_changed.connect(on_scene_changed)
	on_scene_changed()

func on_scene_changed():
	player = get_tree().get_first_node_in_group("player")
	world_center = get_tree().get_first_node_in_group("world_center")
	camera = get_tree().get_first_node_in_group("camera")
	boss = get_tree().get_first_node_in_group("boss")

func _process(delta: float) -> void:
	if timer_on: time_elapsed += delta

func toggle_timer(on_off:bool):
	if on_off: timer_on = true
	else:      timer_on = false
