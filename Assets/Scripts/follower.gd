extends Node2D

@export var speed = 100.0
@export var player: Node2D 
var is_rescued: bool = false
var tree_root

func _ready() -> void:
	_build_behavior_tree()

func _process(delta: float) -> void:
	if is_rescued and tree_root:
		tree_root.tick(self, delta)
		
func rescue() -> void:
	is_rescued = true
	print("AI activated for broccoli!")

func _build_behavior_tree() -> void:
	var root = BehaviorTree.Selector.new()

	var follow_seq = BehaviorTree.Sequence.new()
	follow_seq.children = [
		BehaviorTree.IsRescued.new(),
		BehaviorTree.IsFarFromPlayer.new(),
		BehaviorTree.MoveTowardPlayer.new()
	]

	var idle_seq = BehaviorTree.Sequence.new()
	idle_seq.children = [
		BehaviorTree.IsRescued.new(),
		BehaviorTree.IsCloseToPlayer.new(),
		BehaviorTree.IdleAnimation.new()
	]

	root.children = [follow_seq, idle_seq]
	tree_root = root
