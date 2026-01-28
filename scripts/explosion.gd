extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var hit_targets:Array[CollisionObject2D] = []
var has_hit = false
var damage:int
var kb:int

var parried = false

func setup(d,k,s = 1,was_parried = false):
	damage = d
	kb = k
	scale *= s
	animation_player.play("explode")
	
	if was_parried:
		modulate = Color(0,1,0)
		set_collision_mask_value(2,false)
		set_collision_mask_value(4,true)
		parried = true
	else:
		modulate = Color(1,0,0)


func _on_body_entered(body: Node2D) -> void:
	if parried:
		if !has_hit:
			var knockback = global_position.direction_to(body.global_position)*kb
			if parried:
				body.hit(damage,knockback)
			else:
				body.hit(damage, knockback, false, null, true)
			has_hit = true
	else:
		if body not in hit_targets:
			hit_targets.append(body)
			var knockback = global_position.direction_to(body.global_position)*kb
			if parried:
				body.hit(damage,knockback)
			else:
				body.hit(damage, knockback, false, null, true)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("takes_damage"):
		if area not in hit_targets:
			hit_targets.append(area)
			area.hit(damage,Vector2(0,0))
