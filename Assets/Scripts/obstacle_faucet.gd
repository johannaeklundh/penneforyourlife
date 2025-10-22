extends StaticBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var water_area: Area2D = $WaterArea
@onready var water_collision: CollisionShape2D = $WaterArea/CollisionShape2D

func _ready() -> void:
	anim.frame_changed.connect(_on_frame_changed)
	water_area.body_entered.connect(_on_water_entered)
	_update_collision()

func _on_frame_changed() -> void:
	_update_collision()

func _update_collision() -> void:
	if anim.frame == 2:
		# Safe frame, no collision
		water_collision.disabled = true
	else:
		# Unsafe frames, collision
		water_collision.disabled = false

func _on_water_entered(body: Node) -> void:
	GameState.flushed_count += 1
	if get_parent().has_method("show_hurt_overlay"):
		get_parent().show_hurt_overlay(body)
		
