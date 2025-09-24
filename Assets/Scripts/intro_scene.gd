extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready():
	anim.play("intro")
	anim.animation_finished.connect(_on_intro_done)

func _process(_delta):
	# Allow skip with Enter or Space
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
		_skip()

func _on_intro_done(_anim_name):
	_skip()

func _skip():
	get_tree().change_scene_to_file("res://Assets/Scenes/Areas/area_1.tscn")
