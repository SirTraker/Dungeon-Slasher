extends Node2D

@export var map_size : Vector2 = Vector2(10,10)
@export var min_rooms = 4
@export var max_rooms = 10
@export var room_size : Vector2 = Vector2(31,31)

const tile_size = 16

var rooms : Array[[Vector2, Array]]
var room_pos : Vector2

func _ready():
	var directions : Array = [1,3,4]
	rooms.append([Vector2(1,5), directions])
	rooms.append([Vector2(1,7), directions])
	print(rooms[1][1])
	randomize()
	make_rooms()
	
func make_rooms():
	var num_rooms = randi_range(min_rooms,max_rooms)
	var rooms_left = num_rooms
	var current_room = 0
	
	# Ponto Inicial
	room_pos = Vector2(randi_range(1,map_size.x),randi_range(1,map_size.y)) # * tile_size * room_size
	rooms.append(room_pos)
	current_room =+ 1
	rooms_left =- 1
	
	#while true:
		#var direction = randi_range(1,4)
		#room_pos = rooms[rooms.size() - 1] + get_direction(direction)
		#print(room_pos,rooms.has(room_pos))
		#if !rooms.has(room_pos) && (1 <= room_pos.x && room_pos.x <= map_size.x) && (1 <= room_pos.y && room_pos.y <= map_size.y):
			#rooms.append(room_pos)
			#break
	
	for i in randi_range(min_rooms,max_rooms) - 1:
		while true:
			var direction = randi_range(1,4)
			room_pos = rooms[rooms.size() - 1] + get_direction(direction)
			#print(room_pos,rooms.has(room_pos))
			if !rooms.has(room_pos) && (1 <= room_pos.x && room_pos.x <= map_size.x) && (1 <= room_pos.y && room_pos.y <= map_size.y):
				rooms.append(room_pos)
				break
		#var quant_directions = randi_range(1,3)
		#
		#room_pos = Vector2(randi_range(1,map_size.x),randi_range(1,map_size.y))
		#rooms.append(room_pos)
		#current_room += 1
	
func _draw():
	# draw grid
	for y in map_size.y:
		var row = y * room_size.y * tile_size
		for x in map_size.x:
			var collum = x * room_size.x * tile_size
			draw_rect(Rect2(Vector2(collum,row),room_size * tile_size),Color.WHITE,false)
	
	# draw path
	# draw_rect(Rect2(room_pos - room_size * tile_size, room_size * tile_size), Color.BLUE,true)
	for room in rooms:
		if room == rooms[0]:
			draw_rect(Rect2(room * tile_size * room_size - room_size * tile_size, room_size * tile_size), Color.GREEN,true)
		elif room == rooms[rooms.size()-1]:
			draw_rect(Rect2(room * tile_size * room_size - room_size * tile_size, room_size * tile_size), Color.RED,true)
		else:
			draw_rect(Rect2(room * tile_size * room_size - room_size * tile_size, room_size * tile_size), Color.BLUE,true)

func _input(event):
	if event.is_action_pressed('ui_select'):
		rooms.clear()
		make_rooms()
		queue_redraw()


func get_direction(number):
	if number == 1:
		return Vector2(0,1)
	elif number == 2:
		return Vector2(1,0)
	elif number == 3:
		return Vector2(0,-1)
	elif number == 4:
		return Vector2(-1,0)
	else:
		return Vector2.ZERO
