extends Node2D

@export_group('Debug')
@export var debug : bool = false

@export_group('Parametros de Geração')
@export var map_size = Vector2i(5,5)
@export var terrain_set := 0
@export var padding = 10  # espaçamento entre salas
@export var number_rooms = 5
@export var room_size : Vector2i = Vector2(24,16)

const DIRECTIONS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

enum TerrainType {
	EMPTY = -1,
	FLOOR = 0,
	WALL = 1
}
var ground : TileMapLayer
var walls : TileMapLayer

var grid_size = Vector2()
var rooms : Array[Room]
var taken_positions : Array[Vector2]

var tile_size = 16

func _ready():
	ground= $Map/Ground
	walls= $Map/Walls
	# Limit Room Quantity
	if number_rooms > map_size.x * map_size.y:
		number_rooms = map_size.x * map_size.y - 1
	grid_size = map_size / 2
	await inicialize_rooms() # Gerar Salas
	instantiate_tilemap()
	print('done')

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
		#else :
			#print("Tentativa %d: não foi possível gerar mapa com entrada e saída válidas." % attempt)
	
	if not success:
		push_error("Erro: Não foi possível gerar um mapa válido após várias tentativas.")
	queue_redraw()
	print("1"," rooms = ", rooms.size(), " taken = ", taken_positions.size())

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
			#print("Aviso: Não foi possível encontrar nova posição válida. Tentando Novamente...")
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
	var room_a = get_room_at_pos(pos_a)
	var room_b = get_room_at_pos(pos_b)
	
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
	var room_a = get_room_at_pos(pos_a)
	var room_b = get_room_at_pos(pos_b)
	
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
	var candidate_rooms := []
	var extra_candidate_rooms := []
	# Só consideramos salas com exatamente 1 vizinho
	for i in rooms:
		var num = number_of_neighbors(i.grid_pos)
		if num == 1:
			candidate_rooms.append(i)
		elif num == 2:
			extra_candidate_rooms.append(i)

	if candidate_rooms.size() < 2:
		if not extra_candidate_rooms.is_empty():
			candidate_rooms.append_array(extra_candidate_rooms)
		else:
			push_warning("Não há pontas suficientes para definir entrada e saída.")
			return false
	
	# Seleciona as duas pontas mais distantes entre si
	var max_distance = 0.0
	var entry_room = candidate_rooms[0]
	var exit_room = candidate_rooms[1]
	
	for i in candidate_rooms.size():
		for j in candidate_rooms.size():
			if i == j: continue
			var dist = candidate_rooms[i].grid_pos.distance_to(candidate_rooms[j].grid_pos)
			if dist > max_distance:
				max_distance = dist
				entry_room = candidate_rooms[i]
				exit_room = candidate_rooms[j]
	
	if number_of_neighbors(entry_room.grid_pos) == 2:
		var shuffle_dir = DIRECTIONS.duplicate()
		shuffle_dir.shuffle()
		for dir in shuffle_dir:
			var neighbor_pos = entry_room.grid_pos + dir
			if entry_room.get_door(dir):
				disconnect_rooms(entry_room.grid_pos, neighbor_pos)
				break
	if number_of_neighbors(exit_room.grid_pos) == 2:
		var shuffle_dir = []
		shuffle_dir.append_array(DIRECTIONS)
		shuffle_dir.shuffle()
		for dir in shuffle_dir:
			var neighbor_pos = exit_room.grid_pos + dir
			if exit_room.get_door(dir):
				disconnect_rooms(exit_room.grid_pos, neighbor_pos)
				break
	
	for room in rooms:
		if room == entry_room:
			room.type = 1  # Entrada (verde)
		elif room == exit_room:
			room.type = 2   # Saída (vermelha)
	
	return true

# !!! Substituir por connect_rooms()
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

func get_room_at_pos(pos: Vector2) -> Room:
	for room in rooms:
		if room.grid_pos == pos:
			return room
	return null

func clear_rooms():
	rooms.clear()
	taken_positions.clear()

func instantiate_tilemap():
	fill_entire_map_with(TerrainType.FLOOR, ground)
	fill_entire_map_with(TerrainType.WALL, walls)
	carve_all_rooms(walls)
	print("acabou tilemap")

func fill_entire_map_with(terrain_id: int, tile_layer : TileMapLayer) -> void:
	var positions := []
	var full_width = map_size.x * (room_size.x + padding)
	var full_height = map_size.y * (room_size.y + padding)
	var center_offset = Vector2i(full_width / 2, full_height / 2)
	
	full_width += room_size.x
	full_height += room_size.y
	
	for y in full_height:
		for x in full_width:
			var tile_pos = Vector2i(x, y) - center_offset
			positions.append(tile_pos)
	
	for pos in positions:
		if terrain_id == 0:
			tile_layer.set_cell(pos,1,Vector2i(4,8)) #Tile do chão
		if terrain_id == 1:
			tile_layer.set_cell(pos,1,Vector2i(2,2)) #Tile das paredes

func carve_all_rooms(tile_layer: TileMapLayer) -> void:
	var positions := []
	for room in rooms:
		var start_tile := get_tilemap_pos(room.grid_pos)
		for y in int(room_size.y):
			for x in int(room_size.x):
				positions.append(start_tile + Vector2i(x, y))
	tile_layer.set_cells_terrain_connect(positions, terrain_set, TerrainType.EMPTY, true)

func get_tilemap_pos(grid_pos: Vector2i) -> Vector2i:
	var tile_pos = grid_pos * (room_size + Vector2i(padding,padding))
	return tile_pos

func _draw():
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
		var room_pos = get_room_screen_position(room.grid_pos)
		var size = room_size * tile_size

		# Desenhar retângulo da sala
		var color = room_color_default
		if room.type == 1:
			color = room_color_entry
		elif room.type == 2:
			color = room_color_exit
		
		draw_rect(Rect2(room_pos, size), color, true)	
		
		# Centro da sala
		var center = room_pos + size / 2
		
		# Desenhar linhas de conexão se há portas
		for dir in DIRECTIONS:
			var neighbor_pos = room.grid_pos + dir
			if room.get_door(dir) && taken_positions.has(neighbor_pos):
				var neighbor = get_room_at_pos(neighbor_pos)
				if neighbor == null:
					continue
				var neighbor_screen_pos = get_room_screen_position(neighbor.grid_pos)
				var neighbor_center = neighbor_screen_pos + size / 2
				draw_line(center, neighbor_center, connection_color, 20, false)

func get_room_screen_position(grid_pos: Vector2i ) -> Vector2i:
	return grid_pos * (room_size * tile_size) + (padding * grid_pos * tile_size)

func _input(event):
	if event.is_action_pressed('ui_select'):
		await inicialize_rooms() # Gerar Salas
		instantiate_tilemap()
		print('done')
