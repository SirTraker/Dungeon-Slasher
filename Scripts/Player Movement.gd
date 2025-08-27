extends CharacterBody2D

@export var speed = 3000

const SPEED = 100.0
const ACCEL = 20.0

var input : Vector2

func get_input():
	input.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	return input.normalized()

#func _physics_process(delta):
	#var input_direction = Input.get_vector("Left","Right","Up","Down")
	#velocity = input_direction * speed * delta * 2
	#move_and_slide()

func _process(delta):
	var player_input = get_input()
	
	velocity = lerp(velocity, player_input * SPEED,delta * ACCEL)
	if velocity.length() < 0.05:
		velocity = Vector2.ZERO
	move_and_slide()
	
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	if mouse_pos.x < player_pos.x:
		$Sprite2D.flip_h = true
	else:
		$Sprite2D.flip_h = false
	
	if velocity.length() < 5:
		$Sprite2D.play("idle")
	else :
		if (velocity.x >= 0 and $Sprite2D.flip_h == false) or (velocity.x <= 0 and $Sprite2D.flip_h == true):
			$Sprite2D.play("walking") 
		else:
			$Sprite2D.play_backwards("walking") 
		
	#$"../CanvasLayer/Control/RichTextLabel".text = str("Player Pos: ", player_pos,"\nMouse Pos: ", mouse_pos)
	$"../CanvasLayer/Control/RichTextLabel".text = str("Velocity: ", velocity)
