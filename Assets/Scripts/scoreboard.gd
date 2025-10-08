extends Node2D

@export var digit_textures: Array[Texture2D]    # Assign 0–9 handwritten PNGs

@onready var lines = [
	$Score,
	$Boiled,
	$Flushed,
	$Bounced,
	$TimeFinish,
	$TotalScore
]

@onready var title_label = $Score
@onready var flushed_label = $Flushed

@onready var boiled_digits = [
	$Boiled/Value/digit1,
	$Boiled/Value/digit2,
	$Boiled/Value/digit3	
]

@onready var flushed_digits = [
	$Flushed/Value/digit1,
	$Flushed/Value/digit2,
	$Flushed/Value/digit3	
]

@onready var bounced_digits = [
	$Bounced/Value/digit1,
	$Bounced/Value/digit2,
	$Bounced/Value/digit3	
]

@onready var time_digits = [
	$TimeFinish/Value/digit1,
	$TimeFinish/Value/digit2,
	$TimeFinish/Value/digit3	
]
@onready var total_digits = [
	$TotalScore/Value/digit1,
	$TotalScore/Value/digit2,
	$TotalScore/Value/digit3	
]

func play():
	visible = true
	_ready() 

func _ready():

	show_number(boiled_digits, 01)
	show_number(flushed_digits, 52)
	show_number(bounced_digits, 10)
	show_number(time_digits, 154)
	show_number(total_digits, 949)
	
	for line in lines:
		line.modulate.a = 0.0

	for line in lines:
		await get_tree().create_timer(0.5).timeout
		var tween := get_tree().create_tween()

		tween.tween_property(line, "modulate:a", 1.0, 1.5)
			

func fade_in_text(line: Node2D):
	line.modulate.a = 0.0  # start invisible

	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 1.0, 1.5)

func show_number(digits: Array, number: int) -> void:
	# `digits` is an array of TextureRect/Sprite nodes, left-to-right
	# `number` is the integer to show (e.g. 50)
	var s = str(number)
	# if number is too long, show the rightmost digits:
	if s.length() > digits.size():
		s = s.substr(s.length() - digits.size(), digits.size())

	var start_index = digits.size() - s.length()  # right-align
	for i in range(digits.size()):
		var node = digits[i]
		var idx_in_s = i - start_index
		if idx_in_s >= 0:
			var digit_char = s[idx_in_s]
			var tex_index = int(digit_char)  # '5' -> 5
			node.texture = digit_textures[tex_index]
			node.visible = true
		else:
			node.visible = false
