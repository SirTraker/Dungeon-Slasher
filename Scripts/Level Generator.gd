extends Node2D

@export_group('Debug')
@export var debug : bool = false

@export_group('Generation Parameters')
@export var map_size = Vector2i(8,8)
@export var number_rooms = 20
@export var room_size : Vector2 = Vector2(4,4)

const DIRECTIONS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

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
	var max_attempts = 30
	var success = false
	
	for attempt in range(max_attempts):
		clear_rooms()
		
		# Começa com a sala inicial
		var start_pos = Vector2(randi_range(-grid_size.x, grid_size.x), randi_range(-grid_size.y, grid_size.y))
		var start_room = Room.new()
		start_room.make_room(start_pos, 0)
		rooms.append(start_room)
		taken_positions.append(start_pos)
		
		await create_rooms()
		await connect_doors()

		if assign_entry_and_exit_rooms():
			success = true
			break
		else :
			print("Tentativa %d: não foi possível gerar mapa com entrada e saída válidas." % attempt)
	
	if not success:
		push_error("Erro: Não foi possível gerar um mapa válido após várias tentativas.")
	queue_redraw()

func create_rooms():
	var random_compare_start = 0.5
	var random_compare_end = 0.1
	
	if debug:
			queue_redraw()
			await get_tree().create_timer(0.2).timeout
	
	var i = 1
	while i < number_rooms:
		
		var random_perc = float(i) / (number_rooms - 1)
		var random_compare = lerp(random_compare_start, random_compare_end, random_perc)
		var allow_multiple_neighbors = randf() >= random_compare

		var base_pos : Vector2 = taken_positions.pick_random()
		var check_pos : Vector2 = find_new_position(base_pos, allow_multiple_neighbors)
		
		if check_pos == Vector2.INF:
			print("Aviso: Não foi possível encontrar nova posição válida. Tentando Novamente...")
			continue # não avança o contador, tenta de novo
		
		# Criar e armazenar a nova sala corretamente
		var new_room = Room.new()
		new_room.make_room(check_pos,0,base_pos)
		rooms.append(new_room)
		taken_positions.insert(0, check_pos)
		
		i += 1 # só avança se a sala foi criada com sucesso
		
		if debug:
			queue_redraw()
			await get_tree().create_timer(0.2).timeout

func connect_rooms(pos_a: Vector2, pos_b: Vector2):
	var dir = pos_b - pos_a
	var room_a = get_room_at(pos_a)
	var room_b = get_room_at(pos_b)
	
	if dir == Vector2.UP:
		room_a.door_top = true
		room_b.door_bot = true
	elif dir == Vector2.DOWN:
		room_a.door_bot = true
		room_b.door_top = true
	elif dir == Vector2.LEFT:
		room_a.door_left = true
		room_b.door_right = true
	elif dir == Vector2.RIGHT:
		room_a.door_right = true
		room_b.door_left = true

	if not room_b in room_a.neighbors:
		room_a.neighbors.append(room_b)
	if not room_a in room_b.neighbors:
		room_b.neighbors.append(room_a)

func disconnect_rooms(pos_a: Vector2, pos_b: Vector2):
	var dir = pos_b - pos_a
	var room_a = get_room_at(pos_a)
	var room_b = get_room_at(pos_b)
	
	if dir == Vector2.UP:
		room_a.door_top = false
		room_b.door_bot = false
	elif dir == Vector2.DOWN:
		room_a.door_bot = false
		room_b.door_top = false
	elif dir == Vector2.LEFT:
		room_a.door_left = false
		room_b.door_right = false
	elif dir == Vector2.RIGHT:
		room_a.door_right = false
		room_b.door_left = false
		
	room_a.neighbors.erase(room_b)
	room_b.neighbors.erase(room_a)

func assign_entry_and_exit_rooms() -> bool:
	var candidate_indices := []
	var extra_candidate_indices := []
	# Só consideramos salas com exatamente 1 vizinho
	for i in rooms:
		var num = number_of_neighbors(i.grid_pos)
		if num == 1:
			candidate_indices.append(i)
		elif num == 2:
			extra_candidate_indices.append(i)

	if candidate_indices.size() < 2:
		if not extra_candidate_indices.is_empty():
			#for room in extra_candidate_indices:
				#var shuffle_dir = DIRECTIONS
				#shuffle_dir.shuffle()
				#print(shuffle_dir, DIRECTIONS)
				#for dir in shuffle_dir:
					#if room.get_door(dir):
						#room.disable_door(dir)
						#break
			candidate_indices.append_array(extra_candidate_indices)
		else:
			push_warning("Não há pontas suficientes para definir entrada e saída.")
			return false
	
	# Seleciona as duas pontas mais distantes entre si
	var max_distance = 0.0
	var entry_index = candidate_indices[0]
	var exit_index = candidate_indices[1]
	
	for i in candidate_indices.size():
		for j in candidate_indices.size():
			if i == j: continue
			var dist = candidate_indices[i].grid_pos.distance_to(candidate_indices[j].grid_pos)
			if dist > max_distance:
				max_distance = dist
				entry_index = i
				exit_index = j
	
	if number_of_neighbors(candidate_indices[entry_index].grid_pos) == 2:
		var shuffle_dir = DIRECTIONS
		shuffle_dir.shuffle()
		print(shuffle_dir, DIRECTIONS)
		for dir in shuffle_dir:
			if candidate_indices[entry_index].get_door(dir):
				candidate_indices[entry_index].disable_door(dir)
				break
	if number_of_neighbors(candidate_indices[exit_index].grid_pos) == 2:
		var shuffle_dir = []
		shuffle_dir.append_array(DIRECTIONS)
		shuffle_dir.shuffle()
		print(shuffle_dir, DIRECTIONS)
		for dir in shuffle_dir:
			if candidate_indices[exit_index].get_door(dir):
				candidate_indices[exit_index].disable_door(dir)
				break
	
	for room in rooms:
		if room == candidate_indices[entry_index]:
			room.type = 1  # Entrada (verde)
		elif room == candidate_indices[exit_index]:
			room.type = 2   # Saída (vermelha)
	
	return true

func connect_doors():
	for room in rooms:
		for dir in DIRECTIONS:
			var neighbor_pos = room.grid_pos + dir
			if taken_positions.has(neighbor_pos):
				match dir:
					Vector2.UP: room.door_top = true
					Vector2.DOWN: room.door_bot = true
					Vector2.LEFT: room.door_left = true
					Vector2.RIGHT: room.door_right = true
		queue_redraw()

func find_new_position(base_pos : Vector2, require_single_neighbor := false) -> Vector2:
	var attempts = 0
	while attempts < 200:
		attempts += 1
		
		if require_single_neighbor and number_of_neighbors(base_pos) != 1:
			continue

		var offset = DIRECTIONS.pick_random()
		var new_pos = base_pos + offset
		
		if new_pos.x < -grid_size.x or new_pos.x > grid_size.x:
			continue
		if new_pos.y < -grid_size.y or new_pos.y > grid_size.y:
			continue
		if taken_positions.has(new_pos):
			continue
		
		return new_pos
	
	return Vector2.INF  # sem posição válida encontrada

func number_of_neighbors(pos : Vector2):
	var count = 0
	for dir in DIRECTIONS:
		if taken_positions.has(pos + dir):
			count += 1
	return count

func get_room_at(pos: Vector2) -> Room:
	for room in rooms:
		if room.grid_pos == pos:
			return room
	return null

func clear_rooms():
	rooms.clear()
	taken_positions.clear()

func _draw():
	var padding = 10  # espaçamento entre salas
	var connection_color = Color.YELLOW
	var room_color_default = Color.BLUE
	var room_color_entry = Color.GREEN
	var room_color_exit = Color.RED
	# grid
	for y in map_size.y:
		var row = y * room_size.y * tile_size - grid_size.y  * room_size.y * tile_size - (padding * (grid_size.y-y) * tile_size)
		for x in map_size.x:
			var collum = x * room_size.x * tile_size - grid_size.x  * room_size.x * tile_size - (padding * (grid_size.x-x) * tile_size) 
			draw_rect(Rect2(Vector2(collum,row),room_size * tile_size),Color.WHITE,false)
	# rooms
	for room in rooms:
		var pos = room.grid_pos * (room_size * tile_size) + (padding * room.grid_pos * tile_size)
		var size = room_size * tile_size

		# Desenhar retângulo da sala
		var color = room_color_default
		if room.type == 1:
			color = room_color_entry
		elif room.type == 2:
			color = room_color_exit
		
		draw_rect(Rect2(pos, size), color, true)	
		
		# Centro da sala
		var center = pos + size / 2
		
		# Desenhar linhas de conexão se há portas
		for dir in DIRECTIONS:
			var neighbor_pos = room.grid_pos + dir
			if room.get_door(dir) && taken_positions.has(neighbor_pos):
				var neighbor = get_room_at_position(neighbor_pos)
				if neighbor == null:
					continue

				var neighbor_screen_pos = neighbor.grid_pos * (room_size * tile_size) + (padding * room.grid_pos * tile_size)
				var neighbor_center = neighbor_screen_pos + size / 2
				draw_line(center, neighbor_center, connection_color, 20, false)

func get_room_at_position(pos: Vector2) -> Room:
	for room in rooms:
		if room.grid_pos == pos:
			return room
	return null

func _input(event):
	if event.is_action_pressed('ui_select'):
		inicialize_rooms() # Gerar Salas
