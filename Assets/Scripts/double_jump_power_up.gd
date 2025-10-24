extends Area2D

@export var extra_jumps := 1  # how many jumps to unlock
@export var message_node: NodePath
@onready var coin_sfx: AudioStreamPlayer = $"../Sound/CoinCollect"

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	if GameState.has_double_jump == true: 
			hide()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.max_jumps = 2
		# also reset jumps_left so player can use it immediately
		body.jumps_left = body.max_jumps
		
		if GameState.has_double_jump == false:
			var msg = get_tree().get_first_node_in_group("message")
			msg.show_and_fade()
		
		GameState.has_double_jump = true
		coin_sfx.play()

		# hide + disable coin
		hide()
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
