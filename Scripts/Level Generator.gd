extends Node2D
class_name LevelGenerator

# ──────────────── CONFIGURAÇÃO ────────────────
@export_group("Debug")
@export var debug: bool = false

@export_group("Parâmetros de Geração")
@export var map_size = Vector2i(5, 5)
@export var terrain_set = 0
@export var padding = 10
@export var number_rooms = 5
@export var room_size = Vector2i(24, 16)

@export_group("TileMap Layers")
@export var ground: TileMapLayer
@export var walls: TileMapLayer

# ──────────────── CONSTANTES ────────────────
const DIRECTIONS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

enum TerrainType {
	EMPTY = -1,
	FLOOR = 0,
	WALL = 1
}

# ──────────────── VARIÁVEIS ────────────────
var grid_size = Vector2()
var rooms: Array[Room] = []
var taken_positions: Array[Vector2] = []

var tile_size = 16

var entry_room : Room
var exit_room : Room

#region ▶ Ciclo Principal
func _ready():
	# Garantir que o número de salas não excede a grelha
	number_rooms = min(number_rooms, map_size.x * map_size.y - 1)
	grid_size = map_size / 2
	
	#await generate_rooms() # Gerar Salas
	#instantiate_tilemap()

func _input(event):
	if event.is_action_pressed('Generate Map'):
		walls.clear()
		ground.clear()
		await generate_rooms() # Gerar Salas
		instantiate_tilemap()

func generate_level():
	walls.clear()
	ground.clear()
	await generate_rooms()
	instantiate_tilemap()
#endregion

#region 🧱 Geração de salas
func generate_rooms():
	var max_attempts = 30
	
	for attempt in max_attempts:
		clear_rooms()
		
		# Criar Sala Inicial
		var start_pos = Vector2(
			randi_range(-grid_size.x, grid_size.x), 
			randi_range(-grid_size.y, grid_size.y)
		)
		
		var start_room = Room.new()
		start_room.make_room(start_pos,room_size * 16, 0)
		rooms.append(start_room)
		taken_positions.append(start_pos)
		
		await create_rooms()
		
		for room in rooms:
			for dir in DIRECTIONS:
				var neighbor_pos = room.grid_pos + dir
				if taken_positions.has(neighbor_pos):
					connect_rooms(room.grid_pos, neighbor_pos)
		
		if assign_entry_and_exit_rooms():
			queue_redraw()
			return # sucesso
	push_error("Erro: Não foi possível gerar um mapa válido após várias tentativas.")

func create_rooms():
	var i = 1
	var compare_start = 0.5
	var compare_end = 0.1
	
	while i < number_rooms:
		var ratio = float(i) / (number_rooms - 1)
		var allow_multi_neighbors = randf() >= lerp(compare_start, compare_end, ratio)
		
		var base_pos = taken_positions.pick_random()
		var new_pos = find_new_position(base_pos, allow_multi_neighbors)
		
		if new_pos == Vector2.INF:
			continue
		
		# Criar e armazenar a nova sala
		var new_room = Room.new()
		new_room.make_room(new_pos,room_size * 16,0,base_pos)
		rooms.append(new_room)
		taken_positions.insert(0, new_pos)
		
		i += 1 # só avança se a sala foi criada com sucesso
		
		if debug:
			queue_redraw()
			await get_tree().create_timer(0.2).timeout

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
	var _entry_room = candidate_rooms[0]
	var _exit_room = candidate_rooms[1]
	
	for i in candidate_rooms.size():
		for j in candidate_rooms.size():
			if i == j: continue
			var dist = candidate_rooms[i].grid_pos.distance_to(candidate_rooms[j].grid_pos)
			if dist > max_distance:
				max_distance = dist
				_entry_room = candidate_rooms[i]
				_exit_room = candidate_rooms[j]
	
	if number_of_neighbors(_entry_room.grid_pos) == 2:
		var shuffle_dir = DIRECTIONS.duplicate()
		shuffle_dir.shuffle()
		for dir in shuffle_dir:
			var neighbor_pos = _entry_room.grid_pos + dir
			if _entry_room.get_door(dir):
				disconnect_rooms(_entry_room.grid_pos, neighbor_pos)
				break
	if number_of_neighbors(_exit_room.grid_pos) == 2:
		var shuffle_dir = []
		shuffle_dir.append_array(DIRECTIONS)
		shuffle_dir.shuffle()
		for dir in shuffle_dir:
			var neighbor_pos = _exit_room.grid_pos + dir
			if _exit_room.get_door(dir):
				disconnect_rooms(_exit_room.grid_pos, neighbor_pos)
				break
	
	for room in rooms:
		if room == _entry_room:
			room.type = 1  # Entrada (verde)
		elif room == _exit_room:
			room.type = 2   # Saída (vermelha)
	
	entry_room = _entry_room
	exit_room = _exit_room
	
	return true

func find_new_position(base_pos : Vector2, require_single_neighbor := false) -> Vector2:
	for _attempt in 200:
		var offset = DIRECTIONS.pick_random()
		var new_pos = base_pos + offset
		
		if new_pos.x < -grid_size.x or new_pos.x > grid_size.x:
			continue
		if new_pos.y < -grid_size.y or new_pos.y > grid_size.y:
			continue
		if taken_positions.has(new_pos):
			continue
		if require_single_neighbor and number_of_neighbors(new_pos) != 1:
			continue
	
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
#endregion

#region 🔗 Conexões entre salas
func connect_rooms(pos_a: Vector2, pos_b: Vector2):
	var dir = pos_b - pos_a
	var room_a = get_room_at_pos(pos_a)
	var room_b = get_room_at_pos(pos_b)
	
	match dir:
		Vector2.UP:
			room_a.door_top = true
			room_b.door_bot = true
		Vector2.DOWN:
			room_a.door_bot = true
			room_b.door_top = true
		Vector2.LEFT:
			room_a.door_left = true
			room_b.door_right = true
		Vector2.RIGHT:
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
	
	match dir:
		Vector2.UP:
			room_a.door_top = false
			room_b.door_bot = false
		Vector2.DOWN:
			room_a.door_bot = false
			room_b.door_top = false
		Vector2.LEFT:
			room_a.door_left = false
			room_b.door_right = false
		Vector2.RIGHT:
			room_a.door_right = false
			room_b.door_left = false
		
	room_a.neighbors.erase(room_b)
	room_b.neighbors.erase(room_a)

#endregion

#region 🧰 Utilitários de sala
func clear_rooms():
	rooms.clear()
	taken_positions.clear()

func get_room_at_pos(pos: Vector2) -> Room:
	for room in rooms:
		if room.grid_pos == pos:
			return room
	return null

func number_of_neighbors(pos: Vector2) -> int:
	var count := 0
	for dir in DIRECTIONS:
		if taken_positions.has(pos + dir):
			count += 1
	return count

func remove_duplicates(array: Array) -> Array:
	var result := []
	var seen := {}
	for value in array:
		if not seen.has(value):
			seen[value] = true
			result.append(value)
	return result

func get_entry_room() -> Room:
	return entry_room

func get_exit_room() -> Room:
	return exit_room

#endregion

#region 🧱 Tilemap: Preenchimento e escavação
func instantiate_tilemap():
	fill_tilemap_with_static_tiles() # Preencher o mapa inteiro com tiles base (sem autotile)
	dig_map(walls)
	#carve_all_rooms(walls) # Escavar todas as salas (com autotile)
	if debug:
		print("Geração TileMap Concluida")

func fill_tilemap_with_static_tiles():
	var full_width = map_size.x * (room_size.x + padding)
	var full_height = map_size.y * (room_size.y + padding)
	var center_offset = Vector2i(full_width / 2, full_height / 2)
	
	full_width += room_size.x
	full_height += room_size.y
	
	for y in full_height:
		for x in full_width:
			var pos = Vector2i(x, y) - center_offset
			ground.set_cell(pos, 1, Vector2i(4, 8)) # Tile do chão (Ground) - fixo, não autotile
			walls.set_cell(pos, 1, Vector2i(2, 2)) # Tile da parede (Walls) - fixo, será escavado depois

func carve_all_rooms(tile_layer: TileMapLayer):
	var all_positions: Array[Vector2i] = []
	
	for room in rooms:
		var start_tile = get_tilemap_pos(room.grid_pos)
		for y in int(room_size.y):
			for x in int(room_size.x):
				all_positions.append(start_tile + Vector2i(x, y))
	
	tile_layer.set_cells_terrain_connect(all_positions, terrain_set, TerrainType.EMPTY, true)

func get_tilemap_pos(grid_pos: Vector2i) -> Vector2i:
	return grid_pos * (room_size + Vector2i(padding,padding))

func dig_map(tile_layer: TileMapLayer) -> void:
	var dig_positions = get_all_dig_positions()
	var unique_positions = remove_duplicates(dig_positions)  # Remove duplicados
	
	tile_layer.set_cells_terrain_connect(unique_positions, terrain_set, TerrainType.EMPTY, true)

func get_all_dig_positions() -> Array[Vector2i]:
	var dig_positions: Array[Vector2i] = []
	
	# Adicionar posições das salas
	for room in rooms:
		var start := get_tilemap_pos(room.grid_pos)
		for y in int(room_size.y):
			for x in int(room_size.x):
				dig_positions.append(start + Vector2i(x, y))
	
	# Adicionar posições dos corredores
	var visited_pairs := {}
	for room in rooms:
		for neighbor in room.neighbors:
			var key := [room, neighbor]
			key.sort()
			if visited_pairs.has(key):
				continue
			visited_pairs[key] = true
			
			var center_a := get_tilemap_pos(room.grid_pos) + Vector2i(room_size.x, room_size.y) / 2
			var center_b := get_tilemap_pos(neighbor.grid_pos) + Vector2i(room_size.x, room_size.y) / 2
			
			if center_a.x == center_b.x:
				var y_range := range(min(center_a.y, center_b.y), max(center_a.y, center_b.y) + 1)
				for y in y_range:
					dig_positions.append(Vector2i(center_a.x, y))
					dig_positions.append(Vector2i(center_a.x - 1, y))
					dig_positions.append(Vector2i(center_a.x - 2, y))
					dig_positions.append(Vector2i(center_a.x + 1, y))
			elif center_a.y == center_b.y:
				var x_range := range(min(center_a.x, center_b.x), max(center_a.x, center_b.x) + 1)
				for x in x_range:
					dig_positions.append(Vector2i(x, center_a.y))
					dig_positions.append(Vector2i(x, center_a.y - 1))
					dig_positions.append(Vector2i(x, center_a.y - 2))
					dig_positions.append(Vector2i(x, center_a.y + 1))
	return dig_positions

#endregion

#region 🖼️ Debug: Desenhar mapa e salas
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

#endregion
