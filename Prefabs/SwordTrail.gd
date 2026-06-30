@tool
extends Line2D

@export var target : Node2D

func _process(delta: float) -> void:
	if !target:
		return
	if !visible:
		clear_points()
		return
	#add_point(get_parent().global_position)
	top_level = false
	add_point(to_local(target.global_position))
	
	if points.size() > 30:
		remove_point(0)
