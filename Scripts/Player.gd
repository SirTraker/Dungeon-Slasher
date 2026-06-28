class_name Player extends CharacterBody2D

@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var health_component: HealthComponent = %HealthComponent



func _physics_process(delta: float) -> void:
	input_component.update()
	
	movement_component.move(input_component.move_dir, delta)


func _on_health_component_health_changed(current_health: int, max_health: int) -> void:
	print('Current Health: %d 				Max Health: %d' % [current_health,max_health])


func _on_health_component_died() -> void:
	print('Player Died')
