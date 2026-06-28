extends Node2D

@export var can_rotate : bool = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if can_rotate:
		look_at(get_global_mouse_position())
