extends Area2D

@export var speed := 400
@export var direction := Vector2.RIGHT
@export var damage := 10

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	# Free stuck friends instead of damaging
	if body.has_method("_on_projectile_hit"):
		body._on_projectile_hit()
		queue_free()
		return
	
	queue_free()
