class_name Cannonball
extends Node3D
## Breitseite der Piratin: Eine kleine Kanone erscheint vor ihr und feuert eine Kugel im Bogen.
## Die Kugel explodiert, sobald sie den Gegner, den Boden oder das Ende ihrer Flugzeit erreicht.

const SPEED := 15.0
const LIFT := 4.0
const GRAVITY := 9.0
const LIFETIME := 1.6
const EXPLOSION_RADIUS := 2.2
const CANNON_MODEL := "res://assets/maps/props/kanone.glb"

var shooter: CharacterBody3D
var attack: Dictionary
var direction := 1
var velocity := Vector3.ZERO
var age := 0.0
var ball: MeshInstance3D


func launch(from: CharacterBody3D, atk: Dictionary, start: Vector3, dir: int) -> void:
	shooter = from
	attack = atk
	direction = dir
	global_position = start
	velocity = Vector3(dir * SPEED, LIFT, 0)
	ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.32
	sphere.height = 0.64
	ball.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.14)
	mat.metallic = 0.7
	mat.roughness = 0.3
	ball.material_override = mat
	add_child(ball)
	var smoke := SpecialFX._particles(Color(0.85, 0.85, 0.85, 0.6), 40, 0.6, 0.35)
	smoke.local_coords = false
	smoke.one_shot = false
	smoke.explosiveness = 0.0
	smoke.initial_velocity_min = 0.2
	smoke.initial_velocity_max = 0.6
	smoke.gravity = Vector3(0, 0.8, 0)
	add_child(smoke)
	smoke.emitting = true
	_show_cannon(from, start, dir)
	Audio.sfx("cannon", 1.1)
	SpecialFX._flash_sphere(from.get_parent(), start, Color(1, 0.7, 0.3), 0.2, 1.0, 0.15)
	SpecialFX._sparks(from.get_parent(), start, Color(1, 0.7, 0.3), 25, 6.0, 0.3)
	SpecialFX.shake(from, 0.2, 0.2)


func _physics_process(delta: float) -> void:
	age += delta
	velocity.y -= GRAVITY * delta
	global_position += velocity * delta
	ball.rotation.z -= direction * 10.0 * delta
	var target: CharacterBody3D = shooter.opponent if shooter else null
	var hit_target: bool = target != null and target.visible \
		and (target.global_position + Vector3(0, 0.9, 0)).distance_to(global_position) < 1.0
	if hit_target or global_position.y < 0.2 or age > LIFETIME:
		_explode(target)


func _explode(target: CharacterBody3D) -> void:
	var world := get_parent()
	SpecialFX.impact(shooter, global_position, Color(1, 0.55, 0.2))
	SpecialFX._sparks(world, global_position, Color(1, 0.5, 0.1), 60, 9.0, 0.6)
	Audio.sfx("explosion", 1.1)
	if target and target.visible:
		var offset := target.global_position + Vector3(0, 0.9, 0) - global_position
		if offset.length() < EXPLOSION_RADIUS:
			var side := 1.0 if offset.x >= 0.0 else -1.0
			var angle: Vector2 = attack.angle
			if target.take_hit(attack, Vector3(angle.x * side, angle.y, 0).normalized(), shooter.power_time > 0.0,
					shooter.outgoing_multiplier()):
				shooter.add_special_energy(attack.damage * shooter.SPECIAL_PER_DAMAGE_DEALT)
				shooter.on_hit_landed(target)
	queue_free()


## Die kleine Kanone steht kurz vor der Piratin und verschwindet dann wieder.
func _show_cannon(from: CharacterBody3D, start: Vector3, dir: int) -> void:
	if not ResourceLoader.exists(CANNON_MODEL):
		return
	var cannon: Node3D = load(CANNON_MODEL).instantiate()
	from.get_parent().add_child(cannon)
	cannon.global_position = Vector3(start.x - dir * 0.4, from.global_position.y, 0)
	cannon.scale = Vector3.ONE * 0.6
	cannon.rotation.y = 0.0 if dir > 0 else PI
	var tween := cannon.create_tween()
	tween.tween_property(cannon, "position:x", cannon.position.x - dir * 0.3, 0.08)
	tween.tween_interval(0.5)
	tween.tween_property(cannon, "scale", Vector3.ONE * 0.01, 0.2)
	tween.tween_callback(cannon.queue_free)
