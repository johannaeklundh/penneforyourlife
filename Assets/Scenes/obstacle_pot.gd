extends StaticBody2D

@onready var area: Area2D = $Area2D
@onready var burned_sfx: AudioStreamPlayer = $"../Sound/Burned"


func _ready() -> void:
	area.body_entered.connect(_on_pot_entered)

	
func _on_pot_entered(body: Node) -> void:
	GameState.boiled_count += 1
	burned_sfx.play()
	if get_parent().has_method("show_hurt_overlay"):
		get_parent().show_hurt_overlay(body)
		
