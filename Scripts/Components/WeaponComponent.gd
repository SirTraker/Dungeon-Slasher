class_name WeaponComponent extends Node

@export var current_weapon : Weapon

# TODO - Continuar
func attack() -> void:
	if current_weapon == null:
		return
		
	current_weapon.attack()
