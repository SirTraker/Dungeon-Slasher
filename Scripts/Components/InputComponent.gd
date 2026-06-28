class_name InputComponent extends Node

var move_dir : Vector2 = Vector2.ZERO

func update() -> void:
	move_dir = Input.get_vector("Left","Right","Up","Down")
	if Input.is_action_just_pressed("Debug_Damage"):
		%HealthComponent.damage(1)
	elif Input.is_action_just_pressed("Debug_Heal"):
		%HealthComponent.heal(1)
