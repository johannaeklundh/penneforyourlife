extends Area2D

@export var speed := 300
@export var direction := Vector2.RIGHT
@export var damage := 10
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var hit_sfx: AudioStreamPlayer = $"../Sound/ProjectileHit"

var is_hit := false

func _physics_process(delta):
	if is_hit:
		return
	
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if not body or is_hit:
		return

	# --- Handle physics bodies (anything with collision layers)
	if body is CollisionObject2D:
		var layer = body.collision_layer
		if (layer & (1 << 0)) or (layer & (1 << 5)): # Layers 1 and 6
			play_hit_and_fade()
			return

	if body is TileMapLayer:
		play_hit_and_fade()
		return
	
	if body.has_method("_on_projectile_hit"):
		body._on_projectile_hit(self.global_position)
		
		if not body.freed:
			play_hit_and_fade()
		return
	
	#queue_free()


func play_hit_and_fade():
	is_hit = true
	hit_sfx.play()
	animation.play("hit")
	await animation.animation_finished
	queue_free()
