extends Node2D


# PackedScene objects
export(PackedScene) var Snake
export(PackedScene) var Fruit

# Signals
signal player_hit_snake
signal player_fruit_collected
signal player_hit_wall

# Node children
var fruit
var snake
var walls
var boundary

# Custom properties
var SNAKE_SPEED_SLOW = 0.14
var SNAKE_SPEED_MEDIUM = 0.12
var SNAKE_SPEED_FAST = 0.10

var stage_size = Vector2()
var cell_size = Vector2()
var grid_size = Vector2()


func _ready():
	# Seed the random number generator for this scene
	randomize()
	
	# Instantiate and assign objects
	fruit = Fruit.instance()
	snake = Snake.instance()
	walls = $Walls
	boundary = $Boundary

	# Register signals
	snake.connect("hit", self, "_on_Snake_hit")
	boundary.connect("area_exited", self, "_on_Boundary_area_exited")

	# Initialize properties
	stage_size = boundary.get_node("CollisionShape2D").get_shape().get_extents() * 2
	cell_size = walls.get_cell_size()
	grid_size = stage_size / cell_size

	# Spawn fruit
	self.add_child(fruit)
	fruit.set_position($FruitSpawn.get_position())

	# Spawn snake
	self.add_child(snake)
	snake.set_speed(SNAKE_SPEED_MEDIUM)
	snake.set_step_size(cell_size)
	snake.set_head_position($SnakeSpawn.get_position())


func _on_Boundary_area_exited(area):
	var exit_location = area.get_position()
	print("[%s] %s exited %s at %s %s" % [
		self.get_name(),
		area.get_name(),
		boundary.get_name(),
		exit_location,
		exit_location / cell_size
	])
	
	if area == snake.get_head():
		if exit_location.x < 0:
			area.set_position(Vector2(stage_size.x - cell_size.x, exit_location.y))
		elif exit_location.x > stage_size.x - cell_size.x:
			area.set_position(Vector2(0, exit_location.y))
		elif exit_location.y < 0:
			area.set_position(Vector2(exit_location.x, stage_size.y - cell_size.y))
		elif exit_location.y > stage_size.y - cell_size.y:
			area.set_position(Vector2(exit_location.x, 0))


func _on_Snake_hit(hit_snake, hit_object):
	var hit_location = hit_snake.get_head_position() + hit_snake.get_velocity()
	print("[%s] %s hit %s %s %s" % [
		self.get_name(),
		hit_snake.get_name(),
		hit_object.get_name(),
		hit_location,
		hit_location / cell_size
	])
	match hit_object:
		fruit:
			self.process_fruit_collision()
		walls:
			self.process_wall_collision()
		_:
			if hit_object in snake.get_body_segments():
				self.process_snake_collision()
			else:
				self.process_unknown_collision()


func move_fruit():
	var safe_to_move = false
	var new_grid_position = Vector2()
	var new_position = Vector2()
	var num_tries = 0

	# Move fruit into an empty random location
	while not safe_to_move and num_tries < grid_size.x * grid_size.y:
		# Get random cell location as potential destination
		var rand_row = randi() % int(grid_size.x)
		var rand_col = randi() % int(grid_size.y)
		new_grid_position = Vector2(rand_row, rand_col)
		new_position = new_grid_position * cell_size

		# Check for collisions and try again if we hit anything
		if walls.get_cellv(new_grid_position) == TileMap.INVALID_CELL:
			var snake_hit = false
			for segment in snake.get_body_segments():
				if new_position == segment.get_position():
					snake_hit = true
			if not snake_hit:
				safe_to_move = (fruit.position != new_position)
		
		num_tries += 1

	# Move fruit to new, safe position
	if safe_to_move:
		fruit.set_position(new_position)
		print("[%s] Fruit moved to %s %s in %s tries" % [
			self.name, new_position, new_grid_position, num_tries])
	else:
		print("[%s] Fruit could not be moved after %d tries" % [self.name, num_tries])
		fruit.get_node("HitBox").set_disabled(true)
		fruit.hide()


func process_snake_collision():
	snake.stop()
	self.emit_signal("player_hit_snake")


func process_fruit_collision():
	self.move_fruit()
	snake.grow_on_next_move()
	snake.move()
	self.emit_signal("player_fruit_collected")


func process_wall_collision():
	snake.stop()
	self.emit_signal("player_hit_wall")


func process_unknown_collision():
	snake.stop()
	self.emit_signal("player_hit_wall")


func get_snake():
	return snake


func get_fruit():
	return fruit


func get_stage_size():
	return stage_size


func get_cell_size():
	return cell_size


func get_grid_size():
	return grid_size
