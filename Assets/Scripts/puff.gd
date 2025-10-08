extends Sprite2D

func _ready():
	# Start small
	scale = Vector2(0.06, 0.06)
	modulate = Color(1, 1, 1, 1)

	var tween = create_tween()
	# Scale up to "poof"
	tween.tween_property(self, "scale", Vector2(0.04, 0.04), 0.1)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.05)
	# When done, remove puff
	tween.tween_callback(queue_free)
