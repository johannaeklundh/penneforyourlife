extends Sprite2D

func show_and_fade() -> void:
	print("ENTERED")
	visible = true
	modulate = Color(1, 1, 1, 0)  # start fully transparent
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3) # fade in quickly
	tween.tween_interval(1.0)  # stay visible for 1s
	tween.tween_property(self, "modulate:a", 0.0, 1.0) # fade out
	tween.tween_callback(Callable(self, "_on_fade_finished"))

func _on_fade_finished() -> void:
	visible = true
