extends Node

var start_prompt_shown := false
var tutorial_finished := false
var freed_friends: Array[bool] = [false, false, false]  # bacon, tomato, broccoli
var has_double_jump: bool = false
var has_wall_jump: bool = false
var game_finished := false

var out_of_bounds_count := 0
var boiled_count := 0
var flushed_count := 0
var elapsed_time := 0.0
var score := 0

func _process(delta: float) -> void:
	elapsed_time += delta
	

func reset_stats() -> void:
	out_of_bounds_count = 0
	boiled_count = 0
	flushed_count = 0
	elapsed_time = 0.0
	score = 0
