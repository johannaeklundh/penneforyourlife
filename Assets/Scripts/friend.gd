extends Node2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D

var player_near := false
var freed := false

func _ready() -> void:
	anim_sprite.frame = 0  # start with sad
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)

func _process(_delta: float) -> void:
	if player_near and not freed and Input.is_action_just_pressed("interact"):
		_free_friend()

func _on_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_near = true

func _on_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_near = false

func _free_friend() -> void:
	freed = true
	anim_sprite.frame = 1  # change to happy
	print("Friend is freed!")
