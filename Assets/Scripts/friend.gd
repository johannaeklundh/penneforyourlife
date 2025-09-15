extends Node2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D
@onready var rope_bar: TextureProgressBar = $RopeBar

var player_near := false
var freed := false
var press_count := 0
const PRESS_LIMIT := 20

func _ready() -> void:
	anim_sprite.frame = 0  # start sad
	rope_bar.hide()
	rope_bar.min_value = 0
	rope_bar.max_value = PRESS_LIMIT
	rope_bar.value = 0
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)

func _process(_delta: float) -> void:
	if player_near and not freed and Input.is_action_just_pressed("interact"):
		press_count += 1
		rope_bar.value = press_count
		
		#rope_bar.scale = Vector2(0.3, 0.3)
		#rope_bar.create_tween().tween_property(rope_bar, "scale", Vector2(0.2, 0.2), 0.1)
		shake_bar()

		if press_count >= PRESS_LIMIT:
			_free_friend()

func _on_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not freed:
		player_near = true
		rope_bar.show()

func _on_area_body_exited(body: Node2D) -> void:
	if body.name == "Player" and not freed:
		player_near = false
		rope_bar.hide()

func _free_friend() -> void:
	freed = true
	anim_sprite.frame = 1  # happy
	rope_bar.hide()
	print("Friend is freed!")

func shake_bar():
	var tween = create_tween()
	tween.tween_property(rope_bar, "position:x", rope_bar.position.x + 3, 0.05)
	tween.tween_property(rope_bar, "position:x", rope_bar.position.x - 3, 0.05)
	tween.tween_property(rope_bar, "position:x", rope_bar.position.x, 0.05)
