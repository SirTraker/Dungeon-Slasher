extends Node2D

@export var level_generator: LevelGenerator
@export var player_scene: PackedScene
@export var camera: Camera2D

var player : Node2D

func _ready():
	# 1. Gera o nível
	await level_generator.generate_level()
	
	# 2. Obtém a sala inicial
	var start_room: Room = level_generator.get_entry_room()
	if not start_room:
		push_error("GameManager: Não encontrei a sala inicial!")
		return
	
	# 3. Instancia o player
	player = player_scene.instantiate()
	add_child(player)
	
	# 4. Posiciona o player no centro da sala inicial
	var room_pos: = level_generator.get_tilemap_pos(start_room.grid_pos)
	var center = room_pos + Vector2i(
		level_generator.room_size.x / 2,
		level_generator.room_size.y / 2)
	player.global_position = center * level_generator.tile_size
	
	# 5. Liga a câmera ao player
	if camera:
		camera.is_current()
		camera.target = player
