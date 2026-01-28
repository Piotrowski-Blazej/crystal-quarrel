extends Sprite2D

const MAIN_MENU = preload("uid://bbaywroopna3x")

func _on_area_2d_body_entered(_body: Node2D) -> void:
	get_tree().call_deferred("change_scene_to_packed",MAIN_MENU)
