extends Area2D


# Custom properties
var previous_position = Vector2.ZERO
enum {
	SPRITE_SQUARE,
	SPRITE_UP,
	SPRITE_DOWN,
	SPRITE_LEFT,
	SPRITE_RIGHT,
	SPRITE_UP_LEFT,
	SPRITE_UP_RIGHT,
	SPRITE_DOWN_LEFT,
	SPRITE_DOWN_RIGHT,
	SPRITE_VERTICAL,
	SPRITE_HORIZONTAL
}


func move(velocity : Vector2):
	previous_position = position
	position += velocity


func set_position(new_position : Vector2):
	previous_position = position
	position = new_position

func get_previous_position():
	return previous_position
