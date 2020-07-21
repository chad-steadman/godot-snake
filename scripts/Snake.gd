extends Node2D


# PackedScene objects
export(PackedScene) var BodySegment

# Signals
signal hit(snake, hit_object)

# Node children
var timer
var head
var ray
var debug_label

# Custom properties
export var speed = float()
export var step_size = Vector2()
var input_direction = Vector2()
var direction = Vector2()
var previous_direction = Vector2()
var velocity = Vector2()
var previous_velocity = Vector2()
var body_segments = []
var grow = false


func _ready():
	# Instantiate and assign objects
	timer = $MoveTimer
	head = $Head
	ray = $Head/RayCast2D
	debug_label = $DebugLabel
	
	# Register signals
	timer.connect("timeout", self, "_on_MoveTimer_timeout")
	
	# Initialize properties
	body_segments.append(head)
	timer.set_wait_time(speed)
	timer.start()


func debug_show():
	debug_label.show()


func debug_hide():
	debug_label.hide()


func debug_set_position(new_position):
	debug_label.rect_position = new_position


func debug_refresh_current_stats():
	var text = """-- Snake --
	speed=%s
	step=%s
	in.dir=%s
	pos=%s %s
	dir=%s
	vel=%s
	p.dir=%s
	p.vel=%s
	length=%d
	""" % [
		speed,
		step_size,
		input_direction,
		head.get_position(), head.get_position() / step_size,
		direction,
		velocity,
		previous_direction,
		previous_velocity,
		body_segments.size(),
	]
	
	debug_label.set_text(text)


func _physics_process(_delta):
	# Process inputs
	input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("ui_up") and (
		body_segments.size() == 1 or previous_direction != Vector2.DOWN):
			input_direction = Vector2.UP
			direction = input_direction
	
	elif Input.is_action_pressed("ui_down") and (
		body_segments.size() == 1 or previous_direction != Vector2.UP):
			input_direction = Vector2.DOWN
			direction = input_direction
	
	elif Input.is_action_pressed("ui_left") and (
		body_segments.size() == 1 or previous_direction != Vector2.RIGHT):
			input_direction = Vector2.LEFT
			direction = input_direction
	
	elif Input.is_action_pressed("ui_right") and (
		body_segments.size() == 1 or previous_direction != Vector2.LEFT):
			input_direction = Vector2.RIGHT
			direction = input_direction
	
	# DEBUG
#	elif Input.is_key_pressed(KEY_SPACE):
#		self.stop()
	
	# DEBUG
#	self.debug_refresh_current_stats()


func _on_MoveTimer_timeout():
	# Update velocity
	velocity = direction * step_size
	
	# Check for collisions
	if velocity != Vector2.ZERO:
		ray.set_cast_to(velocity)
		ray.force_raycast_update()
		
		if ray.is_colliding():
			self.emit_signal("hit", self, ray.get_collider())
		else:
			self.move()


func move():
	previous_direction = direction
	previous_velocity = velocity
	head.move(velocity)
	for i in range(1, body_segments.size()):
		var segment = body_segments[i]
		var previous_segment = body_segments[i-1]
		segment.set_position(previous_segment.get_previous_position())
	if grow:
		self.create_body_segment()
		grow = false
	self.refresh_sprites()


func stop():
	direction = Vector2.ZERO


func grow_on_next_move():
	grow = true


func create_body_segment():
	var new_segment = BodySegment.instance()
	var tail = body_segments.back()
	new_segment.set_position(tail.get_previous_position())
	body_segments.append(new_segment)
	self.add_child(new_segment)


func delete_body_segment():
	var tail = body_segments.pop_back()
	tail.queue_free()


func delete_all_segments():
	for i in range(1, body_segments.size()):
		body_segments[i].queue_free()


func refresh_sprites():
	var num_segments = body_segments.size()
	if num_segments > 2:
		# Update head sprite on direction change
		match direction:
			Vector2.UP:
				head.get_node("Sprite").set_frame(head.SPRITE_UP)
			Vector2.DOWN:
				head.get_node("Sprite").set_frame(head.SPRITE_DOWN)
			Vector2.LEFT:
				head.get_node("Sprite").set_frame(head.SPRITE_LEFT)
			Vector2.RIGHT:
				head.get_node("Sprite").set_frame(head.SPRITE_RIGHT)
					
		# Update body sprites
		for i in range(1, num_segments):
			var segment = body_segments[i]
			var previous_segment = body_segments[i-1]
			var next_segment = null
			if i < num_segments - 1:
				next_segment = body_segments[i+1]
			self.connect_sprites(segment, previous_segment, next_segment)
	elif num_segments == 2:
		var tail = body_segments.back()
		self.connect_sprites(head, tail)
		self.connect_sprites(tail, head)


func connect_sprites(segment, previous_segment, next_segment=null):
	var direction_prev = segment.get_position().direction_to(previous_segment.get_position())
	var distance_prev = segment.get_position().distance_to(previous_segment.get_position())
	
	var direction_next = Vector2.ZERO
	var distance_next = 0
	
	if next_segment != null:
		direction_next = segment.get_position().direction_to(next_segment.get_position())
		distance_next = segment.get_position().distance_to(next_segment.get_position())

	# Check for teleporting snake pieces and adjust directions in the x or y axis
	if distance_prev > step_size.x or distance_prev > step_size.y:
		direction_prev *= -1
	if distance_next > step_size.x or distance_next > step_size.y:
		direction_next *= -1

	# Adjust sprites depending on 1 of 10 combinations of body segments
	match direction_prev + direction_next:
		Vector2.UP:
			segment.get_node("Sprite").set_frame(segment.SPRITE_DOWN)
		Vector2.DOWN:
			segment.get_node("Sprite").set_frame(segment.SPRITE_UP)
		Vector2.LEFT:
			segment.get_node("Sprite").set_frame(segment.SPRITE_RIGHT)
		Vector2.RIGHT:
			segment.get_node("Sprite").set_frame(segment.SPRITE_LEFT)
		Vector2.UP + Vector2.LEFT:
			segment.get_node("Sprite").set_frame(segment.SPRITE_DOWN_LEFT)
		Vector2.UP + Vector2.RIGHT:
			segment.get_node("Sprite").set_frame(segment.SPRITE_DOWN_RIGHT)
		Vector2.DOWN + Vector2.LEFT:
			segment.get_node("Sprite").set_frame(segment.SPRITE_UP_LEFT)
		Vector2.DOWN + Vector2.RIGHT:
			segment.get_node("Sprite").set_frame(segment.SPRITE_UP_RIGHT)
		Vector2.ZERO:
			if abs(direction_prev.x) + abs(direction_next.x) == 0:
				segment.get_node("Sprite").set_frame(segment.SPRITE_VERTICAL)
			else:
				segment.get_node("Sprite").set_frame(segment.SPRITE_HORIZONTAL)


func get_head():
	return head


func get_head_position():
	return head.get_position()


func get_head_previous_position():
	return head.get_previous_position()


func get_speed():
	return timer.get_wait_time()


func get_step_size():
	return step_size


func get_input_direction():
	return input_direction


func get_direction():
	return direction


func get_previous_direction():
	return previous_direction


func get_velocity():
	return velocity


func get_previous_velocity():
	return previous_velocity


func get_body_segments():
	return body_segments


func get_grow():
	return grow


func set_head_position(new_position : Vector2):
	head.set_position(new_position)


func set_speed(new_speed : float):
	speed = new_speed
	timer.set_wait_time(speed)

func set_step_size(new_step_size : Vector2):
	step_size = new_step_size


func set_grow(new_grow : bool):
	grow = new_grow
