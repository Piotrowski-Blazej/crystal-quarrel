extends Sprite2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func setup(size):
	scale *= size

func _ready() -> void:
	animation_player.play("warn_appear")

func fade_away():
	animation_player.play("fade_away")
