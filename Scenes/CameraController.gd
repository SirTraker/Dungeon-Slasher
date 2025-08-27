extends Camera2D

@export var target: Node2D
var lock_to_room: bool = false
var room_center: Vector2
var room_size: Vector2

func _process(delta):
	if lock_to_room:
		# Fixa a câmera no centro da sala
		global_position = room_center
		# (podes opcionalmente limitar com offset/zoom usando room_size)
	else:
		# Segue o jogador normalmente
		if target:
			global_position = target.global_position
