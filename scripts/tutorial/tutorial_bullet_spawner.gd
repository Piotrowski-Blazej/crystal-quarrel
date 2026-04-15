extends Node2D

@export var bullet = preload("res://scenes/bullets/enemy_bullet.tscn")
@export var damage = 10
@export var bullet_velocity = 5
@export var kb = 100
@export var color:Color = Color.RED

@onready var firepoint: Node2D = $Firepoint
@onready var shot_sfx: AudioStreamPlayer2D = $ShotSfx

var world_center:Node2D

func _ready() -> void:
	world_center = get_tree().get_first_node_in_group("world_center")

func shoot(parriable = false) -> void:
	shot_sfx.play()
	var i_bullet = bullet.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	var dir:Vector2 = (firepoint.global_position - global_position).normalized()
	
	var can_parry = false
	if parriable:
		can_parry = true
		color = Color8(255,0,127)
	else:
		color = Color8(255,0,0)
	
	i_bullet.setup(damage,kb,bullet_velocity*dir,color,can_parry)
