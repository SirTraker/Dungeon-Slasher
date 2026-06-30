class_name Player extends CharacterBody2D

@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var health_component: HealthComponent = %HealthComponent
@onready var wearpon_component: WearponComponent = %WearponComponent

@onready var wearpon_sword: WearponComponent = $WearponSword # HACK Remover Temporário



func _physics_process(delta: float) -> void:
	input_component.update()
	
	movement_component.move(input_component.move_dir, delta)
	
	if input_component.attack_just_pressed:
		wearpon_sword.attack()


func _on_health_component_health_changed(current_health: int, max_health: int) -> void:
	print('Current Health: %d 				Max Health: %d' % [current_health,max_health])


func _on_health_component_died() -> void:
	print('Player Died')
