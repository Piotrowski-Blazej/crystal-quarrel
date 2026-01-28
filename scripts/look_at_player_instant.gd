extends Node2D

var player:RigidBody2D
@export var offset:int

var active = true

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if active:
		self.look_at(player.global_position)
		global_rotation_degrees += offset
