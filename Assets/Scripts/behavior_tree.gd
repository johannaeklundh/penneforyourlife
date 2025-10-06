class_name BehaviorTree
extends Node

# Statuskoder
enum Status { SUCCESS, FAILURE, RUNNING }

# --- Basnoder ---
class BTNode:
	func tick(_actor, _delta) -> int:
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
	func tick(actor, _delta) -> int:
		return Status.SUCCESS if actor.is_rescued else Status.FAILURE

class IsFarFromPlayer extends BTNode:
	func tick(actor, _delta) -> int:
		if actor.player == null:
			return Status.FAILURE
		return Status.SUCCESS if actor.global_position.distance_to(actor.player.global_position) > 60 else Status.FAILURE

class IsCloseToPlayer extends BTNode:
	func tick(actor, _delta) -> int:
		if actor.player == null:
			return Status.FAILURE
		return Status.SUCCESS if actor.global_position.distance_to(actor.player.global_position) <= 60 else Status.FAILURE

class IsGroundAhead extends BTNode:
	func tick(actor, _delta) -> int:
		var dir_x = sign(actor.player.global_position.x - actor.global_position.x)
		if dir_x == 0:
			return Status.FAILURE

		var space_state = actor.get_world_2d().direct_space_state
		var start = actor.global_position + Vector2(dir_x * 16, 16)  # lower ray origin
		var end = start + Vector2(0, 32)

		var query = PhysicsRayQueryParameters2D.create(start, end)
		query.exclude = [actor]
		var result = space_state.intersect_ray(query)

		# Also move if player is higher/lower
		if result or abs(actor.player.global_position.y - actor.global_position.y) > 40:
			return Status.SUCCESS

		return Status.FAILURE

class IsPlayerAbove extends BTNode:
	func tick(actor, _delta) -> int:
		if actor.player == null:
			return Status.FAILURE
		return Status.SUCCESS if actor.player.global_position.y < actor.global_position.y - 20 else Status.FAILURE


# --- Action nodes ---
class MoveTowardPlayer extends BTNode:
	func tick(actor, delta) -> int:
		actor.move_toward_player(delta)
		return Status.SUCCESS

class JumpTowardPlayer extends BTNode:
	var jumping := false
	var cooldown := 0.0
	
	func tick(actor, delta) -> int:
		var parent = actor.get_parent() as CharacterBody2D
		if parent == null or actor.player == null:
			return Status.FAILURE

		# Cooldown
		if cooldown > 0.0:
			cooldown -= delta
			return Status.FAILURE

		# Om vi redan hoppar → vänta på landning
		if jumping:
			if parent.is_on_floor():
				jumping = false
				cooldown = 0.3
				return Status.SUCCESS
			return Status.RUNNING

		# --- Gap eller hinder framför? ---
		var dir_x = sign(actor.player.global_position.x - actor.global_position.x)
		if dir_x != 0 and parent.is_on_floor():
			var space_state = actor.get_world_2d().direct_space_state
			
			# gap-kontroll (samma princip som IsGroundAhead)
			var start = actor.global_position + Vector2(dir_x * 16, 16)
			var end = start + Vector2(0, 32)
			var query = PhysicsRayQueryParameters2D.create(start, end)
			query.exclude = [actor, parent]
			var ground_ahead = space_state.intersect_ray(query)
			
			if not ground_ahead:
				# Använd befintlig hjälpfunktion
				actor.try_jump_toward_player(delta)
				jumping = true
				return Status.RUNNING

		# --- Spelaren ovanför? ---
		var vertical_diff = actor.player.global_position.y - parent.global_position.y
		if vertical_diff < -40 and parent.is_on_floor():
			actor.try_jump_toward_player(delta)
			jumping = true
			return Status.RUNNING

		return Status.FAILURE

class IdleAnimation extends BTNode:
	func tick(actor, _delta) -> int:
		actor.idle()
		return Status.SUCCESS

class TeleportIfTooFar extends BTNode:
	var teleporting := false
	var timer := 0.0
	var duration := 0.5  # tid för teleport-effekt

	func tick(actor, delta) -> int:
		var parent = actor.get_parent() as CharacterBody2D
		if parent == null or actor.player == null:
			return Status.FAILURE

		var distance = parent.global_position.distance_to(actor.player.global_position)
		# Debug: skriv ut avståndet
		# print("Avstånd mellan vän och pastan: ", distance)

		# Om vi redan håller på att teleportera
		if teleporting:
			timer -= delta
			if timer <= 0.0:
				teleporting = false
				return Status.SUCCESS
			return Status.RUNNING

		# Starta teleport
		if distance > 600:
			# Spela start-effekt
			actor.play_teleport_effect(parent.global_position)

			# Teleportera direkt (eller efter delay om ni vill)
			var offset = Vector2(50, 0)
			if actor.player.global_position.x < parent.global_position.x:
				offset.x *= -1
			parent.global_position = actor.player.global_position + offset

			# Spela slut-effekt
			actor.play_teleport_effect(parent.global_position)

			teleporting = true
			timer = duration
			return Status.RUNNING

		return Status.FAILURE



static var node_registry := {
	"Selector": Selector,
	"Sequence": Sequence,
	"IsRescued": IsRescued,
	"IsFarFromPlayer": IsFarFromPlayer,
	"IsCloseToPlayer": IsCloseToPlayer,
	"IsGroundAhead": IsGroundAhead,
	"IsPlayerAbove": IsPlayerAbove,
	"MoveTowardPlayer": MoveTowardPlayer,
	"JumpTowardPlayer": JumpTowardPlayer,
	"IdleAnimation": IdleAnimation,
	"TeleportIfTooFar": TeleportIfTooFar,
	"Wait": Wait,
	"MoveTowardPlayerFast": MoveTowardPlayerFast,
}


static func build_tree(definition: Dictionary) -> BTNode:
	var node_type = definition.get("type", null)
	if node_type == null or not node_registry.has(node_type):
		push_error("Unknown node type: %s" % node_type)
		return null
	
	var node = node_registry[node_type].new()
	
	# Bygg barn rekursivt om det finns
	if definition.has("children"):
		for child_def in definition["children"]:
			var child = build_tree(child_def)
			if child != null:
				node.children.append(child)
	
	return node


# --- Extra noder för variation mellan vänner ---

# Vänta en viss tid (ex. blyg vän innan den följer)
class Wait extends BTNode:
	var time := 1.0
	var timer := 0.0
	var waiting := false

	func tick(_actor, delta) -> int:
		if not waiting:
			timer = time
			waiting = true
		
		timer -= delta
		if timer <= 0:
			waiting = false
			return Status.SUCCESS
		return Status.RUNNING


# Variant av MoveTowardPlayer som rör sig snabbare
class MoveTowardPlayerFast extends MoveTowardPlayer:
	func tick(actor, delta) -> int:
		var parent = actor.get_parent() as CharacterBody2D
		if parent == null or actor.player == null:
			return Status.FAILURE

		var old_speed = actor.speed
		actor.speed *= 1.5   # snabbare!
		var result = super.tick(actor, delta)
		actor.speed = old_speed
		return result
