extends Node
class_name BehaviorTree   # detta gör att du kan använda "BehaviorTree" i andra script

enum Status { SUCCESS, FAILURE, RUNNING }

# Basnod
class BTNode:
	func tick(actor, delta) -> int:
		return Status.SUCCESS

# --- Composite nodes ---
class Selector extends BTNode:
	var children = []
	func tick(actor, delta) -> int:
		for child in children:
			var result = child.tick(actor, delta)
			if result == Status.SUCCESS or result == Status.RUNNING:
				return result
		return Status.FAILURE

class Sequence extends BTNode:
	var children = []
	func tick(actor, delta) -> int:
		for child in children:
			var result = child.tick(actor, delta)
			if result != Status.SUCCESS:
				return result
		return Status.SUCCESS

# --- Condition nodes ---
class IsRescued extends BTNode:
	func tick(actor, delta) -> int:
		return Status.SUCCESS if actor.is_rescued else Status.FAILURE

class IsFarFromPlayer extends BTNode:
	func tick(actor, delta) -> int:
		if actor.global_position.distance_to(actor.player.global_position) > 60:
			return Status.SUCCESS
		else:
			return Status.FAILURE


class IsCloseToPlayer extends BTNode:
	func tick(actor, delta) -> int:
		if actor.global_position.distance_to(actor.player.global_position) <= 60:
			return Status.SUCCESS
		else:
			return Status.FAILURE

# --- Action nodes ---
class MoveTowardPlayer extends BTNode:
	func tick(actor, delta) -> int:
		if actor.player == null:
			return Status.FAILURE

		var parent = actor.get_parent()  # Broccoli
		var dir = (actor.player.global_position - parent.global_position).normalized()
		parent.global_position += dir * actor.speed * delta
		# print("Moving broccoli towards player...")
		return Status.RUNNING


class IdleAnimation extends BTNode:
	func tick(actor, delta) -> int:
		# Gör inget (eller spela idle-animation)
		return Status.RUNNING
