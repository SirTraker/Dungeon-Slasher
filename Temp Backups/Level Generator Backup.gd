extends Node2D

@export_group('Debug')
@export var debug : bool = false

@export_group('Generation Parameters')
@export var map_size = Vector2i(8,8)
@export var number_rooms = 20
@export var room_size : Vector2 = Vector2(4,4)

var grid_size = Vector2()
var rooms : Array[Room]
var taken_positions : Array[Vector2]

var tile_size = 16

func _ready():
	# Limit Room Quantity
	if number_rooms > map_size.x * map_size.y:
		number_rooms = map_size.x * map_size.y - 1
	grid_size = map_size / 2
	
	inicialize_rooms() # Gerar Salas

func inicialize_rooms():
	var success = false
	while not success:
		rooms.clear()
		taken_positions.clear()
		
		# Começa com a sala inicial
		var start_pos = Vector2(randi_range(-grid_size.x, grid_size.x), randi_range(-grid_size.y, grid_size.y))
		var start_room = Room.new()
		start_room.make_room(start_pos, 0)
		rooms.append(start_room)
		taken_positions.append(start_pos)
		
		await create_rooms()
		
		if rooms.size() >= 3:  # precisa de ao menos 2 salas para entrada e saída
			assign_entry_and_exit_rooms()
			connect_doors()
			success = true
		
	queue_redraw()

func create_rooms():
	var check_pos = Vector2.ZERO	
	#var random_compare = 0.2
	var random_compare_start = 0.5
	var random_compare_end = 0.1
	
	for i in number_rooms:
		if debug:
			queue_redraw()
			await get_tree().create_timer(0.2).timeout
		
		var random_perc = float(i) / (number_rooms - 1)
		var random_compare = lerp(random_compare_start, random_compare_end, random_perc)
		# Grab new Position
		var allow_multiple_neighbors = randf() >= random_compare
		check_pos = find_new_position(allow_multiple_neighbors)
		
		if check_pos == Vector2.INF:
			print("Erro: não foi possível encontrar nova posição válida.")
			continue

		# Finalize position
		rooms.append(Room.new())
		rooms.back().make_room(check_pos)
		taken_positions.insert(0, check_pos)

#func create_exit_room1():
	#var possible_exit : Array[Vector2]
	#for i in map_size.x * 0.2 * 2:
		#var x = map_size.x / 2 * (-1 if i == 0 else 1)
		#for y in map_size.y:
			#y -= map_size.y / 2
			##if taken_positions.has(Vector2(x,y)):
				##if(number_of_neighbors(Vector2(x,y)) == 1):
					##possible_exit.append(Vector2(x,y))
				##elif((number_of_neighbors(Vector2(x,y-1)) > 1)||(number_of_neighbors(Vector2(x,y+1)) > 1)):
					##possible_exit.append(Vector2(x,y))
			#if taken_positions.has(Vector2(x,y)) && ((number_of_neighbors(Vector2(x,y)) == 1)
			#|| ((number_of_neighbors(Vector2(x,y-1)) > 1)||(number_of_neighbors(Vector2(x,y+1)) > 1))):
				#possible_exit.append(Vector2(x,y))
	#for i in map_size.y * 0.2 * 2:
		#var y = map_size.y / 2 * (-1 if i == 0 else 1)
		#for x in map_size.x:
			#x -= map_size.x / 2
			##if taken_positions.has(Vector2(x,y)):
				##if(number_of_neighbors(Vector2(x,y)) == 1):
					##possible_exit.append(Vector2(x,y))
				##elif((number_of_neighbors(Vector2(x-1,y)) > 1)||(number_of_neighbors(Vector2(x+1,y)) > 1)):
					##possible_exit.append(Vector2(x,y))
			#if taken_positions.has(Vector2(x,y)) && ((number_of_neighbors(Vector2(x,y)) == 1)
			#|| ((number_of_neighbors(Vector2(x-1,y)) > 1)||(number_of_neighbors(Vector2(x+1,y)) > 1))):
				#possible_exit.append(Vector2(x,y))
	#if possible_exit.size() == 0:
		#return 1
	#var exit_found = false
	#while exit_found == false:
		#print('here')
		#var i = randi_range(0,possible_exit.size()-1)
		#for room in rooms:
			#if room.grid_pos == possible_exit[i] && room.type == 0:
				#room.type = 2
				#exit_found = true
	#return 0
#
#func create_exit_room():
	#var possible_exit : Array[Vector2] = []
	#var start_pos = rooms[0].grid_pos
	#
	#for pos in taken_positions:
		#if number_of_neighbors(pos) == 1:
			## Ignora se estiver ao lado da entrada
			#if pos.distance_to(start_pos) <= 1:
				#continue
			#possible_exit.append(pos)
	#
	#if possible_exit.is_empty():
		#return 1 #ERRO nenhuma saida válida
		#
	## Escolhe aleatoriamente uma sala de ponta e marca como saída
	#while true:
		#var i = randi_range(0, possible_exit.size() - 1)
		#var chosen = possible_exit[i]
		#for room in rooms:
			#if room.grid_pos == chosen and room.type == 0:
				#room.type = 2  # tipo de sala de saída
				#return 0  # sucesso

func assign_entry_and_exit_rooms():
	var max_distance = 0.0
	var entry_index = 0
	var exit_index = 0
	
	for i in rooms.size():
		for j in rooms.size():
			if i == j: continue
			var dist = rooms[i].grid_pos.distance_to(rooms[j].grid_pos)
			if dist > max_distance:
				max_distance = dist
				entry_index = i
				exit_index = j
	
	rooms[entry_index].type = 1  # Entrada (verde)
	rooms[exit_index].type = 2   # Saída (vermelha)

func connect_doors():
	for room in rooms:
		var pos = room.grid_pos
		if taken_positions.has(pos + Vector2.UP):
			room.door_top = true
		if taken_positions.has(pos + Vector2.DOWN):
			room.door_bot = true
		if taken_positions.has(pos + Vector2.LEFT):
			room.door_left = true
		if taken_positions.has(pos + Vector2.RIGHT):
			room.door_right = true

func find_new_position(require_single_neighbor := false) -> Vector2:
	var attempts = 0
	while attempts < 200:
		attempts += 1
		var index = randi_range(0, taken_positions.size() - 1)
		var base_pos = taken_positions[index]
		
		if require_single_neighbor and number_of_neighbors(base_pos) != 1:
			continue

		var offset = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()
		var new_pos = base_pos + offset
		
		if new_pos.x < -grid_size.x or new_pos.x > grid_size.x:
			continue
		if new_pos.y < -grid_size.y or new_pos.y > grid_size.y:
			continue
		if taken_positions.has(new_pos):
			continue
		
		return new_pos
	
	# Se falhar, retorna uma posição sem filtro
	return find_new_position(false)

#func new_position():
	#var x = 0
	#var y = 0
	#var checking_pos = Vector2.ZERO
	#while true:
		#var index = randi_range(0, taken_positions.size() - 1)
		#x = taken_positions[index].x
		#y = taken_positions[index].y
		#var y_axis = (randf_range(0,1) < 0.5)
		#var positive = (randf_range(0,1) < 0.5)
		#if y_axis:
			#if positive:
				#y += 1
			#else:
				#y -= 1
		#else:
			#if positive:
				#x += 1
			#else:
				#x -= 1
		#checking_pos = Vector2(x,y)
		#if not(taken_positions.has(checking_pos) || x < -grid_size.x || x > grid_size.x || y < -grid_size.y || y > grid_size.y):  
			#break
	#return checking_pos
#
#func selective_new_position():
	#var x = 0
	#var y = 0
	#var index = 0
	#var inc = 0
	#var checking_pos = Vector2.ZERO
	#
	#while true:
		#inc = 0
		#while true:
			#index = randi_range(0, taken_positions.size() - 1)
			#inc += 1
			#if number_of_neighbors(taken_positions[index]) == 1 || inc > 100:
				#break
		#x = taken_positions[index].x
		#y = taken_positions[index].y
		#var up_down = randf() < 0.5
		#var positive = randf() < 0.5
		#if up_down:
			#if positive:
				#y += 1
			#else:
				#y -= 1
		#else:
			#if positive:
				#x += 1
			#else:
				#x -= 1
		#checking_pos = Vector2(x,y)
		#if not(taken_positions.has(checking_pos) || x < -grid_size.x || x > grid_size.x || y < -grid_size.y || y > grid_size.y):  
			#break
	##if inc >= 100:
		##print("Error: no position with only one neighbor")
	#return checking_pos

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
	# grid
	for y in map_size.y:
		var row = y * room_size.y * tile_size - grid_size.y  * room_size.y * tile_size
		for x in map_size.x:
			var collum = x * room_size.x * tile_size - grid_size.x  * room_size.x * tile_size
			draw_rect(Rect2(Vector2(collum,row),room_size * tile_size),Color.WHITE,false)
	
	# rooms
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
		inicialize_rooms() # Gerar Salas
