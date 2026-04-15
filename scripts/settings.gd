extends Control

@onready var fadeout_rect: ColorRect = $FadeoutRect

func _on_back_button_button_up() -> void:
	fadeout_rect.fade_out(0.5)
