extends StaticBody2D

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.body_entered.connect(_on_pot_entered)

func _on_pot_entered(body: Node) -> void:
	GameState.boiled_count += 1
	if get_parent().has_method("show_hurt_overlay"):
		get_parent().show_hurt_overlay(body)
		
