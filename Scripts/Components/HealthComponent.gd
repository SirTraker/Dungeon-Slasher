class_name HealthComponent extends Node

signal health_changed(current_health : int, max_health : int)
signal	died

@export var max_health : int = 10

var current_health : int

func _ready() -> void:
	current_health = max_health

func damage(amout : int) -> void:
	if amout <= 0:
		return
	
	current_health -= amout
	
	if current_health <= 0:
		current_health = 0
		died.emit()
	
	health_changed.emit(current_health,max_health)

func heal(amount : int) -> void:
	if amount <= 0:
		return
	
	current_health += amount
	
	if current_health > max_health:
		current_health = max_health
		
	health_changed.emit(current_health, max_health)
