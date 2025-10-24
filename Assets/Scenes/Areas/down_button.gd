extends Area2D

@onready var sprite = $AnimatedSprite2D
var player_inside = false

func _ready():
	sprite.hide()

func _process(delta):
	if player_inside and Input.is_action_pressed("down"):
		sprite.hide()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		sprite.show()
		player_inside = true


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		sprite.hide()
		player_inside = false
