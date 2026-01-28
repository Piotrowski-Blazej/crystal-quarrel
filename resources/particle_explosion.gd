extends CPUParticles2D

func _ready():
	await get_tree().process_frame
	emitting = true
	$Lifetime.start(lifetime)

func _on_lifetime_timeout():
	queue_free()
