extends Node2D
class_name Room

var previous_room_pos : Vector2 = Vector2.INF
var neighbors : Array = []

@export var grid_pos : Vector2
@export var type : int = 0
@export_group('Doors')
@export var door_top : bool
@export var door_bot : bool
@export var door_left : bool
@export var door_right : bool

func make_room(_pos, _type = type, _previous_room_pos = previous_room_pos):
	grid_pos = _pos
	type = _type
	previous_room_pos = _previous_room_pos

func get_door(direction):
	if direction == Vector2.UP:
		return door_top
	elif direction == Vector2.DOWN:
		return door_bot
	elif direction == Vector2.LEFT:
		return door_left
	elif direction == Vector2.RIGHT:
		return door_right
	else:
		return false

func disable_door(direction):
	if direction == Vector2.UP:
		door_top = false
	elif direction == Vector2.DOWN:
		door_bot = false
	elif direction == Vector2.LEFT:
		door_left = false
	elif direction == Vector2.RIGHT:
		door_right = false
	else:
		push_error('Erro: Direção fornecida não é válida!')
