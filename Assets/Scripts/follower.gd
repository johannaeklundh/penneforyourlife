extends Node2D

@export var speed := 100.0
@export var gravity := 800.0
@export var player: Node2D

var is_rescued := false
var tree_root

func _ready() -> void:
	_build_behavior_tree()

func _physics_process(delta: float) -> void:
	if not is_rescued or tree_root == null:
		return

	# Ticka behavior tree
	tree_root.tick(self, delta)

func rescue() -> void:
	is_rescued = true

# Hjälpfunktioner som BT kan använda
func move_toward_player(delta: float) -> void:
	var parent = get_parent() as CharacterBody2D
	if parent == null or player == null:
		return

	# horisontell rörelse
	var dir_x = sign(player.global_position.x - parent.global_position.x)
	parent.velocity.x = dir_x * speed

	# gravitation
	if not parent.is_on_floor():
		parent.velocity.y += gravity * delta
	else:
		parent.velocity.y = max(parent.velocity.y, 0)

	parent.move_and_slide()

func idle() -> void:
	var parent = get_parent() as CharacterBody2D
	if parent == null:
		return
	parent.velocity.x = 0
	parent.move_and_slide()

func _build_behavior_tree() -> void:
	var root = BehaviorTree.Selector.new()

	var follow_seq = BehaviorTree.Sequence.new()
	follow_seq.children = [
		BehaviorTree.IsRescued.new(),
		BehaviorTree.IsFarFromPlayer.new(),
		BehaviorTree.IsGroundAhead.new(),
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
