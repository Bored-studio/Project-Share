extends CharacterBody2D

@export var SPEED = 160.0 # Movement speed
@export var JUMP_VELOCITY = -160.0 # Jump velocity up
@export var JUMPS_ALLOWED = 2 # Number of consecutive jumps allowed
@export var DASH_SPEED = 400.0
@export var DASH_COOLDOWN = 1000 # Dash cooldown time (in ms)
@export var GRAB_SPEED = 5
@export var SENSITIVITY = 1600 # Higher = more sensitive and faster responses

var dash_cooldown = 0
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
		if velocity.x < 0:
			# print(velocity.x)
			pass

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
		velocity.x = move_toward(velocity.x, direction * SPEED, delta * SENSITIVITY)
	else:
		velocity.x = move_toward(velocity.x, 0, delta * SENSITIVITY)

	# Handle jump.		
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or usedJumps+1 < JUMPS_ALLOWED) and not Input.is_action_pressed("Down"):
		startJump = Time.get_ticks_msec()
		if not is_on_floor() and not onWall:
			usedJumps += 1
			
	if Input.is_action_pressed("Jump") and (Time.get_ticks_msec() - startJump < 300):
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("Jump") and Input.is_action_pressed("Down"):
		set_collision_mask_value(2,false)
		await get_tree().create_timer(0.1).timeout
		set_collision_mask_value(2,true)
		
	# Dash Mechanic
	# if Input.is_action_just_pressed("Dash") and (Time.get_ticks_msec() - start_dash >= DASH_COOLDOWN):
	# 	dashDir = facing
	# 	velocity.x = DASH_SPEED * dashDir
	# 	# print(Time.get_ticks_msec() - start_dash)
	# 	start_dash = Time.get_ticks_msec()
		
	# if (Time.get_ticks_msec() - start_dash < 150):
	# 	velocity.x = lerp(DASH_SPEED*dashDir, 0.0, float(Time.get_ticks_msec() - start_dash)/500.00)

	# Grapple Mechanic

	if Input.is_action_just_pressed("Dash") and (Time.get_ticks_msec() - start_dash >= DASH_COOLDOWN):
		dashDir = facing
		velocity.x = DASH_SPEED * dashDir
		# print(Time.get_ticks_msec() - start_dash)
		start_dash = Time.get_ticks_msec()
		
	if (Time.get_ticks_msec() - start_dash < 150):
		velocity.x = lerp(DASH_SPEED*dashDir, 0.0, float(Time.get_ticks_msec() - start_dash)/500.00)
		
	# Animation handling
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
