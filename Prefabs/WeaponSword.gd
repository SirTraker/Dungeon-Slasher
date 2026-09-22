class_name WeaponSword extends Weapon

@onready var pivot: Marker2D = $Pivot
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var can_rotate : bool = true

func _process(delta: float) -> void:
	if not can_rotate:
		return
	
	var mouse_rotation := (get_global_mouse_position() - global_position).angle()
	rotation = lerp_angle(rotation, mouse_rotation,delta * 10)
	
	if global_rotation > PI/2 or global_rotation < -PI/2:
		pivot.scale.y = -1
	else:
		pivot.scale.y = 1

func attack() -> void:
	animation_player.play("swing")
