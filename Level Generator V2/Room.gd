extends Node2D
class_name Room

@export var grid_pos : Vector2
@export var type : int = 0
@export_group('Doors')
@export var door_top : bool
@export var door_bot : bool
@export var door_left : bool
@export var door_right : bool

func make_room(_pos, _type = type):
	grid_pos = _pos
	type = _type
