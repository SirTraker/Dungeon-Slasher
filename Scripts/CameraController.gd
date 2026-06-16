extends Camera2D
class_name CameraController

@export var target: Node2D
var locked_to_room: bool = false
var room_center: Vector2
var room_size: Vector2

func _process(delta: float) -> void:
	if locked_to_room:
		global_position = room_center # Fixa a câmera no centro da sala
	else:
		if target: # Segue o jogador normalmente
			global_position = target.global_position

func lock_to_room(room: Node2D) -> void:
	# Supomos que o "room" é um RoomController
	if room is RoomController:
		locked_to_room = true
		room_center = room.global_position + Vector2(0,-8)
		room_size = room.room.room_size
		
func unlock() -> void:
	locked_to_room = false
