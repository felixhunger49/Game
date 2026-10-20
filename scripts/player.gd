extends CharacterBody2D

## Laufgeschwindigkeit in Pixeln pro Sekunde.
@export var speed := 300.0
## Anfangsgeschwindigkeit beim Springen (negativ = nach oben).
@export var jump_velocity := -550.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	move_and_slide()

	# Aus der Welt gefallen: zurück zum Start.
	if position.y > 1500:
		position = Vector2(200, 400)
		velocity = Vector2.ZERO
