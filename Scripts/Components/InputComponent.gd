class_name InputComponent extends Node

var move_dir : Vector2 = Vector2.ZERO
var attack_just_pressed : bool = false
var attack_pressed : bool = false
var attack_released : bool = false

func update() -> void:
	move_dir = Input.get_vector("Left","Right","Up","Down")
	
	attack_just_pressed = Input.is_action_just_pressed("Attack")
	attack_pressed = Input.is_action_pressed("Attack")
	attack_released = Input.is_action_just_released("Attack")
	
	if Input.is_action_just_pressed("Debug_Damage"):
		%HealthComponent.damage(1)
	elif Input.is_action_just_pressed("Debug_Heal"):
		%HealthComponent.heal(1)
