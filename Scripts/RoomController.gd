extends Node2D
class_name RoomController

@export var room_size: Vector2i
@export var grid_pos: Vector2i
@export var doors: Array[Node] = [] # podes exportar portas ou ligar via código
@onready var area_trigger: Area2D = $Area2D

var cleared: bool = false
var enemies: Array = []

func _ready():
	# Registar sinal quando o jogador entra
	area_trigger.body_entered.connect(_on_body_entered)
	area_trigger.body_exited.connect(_on_body_exited)
	# Procurar inimigos filhos desta sala (podem estar numa Node chamada "Enemies")
	if has_node("Enemies"):
		enemies = get_node("Enemies").get_children()
		for e in enemies:
			e.active = false
			e.died.connect(_on_enemy_died)
	
	position = grid_pos
	$Area2D/CollisionShape2D.shape.size = room_size

func _on_body_entered(body):
	if body.is_in_group("Player") and not cleared:
		var camera = get_viewport().get_camera_2d()
		if camera:
			camera.lock_to_room = true
			camera.room_center = global_position - Vector2(0,8)
			camera.room_size = room_size
		close_doors()
		activate_enemies()

func _on_body_exited(body):
	if body.is_in_group("Player"):
		var camera = get_viewport().get_camera_2d()
		if camera:
			camera.lock_to_room = false

func activate_enemies():
	for e in enemies:
		e.active = true

func _on_enemy_died():
	# Se todos morreram → sala limpa
	if enemies.all(func(e): return e.dead):
		cleared = true
		open_doors()

func close_doors():
	for d in doors:
		d.close() # assumes portas têm método close()

func open_doors():
	for d in doors:
		d.open() # assumes portas têm método open()
