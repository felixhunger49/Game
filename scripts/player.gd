extends CharacterBody2D

## Wird ausgelöst, wenn die Figur aus der Arena gefallen ist.
signal fell_off(player)

## 1 oder 2: bestimmt, welche Tasten die Figur steuern (p1_... oder p2_...).
@export var player_id := 1
@export var color := Color(1, 0.82, 0.4)
@export var speed := 320.0
@export var jump_velocity := -620.0
@export var max_jumps := 2
@export var start_facing := 1

## Schaden pro Treffer in Prozent.
@export var attack_damage := 10.0
## Rückstoß bei 0 % Schaden und zusätzlicher Rückstoß pro Prozent Schaden.
@export var base_knockback := 250.0
@export var knockback_per_damage := 9.0

## Alles außerhalb dieses Bereichs zählt als heruntergefallen.
const BLAST_ZONE := Rect2(-250, -600, 1780, 1500)
const ATTACK_RANGE := Vector2(80, 60)
const ATTACK_COOLDOWN := 0.35

var opponent: CharacterBody2D
var damage := 0.0
var stocks := 3
var facing := 1
var jumps_left := 0
var hitstun := 0.0
var attack_timer := 0.0
var spawn_position := Vector2.ZERO
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var body: ColorRect = $Body
@onready var eye: ColorRect = $Eye
@onready var attack_flash: ColorRect = $AttackFlash


func _ready() -> void:
	spawn_position = position
	body.color = color
	facing = start_facing
	jumps_left = max_jumps
	_update_facing_visuals()


func _physics_process(delta: float) -> void:
	attack_timer = max(attack_timer - delta, 0.0)
	hitstun = max(hitstun - delta, 0.0)
	if attack_timer < ATTACK_COOLDOWN - 0.1:
		attack_flash.visible = false

	velocity.y += gravity * delta
	if is_on_floor():
		jumps_left = max_jumps

	if hitstun > 0.0:
		# Getroffen: keine Kontrolle, die Figur fliegt weiter.
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	else:
		_handle_input(delta)

	move_and_slide()

	if not BLAST_ZONE.has_point(position):
		_lose_stock()


func _handle_input(delta: float) -> void:
	var direction := Input.get_axis(_action("left"), _action("right"))
	var accel := 3000.0 if is_on_floor() else 1400.0
	velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
	if direction != 0.0:
		facing = int(sign(direction))
		_update_facing_visuals()

	if Input.is_action_just_pressed(_action("jump")) and jumps_left > 0:
		velocity.y = jump_velocity
		jumps_left -= 1

	if Input.is_action_just_pressed(_action("attack")) and attack_timer == 0.0:
		attack()


func attack() -> void:
	attack_timer = ATTACK_COOLDOWN
	attack_flash.visible = true
	if opponent == null or not opponent.visible:
		return
	var offset := opponent.global_position - global_position
	var in_front: bool = signf(offset.x) == facing or absf(offset.x) < 10.0
	if in_front and absf(offset.x) <= ATTACK_RANGE.x and absf(offset.y) <= ATTACK_RANGE.y:
		opponent.take_hit(attack_damage, Vector2(facing, -0.6).normalized())


## Je mehr Schaden die Figur schon hat, desto weiter fliegt sie.
func take_hit(amount: float, direction: Vector2) -> void:
	damage += amount
	velocity = direction * (base_knockback + damage * knockback_per_damage)
	hitstun = 0.15 + damage * 0.004


func _lose_stock() -> void:
	stocks -= 1
	damage = 0.0
	hitstun = 0.0
	velocity = Vector2.ZERO
	if stocks > 0:
		position = spawn_position
	else:
		visible = false
		set_physics_process(false)
	fell_off.emit(self)


func _action(name: String) -> String:
	return "p%d_%s" % [player_id, name]


func _update_facing_visuals() -> void:
	eye.position.x = 6.0 if facing > 0 else -14.0
	attack_flash.position.x = 20.0 if facing > 0 else -70.0
