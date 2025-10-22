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

# Boss capturing
#var is_captured: bool = false
#var capture_hand: CharacterBody2D = null
#var capture_offset: Vector2 = Vector2.ZERO

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
	
	add_to_group("friends")

func _process(_delta: float) -> void:
	# Follow boss hand when captured
	#if is_captured and capture_hand:
		#global_position = capture_hand.global_position + capture_offset
	
	if freed:
		if self.velocity.x > 0:
			anim_sprite.flip_h = false
		elif self.velocity.x < 0:
			anim_sprite.flip_h = true

		# Falling
		if self.velocity.y > 0.0:
			anim_sprite.play("fall")
			return
			
		# Jumping
		if self.velocity.y < 0.0:
			anim_sprite.play("jump")
			return	

		if abs(self.velocity.x) > 0.0:
			var anim_name = "run"
		
			if friend_index == 2: #broccoli
				if abs(self.velocity.x) < 80:
					anim_name = "slow_run"

			anim_sprite.play(anim_name)
		else:
			anim_sprite.play("idle") 
	else:
		anim_sprite.play("stuck")
	
	if player_near and not freed and Input.is_action_just_pressed("interact"):
		#press_count += 1
		rope_bar.value = press_count
				
		# feedback
		shake_friend()
		burst_particles()

		if press_count >= PRESS_LIMIT:
			e_button.hide()
			_free_friend()
			
	
func captured():
	# Reset state
	freed = false
	press_count = 0
	rope_bar.value = 0

	anim_sprite.play("stuck")
	e_button.hide()
	rope_bar.hide()

	burst_particles()
	shake_friend()

func _on_projectile_hit(_projectile_pos: Vector2) -> void:
	if freed:
		return
	
	press_count += 1
	rope_bar.value = press_count
	shake_friend()
	burst_particles()
	
	if press_count >= PRESS_LIMIT:
		e_button.hide()
		_free_friend()
		#if is_captured:
			#capture_hand.release()

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
	#is_captured = false
	anim_sprite.play("idle")	
	GameState.freed_friends[friend_index] = true

	# calls follower.gd
	var ai = get_node("AI")
	ai.rescue()
	
	freed_friend.emit(self)

func shake_friend():
	var tween = create_tween()
	tween.tween_property(anim_sprite, "position:x", anim_sprite.position.x + 2, 0.05)
	tween.tween_property(anim_sprite, "position:x", anim_sprite.position.x - 2, 0.05)
	tween.tween_property(anim_sprite, "position:x", anim_sprite.position.x, 0.05)

func burst_particles():
	particles.emitting = false
	particles.emitting = true
