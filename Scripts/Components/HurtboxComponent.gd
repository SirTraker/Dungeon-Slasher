class_name HurtboxComponent extends Area2D

@export var health_component: HealthComponent

func take_damage(amount : int) -> void:
	if health_component == null:
		push_error("HealthComponent not assigned")
		return

	health_component.damage(amount)
