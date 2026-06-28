class_name MovementComponent extends Node

@export var body: CharacterBody2D
@export var sprite: AnimatedSprite2D
@export var speed:= 100.0

var direction : Vector2 = Vector2.ZERO

func move(_direction : Vector2,_delta : float) -> void:
	if body == null:
		push_error('Body not defined') 
		return
	direction = _direction
	
	#Movement
	if direction:
		body.velocity = direction * speed
	else :
		body.velocity = body.velocity.move_toward(Vector2.ZERO,speed)
	
	body.move_and_slide()
	_update_sprite()
	_update_animation()

func _update_sprite() -> void:
	var mouse_pos = body.get_global_mouse_position()
	sprite.flip_h = mouse_pos.x < body.global_position.x
	
func _update_animation() -> void:
	if body.velocity == Vector2.ZERO:
		sprite.play("idle")
		#print('playing idle')
	elif (body.velocity.x >= 0 and !sprite.flip_h) or (body.velocity.x <= 0 and sprite.flip_h):
		sprite.play("walking")
		#print('playing walking')
	else:
		sprite.play_backwards("walking")
		#print('playing backwards')
