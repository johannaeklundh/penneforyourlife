extends Control

@onready var slots = [$Slot1, $Slot2, $Slot3] # Your target slots
@onready var glitter = [$Glitter1, $Glitter2, $Glitter3] 

func _on_bacon_freed_friend(_friend: Variant) -> void:
	slots[0].set_visible(true)
	glitter[0].emitting = true
	
func _on_tomato_freed_friend(_friend: Variant) -> void:
	slots[1].set_visible(true)
	glitter[1].emitting = true

func _on_broccoli_freed_friend(_friend: Variant) -> void:
	slots[2].set_visible(true)
	glitter[2].emitting = true
	
