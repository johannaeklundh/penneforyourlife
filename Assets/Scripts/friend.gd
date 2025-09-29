extends Node2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D
@onready var rope_bar: TextureProgressBar = $RopeBar
@onready var e_button: Area2D = $EButton
@onready var particles: CPUParticles2D = $RopeParticles

@export var friend_name: String = "broccoli"
@export var freed := false
@export var friend_index := 0

var player_near := false
var press_count := 0
const PRESS_LIMIT := 5

signal freed_friend(friend)

func _ready() -> void:	
	freed = GameState.freed_friends[friend_index]
	
	if freed:
		anim_sprite.play("idle")
	else:
		anim_sprite.play("stuck")
		
	rope_bar.min_value = 0
	rope_bar.max_value = PRESS_LIMIT
	rope_bar.value = 0
	area.body_entered.connect(_on_area_body_entered)
	area.body_exited.connect(_on_area_body_exited)

func _process(_delta: float) -> void:
	if player_near and not freed and Input.is_action_just_pressed("interact"):
		press_count += 1
		rope_bar.value = press_count
				
		# feedback
		shake_friend()
		burst_particles()

		if press_count >= PRESS_LIMIT:
			e_button.hide()
			_free_friend()
	
	if abs(self.velocity.x) > 0.0 and freed:
		anim_sprite.play("run")
	elif freed:
		anim_sprite.play("idle") 
	else:
		anim_sprite.play("stuck")
		
	if freed:
		if self.velocity.x > 0:
			anim_sprite.flip_h = false
		elif self.velocity.x < 0:
			anim_sprite.flip_h = true

func _on_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not freed:
		player_near = true
		e_button.show()
		rope_bar.show()

func _on_area_body_exited(body: Node2D) -> void:
	if body.name == "Player" and not freed:
		player_near = false
		e_button.hide()
		rope_bar.hide()

func _free_friend() -> void:
	freed = true
	anim_sprite.play("idle")
	
	GameState.freed_friends[friend_index] = true

	var ai = get_node("AI")
	ai.rescue()   # <-- anropar rätt metod i follower.gd
	print("Friend is freed!")
	
	freed_friend.emit(self)
	print(friend_name, " is freed!")

func shake_friend():
	var tween = create_tween()
	tween.tween_property(anim_sprite, "position:x", anim_sprite.position.x + 2, 0.05)
	tween.tween_property(anim_sprite, "position:x", anim_sprite.position.x - 2, 0.05)
	tween.tween_property(anim_sprite, "position:x", anim_sprite.position.x, 0.05)

func burst_particles():
	particles.emitting = false
	particles.emitting = true
