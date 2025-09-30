extends Sprite2D

func show_and_blink() -> void:
	visible = true
	modulate = Color(1, 1, 1, 0)  # start fully transparent

	var tween := create_tween()
	tween.set_loops()  # make it loop forever

	# Fade in from 0 -> 1
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# Fade out to 0.5
	tween.tween_property(self, "modulate:a", 0.5, 0.5)

	# Fade back in to 1
	tween.tween_property(self, "modulate:a", 1.0, 0.5)


func _on_fade_finished() -> void:
	visible = true
