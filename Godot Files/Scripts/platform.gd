@tool
class_name platform_maker
extends Node2D
# Customisable values
@export var length:int: 
	set(value): 
		length = value
		print("val changed")
		updateLen(value)
var children:Array[Node2D]
@export var firstSprite:Texture2D
@export var middleSprites:Array[Texture2D]
@export var lastSprite:Texture2D
@export var spriteHeight = 0
@export var spriteHieghtOffset = 0

# Caused on updating length
func updateLen(value):
	if not Engine.is_editor_hint(): # Make sure we're in editor
		return
	
	# Clear old child nodes
	var size = 0
		
	for child in get_children():
		child.queue_free()
	
	# Make a bridge segment for each index
	for index in length:
		var spriteCreating:Texture2D
		
		# Debugging
		if not firstSprite:
			print("Sprite not found")
		else:
			print("Sprite found: " + firstSprite.resource_path)
		
		# Choose appropriate sprite
		if index == 0 and length > 1:
			spriteCreating = firstSprite
		elif (index == 0 and length <= 1) or index < length - 1:
			spriteCreating = middleSprites[randi() % middleSprites.size()]
		else:
			spriteCreating = lastSprite
		
		# Create and position sprite
		var created:Sprite2D = Sprite2D.new()
		created.texture = spriteCreating
		created.position = (Vector2.RIGHT * created.texture.get_width() * created.scale.x * index)
		size = created.texture.get_width() * created.scale.x
		add_child(created)
		created.owner = get_tree().edited_scene_root
		children.append(created)
	
	# Create collision with one static body
	var body := StaticBody2D.new()
	add_child(body)
	body.owner = get_tree().edited_scene_root
	var collider := CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	collider.shape = shape
	shape.size.y = spriteHeight
	shape.size.x = size * length
	body.add_child(collider)
	body.set_collision_layer_value(1,false)
	body.set_collision_layer_value(2,true)
	collider.position.x = size * length / 2 - size/2
	collider.one_way_collision = true
	body.add_to_group("Platforms",true)
	collider.add_to_group("Platforms",true)
	
	children.append(body)
	children.append(collider)
	children.append(collider)
	collider.owner = get_tree().edited_scene_root
	
