extends Node2D


# PackedScene objects
export(PackedScene) var Stage

# Signals
# ...

# Node children
var stage

# Custom properties
var window_size
var score


func _ready():
	# Instantiate and assign objects
	stage = $Stage

	# Register signals
	stage.connect("player_hit_snake", self, "_on_Stage_player_hit_snake")
	stage.connect("player_fruit_collected", self, "_on_Stage_player_fruit_collected")
	stage.connect("player_hit_wall", self, "_on_Stage_player_hit_wall")

	# Initialize properties
	window_size = self.get_viewport_rect().size
	score = 0
	
	# Center stage
	stage.set_position((window_size - stage.stage_size) / 2)


func _on_Stage_player_hit_snake():
	pass
	

func _on_Stage_player_fruit_collected():
	score += 1


func _on_Stage_player_hit_wall():
	pass
