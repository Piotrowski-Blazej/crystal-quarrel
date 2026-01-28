extends Node2D

@export var bullet = preload("res://scenes/bullets/enemy_bullet.tscn")
@export var damage = 10
@export var bullet_velocity = 5
@export var kb = 100
@export var color:Color
@export var parriable_chance = 25
@export var shooting_c = 0.5

@onready var firepoint: Node2D = $Firepoint

var world_center:Node2D

func _ready() -> void:
	world_center = get_tree().get_first_node_in_group("world_center")
	$ShootingC.wait_time = shooting_c

func _on_shooting_c_timeout() -> void:
	var i_bullet = bullet.instantiate()
	world_center.add_child(i_bullet)
	i_bullet.global_position = firepoint.global_position
	var dir:Vector2 = (firepoint.global_position - global_position).normalized()
	
	var can_parry = false
	if randi_range(1,100) <= parriable_chance:
		can_parry = true
		color = Color8(255,0,127)
	else:
		color = Color8(255,0,0)
	
	i_bullet.setup(damage,kb,bullet_velocity*dir,color,can_parry)
