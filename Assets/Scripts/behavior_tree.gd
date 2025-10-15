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
	var threshold = 10
	func tick(actor, _d) -> int:
		var p = actor.get_parent() as CharacterBody2D  
		if p == null or actor.player == null:
			return Status.FAILURE
		var distance = p.global_position.distance_to(actor.player.global_position)
		# print (distance)
		return Status.SUCCESS if distance > threshold else Status.FAILURE

class IsCloseToPlayer extends BTNode:
	var threshold := 10.0
	func tick(actor, _d) -> int:
		var p = actor.get_parent() as CharacterBody2D
		if p == null or actor.player == null: return Status.FAILURE
		return Status.SUCCESS if p.global_position.distance_to(actor.player.global_position) <= threshold else Status.FAILURE


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
	var min_vertical_diff := 60.0
	var max_horizontal_diff := 100.0
	var max_jump_height := 140.0

	func tick(actor, _delta) -> int:
		var body = actor.get_parent() as CharacterBody2D
		if body == null or actor.player == null:
			return Status.FAILURE

		var player_pos = actor.player.global_position
		var self_pos = body.global_position

		# Player must be sufficiently higher
		if player_pos.y >= self_pos.y - min_vertical_diff:
			print("fail in vertical")
			return Status.FAILURE

		# Not too far horizontally
		if abs(player_pos.x - self_pos.x) > max_horizontal_diff:
			print("fail in horizontal")
			return Status.FAILURE

		# There must be a platform above us that we can reach
		if not _reachable_platform_between(actor, body, player_pos):
			print("fail in platform")
			return Status.FAILURE
			
		print("SUCCESS")
		return Status.SUCCESS


	func _reachable_platform_between(actor, body, player_pos: Vector2) -> bool:
		var space_state = actor.get_world_2d().direct_space_state
		var from = body.global_position
		var to = from + Vector2(0, -max_jump_height)

		# Ray up from follower
		var q_up = PhysicsRayQueryParameters2D.create(from, to)
		q_up.exclude = [actor, body, actor.player]
		var up_hit = space_state.intersect_ray(q_up)

		if not up_hit:
			return false

		var platform_y = up_hit.position.y
		var platform_collider = up_hit.get("collider")

		# Optional: verify the player is standing near this platform
		var q_down = PhysicsRayQueryParameters2D.create(player_pos, player_pos + Vector2(0, 10))
		q_down.exclude = [actor, body, actor.player]
		var down_hit = space_state.intersect_ray(q_down)

		if down_hit and down_hit.get("collider") == platform_collider:
			return true

		return false


# --- Action nodes ---
class MoveTowardPlayer extends BTNode:
	func tick(actor, delta) -> int:
		#print("normal")
		var p = actor.get_parent() as CharacterBody2D
		if p == null or actor.player == null:
			return Status.FAILURE

		var threshold = actor.positionsFromPasta[actor.friend_index]
		var margin = 2.0  # liten buffert så vi inte står och stegar
		var to_player = actor.player.global_position - p.global_position
		var dist = to_player.length()
		if dist > threshold + margin:
			var dir = to_player.normalized()
			var step = min(actor.speed * delta, dist - threshold)
			p.velocity.x = dir.x * (step / delta)
		else:
			p.velocity.x = 0

		return Status.SUCCESS

class JumpTowardPlayer extends BTNode:
	var jumping := false
	var did_double_jump := false
	var time_since_jump := 0.0

	# --- Tunable parameters ---
	var base_jump_force := -300.0     # normal jump velocity
	var max_jump_force := -450.0      # max upward impulse if platform is high
	var min_double_delay := 0.08      # min time between first and double jump
	var extra_boost := 200.0          # double jump upward boost
	var max_up_speed := -420.0        # clamp upward speed
	var jump_height_check := 140.0    # how far up to look for a platform

	func tick(actor, delta) -> int:
		var body = actor.get_parent() as CharacterBody2D
		if body == null or actor.player == null:
			return Status.FAILURE

		# --- Reset state if grounded and idle ---
		if body.is_on_floor() and not jumping:
			actor.jumps_left = actor.max_jumps
			did_double_jump = false
			time_since_jump = 0.0

		# --- In mid-air ---
		if jumping:
			time_since_jump += delta

			# Landed
			if body.is_on_floor():
				jumping = false
				return Status.SUCCESS

			# Optional double jump continuation
			if not did_double_jump and actor.jumps_left > 0 and time_since_jump >= min_double_delay:
				var still_blocked : bool = actor.has_obstacle_ahead(body)
				var still_below_player : bool = (actor.player.global_position.y - body.global_position.y) < -60
				if still_blocked or still_below_player:
					body.velocity.y = min(body.velocity.y - extra_boost, max_up_speed)
					actor.jumps_left -= 1
					did_double_jump = true
					actor.just_jumped = true
			return Status.RUNNING

		# --- Try to start a new jump ---
		var need_jump := false
		var vertical_diff = actor.player.global_position.y - body.global_position.y

		# Case 1: Player is above and reachable
		if vertical_diff < -60 and actor.get_platform_above(body):
			need_jump = true

		# Case 2: There’s an obstacle in front
		if actor.has_obstacle_ahead(body) and body.is_on_floor():
			need_jump = true

		if need_jump and actor.jumps_left > 0:
			var jump_force = actor.calculate_jump_force(body, base_jump_force, max_jump_force, jump_height_check)
			body.velocity.y = jump_force
			actor.jumps_left -= 1
			jumping = true
			did_double_jump = false
			time_since_jump = 0.0
			actor.just_jumped = true
			return Status.RUNNING

		return Status.FAILURE


class IsObstacleAhead extends BTNode:
	var min_dist_to_player := 48.0   # don’t treat anything as obstacle if we’re already close
	var ray_len := 20.0              # how far ahead to probe

	func tick(actor, _d) -> int:
		var body = actor.get_parent() as CharacterBody2D
		if body == null or actor.player == null:
			return Status.FAILURE

		# If we’re already close to the player, don’t trigger obstacle logic
		var dist = body.global_position.distance_to(actor.player.global_position)
		if dist <= min_dist_to_player:
			return Status.FAILURE

		# Ray forward toward the player
		var dir_x = sign(actor.player.global_position.x - body.global_position.x)
		if dir_x == 0:
			return Status.FAILURE

		var from = body.global_position + Vector2(dir_x * 12, -4)
		var to   = from + Vector2(dir_x * ray_len, 12)

		var q = PhysicsRayQueryParameters2D.create(from, to)
		# Exclude self AND the player so the player is never seen as an obstacle
		q.exclude = [actor, body, actor.player]
		var hit = actor.get_world_2d().direct_space_state.intersect_ray(q)
		if not hit:
			return Status.FAILURE

		var col = hit.get("collider")
		# Ignore dynamic characters (other followers, enemies)
		if col is CharacterBody2D:
			return Status.FAILURE

		return Status.SUCCESS


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
	"IsObstacleAhead": IsObstacleAhead,
	"IdleAnimation": IdleAnimation,
	"TeleportIfTooFar": TeleportIfTooFar,
	"Wait": Wait,
	"RandomChoiceMemory": RandomChoiceMemory,
	"MoveTowardPlayerFast": MoveTowardPlayerFast,
	"MoveTowardPlayerSlow": MoveTowardPlayerSlow
}


static func build_tree(definition: Dictionary) -> BTNode:
	var node_type = definition.get("type", null)
	if node_type == null or not node_registry.has(node_type):
		push_error("Unknown node type: %s" % node_type)
		return null
	
	var node = node_registry[node_type].new()
	
	# Copy all other properties (besides type/children) into the node, if it has matching members
	for key in definition.keys():
		if key == "type" or key == "children":
			continue
		var property_list = node.get_property_list()
		var has_prop = false
		for p in property_list:
			if p.name == key:
				has_prop = true
				break
		if has_prop:
			node.set(key, definition[key])
	
	# Build children recursively
	if definition.has("children"):
		for child_def in definition["children"]:
			var child = build_tree(child_def)
			if child != null:
				node.children.append(child)
	
	return node



# --- Extra noder för variation mellan vänner ---

# Vänta en viss tid (ex. blyg vän innan den följer)
class Wait extends BTNode:
	var time := 2.0
	var timer := 0.0
	var done := false

	func tick(_actor, delta) -> int:
		if done:
			return Status.SUCCESS

		if timer <= 0:
			timer = time

		timer -= delta
		if timer <= 0:
			done = true
			return Status.SUCCESS
		return Status.RUNNING

class RandomChoiceMemory extends BTNode:
	var chance := 0.7
	var duration := 3.0  # seconds to keep choice
	var timer := 0.0
	var use_slow := false

	func tick(_actor, delta) -> int:
		timer -= delta
		if timer <= 0.0:
			# re-roll the choice
			use_slow = randf() >= chance
			timer = duration
		# print(chance, " , ", duration)
		return Status.SUCCESS if use_slow else Status.FAILURE

# Variant av MoveTowardPlayer som rör sig snabbare
class MoveTowardPlayerFast extends MoveTowardPlayer:
	func tick(actor, delta) -> int:
		#print("fast")
		var old_speed = actor.speed
		actor.speed *= 1.5  # eller vilken faktor du vill
		var result = super.tick(actor, delta)
		actor.speed = old_speed
		return result
		
# Variant av MoveTowardPlayer som rör sig snabbare
class MoveTowardPlayerSlow extends MoveTowardPlayer:
	func tick(actor, delta) -> int:
		# print("slow")
		var old_speed = actor.speed
		actor.speed *= 0.5  # eller vilken faktor du vill
		var result = super.tick(actor, delta)
		actor.speed = old_speed
		return result
