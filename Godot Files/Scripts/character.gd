extends CharacterBody2D

@export var SPEED = 300.0
@export var JUMP_VELOCITY = -200.0
@export var JUMP_COUNT = 1
@export var DASH_SPEED = 1000.0
@export var GRAB_SPEED = 5

var usedJumps = 0
var startJump = -1
var start_dash = -1
var facing = 1;
var dashDir = 0;

var grabPosition:Vector2 = Vector2.ZERO
var start_grab = 0
var grab_start_pos:Vector2 = Vector2.ZERO
var calculated_grab_time = 1.0

func _ready():
	$AnimatedSprite2D.play()

func getHangingOnWall() -> bool:
	if is_on_wall():
		for index in get_slide_collision_count():
			var collision := get_slide_collision(index)
			var collider = collision.get_collider()
			# One way of doing collision detection I removed for a more universal approach
			#if collider is TileMap:
				#var tile_rid = get_slide_collision(index).get_collider_rid()
				#var layer = PhysicsServer2D.body_get_collision_layer(tile_rid)
				#if layer == 1:
					#return true
			if collider is TileMapLayer:
				var tile_map:TileMapLayer = collider
				var hit_cell = tile_map.local_to_map(collision.get_position() + collision.get_normal() * - 4)
				var data = tile_map.get_cell_tile_data(hit_cell)
				if data:
					return data.get_custom_data("AbleToGrab?")
	return false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	var onWall:bool = getHangingOnWall()
	if not is_on_floor() and not onWall and not (Time.get_ticks_msec() - start_grab < 1000):
		velocity += get_gravity() * delta
	else: 
		usedJumps = 0

	if onWall:
		velocity.y = 0
		

		
	var upDown := Input.get_axis("Up", "Down")
	if onWall:
		velocity.y = upDown * SPEED
	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("Move_Left", "Move_Right")
	if (direction != 0):
		if direction < 0: facing = -1
		else: facing = 1
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Handle jump.		
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or usedJumps < JUMP_COUNT) and not Input.is_action_pressed("Down"):
		startJump = Time.get_ticks_msec()
		if not is_on_floor() and not onWall:
			usedJumps += 1
			
	if Input.is_action_pressed("Jump") and (Time.get_ticks_msec() - startJump < 300):
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("Jump") and Input.is_action_pressed("Down"):
		set_collision_mask_value(2,false)
		await get_tree().create_timer(0.1).timeout
		set_collision_mask_value(2,true)
		
		# Keeping this around to show of the stupid stuff I was doing :)
		#var space_state = get_world_2d().direct_space_state
		#var query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2.DOWN * 100,
			#collision_mask, [self])
		#var results := space_state.intersect_ray(query)
		#print(results)
		##print(results.values().back())
		#if results:
			#var collider:Node2D = results["collider"]
			#print(collider.get_groups())
			#if (collider.is_in_group("Platforms")):
				#print("it's a platform!")
				#var coll:StaticBody2D = collider
				#coll.set_collision_layer_value(1,false)
				#await get_tree().create_timer(0.1).timeout
				#coll.set_collision_layer_value(1,true)

		#var closest := results.values().back()
		#for result in results.values():
			#if len(result.position - position) < len(closest.position - position):
				#closest = result
		

	
		
	# Dash Mechanic
	if Input.is_action_just_pressed("Dash"):
		dashDir = facing
		velocity.x = DASH_SPEED * dashDir
		start_dash = Time.get_ticks_msec()
	# First attempt at a "grab" dash mechanic... I think we should replace this by sending out an scene rather than just a raycast (which is also buggy)
	#if Input.is_action_just_pressed("Dash"):
		#dashDir = facing
		##velocity.x = DASH_SPEED * dashDir
		##start_dash = Time.get_ticks_msec()
		#var space_state = get_world_2d().direct_space_state
		#var mask = 0b00000000_00000000_00000000_00000100 # Only look on environment layer
		#var queryMiddle = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2.RIGHT * 500 * dashDir, mask, [self])
		##var shape:RectangleShape2D = $CollisionShape2D.shape
		##shape.size.x
		##var queryTop = PhysicsRayQueryParameters2D.create(global_position + Vector2.UP * ($CollisionShape2D.shape.size.y/2), global_position + Vector2.UP * ($CollisionShape2D.shape.size.y/2) + Vector2.RIGHT * 500 * dashDir, mask, [self])
		##var queryBottom = PhysicsRayQueryParameters2D.create(global_position + Vector2.UP * -($CollisionShape2D.shape.size.y/2), global_position + Vector2.UP * -($CollisionShape2D.shape.size.y/2) + Vector2.RIGHT * 500 * dashDir, mask, [self])
		#var results := space_state.intersect_ray(queryMiddle)
		#if results:
			#print(results)
			#var pos:Vector2 = results["position"]
			#
			#start_grab = Time.get_ticks_msec()
			#grab_start_pos = position
			#grabPosition = pos
			#velocity.y = 0
			#calculated_grab_time = abs(grabPosition.x - grab_start_pos.x) / GRAB_SPEED
			#var pos = results[""]
			#var collider:Node2D = results["collider"]
			#print(collider.get_groups())
			#if (collider.is_in_group("Platforms")):
				#print("it's a platform!")
				#var coll:StaticBody2D = collider
				#coll.set_collision_layer_value(1,false)
				#await get_tree().create_timer(0.1).timeout
				#coll.set_collision_layer_value(1,true)
	#if (Time.get_ticks_msec() - start_grab <= calculated_grab_time) and start_grab != 0:
		#velocity.x = lerp(grab_start_pos.x,grabPosition.x,(Time.get_ticks_msec() - start_grab) /calculated_grab_time)
		##print("Lerp: " + String(lerp(grab_start_pos.x,grabPosition.x,(Time.get_ticks_msec() - start_grab) /5000)) + ", GrabStart: " + String(grab_start_pos.x) + ", GrabPosition: " + String(grabPosition.x) )
		#print("start")
		#print(calculated_grab_time)
		#print(lerp(grab_start_pos.x,grabPosition.x,(Time.get_ticks_msec() - start_grab) /500.0))
		#print(grab_start_pos)
		#print(grabPosition)
		#print((Time.get_ticks_msec() - start_grab) /500.0)
		#print(position)
		
	if (Time.get_ticks_msec() - start_dash < 150):
		velocity.x = lerp(DASH_SPEED*dashDir,0.0, float(Time.get_ticks_msec() - start_dash)/500.00)
		
	#Animation handling
	$AnimatedSprite2D.flip_h = facing < 0
	if is_on_floor():
		if (direction == 0):
			$AnimatedSprite2D.animation = "idle"
		else:
			$AnimatedSprite2D.animation = "run"
		if Input.is_action_pressed("Jump"):
			$AnimatedSprite2D.play_backwards("Jump_Land")
	else: 
		if velocity.y > 0:
			$AnimatedSprite2D.animation = "jump_down"
		else: 
			$AnimatedSprite2D.animation = "jump_up"
		if onWall:
			#$AnimatedSprite2D.animation = "wall" Replaced with default because it looks better :)
			$AnimatedSprite2D.flip_h = facing > 0
		if usedJumps != 0 and (Time.get_ticks_msec() - startJump < 200):
			$AnimatedSprite2D.animation = "double_jump"

	move_and_slide()
