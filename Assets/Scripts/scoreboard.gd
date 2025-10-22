extends Node2D

@export var digit_textures: Array[Texture2D] # Handwritten numbers

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

# The minusnumbers
@onready var boiled_digits_removed = [
	$Boiled/ValueRemove/digit1,
	$Boiled/ValueRemove/digit2,
	$Boiled/ValueRemove/digit3	
]

@onready var flushed_digits_removed = [
	$Flushed/ValueRemove/digit1,
	$Flushed/ValueRemove/digit2,
	$Flushed/ValueRemove/digit3	
]

@onready var bounced_digits_removed = [
	$Bounced/ValueRemove/digit1,
	$Bounced/ValueRemove/digit2,
	$Bounced/ValueRemove/digit3	
]

@onready var time_digits_removed = [
	$TimeFinish/ValueRemove/digit1,
	$TimeFinish/ValueRemove/digit2,
	$TimeFinish/ValueRemove/digit3
]

func play():
	visible = true
	_ready() 

func _ready():
	
	#Invisible first
	for line in lines:
		line.modulate.a = 0.0

	if GameState.game_finished:
		calculate_scores()

		for line in lines:
			await get_tree().create_timer(0.5).timeout		
			fade_in_text(line)

func calculate_scores():
	
	var flushed_times := GameState.flushed_count
	var boiled_times := GameState.boiled_count
	var bounced_times := GameState.out_of_bounds_count
	var total_score := 1000
	var time = GameState.elapsed_time
	
	total_score -= (flushed_times*10)
	show_number(flushed_digits_removed, flushed_times*10)
		
	total_score -= (boiled_times*10) 
	show_number(boiled_digits_removed, boiled_times*10)

	total_score -= (bounced_times*(10))
	show_number(bounced_digits_removed, bounced_times*10)
	
	total_score = total_score - floor(time*2)
	GameState.score = total_score
	
	show_number(time_digits_removed, time*2)
	
	show_number(boiled_digits, boiled_times)
	show_number(flushed_digits, flushed_times)
	show_number(bounced_digits, bounced_times)
	show_number(time_digits, time)
	show_number(total_digits, total_score)
	

func fade_in_text(line):
	#Dramatic effect
	if line == $TotalScore:
		await get_tree().create_timer(1).timeout

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
