class_name BehaviorTree
extends Node

# Statuskoder
enum Status { SUCCESS, FAILURE, RUNNING }

# --- Basnoder ---
class BTNode:
	func tick(actor, delta) -> int:
		return Status.FAILURE

class Selector extends BTNode:
	var children: Array = []
	func tick(actor, delta) -> int:
		for child in children:
			var status = child.tick(actor, delta)
			if status != Status.FAILURE:
				return status
		return Status.FAILURE

class Sequence extends BTNode:
	var children: Array = []
	func tick(actor, delta) -> int:
		for child in children:
			var status = child.tick(actor, delta)
			if status != Status.SUCCESS:
				return status
		return Status.SUCCESS

# --- Condition nodes ---
class IsRescued extends BTNode:
	func tick(actor, delta) -> int:
		return Status.SUCCESS if actor.is_rescued else Status.FAILURE

class IsFarFromPlayer extends BTNode:
	func tick(actor, delta) -> int:
		if actor.player == null:
			return Status.FAILURE
		return Status.SUCCESS if actor.global_position.distance_to(actor.player.global_position) > 60 else Status.FAILURE

class IsCloseToPlayer extends BTNode:
	func tick(actor, delta) -> int:
		if actor.player == null:
			return Status.FAILURE
		return Status.SUCCESS if actor.global_position.distance_to(actor.player.global_position) <= 60 else Status.FAILURE

class IsGroundAhead extends BTNode:
	func tick(actor, delta) -> int:
		var dir_x = sign(actor.player.global_position.x - actor.global_position.x)
		if dir_x == 0:
			return Status.FAILURE

		var space_state = actor.get_world_2d().direct_space_state
		var start = actor.global_position + Vector2(dir_x * 16, 0)
		var end = start + Vector2(0, 32)

		var query = PhysicsRayQueryParameters2D.create(start, end)
		query.exclude = [actor]

		var result = space_state.intersect_ray(query)

		return Status.SUCCESS if result else Status.FAILURE


# --- Action nodes ---
class MoveTowardPlayer extends BTNode:
	func tick(actor, delta) -> int:
		actor.move_toward_player(delta)
		return Status.SUCCESS


class IdleAnimation extends BTNode:
	func tick(actor, delta) -> int:
		actor.idle()
		return Status.SUCCESS
