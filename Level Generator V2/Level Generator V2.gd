extends Node2D

@export var map_size = Vector2i(8,8)
var grid_size = Vector2i()
@export var number_rooms = 20
@export var room_size : Vector2 = Vector2(4,4)

var rooms : Array[Room]
var taken_positions : Array[Vector2]

var tile_size = 16

func _ready():
	# Limit Room Quantity
	if number_rooms > map_size.x * map_size.y:
		number_rooms = map_size.x * map_size.y
	grid_size = map_size / 2
	create_rooms()

func create_rooms():
	# Setup
	rooms.append(Room.new())
	rooms[0].make_room(Vector2.ZERO, 1)
	taken_positions.insert(0,rooms[0].grid_pos)
	var check_pos = Vector2.ZERO
	for i in rooms.size() - 1: 
		print('Room Pos:',rooms[i].grid_pos)
	
	# Tree expansion limitators
	var random_compare = 0.2
	var random_compare_start = 0.5
	var random_compare_end = 0.1
	
	# Add Rooms
	for i in number_rooms:
		queue_redraw()
		await get_tree().create_timer(0.2).timeout
		# Tree Expansion change
		var random_perc = i / (number_rooms - 1)
		random_compare = lerp(random_compare_start,random_compare_end,random_perc)
		# Grab new Position
		check_pos = new_position()
		# Test new Position
		if number_of_neighbors(check_pos) > 1 && randf() < random_compare:
			var iterations = 0
			while true:
				check_pos = selective_new_position()
				iterations += 1
				if number_of_neighbors(check_pos) == 1 && iterations > 100:
					break
			if iterations >= 50:
				print("error: could not create with fewer neighbors than : ", number_of_neighbors(check_pos))
		
		# Finalize position
		rooms.append(Room.new())
		rooms.back().make_room(check_pos)
		taken_positions.insert(0, check_pos)

func new_position():
	var x = 0
	var y = 0
	var checking_pos = Vector2.ZERO
	while true:
		var index = randi_range(0, taken_positions.size() - 1)
		x = taken_positions[index].x
		y = taken_positions[index].y
		var y_axis = (randf_range(0,1) < 0.5)
		var positive = (randf_range(0,1) < 0.5)
		if y_axis:
			if positive:
				y += 1
			else:
				y -= 1
		else:
			if positive:
				x += 1
			else:
				x -= 1
		checking_pos = Vector2(x,y)
		if not(taken_positions.has(checking_pos) || x < -grid_size.x || x > grid_size.x || y < -grid_size.y || y > grid_size.y):  
			break
	return checking_pos

func selective_new_position():
	var x = 0
	var y = 0
	var index = 0
	var inc = 0
	var checking_pos = Vector2.ZERO
	
	while true:
		inc = 0
		while true:
			index = randi_range(0, taken_positions.size() - 1)
			inc += 1
			if number_of_neighbors(taken_positions[index]) == 1 && inc > 100:
				break
		x = taken_positions[index].x
		y = taken_positions[index].y
		var up_down = randf() < 0.5
		var positive = randf() < 0.5
		if up_down:
			if positive:
				y += 1
			else:
				y -= 1
		else:
			if positive:
				x += 1
			else:
				x -= 1
		checking_pos = Vector2(x,y)
		if not(taken_positions.has(checking_pos) || x < -grid_size.x || x > grid_size.x || y < -grid_size.y || y > grid_size.y):  
			break
	#if inc >= 100:
		#print("Error: no position with only one neighbor")
	return checking_pos

func number_of_neighbors(checkingPos : Vector2):
	var ret = 0
	if taken_positions.has(checkingPos + Vector2.RIGHT):
		ret += 1
	if taken_positions.has(checkingPos + Vector2.LEFT):
		ret += 1
	if taken_positions.has(checkingPos + Vector2.UP):
		ret += 1
	if taken_positions.has(checkingPos + Vector2.DOWN):
		ret += 1
	return ret

func _draw():
	for y in map_size.y + 1:
		var row = (y * room_size.y * tile_size) - grid_size.y * tile_size * (map_size.y/2)
		for x in map_size.x + 1:
			var collum = (x * room_size.x * tile_size) - grid_size.x * tile_size * (map_size.x/2)
			draw_rect(Rect2(Vector2(collum,row),room_size * tile_size),Color.WHITE,false)
	
	for room in rooms:
		var pos = room.grid_pos * (tile_size * room_size)
		var size = room_size * tile_size
		
		if room.type == 1:
			draw_rect(Rect2(pos, size), Color.GREEN,true)
		elif room.type == 2:
			draw_rect(Rect2(pos, size), Color.RED,true)
		else:
			draw_rect(Rect2(pos, size), Color.BLUE,true)

func _input(event):
	if event.is_action_pressed('ui_select'):
		rooms.clear()
		taken_positions.clear()
		create_rooms()
		queue_redraw()
