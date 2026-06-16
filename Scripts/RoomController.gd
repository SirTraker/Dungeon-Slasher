extends Node2D
class_name RoomController

# ──────────────── CONFIGURAÇÃO ────────────────
@onready var area_trigger: Area2D = $Area2D

@export var room : Room

# ──────────────── VARIÁVEIS ────────────────
var cleared: bool = false
var enemies: Array = []
var doors: Array[Node] = []

func _ready():
	_setup_area()
	_setup_doors()
	_setup_enemies()
	position = room.screen_pos + room.room_size / 2

#region 🔧 SETUP da Sala
func _setup_area():
	area_trigger.body_entered.connect(_on_body_entered)
	area_trigger.body_exited.connect(_on_body_exited)
	$Area2D/CollisionShape2D.shape.size = room.room_size

func _setup_doors():
	if has_node("Doors"):
		doors = get_node("Doors").get_children()

func _setup_enemies():
	if has_node("Enemies"):
		enemies = get_node("Enemies").get_children()
		for e in enemies:
			e.active = false
			e.died.connect(_on_enemy_died)

#endregion

#region 🔔 SIGNALS
func _on_body_entered(body):
	if room.type == 0 and body.is_in_group("Player") and not cleared:
		var camera = get_viewport().get_camera_2d()
		if camera and camera.has_method("lock_to_room"):
			camera.lock_to_room(self)
			#camera.lock_to_room = true
			#camera.room_center = global_position - Vector2(0,8)
			#camera.room_size = room_size
		close_doors()
		activate_enemies()
	else:
		print(room.type)
		print(body.is_in_group("Player"))
		print(cleared)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		var camera = get_viewport().get_camera_2d()
		if camera and camera.has_method("unlock"):
			camera.unlock()

func _on_enemy_died():
	# Se todos morreram → sala limpa
	if enemies.all(func(e): return e.dead):
		cleared = true
		open_doors()

#endregion

func activate_enemies():
	for e in enemies:
		e.active = true

func close_doors():
	for d in doors:
		d.close() # assumes portas têm método close()

func open_doors():
	for d in doors:
		d.open() # assumes portas têm método open()
