extends Area2D

@export var message_node: NodePath
@onready var coin_sfx: AudioStreamPlayer = $"../Sound/CoinCollect"

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	if GameState.has_wall_jump == true: 
			hide()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":	 
		if GameState.has_wall_jump == false:
			var msg = get_tree().get_first_node_in_group("wallJumpMessage")
			msg.show_and_fade()
		
		GameState.has_wall_jump = true
		coin_sfx.play()

		# hide + disable coin
		hide()
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
