class_name Player extends CharacterBody2D

@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent


func _physics_process(delta: float) -> void:
	input_component.update()
	
	movement_component.move(input_component.move_dir, delta)
