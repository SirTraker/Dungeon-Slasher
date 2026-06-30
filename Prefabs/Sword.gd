class_name WearponComponent extends Node2D

@onready var pivot: Marker2D = $Pivot

@export var can_rotate : bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if can_rotate:
		#look_at(get_global_mouse_position())
		var mouse_rotation = (get_global_mouse_position() - global_position).angle()
		rotation = lerp_angle(rotation, mouse_rotation,delta * 10)
		if pivot and (global_rotation > PI / 2 or global_rotation < -PI / 2):
			pivot.scale.y = -1
		elif pivot:
			pivot.scale.y = 1
		#if pivot and get_global_mouse_position().x < global_position.x:
			#pivot.scale.y = -1
		#elif pivot:
			#pivot.scale.y = 1

func attack():
	$AnimationPlayer.play("swing")
