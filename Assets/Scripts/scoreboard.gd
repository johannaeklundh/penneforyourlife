extends Node2D

@export var digit_textures: Array[Texture2D]    # Assign 0–9 handwritten PNGs

#@onready var lines = [
	#$Score,
	#$Boiled/Label,
	#$Flushed/Label,
	#$Bounced/Label,
	#$TimeFinish/Label,
	#$TotalScore
#]

@onready var lines = [
	$Score,
	$Boiled,
	$Flushed,
	$Bounced,
	$TimeFinish,
	$TotalScore
]

#@onready var time_value = $TimeFinish/Value
@onready var title_label = $Score
@onready var flushed_label = $Flushed
var delay := 0.0

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
	_ready()  # or call fade/animation setup manually

func _ready():

	
	#show_number(boiled_digits, 510)
	#fade_in_text(title_label)
	#await get_tree().create_timer(2.0).timeout
	show_number(boiled_digits, 4)
	show_number(flushed_digits, 52)
	show_number(bounced_digits, 10)
	show_number(time_digits, 154)
	show_number(total_digits, 949)
	
	for line in lines:
		line.modulate.a = 0.0
		
	#await get_tree().create_timer(2.0).timeout

	for line in lines:
		await get_tree().create_timer(0.5).timeout
		var tween := get_tree().create_tween()

		tween.tween_property(line, "modulate:a", 1.0, 1.5)
		
	#fade_in_text(flushed_label)
	#animate_scoreboard()
	

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

#func animate_scoreboard():
	#var delay := 0.0
	#for line in lines:
		#var value_node = line["node"].Value
		#fade_in(line["node"].Label, delay)
		#fade_in(value_node, delay + 0.2)
		##tick_up_number_label(value_node, line["target"], delay + 0.3)
		#delay += 1.2
#
	## Time
	#fade_in($TimeFinish.Label, delay)
	#fade_in(time_value, delay + 0.2)
	##tick_up_number_label(time_value, 56, delay + 0.3)
	#delay += 1.5
#
	## Total
	#fade_in($Total.Label, delay)
	#fade_in($Total.Value, delay + 0.3)
	##tick_up_total_digits(total_digits, 789, delay + 0.5)
#
#
#func fade_in(node: CanvasItem, delay: float):
	#var tween = get_tree().create_tween()
	#tween.tween_property(node, "modulate:a", 1.0, 0.5).set_delay(delay)

#
#func tick_up_number_label(label: Label, target_value: int, delay: float):
	#var tween = get_tree().create_tween()
	#var duration = 1.2
	#tween.set_delay(delay)
	#tween.tween_method(func(v):
		#label.text = str(round(v))
	#, 0.0, float(target_value), duration)
#
#
#func tick_up_total_digits(digits: Array, target_value: int, delay: float):
	#var tween = get_tree().create_tween()
	#var duration = 2.0  # take a bit longer for the big reveal
	#tween.set_delay(delay)
	#tween.tween_method(func(v):
		#var current = int(round(v))
		#update_digits(digits, current)
	#, 0.0, float(target_value), duration)
#
#
#func update_digits(digits: Array, number: int):
	#var str_num = str(number).pad_zeroes(digits.size())
	#for i in digits.size():
		#var digit = int(str_num[i])
		#digits[i].texture = digit_textures[digit]
